local blueshift = require "blueshift"
local Math = blueshift.Math
local Point = blueshift.Point
local Vec2 = blueshift.Vec2
local Vec3 = blueshift.Vec3

properties = {
    player = { label = "Player", type = "object", classname = "ComScript", value = nil },
    home_button = { label = "Home Button", type = "object", classname = "ComScript", value = nil },
    restart_button = { label = "Restart Button", type = "object", classname = "ComScript", value = nil },
    pause_button = { label = "Pause Button", type = "object", classname = "ComScript", value = nil },
    resume_button = { label = "Resume Button", type = "object", classname = "ComScript", value = nil },
}

property_names = {
    "player",
    "home_button",
    "restart_button",
    "pause_button",
    "resume_button"
}

m = {
	pause = false,
    player_state = nil
}

function start()
    m.player_state = _G[properties.player.value:cast_script():sandbox_name()]
end

function update()
    -- activate home button and restart button when the player've died
    if not m.player_state.m.alive then
        if owner.game_world:time() - m.player_state.m.dead_time > 3000 then
            local home_button = properties.home_button.value:cast_script()
            if not home_button:entity():is_active_self() then
                home_button:entity():set_active(true)
            end

            local restart_button = properties.restart_button.value:cast_script()
            if not restart_button:entity():is_active_self() then
                restart_button:entity():set_active(true)
            end
        end
    end
end

function on_pause()
    m.pause = true

    owner.game_world:set_time_scale(0)

    local pause_button = properties.pause_button.value:cast_script()
    pause_button:entity():set_active(false)

    local resume_button = properties.resume_button.value:cast_script()
    resume_button:entity():set_active(true)
end

function on_resume()
    m.pause = false

    owner.game_world:set_time_scale(1)

    local pause_button = properties.pause_button.value:cast_script()
    pause_button:entity():set_active(true)

    local resume_button = properties.resume_button.value:cast_script()
    resume_button:entity():set_active(false)
end

function on_application_pause(pause)
    if pause then
        on_pause()
    end
end

function button_pressed(name)
    if name == "Pause Button" then
        on_pause()        
    elseif name == "Resume Button" then
        on_resume()
    elseif name == "Home Button" then
        owner.game_world:restart_game("Contents/Maps/title.map")
    elseif name == "Restart Button" then
        owner.game_world:restart_game(owner.game_world:loded_map_name())
    end
end
