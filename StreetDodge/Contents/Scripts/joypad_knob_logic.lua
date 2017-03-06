local blueshift = require "blueshift"
local Point = blueshift.Point
local Vec2 = blueshift.Vec2
local Plane = blueshift.Plane
local Input = blueshift.Input
local Screen = blueshift.Screen

properties = {
	knob_radius = { type = "float", minimum = 1, maximum = 100, value = 40 },
}

property_names = {
    "knob_radius"
}

m = {
    knob_delta = Vec2(0, 0),
    clicked_id = -1
}

function start()
end

function update()
    local camera_entity = owner.game_world:find_entity("UICamera")
    local camera = camera_entity:camera()

    local knob_center = owner.transform:origin()
    local knob_screen_center = camera:world_to_screen(knob_center)
    local knob_screen_radius = (properties.knob_radius.value / 640) * Screen.renderWidth()

    for i = 0, Input.touch_count() do
        local touch = Input.touch(i)
        if touch:phase() == Input.Touch.Started then
            if touch:position():distance_squared(knob_screen_center) <= knob_screen_radius * knob_screen_radius then
                m.clicked_id = touch:id()
            end
        elseif touch:phase() == Input.Touch.Ended or touch:phase() == Input.Touch.Canceled then
            if touch:id() == m.clicked_id then
                m.clicked_id = -1

                --move knob to center
                local knob_entity = owner.entity:find_child("knob")
                local knob_local_pos = knob_entity:transform():local_origin()
                knob_local_pos:set_y(0)
                knob_local_pos:set_z(0)
               
                knob_entity:transform():set_local_origin(knob_local_pos)
                m.knob_delta:set(0, 0)
            end
        elseif touch:phase() == Input.Touch.Moved then
            if touch:id() == m.clicked_id then
                m.knob_delta:set_x(touch:position():x() - knob_screen_center:x())
                m.knob_delta:set_y(touch:position():y() - knob_screen_center:y())

                if m.knob_delta:length_squared() >= knob_screen_radius * knob_screen_radius then
                    m.knob_delta:normalize()
                    m.knob_delta = m.knob_delta:mul(knob_screen_radius)
                end

                local ray = camera:screen_to_ray(knob_screen_center + Point(m.knob_delta:x(), m.knob_delta:y()))
                local knob_entity = owner.entity:find_child("knob")

                local knob_plane = Plane(-camera_entity:transform():axis():at(0), 0)
                knob_plane:fit_through_point(knob_center)

                local s = knob_plane:ray_intersection(ray:origin(), ray:direction())
                knob_entity:transform():set_origin(ray:origin() + ray:direction():mul(s))

                --normalize
                m.knob_delta = m.knob_delta:div(knob_screen_radius)
            end
        end
    end
end