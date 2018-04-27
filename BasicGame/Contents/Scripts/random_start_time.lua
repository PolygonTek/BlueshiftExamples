local blueshift = require "blueshift"

function start()
	local skinned_mesh_renderer = owner.entity:skinned_mesh_renderer()
	if skinned_mesh_renderer then
		skinned_mesh_renderer:set_time_offset(math.random() * skinned_mesh_renderer:anim_seconds())
		skinned_mesh_renderer:set_time_scale(math.random() * 1.5 + 0.5)
	end
end

function update()
end