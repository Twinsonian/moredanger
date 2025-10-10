return function(boost, debug)
    minetest.register_chatcommand("moredanger", {
        params = "mode <normal|hard|nightmare|hell>",
        description = "Set mob difficulty (creative mode only)",
        privs = {server=true},
        func = function(name, param)
            if not minetest.settings:get_bool("creative_mode") then
                return false, "This command is only available in creative mode."
            end
            if not boost then
                return false, "Mob API not detected. Command unavailable."
            end

            local mode = param:match("^mode%s+(%w+)$")
            local allowed = {
                normal = true,
                hard = true,
                nightmare = true,
                hell = true
            }

            if not mode or not allowed[mode] then
                return false, "Usage: /moredanger mode <normal|hard|nightmare|hell>"
            end

            minetest.settings:set("moredanger_difficulty", mode)
            return true, "Difficulty set to " .. mode .. ". Changes will apply automatically to hostile mobs nearby."
        end
    })

    minetest.register_chatcommand("moredanger_mode", {
        description = "Show current mob difficulty mode",
        privs = {server=true},
        func = function(name)
            local mode = minetest.settings:get("moredanger_difficulty") or "normal"
            return true, "Current difficulty mode: " .. mode
        end
    })

    minetest.register_chatcommand("moredanger_off", {
        description = "Disable all difficulty boosts (creative mode only)",
        privs = {server=true},
        func = function(name)
            if not minetest.settings:get_bool("creative_mode") then
                return false, "This command is only available in creative mode."
            end
            if not boost then
                return false, "Mob API not detected. Command unavailable."
            end

            minetest.settings:set("moredanger_difficulty", "off")

            for _, player in ipairs(minetest.get_connected_players()) do
                local pos = player:get_pos()
                for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 200)) do
                    local ent = obj:get_luaentity()
                    if ent and ent.name and boost.hostile_mobs[ent.name] then
                        if ent._moredanger_original_speed then
                            ent.movement_speed = ent._moredanger_original_speed
                        end
                        if ent._moredanger_original_damage then
                            ent.damage = ent._moredanger_original_damage
                        end
                        ent._overflow_hp = 0
                        ent._overflow_max = 0
                        ent._last_health = ent.health
                    end
                end
            end

            return true, "Difficulty boosts disabled. Nearby mobs reset to normal."
        end
    })

    minetest.register_chatcommand("moredanger_debug", {
        description = "Toggle debug nametags on/off",
        privs = {server=true},
        func = function(name)
            return debug.toggle_debug()
        end
    })
end

