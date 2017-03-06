local blueshift = require "blueshift"
local Math = blueshift.Math

properties = {
    crash_sound = { label = "Crash sound", type = "object", classname = "SoundAsset", value = nil }
}

property_names = {
    "crash_sound",
}

m = {
}

function start()
end

function update()
end

function on_sensor_enter(entity)
	local player_entity = nil

	if entity:tag() == "Player" then
		player_entity = entity
	elseif entity:parent() and entity:parent():tag() == "Player" then
		player_entity = entity:parent()
	end

	if player_entity then
        local sound = properties.crash_sound.value:cast_sound_asset():sound()
		local s = sound:instantiate()
		s:play2d(0.2, false)
		
		local player_state = _G[player_entity:script():sandbox_name()]
		player_state.on_dead()
	end
end

function on_sensor_exit(entity)
end
