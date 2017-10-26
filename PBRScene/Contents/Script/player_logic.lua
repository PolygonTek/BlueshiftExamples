local blueshift = require "blueshift"
local Common = blueshift.Common
local Math = blueshift.Math
local Point = blueshift.Point
local Vec2 = blueshift.Vec2
local Vec3 = blueshift.Vec3
local Angles = blueshift.Angles
local Input = blueshift.Input
local Physics = blueshift.Physics

properties = {
    hp = { label = "HP", type = "int", value = 10 },
    gravity = { label = "Gravity", type = "float", value = 9.8 },
    max_speed = { label = "Max Speed", type = "float", value = 4.0 },
    stop_speed = { label = "Stop Speed", type = "float", value = 2.0 },
    acceleration = { label = "Acceleration", type = "float", value = 8.0 },
    friction = { label = "Friction", type = "float", value = 6.0 },
    joypad_l = { label = "Left Joypad", type = "object", classname = "ComScript", value = nil },
    joypad_r = { label = "Right Joypad", type = "object", classname = "ComScript", value = nil },
    footstep1_sound = { label = "Footstep1 sound", type = "object", classname = "SoundAsset", value = nil },
    footstep2_sound = { label = "Footstep2 sound", type = "object", classname = "SoundAsset", value = nil },
    footstep3_sound = { label = "Footstep3 sound", type = "object", classname = "SoundAsset", value = nil },
    footstep4_sound = { label = "Footstep4 sound", type = "object", classname = "SoundAsset", value = nil },
    slide_sound = { label = "Slide sound", type = "object", classname = "SoundAsset", value = nil }
}

property_names = {
    "hp",
    "gravity", 
    "max_speed",
    "stop_speed",
    "acceleration",
    "friction",
    "joypad_l",
    "joypad_r",
    "footstep1_sound",
    "footstep2_sound",
    "footstep3_sound",
    "footstep4_sound",
    "slide_sound"
}

m = {
    alive = true,
    gravity = 0,
    max_speed = 0,
    stop_speed = 0,
    acceleration = 0,
    friction = 0,

    footsteps = {},

    sensitivity = 5.0,
    input_move_accel = 0.0,
    input_scale_x = 0.022,
    input_scale_y = 0.022,

    keymove_up_speed = 1.0,
    keymove_yaw_speed = 0.1,
    keymove_pitch_speed = 0.1,
    keymove_move_boost = 2.0,
    keymove_angle_boost = 2.0,
    keymove_always_run = true,

    anim_current_pos = Vec2(0, 0),
    anim_turn = 0,
    
    anim_angle = 0.0,
    anim_speed = 0.0,
    ground_accel = 8.0,
    ground_friction = 6.0,
    air_accel = 1.0,
    air_friction = 0.0,
    velocity = Vec3(0, 0, 0),
    
    user_cmd = {
        wish_delta_angles = Angles(0, 0, 0),
        wish_turn = 0,
        wish_direction = Vec2(0, 0),
        wish_speed = 0,
        up_move = 0
    }
}

function start()
    m.gravity = blueshift.meter_to_unit(properties.gravity.value)
    m.max_speed = blueshift.meter_to_unit(properties.max_speed.value)
    m.stop_speed = blueshift.meter_to_unit(properties.stop_speed.value)
    m.acceleration = properties.acceleration.value
    m.friction = properties.friction.value

    m.velocity:set_from_scalar(0)

    m.footsteps[1] = properties.footstep1_sound.value:cast_sound_asset()
    m.footsteps[2] = properties.footstep2_sound.value:cast_sound_asset()
    m.footsteps[3] = properties.footstep3_sound.value:cast_sound_asset()
    m.footsteps[4] = properties.footstep4_sound.value:cast_sound_asset()
end

function apply_accel(wish_velocity, accel)
    local wish_dir = wish_velocity
    local wish_speed = wish_dir:normalize()

    local cur_speed = m.velocity:dot(wish_dir)
    local add_speed = wish_speed - cur_speed
    if add_speed <= 0 then
        return
    end

    local accel_speed = accel * (owner.game_world:delta_time() / 1000) * wish_speed
    if accel_speed > add_speed then
        accel_speed = add_speed
    end

    m.velocity = m.velocity + wish_dir:mul(accel_speed)
end

function apply_friction(friction)
    local speed = m.velocity:length()
    if speed < 0.01 then
        m.velocity:set_from_scalar(0)
        return
    end

    local drop_speed = math.max(speed, m.stop_speed) * friction * (owner.game_world:delta_time() / 1000)
    local new_speed = speed - drop_speed
    if new_speed < 0 then
    	new_speed = 0
    end

    new_speed = new_speed / speed

    m.velocity = m.velocity:mul(new_speed)
