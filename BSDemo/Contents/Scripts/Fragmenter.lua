local blueshift = require "blueshift"
local Queue = require "Scripts/queue"
local Math = blueshift.Math
local Vec3 = blueshift.Vec3
local Quat = blueshift.Quat
local Plane = blueshift.Plane
local Mesh = blueshift.Mesh
local ComStaticMeshRenderer = blueshift.ComStaticMeshRenderer
local ComMeshCollider = blueshift.ComMeshCollider
local ComRigidBody = blueshift.ComRigidBody
local Entity = blueshift.Entity
local EntityPtrArray = blueshift.EntityPtrArray

local fragmenter = {}

fragmenter.co_list = {}

function fragmenter.create_fragment(name, src_entity, mesh)
    local src_transform = src_entity:transform()
    local src_rigid_body = src_entity:rigid_body()
    local src_static_mesh_renderer = src_entity:static_mesh_renderer()
    local src_mesh = src_static_mesh_renderer:mesh()
    local volume_fraction = mesh:aabb():volume() / src_mesh:aabb():volume()
    Mesh.release(src_mesh)

    local fragment_entity = src_entity:game_world():create_empty_entity(name)
    fragment_entity:transform():set_origin_axis_scale(src_transform:origin(), src_transform:axis(), src_transform:scale())

    local static_mesh_renderer = fragment_entity:add_new_component(ComStaticMeshRenderer.meta_object):cast_static_mesh_renderer()
    static_mesh_renderer:set_color(src_static_mesh_renderer:color())
    static_mesh_renderer:set_alpha(src_static_mesh_renderer:alpha())
    static_mesh_renderer:set_mesh(mesh)
    for i = 0, src_static_mesh_renderer:num_materials() - 1 do
        static_mesh_renderer:set_material(i, src_static_mesh_renderer:material(i))
    end

    local mesh_collider = fragment_entity:add_new_component(ComMeshCollider.meta_object):cast_mesh_collider()
    mesh_collider:set_convex(true)
    mesh_collider:set_mesh(mesh)

    local rigid_body = fragment_entity:add_new_component(ComRigidBody.meta_object):cast_rigid_body()
    rigid_body:set_mass(src_rigid_body:mass() * volume_fraction)
    rigid_body:set_restitution(src_rigid_body:restitution())
    rigid_body:set_friction(src_rigid_body:friction())
    rigid_body:set_rolling_friction(src_rigid_body:rolling_friction())
    rigid_body:set_spinning_friction(src_rigid_body:spinning_friction())
    rigid_body:set_linear_damping(src_rigid_body:linear_damping())
    rigid_body:set_angular_damping(src_rigid_body:angular_damping())
    rigid_body:set_ccd(src_rigid_body:is_ccd())
    rigid_body:set_linear_velocity(src_rigid_body:linear_velocity() * 0.9)
    rigid_body:set_angular_velocity(src_rigid_body:angular_velocity() * 0.9)

    return fragment_entity
end

function fragmenter.slice(entity, slicing_plane)
    local src_static_mesh_renderer = entity:static_mesh_renderer()
    local sliced_entity_a = nil
    local sliced_entity_b = nil

    if src_static_mesh_renderer then
        local src_mesh = src_static_mesh_renderer:mesh()
        local src_mesh_material_count = src_static_mesh_renderer:num_materials()
        local sliced_below_mesh = Mesh.new()
        local sliced_above_mesh = Mesh.new()
        local world_to_local_matrix = entity:transform():transform():inverse_orthogonal()
        slicing_plane:transform_by_mat3x4_self(world_to_local_matrix)

        if Mesh.try_slice_mesh(src_mesh, slicing_plane, true, 1.0, true, sliced_below_mesh, sliced_above_mesh) == true then
            local src_mesh_volume = entity:static_mesh_renderer():aabb():volume()
            local src_mesh_mass = entity:rigid_body():mass()
            local below_mesh_volume = sliced_below_mesh:aabb():volume()
            local below_mesh_mass = src_mesh_mass * below_mesh_volume / src_mesh_volume
            local above_mesh_volume = sliced_above_mesh:aabb():volume()            
            local above_mesh_mass = src_mesh_mass * above_mesh_volume / src_mesh_volume

            -- both sliced meshes have mass greater than 8g
            if below_mesh_mass > 0.008 and above_mesh_mass > 0.008 then
                local child_entities = EntityPtrArray()
                entity:children(child_entities)

                for k = 0, child_entities:count() - 1 do
                    child_entities:at(k):set_parent(nil) -- fix me
                end

                local entity_name = entity:name():c_str()
                sliced_entity_a = fragmenter.create_fragment(entity_name.."-SlicedA", entity, sliced_above_mesh)
                sliced_entity_b = fragmenter.create_fragment(entity_name.."-SlicedB", entity, sliced_below_mesh)
                
                -- Disable original entity
                entity:set_active(false)
                --Entity.destroy(entity)
            end
        end

        Mesh.release(src_mesh)
        Mesh.release(sliced_below_mesh)
        Mesh.release(sliced_above_mesh)
    end

    return sliced_entity_a, sliced_entity_b
end

function fragmenter.fracture(entity, impact_point, impact_direction, fragment_count)
    local left = Vec3(0, 0, 0)
    local up = Vec3(0, 0, 0)
    impact_direction:orthogonal_basis(left, up)

    local fragments = Queue.new()
    Queue.push(fragments, entity)

    local co = coroutine.create(function()
        for i = 1, fragment_count - 1 do
            local current_entity = Queue.pop(fragments)

            if current_entity then
                local slicing_plane = Plane(Vec3(0, 0, 0), 0)
            
                if i <= 3 then
                    local rotator = Quat.from_angle_axis(Math.random(-Math.pi, Math.pi), impact_direction)
                    slicing_plane:set_normal(rotator:rotate_vector(up))
                    slicing_plane:normalize()
                    slicing_plane:fit_through_point(impact_point)
                else
                    local normal = Vec3(Math.random(-1.0, 1.0), Math.random(-1.0, 1.0), Math.random(-1.0, 1.0))
                    slicing_plane:set_normal(normal)
                    slicing_plane:normalize()
                    local fragment_center = current_entity:world_aabb(false):center()
                    local plane_position = Vec3.from_lerp(impact_point, fragment_center, i / fragment_count)
                    slicing_plane:fit_through_point(plane_position)
                end

                local sliced_entity_a = nil
                local sliced_entity_b = nil
                sliced_entity_a, sliced_entity_b = fragmenter.slice(current_entity, slicing_plane)

                if sliced_entity_a and sliced_entity_b then
                    Queue.push(fragments, sliced_entity_a)
                    Queue.push(fragments, sliced_entity_b)

                    coroutine.yield()
                end
            end
        end
    end)
    coroutine.resume(co)
    table.insert(fragmenter.co_list, co)
end

function fragmenter.update()
    local remove_index_list = {}

    for index, co in pairs(fragmenter.co_list) do
        if not coroutine.resume(co) then
            table.insert(remove_index_list, index)
        end
    end

    for _, remove_index in pairs(remove_index_list) do
        table.remove(fragmenter.co_list, remove_index)
    end
end

return fragmenter