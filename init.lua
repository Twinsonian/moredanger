-- Load modules
local debug = dofile(minetest.get_modpath("moredanger") .. "/md_debug.lua")
local register_commands = dofile(minetest.get_modpath("moredanger") .. "/md_commands.lua")
local gui = dofile(minetest.get_modpath("moredanger") .. "/md_gui.lua")
local boost = nil
local LAST_DIFFICULTY = nil

-- Detect game environment
local game_id = minetest.get_game_info().id or "unknown"
minetest.log("action", "[moredanger] Detected game ID: " .. game_id)

local game_id = minetest.get_game_info().id or "unknown"
minetest.log("action", "[moredanger] Detected game ID: " .. game_id)

if game_id == "mineclonia" then
    boost = dofile(minetest.get_modpath("moredanger") .. "/md_mineclonia.lua")
    minetest.after(1, function()
        minetest.chat_send_all("More Danger Enabled for Mineclonia.")
        minetest.log("action", "[moredanger] Mineclonia module loaded.")
    end)
elseif minetest.get_modpath("mobs") then
    boost = dofile(minetest.get_modpath("moredanger") .. "/md_mobsredo.lua")
    minetest.after(1, function()
        minetest.chat_send_all("More Danger Enabled for Mobs Redo.")
        minetest.log("action", "[moredanger] Mobs Redo module loaded.")
    end)
else
    minetest.log("action", "[moredanger] No compatible mob API detected. Mod disabled.")
    return
end


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

-- Start mod
minetest.register_on_mods_loaded(function()
    minetest.after(1, periodic_difficulty_scan)
end)

-- Register commands
register_commands(boost, debug)

-- Register GUI shortcut command
minetest.register_chatcommand("md", {
    description = "Open MoreDanger GUI",
    privs = {server=true},
    func = function(name)
        minetest.show_formspec(name, "moredanger:gui", gui.get_formspec())
    end
})