end

function gen_user_cmd(dx, dy)
    m.user_cmd.wish_delta_angles:set(0, 0, 0)
    m.user_cmd.wish_direction:set_from_scalar(0)
    m.user_cmd.wish_speed = 0
    m.user_cmd.up_move = 0

    m.user_cmd.wish_delta_angles:set_yaw(-dx)
    m.user_cmd.wish_delta_angles:set_pitch(dy)

    local angle_speed = owner.game_world:delta_time()

    if Input.is_key_pressed(Input.KeyCode.LeftShift) then
        angle_speed = angle_speed * m.keymove_angle_boost
    end

    if Input.is_key_pressed(Input.KeyCode.UpArrow) then
        m.user_cmd.wish_delta_angles:set_pitch(m.user_cmd.wish_delta_angles:pitch() - angle_speed * m.keymove_pitch_speed)
    end

    if Input.is_key_pressed(Input.KeyCode.DownArrow) then
        m.user_cmd.wish_delta_angles:set_pitch(m.user_cmd.wish_delta_angles:pitch() + angle_speed * m.keymove_pitch_speed)
    end

    if Input.is_key_pressed(Input.KeyCode.RightArrow) then
        m.user_cmd.wish_delta_angles:set_yaw(m.user_cmd.wish_delta_angles:yaw() - angle_speed * m.keymove_yaw_speed)
    end

    if Input.is_key_pressed(Input.KeyCode.LeftArrow) then
        m.user_cmd.wish_delta_angles:set_yaw(m.user_cmd.wish_delta_angles:yaw() + angle_speed * m.keymove_yaw_speed)
    end

    if properties.joypad_r.value then
	    local joypad_r = properties.joypad_r.value:cast_script()
	    if joypad_r then
	        local joypad_r_state = _G[joypad_r:sandbox_name()]
	        local knob_delta = joypad_r_state.m.knob_delta
	        m.user_cmd.wish_delta_angles:set_pitch(m.user_cmd.wish_delta_angles:pitch() - knob_delta:y())
	        m.user_cmd.wish_delta_angles:set_yaw(m.user_cmd.wish_delta_angles:yaw() - knob_delta:x())
	    end
   	end    

    if m.user_cmd.wish_delta_angles:yaw() > 0.01 then
		m.wish_turn = 1
	elseif m.user_cmd.wish_delta_angles:yaw() < -0.01 then
		m.wish_turn = -1
	else
		m.wish_turn = 0
	end

    local key_move = false
    if Input.is_key_pressed(Input.KeyCode.W) then
        m.user_cmd.wish_direction = m.user_cmd.wish_direction + Vec2.unit_x
        key_move = true
    end

    if Input.is_key_pressed(Input.KeyCode.S) then
        m.user_cmd.wish_direction = m.user_cmd.wish_direction - Vec2.unit_x
        key_move = true
    end

    if Input.is_key_pressed(Input.KeyCode.D) then
        m.user_cmd.wish_direction = m.user_cmd.wish_direction - Vec2.unit_y
        key_move = true
    end

    if Input.is_key_pressed(Input.KeyCode.A) then
        m.user_cmd.wish_direction = m.user_cmd.wish_direction + Vec2.unit_y
        key_move = true
    end

    if Input.is_key_pressed(Input.KeyCode.Space) then
        m.user_cmd.up_move = m.user_cmd.up_move + blueshift.meter_to_unit(m.keymove_up_speed)
    end

    if Input.is_key_pressed(Input.KeyCode.C) then
        m.user_cmd.up_move = m.user_cmd.up_move - blueshift.meter_to_unit(m.keymove_up_speed)
    end

    if properties.joypad_l.value then
	    local joypad_l = properties.joypad_l.value:cast_script()
	    if joypad_l then
	        local joypad_l_state = _G[joypad_l:sandbox_name()]
	        local knob_delta = joypad_l_state.m.knob_delta
	        if knob_delta:length() >= 0.1 then
	            m.user_cmd.wish_direction:set_x(m.user_cmd.wish_direction:x() - knob_delta:y())
	            m.user_cmd.wish_direction:set_y(m.user_cmd.wish_direction:y() - knob_delta:x())

	            local t = m.user_cmd.wish_direction:normalize()
	            if t >= 0.1 then
	                t = (t - 0.1) / 0.9
	                m.user_cmd.wish_speed = 2.0 * t + 1.0 * (1.0 - t)
	            end
	        end
	    end
	end

    if key_move then
        if m.user_cmd.wish_direction:length_squared() > 0 then
            local speed = m.user_cmd.wish_direction:normalize()
            m.user_cmd.wish_speed = 1.0

            if (m.keymove_always_run == true and not Input.is_key_pressed(Input.KeyCode.LeftShift)) or
               (m.keymove_always_run == false and Input.is_key_pressed(Input.KeyCode.LeftShift)) then
                m.user_cmd.wish_speed = m.keymove_move_boost
            end
        end
    end
