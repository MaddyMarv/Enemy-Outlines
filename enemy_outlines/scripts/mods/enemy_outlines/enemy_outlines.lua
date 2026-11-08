local mod = get_mod("enemy_outlines")

local OutlineSettings = require("scripts/settings/outline/outline_settings")
local HitZone = require("scripts/utilities/attack/hit_zone")

local function get_rgb_color(prefix)
    local c = mod:get(prefix .. "_color")
    if c and type(c) == "table" and #c >= 4 then
        local a = (c[1] or 255) / 255
        return { (c[2] / 255) * a, (c[3] / 255) * a, (c[4] / 255) * a }
    elseif c and type(c) == "table" and #c >= 3 then
        return { c[1] / 255, c[2] / 255, c[3] / 255 }
    end
    local defaults = {
        aimed = {255, 255, 255},
        human_boss = {255, 50, 100},
        monster = {255, 0, 0},
        disabler = {0, 255, 0},
        ranged_special = {0, 255, 255},
        poxburster = {255, 255, 0},
        ranged_elite = {0, 0, 255},
        melee_elite = {81, 53, 146},
        crushers_maulers = {255, 140, 0},
        shooters = {245, 245, 135},
        chaff = {105, 55, 20},
    }
    local d = defaults[prefix]
    if d then
        return { d[1] / 255, d[2] / 255, d[3] / 255 }
    end
    return { 1, 1, 1 }
end

local function get_material_layers()
    return { "minion_outline", "minion_outline_reversed_depth" }
end

local function _check_line_of_sight(player_unit, target_unit)
    local player_pos = Unit.local_position(player_unit, 1) + Vector3(0, 0, 1.6)
    local target_pos = Unit.local_position(target_unit, 1) + Vector3(0, 0, 1.0)
    local to_target = target_pos - player_pos
    local distance = Vector3.length(to_target)
    if distance < 0.5 then return true end
    local direction = Vector3.normalize(to_target)

    local world = Managers.world:world("level_world")
    if not world then return true end
    local physics_world = World.physics_world(world)
    if not physics_world then return true end

    local hit = PhysicsWorld.raycast(physics_world, player_pos, direction, distance, "closest", "types", "statics", "collision_filter", "filter_minion_line_of_sight_check")
    return not hit
end

local _outline_tag_fixed = setmetatable({}, { __mode = "k" })

local function _fix_missing_outline_tags(unit)
    local visual_loadout_extension = ScriptUnit.has_extension(unit, "visual_loadout_system") and ScriptUnit.extension(unit, "visual_loadout_system")
    if not visual_loadout_extension then return end

    for slot_name, slot in pairs(visual_loadout_extension:inventory_slots()) do
        if slot.use_outline == nil and visual_loadout_extension:slot_unit(slot_name) then
            slot.use_outline = true
        end
    end
    _outline_tag_fixed[unit] = true
end

local function _minion_alive_check(unit)
    if not HEALTH_ALIVE[unit] then
        return false
    end
    if not _outline_tag_fixed[unit] then
        _fix_missing_outline_tags(unit)
    end
    return true
end

