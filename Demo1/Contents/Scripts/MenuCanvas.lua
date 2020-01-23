local blueshift = require "blueshift"
local Entity = blueshift.Entity

local map_buttons = {
	['MapButton 1'] = 'Contents/Maps/third_person_player.map',
	['MapButton 2'] = 'Contents/Maps/joints.map',
	['MapButton 3'] = 'Contents/Maps/rolling_friction.map',
	['MapButton 4'] = 'Contents/Maps/shadows.map',
	['MapButton 5'] = 'Contents/Maps/pbr.map',
	['MapButton 6'] = 'Contents/Maps/vehicle.map',
	['MapButton 7'] = 'Contents/Maps/particle_system.map',
	['MapButton 8'] = 'Contents/Maps/skinned_instancing.map',
	['MapButton 9'] = 'Contents/Maps/sensor.map',
	['MapButton 10'] = 'Contents/Maps/3d_sound.map'
}

function awake()
	owner.game_world:dont_destroy_on_load(owner.game_world:find_entity("Canvas"))

	owner.game_world:restart_game(map_buttons['MapButton 1'])
end

function on_clicked(name)
	if name == 'ChangeMapButton' then
		local map_buttons = owner.game_world:find_entity("MapButtons")
		map_buttons:set_active(not map_buttons:is_active_self())
	else 
		for k, v in pairs(map_buttons) do
			if k == name then
				owner.game_world:restart_game(v)
			end
		end
	end
end