end

function update()
    local dx = 0.0
    local dy = 0.0

    if not m.alive and owner.game_world:time() - m.dead_time > 5000 then
        local restart_button = properties.restart_button.value:cast_script()
        if restart_button then
            if not restart_button:entity():is_active_self() then
                restart_button:entity():set_active(true)
            end

            local restart_button_pressed = false
            local restart_button_state = _G[restart_button:sandbox_name()]
            if restart_button_state.m.pressed then
                restart_button:entity():set_active(false)

                owner.game_world:restart_game()
            end
        end
    end

    -- handle mouse1 clicks on rigid body  
    if Input.is_key_down(Input.KeyCode.Mouse1) then
        local camera_entity = owner.game_world:find_entity_by_tag("MainCamera")
        local camera = camera_entity:camera()

        local mouse_pos = Input.mouse_pos()
        local ray = camera:screen_to_ray(mouse_pos)

        local min_scale = blueshift.meter_to_unit(100000)
        
        local cast_result = Physics.CastResult()
        if Physics.ray_cast(ray:origin(), ray:distance_point(min_scale), 
            Physics.FilterGroup.DefaultGroup, Physics.FilterGroup.AllGroup, cast_result) then
            local hit_rigid_body = cast_result:rigid_body()

            if hit_rigid_body then
                local forward = camera_entity:transform():axis():at(0)
                hit_rigid_body:apply_central_impulse(forward:mul(500))
            end
        end
    end

    -- handle mouse2 clicks to hide cursor in rotation
    if Input.is_key_down(Input.KeyCode.Mouse2) then
        Input.lock_cursor(true)
    end

    if Input.is_key_up(Input.KeyCode.Mouse2) then
        Input.lock_cursor(false)
    end

    local character_controller = owner.entity:character_controller()
    local animator = owner.entity:animator()

    if m.alive then        
        --[[if m.throwing then
            local elapsed_time = owner.game_world:time() - m.throw_time
            --[[if elapsed_time > 820 and not m.projectile then
                local entity = properties.projectile.value:cast_prefab_asset():prefab():root_entity()
                m.projectile = owner.game_world:clone_entity(entity)
                if m.projectile then
                    local projectile_transform = properties.shoot_place.value:cast_transform()
                    m.projectile:transform():set_origin(projectile_transform:origin())
                    m.projectile:transform():set_axis(projectile_transform:axis())
                    m.projectile:rigid_body():set_linear_velocity(projectile_transform:axis():at(0):mul(blueshift.meter_to_unit(18)))
                end
            end
        end--]]

        if Input.is_key_pressed(Input.KeyCode.Mouse2) then
            local axis_delta = Input.axis_delta()
            local move_delta = Vec2(axis_delta:x(), axis_delta:y())

            local sensi_scale = 1.0
            local move_rate = Math.sqrt(move_delta:x() * move_delta:x() + move_delta:y() * move_delta:y())
            local sensi = (move_rate * m.input_move_accel + m.sensitivity) * sensi_scale

            dx = move_delta:x() * sensi * m.input_scale_x
            dy = move_delta:y() * sensi * m.input_scale_y
        end

        gen_user_cmd(dx, dy)

        local angles = owner.transform:angles()
        angles:set_yaw(Math.angle_normalize_360(angles:yaw() + m.user_cmd.wish_delta_angles:yaw()))
        angles:set_pitch(0)
        angles:set_roll(0)
        owner.transform:set_angles(angles)

        if character_controller then
--[[
            local wish_vel = angles:to_mat3():mul_vec(Vec3(m.user_cmd.wish_direction:x(), m.user_cmd.wish_direction:y(), 0):mul(m.user_cmd.wish_speed))
            --wish_vel:set_z(wish_vel:z() + m.user_cmd.up_move

            if m.user_cmd.wish_speed > m.max_speed then
                wish_vel = wish_vel:mul(m.max_speed / m.user_cmd.wish_speed)
            end

            if character_controller:is_on_ground() then
                m.acceleration = m.ground_accel
                m.friction = m.ground_friction

                if (m.user_cmd.up_move) then
                    m.velocity:set_z(blueshift.meter_to_unit(4.0))
                else
                    m.velocity:set_z(0)
                end
            else 
                m.acceleration = m.air_accel
                m.friction = m.air_friction

                m.velocity:set_z(m.velocity:z() - m.gravity * (owner.game_world:delta_time() / 1000))
            end

            apply_friction(m.friction)

            apply_accel(wish_vel, m.acceleration)

            if m.velocity:length_squared() > 0.001 then
                if character_controller:move(m.velocity:mul((owner.game_world:delta_time() / 1000))) then
                    m.velocity:set_from_scalar(0)
                end
            end
--[[]]

            if character_controller:is_on_ground() then
                m.friction = m.ground_friction

                if (m.user_cmd.up_move > 0) then
                    --m.velocity:set_z(blueshift.meter_to_unit(4.0));
                else
                    --m.velocity:set_z(0) 
                end
            else
                m.friction = m.air_friction
                m.velocity:set_z(m.velocity:z() - m.gravity * owner.game_world:delta_time() / 1000)
            end

            apply_friction(m.friction)

            if animator and m.anim_speed > 0.001 then
                local translation_delta = animator:translation_delta(owner.game_world:prev_time(), owner.game_world:time())
                local move_delta = angles:to_mat3():mul_vec(translation_delta):mul_comp(owner.transform:scale())
                if m.throwing then
                    move_delta:set_z(move_delta:z() * 1.0)
                else
                    move_delta:set_z(m.velocity:z() * owner.game_world:delta_time() / 1000)
                end

                character_controller:move(move_delta)
            end
 --]]
        end        

        if animator then
            if true then
                local current_anim_state = animator:current_anim_state(0)

                local delta_pos = m.user_cmd.wish_direction - m.anim_current_pos;
                if delta_pos:length_squared() > 0.001 then
                    m.anim_current_pos = m.anim_current_pos + delta_pos:mul((owner.game_world:delta_time() / 1000) * 5.0)
                else 
                    m.anim_current_pos:set_x(m.user_cmd.wish_direction:x())
                    m.anim_current_pos:set_y(m.user_cmd.wish_direction:y())
                end

                animator:set_anim_parameter("x", m.anim_current_pos:x())
                animator:set_anim_parameter("y", m.anim_current_pos:y())

                local delta_turn = m.wish_turn - m.anim_turn
                if Math.fabs(delta_turn) > 0.001 then
                    m.anim_turn = m.anim_turn + delta_turn * (owner.game_world:delta_time() / 1000) * 10.0
                else
                    m.anim_turn = m.wish_turn
                end

                animator:set_anim_parameter("turn", m.anim_turn)

                local delta_speed = m.user_cmd.wish_speed - m.anim_speed
                if Math.fabs(delta_speed) > 0.001 then
                    m.anim_speed = m.anim_speed + delta_speed * (owner.game_world:delta_time() / 1000) * 10.0
                else
                    m.anim_speed = m.user_cmd.wish_speed
                end
                
                animator:set_anim_parameter("speed", m.anim_speed)

				--[[if properties.attack_button.value then
	                local attack_button = properties.attack_button.value:cast_script()
	                local attack_button_pressed = false
	                if attack_button then
	                    local attack_button_state = _G[attack_button:sandbox_name()]
	                    if attack_button_state.m.pressed then
	                        attack_button_pressed = true
	                    end
	                end
	            end]]

                if Input.is_key_down(Input.KeyCode.Space) or attack_button_pressed then
                    animator:set_anim_parameter("jump", 1)
                else
                    animator:set_anim_parameter("jump", 0)
                end

                if Input.is_key_down(Input.KeyCode.C) then
                    animator:set_anim_parameter("sliding", 1)
                else
                    animator:set_anim_parameter("sliding", 0)
                end

                animator:set_anim_parameter("locomotion", m.anim_speed)
            end
        end
    end
end

function on_dead()
    m.alive = false
    m.dead_time = owner.game_world:time()

    owner.entity:character_controller():enable(false)
end

function on_jump()
    m.throwing = true
end

function on_land()
    m.throwing = false
end

function on_slide()
    local sound_asset = properties.slide_sound.value:cast_sound_asset()
    if sound_asset then
        local s = sound_asset:sound():instantiate()
        s:play2d(0.5, false)--owner.transform:origin(), blueshift.meter_to_unit(4), blueshift.meter_to_unit(15), 1.0, false)
    end
end

function on_footstep_left()
    local index = math.random(1, 4)
    local sound_asset = m.footsteps[index]
    if sound_asset then
        local s = sound_asset:sound():instantiate()
        s:play2d(0.5, false)--owner.transform:origin(), blueshift.meter_to_unit(4), blueshift.meter_to_unit(15), 1.0, false)
    end
end

function on_footstep_right()
    local index = math.random(1, 4)
    local sound_asset = m.footsteps[index]
    if sound_asset then
        local s = sound_asset:sound():instantiate()
        s:play2d(0.5, false)--owner.transform:origin(), blueshift.meter_to_unit(4), blueshift.meter_to_unit(15), 1.0, false)
    end
end