local function update_outline_settings()
    local layers = get_material_layers()

    OutlineSettings.MinionOutlineExtension.mod_outline_human_boss = {
        priority = 20,
        color = get_rgb_color("human_boss"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
    OutlineSettings.MinionOutlineExtension.mod_outline_monster = {
        priority = 20,
        color = get_rgb_color("monster"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
    OutlineSettings.MinionOutlineExtension.mod_outline_disabler = {
        priority = 20,
        color = get_rgb_color("disabler"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
    OutlineSettings.MinionOutlineExtension.mod_outline_ranged_special = {
        priority = 20,
        color = get_rgb_color("ranged_special"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
    OutlineSettings.MinionOutlineExtension.mod_outline_poxburster = {
        priority = 20,
        color = get_rgb_color("poxburster"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
    OutlineSettings.MinionOutlineExtension.mod_outline_ranged_elite = {
        priority = 20,
        color = get_rgb_color("ranged_elite"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
    OutlineSettings.MinionOutlineExtension.mod_outline_melee_elite = {
        priority = 20,
        color = get_rgb_color("melee_elite"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
    OutlineSettings.MinionOutlineExtension.mod_outline_aimed = {
        priority = 0,
        color = get_rgb_color("aimed"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
    OutlineSettings.MinionOutlineExtension.mod_outline_crushers_maulers = {
        priority = 20,
        color = get_rgb_color("crushers_maulers"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
    OutlineSettings.MinionOutlineExtension.mod_outline_shooters = {
        priority = 20,
        color = get_rgb_color("shooters"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
    OutlineSettings.MinionOutlineExtension.mod_outline_chaff = {
        priority = 20,
        color = get_rgb_color("chaff"),
        material_layers = layers,
        visibility_check = _minion_alive_check,
    }
end

update_outline_settings()

local _MOD_OUTLINE_NAMES = {
    "mod_outline_human_boss",
    "mod_outline_monster",
    "mod_outline_disabler",
    "mod_outline_ranged_special",
    "mod_outline_poxburster",
    "mod_outline_ranged_elite",
    "mod_outline_melee_elite",
    "mod_outline_aimed",
    "mod_outline_crushers_maulers",
    "mod_outline_shooters",
    "mod_outline_chaff",
}

local function _clear_all_mod_outlines()
    local extension_manager = Managers.state and Managers.state.extension
    if not extension_manager then return end

    local outline_system = extension_manager:system("outline_system")
    local side_system = extension_manager:system("side_system")
    if not outline_system or not side_system then return end

    for unit, _ in pairs(side_system.side_by_unit) do
        if outline_system._unit_extension_data and outline_system._unit_extension_data[unit] then
            for i = 1, #_MOD_OUTLINE_NAMES do
                local name = _MOD_OUTLINE_NAMES[i]
                if outline_system:has_outline(unit, name) then
                    outline_system:remove_outline(unit, name)
                end
            end
        end
    end
end

local CATEGORY_SETTINGS = {
    human_boss = "outline_human_bosses",
    monster = "outline_monsters",
    disabler = "outline_disablers",
    ranged_special = "outline_ranged_specials",
    poxburster = "outline_poxbursters",
    ranged_elite = "outline_ranged_elites",
    melee_elite = "outline_melee_elites",
    crushers_maulers = "outline_crushers_maulers",
    shooters = "outline_shooters",
    chaff = "outline_chaff",
}

local _enabled_outline = {}
local _only_targeting_me = false
local _max_dist_sq = nil
local _enable_aimed = false
local _aimed_ignore_distance = false

local function refresh_settings()
    for category, setting_id in pairs(CATEGORY_SETTINGS) do
        _enabled_outline[category] = mod:get(setting_id) and ("mod_outline_" .. category) or nil
    end
    _only_targeting_me = mod:get("only_targeting_me")
    local max_distance = mod:get("max_distance")
    if max_distance == nil then max_distance = 30 end
    _max_dist_sq = max_distance > 0 and (max_distance * max_distance) or nil
    _enable_aimed = mod:get("outline_aimed")
    _aimed_ignore_distance = mod:get("aimed_ignore_distance_limit")
end

refresh_settings()

local _refresh_outlines = false
local _aimed_unit = nil

mod.on_setting_changed = function(setting_id)
    refresh_settings()
    update_outline_settings()
    _refresh_outlines = true
end

mod.on_disabled = function(initial_call)
    _clear_all_mod_outlines()
    _aimed_unit = nil
end

mod.on_enabled = function(initial_call)
    refresh_settings()
    update_outline_settings()
    _refresh_outlines = true
end

mod.on_unload = function(exit_game)
    _clear_all_mod_outlines()
end

local function _resolve_target_from_game_object(enemy_unit, game_session, unit_spawner)
    local ok_go_id, game_object_id = pcall(unit_spawner.game_object_id, unit_spawner, enemy_unit)
    if not ok_go_id or not game_object_id then return nil end

    local ok_has_field, has_field = pcall(GameSession.has_game_object_field, game_session, game_object_id, "target_unit_id")
    if not ok_has_field or has_field ~= true then return nil end

    local ok_target_id, target_unit_id = pcall(GameSession.game_object_field, game_session, game_object_id, "target_unit_id")
    if not ok_target_id or not target_unit_id or target_unit_id == NetworkConstants.invalid_game_object_id then return nil end

    local ok_unit, target_unit = pcall(unit_spawner.unit, unit_spawner, target_unit_id)
    if ok_unit and target_unit and HEALTH_ALIVE[target_unit] and Unit.alive(target_unit) then
        return target_unit
    end
    return nil
end

local function _resolve_target_from_perception(enemy_unit, perception_map)
    if not perception_map then return nil end
    local ext = perception_map[enemy_unit]
    if not ext then return nil end
    local perception_component = ext._perception_component
    local target_unit = perception_component and perception_component.target_unit
    if target_unit and HEALTH_ALIVE[target_unit] and Unit.alive(target_unit) then
        return target_unit
    end
    return nil
end

local function _get_enemy_category(unit)
    local unit_data_ext = ScriptUnit.has_extension(unit, "unit_data_system") and ScriptUnit.extension(unit, "unit_data_system")
    if not unit_data_ext then return nil end
    local breed = unit_data_ext:breed()
    if not breed or not breed.tags then return nil end
    
    if breed.tags.captain or breed.tags.cultist_captain then
        return "human_boss"
    elseif breed.tags.monster then
        return "monster"
    elseif breed.tags.disabler then
        return "disabler"
    elseif breed.tags.special then
        if breed.tags.bomber then
            return "poxburster"
        elseif breed.ranged or breed.tags.scrambler or breed.tags.sniper or breed.name:find("grenadier") or breed.name:find("flamer") then
            return "ranged_special"
        else
            return "poxburster"
        end
    elseif breed.tags.elite then
        if breed.name == "chaos_ogryn_executor" or breed.name == "renegade_executor" then
            return "crushers_maulers"
        elseif breed.ranged then
            return "ranged_elite"
        else
            return "melee_elite"
        end
    elseif breed.name == "cultist_assault" or breed.name == "renegade_assault" or breed.name == "renegade_rifleman" or breed.ranged then
        return "shooters"
    else
        return "chaff"
    end
end

local SCAN_INTERVAL = 0.25
local _last_scan_time = 0

local _unit_category_cache = setmetatable({}, { __mode = "k" })
local _unit_is_enemy_cache = setmetatable({}, { __mode = "k" })

local function _is_enemy(unit, side_system, enemy_side_names)
    local is_enemy = _unit_is_enemy_cache[unit]
    if is_enemy == nil then
        is_enemy = false
        local unit_side = side_system.side_by_unit[unit]
        if unit_side then
            local unit_side_name = unit_side:name()
            for i = 1, #enemy_side_names do
                if enemy_side_names[i] == unit_side_name then
                    is_enemy = true
                    break
                end
            end
        end
        _unit_is_enemy_cache[unit] = is_enemy
    end
    return is_enemy
end

local function _in_range(player_pos, unit)
    if not _max_dist_sq or not player_pos then
        return true
    end
    local enemy_pos = Unit.local_position(unit, 1)
    return enemy_pos ~= nil and Vector3.distance_squared(player_pos, enemy_pos) <= _max_dist_sq
end

local AIM_RAY_MAX_DISTANCE = 200

local function _enemy_under_crosshair(player_unit, side_system, enemy_side_names)
    local unit_data_extension = ScriptUnit.has_extension(player_unit, "unit_data_system")
    local first_person = unit_data_extension and unit_data_extension:read_component("first_person")
    local world = first_person and Managers.world:world("level_world")
    local physics_world = world and World.physics_world(world)
    if not physics_world then
        return nil
    end

    local ray_length = AIM_RAY_MAX_DISTANCE
    if not _aimed_ignore_distance and _max_dist_sq then
        ray_length = math.sqrt(_max_dist_sq) + 2
    end

    local hits = PhysicsWorld.raycast(physics_world, first_person.position, Quaternion.forward(first_person.rotation), ray_length,
        "all", "types", "both", "max_hits", 32, "collision_filter", "filter_player_character_shooting_raycast")
    if not hits then
        return nil
    end

    local side_by_unit = side_system.side_by_unit
    local best_distance = ray_length + 1
    local best_unit = nil
    for i = 1, #hits do
        local hit = hits[i]
        local distance = hit.distance or hit[2]
        if distance < best_distance then
            local actor = hit.actor or hit[4]
            local unit = actor and Actor.unit(actor)
            if unit and unit ~= player_unit then
                if not side_by_unit[unit] then
                    best_distance = distance
                    best_unit = nil
                elseif HEALTH_ALIVE[unit] and _is_enemy(unit, side_system, enemy_side_names) and HitZone.get_name(unit, actor) ~= "afro" then
                    best_distance = distance
                    best_unit = unit
                end
            end
        end
    end
    return best_unit
end

local function _update_aimed_outline(outline_system, side_system, enemy_side_names, player_unit, player_pos)
    local target = nil
    if _enable_aimed then
        local unit = _enemy_under_crosshair(player_unit, side_system, enemy_side_names)
        if unit and Unit.alive(unit) and outline_system._unit_extension_data[unit] ~= nil
            and (_aimed_ignore_distance or _in_range(player_pos, unit)) then
            target = unit
        end
    end

    local previous = _aimed_unit
    if previous and previous ~= target and outline_system._unit_extension_data[previous] ~= nil
        and outline_system:has_outline(previous, "mod_outline_aimed") then
        outline_system:remove_outline(previous, "mod_outline_aimed")
    end
    if target and not outline_system:has_outline(target, "mod_outline_aimed") then
        outline_system:add_outline(target, "mod_outline_aimed")
    end
    _aimed_unit = target
end

mod.update = function(dt)
    if not mod:is_enabled() then
        return
    end

    local run_heavy_scan = false
    _last_scan_time = _last_scan_time + dt
    if _last_scan_time >= SCAN_INTERVAL or _refresh_outlines then
        run_heavy_scan = true
        _last_scan_time = 0
    end

    local extension_manager = Managers.state and Managers.state.extension
    if not extension_manager then return end

    local outline_system = extension_manager:system("outline_system")
    local side_system = extension_manager:system("side_system")
    if not outline_system or not side_system then return end

    local player_unit = Managers.player and Managers.player:local_player(1) and Managers.player:local_player(1).player_unit
    if not player_unit then return end

    local player_side = side_system.side_by_unit[player_unit]
    if not player_side then return end

    local enemy_side_names = player_side:relation_side_names("enemy")
    if not enemy_side_names then return end

    local player_pos = Unit.local_position(player_unit, 1)

    if run_heavy_scan then
        local refresh = _refresh_outlines
        _refresh_outlines = false
        if refresh then
            _aimed_unit = nil
        end

        local unit_spawner, game_session, perception_map = nil, nil, nil
        if _only_targeting_me then
            unit_spawner = Managers.state.unit_spawner
            local game_session_manager = Managers.state.game_session
            if game_session_manager and type(game_session_manager.game_session) == "function" then
                local ok, session = pcall(game_session_manager.game_session, game_session_manager)
                game_session = ok and session or nil
            end

            local perception_system = extension_manager:system("perception_system")
            if perception_system and type(perception_system.unit_to_extension_map) == "function" then
                local ok, map = pcall(perception_system.unit_to_extension_map, perception_system)
                perception_map = ok and map or nil
            end
        end

        for unit, _ in pairs(side_system.side_by_unit) do
            if HEALTH_ALIVE[unit] and Unit.alive(unit) and _is_enemy(unit, side_system, enemy_side_names)
                and outline_system._unit_extension_data[unit] ~= nil then
                if refresh then
                    for i = 1, #_MOD_OUTLINE_NAMES do
                        local name = _MOD_OUTLINE_NAMES[i]
                        if outline_system:has_outline(unit, name) then
                            outline_system:remove_outline(unit, name)
                        end
                    end
                end

                local category = _unit_category_cache[unit]
                if category == nil then
                    category = _get_enemy_category(unit) or false
                    _unit_category_cache[unit] = category
                end

                local outline_name = category and _enabled_outline[category]
                if outline_name then
                    local should_outline = false
                    if _in_range(player_pos, unit) and _check_line_of_sight(player_unit, unit) then
                        if _only_targeting_me then
                            local target_unit = nil
                            if game_session and unit_spawner then
                                target_unit = _resolve_target_from_game_object(unit, game_session, unit_spawner)
                            end
                            if not target_unit then
                                target_unit = _resolve_target_from_perception(unit, perception_map)
                            end
                            should_outline = target_unit == player_unit
                        else
                            should_outline = true
                        end
                    end

                    if should_outline then
                        if not outline_system:has_outline(unit, outline_name) then
                            outline_system:add_outline(unit, outline_name)
                        end
                    elseif outline_system:has_outline(unit, outline_name) then
                        outline_system:remove_outline(unit, outline_name)
                    end
                end
            end
        end
    end

    _update_aimed_outline(outline_system, side_system, enemy_side_names, player_unit, player_pos)
end
