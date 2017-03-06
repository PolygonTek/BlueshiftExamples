local blueshift = require "blueshift"
local Common = blueshift.Common
local Math = blueshift.Math
local Vec3 = blueshift.Vec3

properties = {
    pickup_sound = { label = "Pick up sound", type = "object", classname = "SoundAsset", value = nil }
}

property_names = {
    "pickup_sound"
}

m = {
	ate_time
}

function start() 
	m.origin = owner.transform:origin()
	m.axis = owner.transform:axis()
end

function update()
	if owner.entity:renderable():is_enabled() then
		local t = (owner.game_world:time() * 0.001) * Math.pi
		local d = Math.sin(t) * blueshift.meter_to_unit(0.2)

		owner.transform:rotate(Vec3.unit_z, Math.to_degree((owner.game_world:delta_time() * 0.001) * Math.pi * 1.0))
		owner.transform:set_origin(m.origin + m.axis:at(2):mul(d))
	else
		local elapsed_time = owner.game_world:time() - m.ate_time
		if elapsed_time > 30000 then -- re-activate this entity after 30 seconds
			owner.entity:renderable():enable(true)
			owner.entity:sensor():enable(true)
		end
	end
end

function on_sensor_enter(entity)
	local player_entity = nil

	if entity:tag() == "Player" then
		player_entity = entity
	elseif entity:parent() and entity:parent():tag() == "Player" then
		player_entity = entity:parent()
	end

	if player_entity then
        local sound = properties.pickup_sound.value:cast_sound_asset():sound()
		local s = sound:instantiate()
		s:play2d(1.0, false)
		
		local player_state = _G[player_entity:script():sandbox_name()]
		player_state.get_coin()

		owner.entity:renderable():enable(false)
		owner.entity:sensor():enable(false)

		m.ate_time = owner.game_world:time()
	end
end
