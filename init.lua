-- Load modules
local modname = minetest.get_current_modname()

local debug = dofile(minetest.get_modpath(modname) .. "/md_debug.lua")
local register_commands = dofile(minetest.get_modpath(modname) .. "/md_commands.lua")
local gui = dofile(minetest.get_modpath(modname) .. "/md_gui.lua")
local boost = nil
local LAST_DIFFICULTY = nil

local game_id = minetest.get_game_info().id or "unknown"
local modpath = minetest.get_modpath(modname)

-- Load user-configurable settings
local enable_hard_mode = minetest.settings:get_bool("moredanger.enable_hard_mode", false)
local enable_nightmare_mode = minetest.settings:get_bool("moredanger.enable_nightmare_mode", false)
local enable_hell_mode = minetest.settings:get_bool("moredanger.enable_hell_mode", false)
local debug_mode = minetest.settings:get_bool("moredanger.debug_mode", true)
local nightmare_effect_chance = tonumber(minetest.settings:get("moredanger.nightmare_effect_chance")) or 0.33
local hell_effect_chance = tonumber(minetest.settings:get("moredanger.hell_effect_chance")) or 0.5

-- Store the message to show based on environment
local startup_message = nil

-- Detect game environment
if game_id == "mineclonia" then
    boost = dofile(modpath .. "/md_mineclonia.lua")
    startup_message = "More Danger Enabled for Mineclonia."

elseif minetest.get_modpath("mobs") then
    boost = dofile(modpath .. "/md_mobsredo.lua")
    startup_message = "More Danger Enabled for Mobs Redo."

else
    startup_message = "More Danger could not be enabled — no compatible mob API found."
    return
end

-- Show startup message as a temporary HUD to the first player who joins
local notified = false
minetest.register_on_joinplayer(function(player)
    if not notified and startup_message then
        local id = player:hud_add({
            hud_elem_type = "text",
            position = {x=0.5, y=0.1},
            offset = {x=0, y=0},
            text = startup_message,
            alignment = {x=0, y=0},
            scale = {x=100, y=100},
            number = 0xFFFFFF
        })
        minetest.after(5, function()
            player:hud_remove(id)
        end)
        notified = true
    end
end)

-- Periodic difficulty scan
local function periodic_difficulty_scan()
    local difficulty = minetest.settings:get("moredanger_difficulty") or "normal"

    if difficulty ~= LAST_DIFFICULTY then
        LAST_DIFFICULTY = difficulty
        for _, player in ipairs(minetest.get_connected_players()) do
            local pos = player:get_pos()
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 200)) do
                local ent = obj:get_luaentity()
                if ent and ent.name and boost and boost.hostile_mobs[ent.name] then
                    boost.refresh_mob(obj, ent)
                end
            end
        end
    end

    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 200)) do
            local ent = obj:get_luaentity()
            if ent and ent.name and boost and boost.hostile_mobs[ent.name] then
                boost.boost_mob(obj, ent)
            end
        end
    end

    minetest.after(1, periodic_difficulty_scan)
end

-- Start Mod
minetest.register_on_mods_loaded(function()
    -- Read difficulty setting once world is loaded
    LAST_DIFFICULTY = minetest.settings:get("moredanger_difficulty") or "normal"

    minetest.log("action", "[MoreDanger] Difficulty set to: " .. LAST_DIFFICULTY)

    -- Start periodic scan
    minetest.after(1, periodic_difficulty_scan)
end)


-- Register commands
register_commands(boost, debug)

-- Register GUI shortcut command
minetest.register_chatcommand("md", {
    description = "Open MoreDanger GUI",
    privs = {},
    func = function(name)
        minetest.show_formspec(name, "moredanger:gui", gui.get_formspec())
    end
})

