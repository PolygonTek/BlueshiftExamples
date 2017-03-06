local blueshift = require "blueshift"
local Math = blueshift.Math
local Entity = blueshift.Entity

m = {
	collided = false,
	dead_time = 0,
}

function start()
end

function update()
	m.dead_time = m.dead_time + (owner.game_world:delta_time() / 1000)
	if m.dead_time > 5 then
		Entity.destroy(owner.entity, false)
	end
end

function on_collision_enter(collision)
	local audio_source = owner.entity:audio_source()
	if audio_source and collision:impulse() > 100 then 
		audio_source:play()
	end

	if not m.collided then
		local entity = collision:entity()

		if entity:tag() == "Enemy" then
			local enemy_state = _G[entity:script():sandbox_name()]
			enemy_state.properties.hp.value = enemy_state.properties.hp.value - 1
			m.collided = true
		end
	end
end