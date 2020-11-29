local blueshift = require "blueshift"
local Entity = blueshift.Entity
local Vec3 = blueshift.Vec3

m = {
	entered = false
}

function on_sensor_enter(entity)
	m.entered = true
end

function on_sensor_stay(entity)
	m.entered = true

	local rigid_body = entity:rigid_body()
	if rigid_body then 
		rigid_body:apply_central_force(Vec3(0, 0, 20))
	end
end

function on_sensor_exit(entity)
	m.entered = false
end