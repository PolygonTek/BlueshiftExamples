local blueshift = require "blueshift"
local Fragmenter = require "Scripts/Fragmenter"
local Common = blueshift.Common
local Math = blueshift.Math
local Vec3 = blueshift.Vec3
local Plane = blueshift.Plane
local Input = blueshift.Input
local Physics = blueshift.Physics
local ComParticleSystem = blueshift.ComParticleSystem
local Entity = blueshift.Entity
local EntityPtrArray = blueshift.EntityPtrArray

--[properties]--
properties = {
    slicing_prts = { label = "Slicing", type = "object", classname = "ParticleSystemResource", value = nil }
}

m = {
    slicing_entities = {}
}

function start()
    m.camera_entity = owner.game_world:find_entity_by_tag("MainCamera")

    m.slicing_pointer_entity = owner.game_world:create_empty_entity("Slicing Pointer")
    local particle_system_component = m.slicing_pointer_entity:add_new_component(ComParticleSystem.meta_object):cast_particle_system()
    local slicing_prts_asset = properties.slicing_prts.value:cast_asset()
    particle_system_component:set_play_on_awake(false)
    particle_system_component:set_particle_system(slicing_prts_asset:particle_system())    
end

function handle_mouse_slice()
    for i = 0, Input.touch_count() - 1 do
        local touch = Input.touch(i)
        if touch:phase() == Input.Touch.Started then
            local camera = m.camera_entity:camera()
            local ray = camera:screen_point_to_ray(touch:position())

            m.slice_start_position = ray:get_point(blueshift.meter_to_unit(15))
            m.slicing = true

            local prts_position = ray:get_point(blueshift.meter_to_unit(1))
            m.slicing_pointer_entity:transform():set_origin(prts_position)
            m.slicing_pointer_entity:particle_system():play()            

            m.clicked_id = touch:id()
        elseif touch:phase() == Input.Touch.Moved then
            if touch:id() == m.clicked_id then
                if m.slicing then
                    local camera = m.camera_entity:camera()
                    local ray = camera:screen_point_to_ray(touch:position())
                    local new_position = ray:get_point(blueshift.meter_to_unit(15))
                    local slice_length = new_position:distance(m.slice_start_position)

                    local prts_position = ray:get_point(blueshift.meter_to_unit(1))
                    m.slicing_pointer_entity:transform():set_origin(prts_position)

                    if slice_length >= 0.1 then
                        local slicing_plane = Plane(Vec3(0, 0, 0), 0)
                        slicing_plane:set_from_points(m.slice_start_position, ray:origin(), new_position)
                        --print(slicing_plane:to_string())

                        local overlap_entities = EntityPtrArray()
                        owner.game_world:overlap_triangle(m.slice_start_position, ray:origin(), new_position, 1, overlap_entities)
                        for j = 0, overlap_entities:count() - 1 do
                            local entity = overlap_entities:at(j)
                            local already_sliced = false
                            for _, e in pairs(m.slicing_entities) do
                                if e:instance_id() == entity:instance_id() then
                                    already_sliced = true
                                    break
                                end
                            end

                            if entity:static_mask() == 0 and entity:rigid_body() and already_sliced == false then
                                local sliced_entity_a = nil
                                local sliced_entity_b = nil

                                sliced_entity_a, sliced_entity_b = Fragmenter.slice(entity, slicing_plane)

                                table.insert(m.slicing_entities, sliced_entity_a)
                                table.insert(m.slicing_entities, sliced_entity_b)
                            end
                        end
                    end
                    m.slice_start_position = new_position                    
                end
            end
        elseif touch:phase() == Input.Touch.Ended or touch:phase() == Input.Touch.Canceled then
            if touch:id() == m.clicked_id then
                m.slicing = false
                m.slicing_entities = {}

                m.slicing_pointer_entity:particle_system():stop(ComParticleSystem.StopMode.StopEmitting)
            end
        end
    end    
end

function update()
	handle_mouse_slice()
end
