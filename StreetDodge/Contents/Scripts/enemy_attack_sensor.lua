local blueshift = require "blueshift"
local Common = blueshift.Common
local Math = blueshift.Math
local Entity = blueshift.Entity

m = {
	enter = false,
	timer = 0
}

function start()
end

function update()
	m.timer = m.timer + Common.frame_sec()
	if m.timer > 0.5 then
		Entity.destroy(owner.entity, false)
	end
end

function on_sensor_enter(entity)
	if entity:tag() == "Player" then
		local player_state = _G[entity:script():sandbox_name()]
		player_state.properties.hp.value = player_state.properties.hp.value - 1
		owner.entity:sensor():enable(false)
	end
end

function on_sensor_exit(entity)
	
end

function on_sensor_stay(entity)	
end