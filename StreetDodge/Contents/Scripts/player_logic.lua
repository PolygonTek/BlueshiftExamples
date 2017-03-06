local blueshift = require "blueshift"
local Math = blueshift.Math
local Point = blueshift.Point
local Vec2 = blueshift.Vec2
local Vec3 = blueshift.Vec3
local Angles = blueshift.Angles
local Input = blueshift.Input
local Physics = blueshift.Physics

properties = {
    standard_sensor = { label = "Standard Sensor", type = "object", classname = "ComSensor", value = 0 },
    jumping_sensor = { label = "Jumping Sensor", type = "object", classname = "ComSensor", value = 0 },
    sliding_sensor = { label = "Sliding Sensor", type = "object", classname = "ComSensor", value = 0 },
    footstep1_sound = { label = "Footstep1 sound", type = "object", classname = "SoundAsset", value = nil },
    footstep2_sound = { label = "Footstep2 sound", type = "object", classname = "SoundAsset", value = nil },
    footstep3_sound = { label = "Footstep3 sound", type = "object", classname = "SoundAsset", value = nil },
    footstep4_sound = { label = "Footstep4 sound", type = "object", classname = "SoundAsset", value = nil },
    slide_sound = { label = "Slide sound", type = "object", classname = "SoundAsset", value = nil },
    crash_sound = { label = "Crash sound", type = "object", classname = "SoundAsset", value = nil }
}

property_names = {
    "standard_sensor",
    "jumping_sensor",
    "sliding_sensor",
    "footstep1_sound",
    "footstep2_sound",
    "footstep3_sound",
    "footstep4_sound",
    "slide_sound",
    "crash_sound"
}

m = {
    alive = true,
    speed = 0,
    jumping = false,
    sliding = false,

    touch_id = -1,
    touch_last_pos = Point(0, 0),
    touch_vector = Vec2(0, 0),
    swipe_up = false,
    swipe_down = false,
    swipe_left = false,
    swipe_right = false,
    
    footsteps = {},
    score_entity = nil,
    spline = nil,
    t = 0,
    last_spline_pos = Vec2(0, 0),   
    side_target_offset = 0,
    side_offset = 0,
    score = 0
}

function start()
    m.footsteps[1] = properties.footstep1_sound.value:cast_sound_asset()
    m.footsteps[2] = properties.footstep2_sound.value:cast_sound_asset()
    m.footsteps[3] = properties.footstep3_sound.value:cast_sound_asset()
    m.footsteps[4] = properties.footstep4_sound.value:cast_sound_asset()

    m.score_entity = owner.game_world:find_entity("Score")

    m.spline = owner.game_world:find_entity("Move Path")
    m.spline_speed = 6.0 / blueshift.unit_to_meter(m.spline:spline():length())
    m.t = 0

    m.speed = 2
    m.start_time = owner.game_world:time()
end

function get_coin()
    m.score = m.score + 1

    m.score_entity:text_renderer():set_text(string.format("%i Coins", m.score))
end

