local M = {}

local DIFFICULTY_MULTIPLIERS = {
    normal    = {speed = 1.1, damage = 1, health = 5},
    hard      = {speed = 1.2, damage = 2, health = 10},
    nightmare = {speed = 1.3, damage = 3, health = 20},
    hell      = {speed = 1.4, damage = 4, health = 30}
}

M.hostile_mobs = {
    ["mobs_mc:zombie"] = true,
    ["mobs_mc:skeleton"] = true,
    ["mobs_mc:creeper"] = true,
    ["mobs_mc:spider"] = true,
    ["mobs_mc:enderman"] = true,
    ["mobs_mc:witch"] = true,
    ["mobs_mc:slime"] = true,
    ["mobs_mc:blaze"] = true,
    ["mobs_mc:ghast"] = true,
    ["mobs_mc:guardian"] = true,
    ["mobs_mc:evoker"] = true,
    ["mobs_mc:vindicator"] = true,
    ["mobs_mc:pillager"] = true,
    ["mobs_mc:ravager"] = true
}

M.base_hp = {
    ["mobs_mc:zombie"] = 20,
    ["mobs_mc:skeleton"] = 20,
    ["mobs_mc:creeper"] = 20,
    ["mobs_mc:spider"] = 16,
    ["mobs_mc:enderman"] = 40,
    ["mobs_mc:witch"] = 26,
    ["mobs_mc:slime"] = 16,
    ["mobs_mc:blaze"] = 20,
    ["mobs_mc:ghast"] = 10,
    ["mobs_mc:guardian"] = 30,
    ["mobs_mc:evoker"] = 24,
    ["mobs_mc:vindicator"] = 24,
    ["mobs_mc:pillager"] = 24,
    ["mobs_mc:ravager"] = 100
}

function M.boost_mob(obj, luaent)
    if not luaent or not obj then return end
    if not M.hostile_mobs[luaent.name] then return end

    local difficulty = minetest.settings:get("moredanger_difficulty") or "normal"
    local level = DIFFICULTY_MULTIPLIERS[difficulty]
    if not level then return end

    local base_hp = M.base_hp[luaent.name] or luaent.health or 10

    -- Respect Mineclonia's clamp
    luaent.hp_max = base_hp
    luaent.health = math.min(luaent.health or base_hp, base_hp)

    -- Speed boost
    if not luaent._moredanger_original_speed and luaent.movement_speed then
        luaent._moredanger_original_speed = luaent.movement_speed
    end
    luaent.movement_speed = luaent._moredanger_original_speed * level.speed

    -- Damage boost
    if not luaent._moredanger_original_damage and luaent.damage then
        luaent._moredanger_original_damage = luaent.damage
    end
    if luaent._moredanger_original_damage then
        luaent.damage = luaent._moredanger_original_damage + level.damage
    end

    -- Overflow healing or damage
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
end

function M.refresh_mob(obj, luaent)
    local difficulty = minetest.settings:get("moredanger_difficulty") or "normal"
    local level = DIFFICULTY_MULTIPLIERS[difficulty]
    if not level then return end  -- <-- Add this line to prevent nil access

    local base_hp = M.base_hp[luaent.name] or luaent.health or 10

    luaent._overflow_max = level.health
    luaent._overflow_hp = level.health
    luaent.health = base_hp
    luaent._last_health = base_hp
end


return M

