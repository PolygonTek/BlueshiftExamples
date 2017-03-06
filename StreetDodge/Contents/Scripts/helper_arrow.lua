local blueshift = require "blueshift"
local Common = blueshift.Common
local Math = blueshift.Math
local Vec3 = blueshift.Vec3

properties = {
	direction = { label = "Direction", type = "vec3", value = Vec3(1, 0, 0) },
	life_time = { label = "Life Time", type = "float", value = 3 }
}

property_names = {
    "direction",
    "life_time"
}

m = {
	position = Vec3(0, 0, 0)
}

function start()
	m.position = owner.transform:origin()

	m.start_time = owner.game_world:time()
end

function update()
	if owner.game_world:time() - m.start_time > properties.life_time.value * 1000 then
		owner.entity:set_active(false)
	end

	local t = (owner.game_world:time() - m.start_time) * 0.001 * Math.pi * 2.0
	local a = (1.0 - Math.cos(t)) * 0.5
	local offset = properties.direction.value:mul(a * 90)
	
	owner.entity:renderable():set_alpha(a * 0.5)
	
	owner.transform:set_origin(m.position + offset)
end