local M = {}
local DEBUG_MODE = false

-- Toggle debug mode on/off
function M.toggle_debug()
    DEBUG_MODE = not DEBUG_MODE

    if DEBUG_MODE then
        M.debug_loop()
        return true, "Debug mode ON: HP tags will update every second."
    else
        -- Clear all nametags from all entities
        for _, obj in pairs(minetest.luaentities) do
            if obj and obj.object and obj.object:get_luaentity() then
                local ent = obj.object:get_luaentity()
                if ent and ent.name then
                    obj.object:set_properties({
                        nametag = "",
                        nametag_color = "#000000",
                        glow = 0,
                        show_on_minimap = false
                    })
                end
            end
        end
        return true, "Debug mode OFF: Nametags cleared globally."
    end
end

-- Update nametags every second while debug mode is active
function M.debug_loop()
    if not DEBUG_MODE then return end

    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 200)) do
            local ent = obj:get_luaentity()
            if ent and ent.name and ent.health and ent.health > 0 then
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

