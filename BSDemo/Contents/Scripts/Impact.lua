local blueshift = require "blueshift"

m = {}

function on_collision_enter(collision)
	if collision:impulse() > 0.5 and collision:distance() < -0.003 then
		local audio_source = owner.entity:audio_source()
		if audio_source then
			local volume = math.min(1, (collision:impulse() - 0.5) / 3)
			audio_source:set_volume(volume)
			audio_source:play()
		end
	end
end

function on_collision_stay(collision)
	if collision:impulse() > 0.5 and collision:distance() < -0.003 then
		local audio_source = owner.entity:audio_source()
		if audio_source then
			local volume = math.min(1, (collision:impulse() - 0.5) / 3)
			audio_source:set_volume(volume)
			audio_source:play()
		end
	end
end
