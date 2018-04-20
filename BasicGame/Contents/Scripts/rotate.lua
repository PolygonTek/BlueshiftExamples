local blueshift = require "blueshift"
local Common = blueshift.Common
local Math = blueshift.Math
local Vec3 = blueshift.Vec3

properties = {
    rotation_speed = { label = "Rotation Speed", type = "float", value = 180 },
    bounce_speed = { label = "Bounce Speed", type = "float", value = 1 },
    bounce_delta = { label = "Bounce Delta", type = "float", value = 0.2 },
}

property_names = {
	"rotation_speed",
	"bounce_speed",
	"bounce_delta"
}

m = {
}

function start() 
	m.origin = owner.transform:origin()
	m.axis = owner.transform:axis()

	m.rotation_speed = Math.to_radian(properties.rotation_speed.value);
	m.bounce_speed = properties.bounce_speed.value;
	m.bounce_delta = blueshift.meter_to_unit(properties.bounce_delta.value);
end

function update()
	local t = (owner.game_world:time() * 0.001) * Math.pi
	local d = Math.sin(t * m.bounce_speed) * m.bounce_delta;

	owner.transform:rotate(Vec3.unit_z, Math.to_degree((owner.game_world:delta_time() * 0.001) * m.rotation_speed))
	owner.transform:set_origin(m.origin + m.axis:at(2):mul(d))
end