local blueshift = require "blueshift"
local Common = blueshift.Common
local Math = blueshift.Math

properties = {
	axis = { label = "Axis", type = "enum", sequence = "X;Y;Z", value = 0 },
    speed = { label = "Speed", type = "float", value = 1.0 },
    time_offset = { label = "Time Offset", type = "float", value = 0.0 },
    range = { label = "Range", type = "float", value = 1.0 }
}

property_names = {
    "axis",
    "speed",
    "time_offset",
    "range"
}

m = {
}

function start() 
	m.origin = owner.transform:origin()
	m.axis = owner.transform:axis()
end

function update()
	local t = (owner.game_world:time() * 0.001 + properties.time_offset.value) * Math.pi * properties.speed.value
	local d = Math.sin(t) * blueshift.meter_to_unit(properties.range.value)

	owner.transform:set_origin(m.origin + m.axis:at(properties.axis.value):mul(d))
end