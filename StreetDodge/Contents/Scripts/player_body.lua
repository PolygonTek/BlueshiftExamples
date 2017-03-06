local blueshift = require "blueshift"
local Common = blueshift.Common

m = {
    player = nil
}

function start()
    m.player = owner.game_world:find_entity("Player")
end

function update()
end

function on_sensor_enter(entity)
    if entity:tag() == "Enemy" then
        _G[m.player:script():sandbox_name()].on_dead()
    end
end
