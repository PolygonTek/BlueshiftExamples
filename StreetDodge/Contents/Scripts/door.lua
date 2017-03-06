local blueshift = require "blueshift"
local Common = blueshift.Common
local Math = blueshift.Math

properties = {
	axis = { label = "Axis", type = "enum", sequence = "X;Y;Z", value = 0 },
    speed = { label = "Speed", type = "float", value = 1.0 },
    range = { label = "Range", type = "float", value = 1.0 }
}

property_names = {
    "axis",
    "speed",
    "range"
}

m = {
	door = nil,
	enter = false,
	moving = false
}

function start()
	m.door = owner.entity:parent()
	if m.door then
		m.origin = m.door:transform():origin()
		m.axis = m.door:transform():axis()
	end
end

function update()
	if m.door then
		if m.moving then
			local delta_pos = m.target_pos - m.door:transform():origin()
			local d = m.target_dir:mul(Common.frame_sec() * blueshift.meter_to_unit(properties.speed.value))
			if (d:length_squared() > delta_pos:length_squared()) then
				d:scale_to_length(delta_pos:length())
				m.moving = false
			end
			m.door:transform():set_origin(m.door:transform():origin() + d)
		end
	end
end

function on_sensor_enter(entity)
	if m.door then
		if (not m.enter) and entity:tag() == "Player" then
			m.enter = true
			m.moving = true
			m.target_pos = m.origin + m.axis:at(properties.axis.value):mul(blueshift.meter_to_unit(properties.range.value))
			m.target_dir = m.target_pos - m.door:transform():origin()
			m.target_dir:normalize()
		end
	end
end

function on_sensor_exit(entity)
	if (m.door) then
		if (m.enter and entity:tag() == "Player") then
			m.enter = false
			m.moving = true
			m.target_pos = m.origin
			m.target_dir = m.target_pos - m.door:transform():origin()
			m.target_dir:normalize()
		end
	end
end

function on_sensor_stay(entity)	
end