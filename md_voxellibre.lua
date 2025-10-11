local M = {}

local DIFFICULTY_MULTIPLIERS = {
    off       = {speed = 1.0, damage = 0, health = 0},
    normal    = {speed = 1.1, damage = 1, health = 5},
    hard      = {speed = 1.2, damage = 2, health = 10},
    nightmare = {speed = 1.3, damage = 3, health = 20},
    hell      = {speed = 1.4, damage = 4, health = 30}
}

-- Dynamically detect hostile mobs
M.hostile_mobs = setmetatable({}, {
    __index = function(_, name)
        local def = minetest.registered_entities[name]
        return def and def.type == "monster"
    end
})

-- Helper: Apply movement speed boost
local function apply_speed_boost(luaent, level)
    if not luaent._base_speed then
        luaent._base_speed = luaent.movement_speed or 1.0
    end
    if not luaent._base_walk_speed and luaent.walk_speed then
        luaent._base_walk_speed = luaent.walk_speed
    end
    if not luaent._base_run_speed and luaent.run_speed then
        luaent._base_run_speed = luaent.run_speed
    end
    if not luaent._base_run_velocity and luaent.run_velocity then
        luaent._base_run_velocity = luaent.run_velocity
    end

    luaent.movement_speed = luaent._base_speed * level.speed
    if luaent._base_walk_speed then
        luaent.walk_speed = luaent._base_walk_speed * level.speed
    end
    if luaent._base_run_speed then
        luaent.run_speed = luaent._base_run_speed * level.speed
    end
    if luaent._base_run_velocity then
        luaent.run_velocity = luaent._base_run_velocity * level.speed
    end
end

-- Boost mob stats and apply overflow health
function M.boost_mob(obj, luaent)
    if not obj or not luaent then return end
    if not M.hostile_mobs[luaent.name] then return end

    local difficulty = minetest.settings:get("moredanger_difficulty") or "normal"
    local level = DIFFICULTY_MULTIPLIERS[difficulty]
    if not level then return end

    -- Initialize overflow pool if missing (first-time spawn)
    if luaent._overflow_hp == nil then
        M.refresh_mob(obj, luaent)
    end

    -- Base HP from initial definition
    local base_hp = luaent.initial_properties and luaent.initial_properties.hp_max or luaent.health or 10

    -- Clamp visible HP
    luaent.hp_max = base_hp
    luaent.health = math.min(luaent.health or base_hp, base_hp)

    -- Speed boost
    apply_speed_boost(luaent, level)

    -- Damage boost
    if not luaent._base_damage and luaent.damage then
        luaent._base_damage = luaent.damage
    end
    if luaent._base_damage then
        luaent.damage = luaent._base_damage + level.damage
    end

    -- Overflow health logic
    local current = luaent.health or 0
    local last = luaent._last_health or current
    local lost = last - current

    if lost > 0 and luaent._overflow_hp and luaent._overflow_hp > 0 then
        local heal = math.min(lost, luaent._overflow_hp)
        luaent.health = luaent.health + heal
        luaent._overflow_hp = luaent._overflow_hp - heal
    elseif current >= luaent.hp_max and luaent._overflow_hp and luaent._overflow_hp < luaent._overflow_max then
        luaent.health = luaent.health - 0.1
    end

    luaent._last_health = luaent.health
    luaent._boosted = true
end

-- Refresh mob when difficulty changes or on first scan
function M.refresh_mob(obj, luaent)
    if not obj or not luaent then return end
    if not M.hostile_mobs[luaent.name] then return end

    local difficulty = minetest.settings:get("moredanger_difficulty") or "normal"
    local level = DIFFICULTY_MULTIPLIERS[difficulty]
    if not level then return end

    local base_hp = luaent.initial_properties and luaent.initial_properties.hp_max or luaent.health or 10

    luaent._overflow_max = level.health
    luaent._overflow_hp = level.health
    luaent.health = base_hp
    luaent._last_health = base_hp
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
            if luaent and luaent._boosted and not seen[obj.object] then
                luaent.movement_speed = luaent._base_speed or luaent.movement_speed
                luaent.walk_speed = luaent._base_walk_speed or luaent.walk_speed
                luaent.run_speed = luaent._base_run_speed or luaent.run_speed
                luaent.run_velocity = luaent._base_run_velocity or luaent.run_velocity
                luaent.damage = luaent._base_damage or luaent.damage
                luaent._boosted = nil
            end
        end
    end
end)

return M

