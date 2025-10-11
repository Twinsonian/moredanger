local M = {}

local DIFFICULTY_MULTIPLIERS = {
    off       = {speed = 1.05, damage = 0, health = 0},
    normal    = {speed = 1.1, damage = 1, health = 0},
    hard      = {speed = 1.15, damage = 2, health = 10},
    nightmare = {speed = 1.2, damage = 3, health = 20},
    hell      = {speed = 1.25, damage = 4, health = 30}
}

-- Hostile mob filter
M.hostile_mobs = setmetatable({}, {
    __index = function(_, name)
        local def = minetest.registered_entities[name]
        return def and def._cmi_is_mob and def.type == "monster"
    end
})

-- Boost a mob once per difficulty
function M.boost_mob(obj, luaent)
    if not obj or not luaent then return end
    if not M.hostile_mobs[luaent.name] then return end

    local difficulty = minetest.settings:get("moredanger_difficulty") or "normal"
    local level = DIFFICULTY_MULTIPLIERS[difficulty]
    if not level then return end

    local props = obj:get_properties()
    if not props or not props.hp_max then return end

    -- Store base HP once
    if not luaent._moredanger_base_hp then
        luaent._moredanger_base_hp = obj:get_hp()
    end

    if luaent._moredanger_boosted then return end

    local base_hp = luaent._moredanger_base_hp
    local new_hp = base_hp + level.health

    obj:set_properties({hp_max = new_hp})
    obj:set_hp(new_hp)
    luaent.hp_max = new_hp
    luaent.health = new_hp

    -- Speed boost (walk/run velocity)
    if not luaent._moredanger_original_walk_velocity and luaent.walk_velocity then
        luaent._moredanger_original_walk_velocity = luaent.walk_velocity
    end
    if not luaent._moredanger_original_run_velocity and luaent.run_velocity then
        luaent._moredanger_original_run_velocity = luaent.run_velocity
    end
    if luaent._moredanger_original_walk_velocity then
        luaent.walk_velocity = luaent._moredanger_original_walk_velocity * level.speed
    end
    if luaent._moredanger_original_run_velocity then
        luaent.run_velocity = luaent._moredanger_original_run_velocity * level.speed
    end
    luaent.v_start = true  -- triggers velocity recalculation

    -- Damage boost
    if not luaent._moredanger_original_damage and luaent.damage then
        luaent._moredanger_original_damage = luaent.damage
    end
    if luaent._moredanger_original_damage then
        luaent.damage = luaent._moredanger_original_damage + level.damage
        local group = luaent.damage_group or "fleshy"
        luaent.damage_groups = {[group] = luaent.damage}
    end

    luaent._moredanger_boosted = true
end

-- Refresh mob when difficulty changes
function M.refresh_mob(obj, luaent)
    if not obj or not luaent then return end
    if not M.hostile_mobs[luaent.name] then return end

    local difficulty = minetest.settings:get("moredanger_difficulty") or "normal"
    local level = DIFFICULTY_MULTIPLIERS[difficulty]
    if not level then return end

    local props = obj:get_properties()
    if not props or not props.hp_max then return end

    -- Restore base HP if missing
    if not luaent._moredanger_base_hp then
        luaent._moredanger_base_hp = props.hp_max
    end

    local base_hp = luaent._moredanger_base_hp
    local new_hp = base_hp + level.health

    obj:set_properties({hp_max = new_hp})
    obj:set_hp(new_hp)
    luaent.hp_max = new_hp
    luaent.health = new_hp

    -- Reapply speed (walk/run velocity)
    if luaent._moredanger_original_walk_velocity then
        luaent.walk_velocity = luaent._moredanger_original_walk_velocity * level.speed
    end
    if luaent._moredanger_original_run_velocity then
        luaent.run_velocity = luaent._moredanger_original_run_velocity * level.speed
    end
    luaent.v_start = true

    -- Reapply damage
    if luaent._moredanger_original_damage then
        luaent.damage = luaent._moredanger_original_damage + level.damage
        local group = luaent.damage_group or "fleshy"
        luaent.damage_groups = {[group] = luaent.damage}
    end

    luaent._moredanger_boosted = true
end

-- Runtime loop: boost nearby mobs and clean up distant ones
local BOOST_RADIUS = 50
local BOOST_INTERVAL = 1
local timer = 0

minetest.register_globalstep(function(dtime)
    timer = timer + dtime
    if timer < BOOST_INTERVAL then return end
    timer = 0

    local players = minetest.get_connected_players()
    local seen = {}

    for _, player in ipairs(players) do
        local pos = player:get_pos()
        local objs = minetest.get_objects_inside_radius(pos, BOOST_RADIUS)
        for _, obj in ipairs(objs) do
            local luaent = obj:get_luaentity()
            if luaent and luaent.name and M.hostile_mobs[luaent.name] then
                seen[obj] = true
                M.boost_mob(obj, luaent)
            end
        end
    end

    -- Cleanup: reset mobs that were boosted but are no longer near any player
    for _, obj in pairs(minetest.luaentities) do
        if obj and obj.object and obj.object:get_luaentity() then
            local luaent = obj.object:get_luaentity()
            if luaent and luaent._moredanger_boosted and not seen[obj.object] then
                if luaent._moredanger_original_walk_velocity then
                    luaent.walk_velocity = luaent._moredanger_original_walk_velocity
                end
                if luaent._moredanger_original_run_velocity then
                    luaent.run_velocity = luaent._moredanger_original_run_velocity
                end
                if luaent._moredanger_original_damage then
                    luaent.damage = luaent._moredanger_original_damage
                    local group = luaent.damage_group or "fleshy"
                    luaent.damage_groups = {[group] = luaent.damage}
                end
                if luaent._moredanger_base_hp then
                    obj.object:set_properties({hp_max = luaent._moredanger_base_hp})
                    obj.object:set_hp(luaent._moredanger_base_hp)
                    luaent.hp_max = luaent._moredanger_base_hp
                    luaent.health = luaent._moredanger_base_hp
                end
                luaent._moredanger_boosted = nil
            end
        end
    end
end)

return M

