local blueshift = require "blueshift"
local Fragmenter = require "Scripts/Fragmenter"
local Common = blueshift.Common
local Input = blueshift.Input
local Physics = blueshift.Physics
local ComRigidBody = blueshift.ComRigidBody

m = {
    fragmenter_co = nil
}

function start()
    m.camera_entity = owner.game_world:find_entity_by_tag("MainCamera")
end

function handle_mouse_fracture()
    for i = 0, Input.touch_count() - 1 do
        local touch = Input.touch(i)
        if touch:phase() == Input.Touch.Started then
            local camera = m.camera_entity:camera()
            local ray = camera:screen_point_to_ray(touch:position())
            local max_dist = blueshift.meter_to_unit(30)
            local cast_result = Physics.CastResult()

            if Physics.ray_cast(ray:origin(), ray:get_point(max_dist), 1, cast_result) then
                local hit_rigid_body = ComRigidBody.from_cast_result(cast_result)

                if hit_rigid_body then
                    local entity = hit_rigid_body:entity()
                    local volume = entity:local_aabb():volume()

                    if entity:static_mask() == 0 then
                        local impulse = ray:direction() * hit_rigid_body:mass() * 3 -- mass * 3m/s
                        hit_rigid_body:apply_impulse(impulse, cast_result:point())

                        Fragmenter.fracture(hit_rigid_body:entity(), cast_result:point(), ray:direction(), 10)
                    end
                end
            end
        end
    end    
end

function update()
    Fragmenter.update()

    handle_mouse_fracture()
end
