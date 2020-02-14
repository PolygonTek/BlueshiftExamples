local blueshift = require "blueshift"
local Common = blueshift.Common
local Input = blueshift.Input
local Math = blueshift.Math
local Vec2 = blueshift.Vec2

--[properties]--
properties = {
    wheel_max_angle = { label = "Angle Limit", type = "float", value = 450 },
	wheel_radius = { label = "Wheel Radius", type = "float", minimum = 1, maximum = 100, value = 100 },
    target_car = { label = "Target Car", type = "object", classname = "Entity", value = nil }
}

m = {
    last_angle = 0,
    wheel_angle = 0,
    clicked_id = -1,
    key_steering_delta = 0
}

function start()
    local canvas_entity = owner.entity:parent()
    m.canvas = canvas_entity:canvas()

    m.car = properties.target_car.value:cast_entity()
end

function update()
    handle_touch_input()
    handle_key_input()

    if m.wheel_angle < -properties.wheel_max_angle.value then
        m.wheel_angle = -properties.wheel_max_angle.value
    elseif m.wheel_angle > properties.wheel_max_angle.value then
        m.wheel_angle = properties.wheel_max_angle.value
    end

    if m.clicked_id == -1 and m.key_steering_delta == 0 then
        local speed = m.car:rigid_body():linear_velocity():length()

        if speed > 0.4 then
	        local rotation_speed = speed * 0.05

	        if m.wheel_angle > 1 then
	            m.wheel_angle = m.wheel_angle - rotation_speed * owner.game_world:delta_time()
	            if m.wheel_angle < 0 then
	                m.wheel_angle = 0
	            end
	        elseif m.wheel_angle < -1 then
	            m.wheel_angle = m.wheel_angle + rotation_speed * owner.game_world:delta_time()
	            if m.wheel_angle > 0 then
	                m.wheel_angle = 0
	            end
	        end
	    end
    end

    local local_angles = owner.transform:local_angles()
    local_angles:set_roll(m.wheel_angle)
    owner.transform:set_local_angles(local_angles)
end

function handle_touch_input()
    local touch_count = Input.touch_count()

    if touch_count > 0 then 
        local wheel_center = owner.transform:origin()
        -- wheel center position in canvas space.
        local wheel_center_in_canvas = m.canvas:world_to_canvas_point(wheel_center)
        local wheel_radius_in_canvas = properties.wheel_radius.value

        for i = 0, touch_count - 1 do
            local touch = Input.touch(i)
            local touch_point_in_canvas = m.canvas:screen_to_canvas_point(touch:position())

            if touch:phase() == Input.Touch.Started then
                -- Check if touch point is within wheel radius.
                if touch_point_in_canvas:distance_squared(wheel_center_in_canvas) <= wheel_radius_in_canvas * wheel_radius_in_canvas then
                    m.clicked_id = touch:id()

                    local offset = Vec2(0, 0)
                    offset:set_x(touch_point_in_canvas:x() - wheel_center_in_canvas:x())
                    offset:set_y(touch_point_in_canvas:y() - wheel_center_in_canvas:y())
                    offset:normalize()

                    m.last_angle = -offset:to_angle()
                end
            elseif touch:phase() == Input.Touch.Ended or touch:phase() == Input.Touch.Canceled then
                if touch:id() == m.clicked_id then
                    m.clicked_id = -1
                end
            elseif touch:phase() == Input.Touch.Moved then
                if touch:id() == m.clicked_id then
                    local offset = Vec2(0, 0)
                    offset:set_x(touch_point_in_canvas:x() - wheel_center_in_canvas:x())
                    offset:set_y(touch_point_in_canvas:y() - wheel_center_in_canvas:y())
                    offset:normalize()

                    local new_angle = -offset:to_angle() -- compensate positive down y axis

                    m.wheel_angle = m.wheel_angle + Math.angle_normalize_180(Math.to_degree(new_angle - m.last_angle))

                    m.last_angle = new_angle
                end
            end
        end
    end
end

function handle_key_input()
    m.key_steering_delta = 0

    if Input.is_key_pressed(Input.KeyCode.LeftArrow) then
        m.key_steering_delta = m.key_steering_delta + 1
    end

    if Input.is_key_pressed(Input.KeyCode.RightArrow) then
        m.key_steering_delta = m.key_steering_delta - 1
    end
    
    if m.key_steering_delta ~= 0 then
        m.wheel_angle = m.wheel_angle + 0.8 * m.key_steering_delta * owner.game_world:delta_time()
    end
end