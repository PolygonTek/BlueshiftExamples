local blueshift = require "blueshift"

function start()
	local animation = owner.entity:animation()
	if animation then
		animation:set_time_offset(math.random() * animation:current_anim_seconds())
		animation:set_time_scale(math.random() * 1.5 + 0.5)
	end
end

function update()
end