local M = {}

function M.get_formspec()
    return "formspec_version[4]" ..
           "size[8,7]" ..
           "label[0.5,0.5;Difficulties]" ..
           "button[0.5,1;2,1;md_off;OFF]" ..
           "button[0.5,2;2,1;md_normal;Normal]" ..
           "button[0.5,3;2,1;md_hard;Hard]" ..
           "button[0.5,4;2,1;md_nightmare;Nightmare]" ..
           "button[0.5,5;2,1;md_hell;Hell]" ..
           "button[3.5,2.5;3,1;md_debug;Toggle Debug]" ..
           "button_exit[3.5,5.5;3,1;exit;Close]"
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "moredanger:gui" then return end
    local name = player:get_player_name()

    if fields.md_off then
        minetest.chat_send_player(name, "Setting difficulty to OFF")
        minetest.chatcommands["moredanger_off"].func(name)
    elseif fields.md_normal then
        minetest.chat_send_player(name, "Setting difficulty to NORMAL")
        minetest.chatcommands["moredanger"].func(name, "mode normal")
    elseif fields.md_hard then
        minetest.chat_send_player(name, "Setting difficulty to HARD")
        minetest.chatcommands["moredanger"].func(name, "mode hard")
    elseif fields.md_nightmare then
        minetest.chat_send_player(name, "Setting difficulty to NIGHTMARE")
        minetest.chatcommands["moredanger"].func(name, "mode nightmare")
    elseif fields.md_hell then
        minetest.chat_send_player(name, "Setting difficulty to HELL")
        minetest.chatcommands["moredanger"].func(name, "mode hell")
    elseif fields.md_debug then
        minetest.chat_send_player(name, "Toggling debug mode")
        minetest.chatcommands["moredanger_debug"].func(name)
    end
end)

return M