function update()
    -- activate home button and restart button when the player've died
    if not m.alive then
        return
    end

    m.swipe_up = false
    m.swipe_down = false
    m.swipe_left = false
    m.swipe_right = false

    -- handle swipe input
    for i = 0, Input.touch_count() do
        local touch = Input.touch(i)
        if touch:phase() == Input.Touch.Started then
            m.touch_id = touch:id()            
            m.touch_last_pos = touch:position()
            m.touch_vector:set(0, 0)
        elseif touch:phase() == Input.Touch.Ended or touch:phase() == Input.Touch.Canceled then
            if touch:id() == m.touch_id then
                m.touch_id = -1
                m.touch_vector:set(0, 0)
            end
        elseif touch:phase() == Input.Touch.Moved then
            if touch:id() == m.touch_id then
                local delta = touch:position() - m.touch_last_pos
                m.touch_last_pos = touch:position()
                m.touch_vector:add_self(Vec2(delta:x(), delta:y()))

                if m.touch_vector:length() > 50 then
                    if Math.abs(m.touch_vector:x()) > Math.abs(m.touch_vector:y()) then
                        if m.touch_vector:x() > 0 then
                            m.swipe_right = true
                        else
                            m.swipe_left = true
                        end
                    else
                        if m.touch_vector:y() > 0 then
                            m.swipe_down = true
                        else
                            m.swipe_up = true
                        end
                    end

                    m.touch_vector:set(0, 0)
                end
            end
        end
    end

    local skinned_mesh_renderer = owner.entity:skinned_mesh_renderer()
        
    skinned_mesh_renderer:set_anim_parameter("speed", m.speed)

    if Input.is_key_down(Input.KeyCode.Space) or attack_button_pressed or m.swipe_up then
        skinned_mesh_renderer:set_anim_parameter("jump", 1)
    else
        skinned_mesh_renderer:set_anim_parameter("jump", 0)
    end

    if Input.is_key_down(Input.KeyCode.C) or m.swipe_down then
        skinned_mesh_renderer:set_anim_parameter("sliding", 1)
    else
        skinned_mesh_renderer:set_anim_parameter("sliding", 0)
    end

    local side_delta = m.side_target_offset - m.side_offset
    if Math.fabs(side_delta) > 0.01  then
        m.side_offset = m.side_offset + side_delta * (owner.game_world:delta_time() * 0.001) * 7.0
    else
        m.side_offset = m.side_target_offset
    end

    local side_moving = Math.fabs(side_delta) > 0.1 or false 

    if Input.is_key_down(Input.KeyCode.LeftArrow) or Input.is_key_down(Input.KeyCode.A) or m.swipe_left then
        if not side_moving and m.side_target_offset < 1 then
            m.side_target_offset = m.side_target_offset + 1
        end
    end

    if Input.is_key_down(Input.KeyCode.RightArrow) or Input.is_key_down(Input.KeyCode.D) or m.swipe_right then
        if not side_moving and m.side_target_offset > -1 then
            m.side_target_offset = m.side_target_offset - 1
        end
    end
    
    local current_spline_pos = m.spline:spline():current_origin(m.t)
    local current_spline_axis = m.spline:spline():current_axis(m.t)

    local move_delta = Vec2(current_spline_pos:x() - m.last_spline_pos:x(), current_spline_pos:y() - m.last_spline_pos:y())

    if move_delta:length_squared() > 0 then
        local move_dir = move_delta
        move_dir:normalize()
        local move_angle = move_dir:to_angle()

        m.last_spline_pos:set(current_spline_pos:x(), current_spline_pos:y())

        local camera_dir = Vec2(0, 0)
        camera_dir:set(current_spline_axis:at(0):x(), current_spline_axis:at(0):y())
        local view_angle = camera_dir:to_angle()

        local da = Math.angle_delta(move_angle, view_angle)
        local x = Math.cos(da)
        local y = Math.sin(da)

        y = y + side_delta;

        skinned_mesh_renderer:set_anim_parameter("x", x)
        skinned_mesh_renderer:set_anim_parameter("y", y)
    end

    m.t = m.t + (owner.game_world:delta_time() * 0.001) * m.spline_speed

    local current_pos = current_spline_pos:add(current_spline_axis:at(1):mul(m.side_offset * blueshift.meter_to_unit(2.3)))

    owner.transform:set_origin(current_pos)
    owner.transform:set_axis(current_spline_axis)
end

function on_sensor_enter(entity)
    local player_entity = nil

    if entity:tag() == "Enemy" then
        on_dead()
    end
end

function on_dead()
    m.alive = false
    m.dead_time = owner.game_world:time()

    local sound = properties.crash_sound.value:cast_sound_asset():sound()
    local s = sound:instantiate()
    s:play2d(0.2, false)

    local skinned_mesh_renderer = owner.entity:skinned_mesh_renderer()
    skinned_mesh_renderer:transit_anim_state(0, "death", 0, 100, true)

    owner.entity:rigid_body():enable(false)
    owner.entity:sensor():enable(false)
end

function on_jump()
    m.jumping = true
    properties.standard_sensor.value:cast_sensor():enable(false)
    properties.jumping_sensor.value:cast_sensor():enable(true)
    properties.sliding_sensor.value:cast_sensor():enable(false)
end

function on_land()
    m.jumping = false
    properties.standard_sensor.value:cast_sensor():enable(true)
    properties.jumping_sensor.value:cast_sensor():enable(false)
    properties.sliding_sensor.value:cast_sensor():enable(false)
end

function on_slide()
    m.sliding = true
    properties.standard_sensor.value:cast_sensor():enable(false)
    properties.jumping_sensor.value:cast_sensor():enable(false)
    properties.sliding_sensor.value:cast_sensor():enable(true)

    local sound_asset = properties.slide_sound.value:cast_sound_asset()
    if sound_asset then
        local s = sound_asset:sound():instantiate()
        s:play2d(0.5, false)--owner.transform:origin(), blueshift.meter_to_unit(4), blueshift.meter_to_unit(15), 1.0, false)
    end
end

function on_slide_end()
    m.sliding = false
    properties.standard_sensor.value:cast_sensor():enable(true)
    properties.jumping_sensor.value:cast_sensor():enable(false)
    properties.sliding_sensor.value:cast_sensor():enable(false)
end

function on_footstep_left()
    local index = math.random(1, 4)
    local sound_asset = m.footsteps[index]
    if sound_asset then
        local s = sound_asset:sound():instantiate()
        s:play2d(1.0, false)--owner.transform:origin(), blueshift.meter_to_unit(4), blueshift.meter_to_unit(15), 1.0, false)
    end
end

function on_footstep_right()
    local index = math.random(1, 4)
    local sound_asset = m.footsteps[index]
    if sound_asset then
        local s = sound_asset:sound():instantiate()
        s:play2d(1.0, false)--owner.transform:origin(), blueshift.meter_to_unit(4), blueshift.meter_to_unit(15), 1.0, false)
    end
end