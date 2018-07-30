local blueshift = require "blueshift"
local Color3 = blueshift.Color3

function start()
	local renderable = owner.entity:renderable()
	if renderable then
		renderable:set_color(Color3(math.random(), math.random(), math.random()))
	end
end
