local blueshift = require "blueshift"
local Vec3 = blueshift.Vec3
local Mat3 = blueshift.Mat3

--[properties]--
properties = {
	position_target = { label = "Position Target", type = "object", classname = "ComTransform", value = nil },
	look_at_target = { label = "Look At Target", type = "object", classname = "ComTransform", value = nil },
	vehicle = { label = "Vehicle Body", type = "object", classname = "Entity", value = nil }
}

m = {
}

function start()
	m.position_target_transform = properties.position_target.value:cast_transform()
	m.look_at_target_transform = properties.look_at_target.value:cast_transform()
	m.vehicle = properties.vehicle.value:cast_entity()
	m.vehicle_body = m.vehicle:rigid_body()
end

function update()
	owner.transform:set_origin(Vec3.from_lerp(owner.transform:origin(), m.position_target_transform:origin(), owner.game_world:delta_time() * 0.001 * 4));

	--local velocity = m.vehicle_body:linear_velocity()
	owner.transform:look_at(m.look_at_target_transform:origin(), Vec3.unit_z)	
end