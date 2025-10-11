local M = {}

function M.get_formspec()
    return "formspec_version[4]" ..
           "size[5,8]" ..
           "label[0.5,0.5;Difficulties]" ..
           "button[0.5,1;4,1;md_off;OFF]" ..
           "button[0.5,2;4,1;md_normal;Normal]" ..
           "button[0.5,3;4,1;md_hard;Hard]" ..
           "button[0.5,4;4,1;md_nightmare;Nightmare]" ..
           "button[0.5,5;4,1;md_hell;Hell]" ..
           "button_exit[1,6.2;3,1;exit;Close]"
end

local function show_notification(player, message)
    local id = player:hud_add({
        hud_elem_type = "text",
        position = {x=0.5, y=0.1},
        offset = {x=0, y=0},
        text = message,
        alignment = {x=0, y=0},
        scale = {x=100, y=100},
        number = 0xFFFFFF
    })
    minetest.after(5, function()
        player:hud_remove(id)
    end)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "moredanger:gui" then return end
    local name = player:get_player_name()

    if fields.md_off then
        show_notification(player, "Setting difficulty to OFF")
        minetest.chatcommands["moredanger_off"].func(name)

    elseif fields.md_normal then
        show_notification(player, "Setting difficulty to NORMAL")
        minetest.chatcommands["moredanger"].func(name, "mode normal")

    elseif fields.md_hard then
        show_notification(player, "Setting difficulty to HARD")
        minetest.chatcommands["moredanger"].func(name, "mode hard")

    elseif fields.md_nightmare then
        show_notification(player, "Setting difficulty to NIGHTMARE")
        minetest.chatcommands["moredanger"].func(name, "mode nightmare")

    elseif fields.md_hell then
        show_notification(player, "Setting difficulty to HELL")
        minetest.chatcommands["moredanger"].func(name, "mode hell")
    end
end)

return M

