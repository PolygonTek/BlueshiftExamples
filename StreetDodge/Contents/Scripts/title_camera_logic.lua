local blueshift = require "blueshift"

m = {
    spline = {},
    spline_index = 0,
    t = 0
}

function start()
    m.spline[1] = owner.game_world:find_entity("Camera Animation Path 1")
    m.spline[2] = owner.game_world:find_entity("Camera Animation Path 2")
    m.spline[3] = owner.game_world:find_entity("Camera Animation Path 3")

    m.spline_speed = 2.0 / blueshift.unit_to_meter(m.spline[1]:spline():length())
end

function update()
    local spline_entity = m.spline[m.spline_index + 1]
    local current_origin = spline_entity:spline():current_origin(m.t)
    local current_axis = spline_entity:spline():current_axis(m.t)

    m.t = m.t + (owner.game_world:delta_time() * 0.001) * m.spline_speed

    owner.transform:set_origin(current_origin)
    owner.transform:set_axis(current_axis)

    if m.t > 1.0 then
        m.t = 0
        m.spline_index = math.fmod(m.spline_index + 1, 3)
        m.spline_speed = 2.0 / blueshift.unit_to_meter(m.spline[m.spline_index + 1]:spline():length())
    end
end