local M = {}
local DEBUG_MODE = false

function M.toggle_debug()
    DEBUG_MODE = not DEBUG_MODE

    if DEBUG_MODE then
        M.debug_loop()
        return true, "Debug mode ON: HP tags will update every second."
    else
        for _, player in ipairs(minetest.get_connected_players()) do
            local pos = player:get_pos()
            for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 200)) do
                local ent = obj:get_luaentity()
                if ent and ent.name then
                    obj:set_properties({nametag = ""})
                end
            end
        end
        return true, "Debug mode OFF: Nametags cleared."
    end
end

function M.debug_loop()
    if not DEBUG_MODE then return end

    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 200)) do
            local ent = obj:get_luaentity()
            if ent and ent.name then
                local hp = ent.health or 0
                local overflow = ent._overflow_hp or 0
                obj:set_properties({
                    nametag = "HP: " .. math.floor(hp) .. " + " .. math.floor(overflow),
                    nametag_color = "#FFFFFF",
                    show_on_minimap = true,
                    glow = 10
                })
            end
        end
    end

    minetest.after(1, M.debug_loop)
end

return M

