local blueshift = require "blueshift"
local ComVehicleWheel = blueshift.ComVehicleWheel
local Input = blueshift.Input

properties = {
    torque = { label = "Torque", type = "float", value = 160 },
    brakingTorque = { label = "Braking Torque", type = "float", value = 2.5 },
    joypad_l = { label = "Left Joypad", type = "object", classname = "ComScript", value = nil },
    joypad_r = { label = "Right Joypad", type = "object", classname = "ComScript", value = nil },
    clunk_sound = { label = "Sounds/Clunk", type = "object", classname = "SoundResource", value = nil },
    accel_sound = { label = "Sounds/Accel", type = "object", classname = "SoundResource", value = nil },
    skid_sound = { label = "Sounds/Skid", type = "object", classname = "SoundResource", value = nil },
}

property_names = {
    "torque",
    "brakingTorque",
    "joypad_l",
    "joypad_r",
    "clunk_sound",
    "accel_sound",
    "skid_sound"
}

m = {
	front_wheels = {},
	wheels = {},
	steering_angle = 0,
	torque = 0,
	brakingTorque = 0,
    skid_time = 0
}

function start()
	local components = owner.entity:components_in_children(ComVehicleWheel.meta_object)

	for i = 1, components:count() do 
		 local vehicle_wheel = components:at(i - 1):cast_vehicle_wheel()
		 if vehicle_wheel then
		 	m.wheels[#m.wheels + 1] = vehicle_wheel

			 if vehicle_wheel:entity():transform():local_origin():x() > 0 then
			 	m.front_wheels[#m.front_wheels + 1] = vehicle_wheel
			 end
		end
	end

    if properties.accel_sound.value then
        m.accel_sound = properties.accel_sound.value:cast_asset():sound():instantiate()
    end

    if properties.skid_sound.value then
        m.skid_sound = properties.skid_sound.value:cast_asset():sound():instantiate()
    end
end

function update()
    local steering_delta = 0

    m.torque = 0
    m.brakingTorque = 0

    if properties.joypad_l.value then
        local joypad_l = properties.joypad_l.value:cast_script()
        if joypad_l then
            local joypad_l_state = _G[joypad_l:sandbox_name()]
            local knob_delta = joypad_l_state.m.knob_delta

            if knob_delta:length() >= 0.1 then
                steering_delta = -knob_delta:x()

                m.torque = -properties.torque.value * knob_delta:y()
            end
        end
    end

	if Input.is_key_pressed(Input.KeyCode.LeftArrow) then
        steering_delta = steering_delta + 1
    end

    if Input.is_key_pressed(Input.KeyCode.RightArrow) then
        steering_delta = steering_delta - 1
    end
    
    if steering_delta == 0 then
    	if m.steering_angle > 0 then
    		m.steering_angle = m.steering_angle - 0.1 * owner.game_world:delta_time()
    		if m.steering_angle < 0 then
    			m.steering_angle = 0
    		end
    	else 
    		m.steering_angle = m.steering_angle + 0.1 * owner.game_world:delta_time()
    		if m.steering_angle > 0 then
    			m.steering_angle = 0
    		end
    	end
    else
        m.steering_angle = m.steering_angle + 0.1 * steering_delta * owner.game_world:delta_time()

        if m.steering_angle > 40 then
            m.steering_angle = 40
        elseif m.steering_angle < -40 then
            m.steering_angle = -40
        end
    end

    if Input.is_key_pressed(Input.KeyCode.UpArrow) then
    	m.torque = properties.torque.value
    elseif Input.is_key_pressed(Input.KeyCode.DownArrow) then
    	m.torque = -properties.torque.value
    end

    if Input.is_key_pressed(Input.KeyCode.Space) then
    	m.brakingTorque = properties.brakingTorque.value
    end

	for i = 1, #m.front_wheels do
    	m.front_wheels[i]:set_steering_angle(m.steering_angle)
        m.front_wheels[i]:set_torque(m.torque)
    end

    for i = 1, #m.wheels do
    	m.wheels[i]:set_braking_torque(m.brakingTorque)
    end

    local velocity = owner.entity:rigid_body():linear_velocity()
    local speed_km = blueshift.unit_to_meter(velocity:length()) * 3.6

    if speed_km > 40 then
        for i = 1, #m.wheels do
            local skid_info = m.wheels[i]:skid_info()

            if skid_info > 0 and skid_info < 0.2 then
                m.skid_time = owner.game_world:time()
            end
        end
    end

    if m.skid_sound then
        if owner.game_world:time() - m.skid_time < 200 then
            local volume = math.max(math.min((speed_km - 40) / 100, 1.0), 0.1)
            if m.skid_sound:is_playing() then
                m.skid_sound:set_volume(volume)
            else
                m.skid_sound:play2d(volume, true)
            end
        elseif m.skid_sound:is_playing() then
            m.skid_sound:stop()
        end
    end
end