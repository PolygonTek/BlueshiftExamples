local blueshift = require "blueshift"

function on_collision_enter(collision)
	if collision:impulse() > 50 and collision:distance() < -1 then
		local volume = math.min(1, (collision:impulse() - 50) / 300)
		owner.entity:audio_source():set_volume(volume)
		owner.entity:audio_source():play()
	end
end

function on_collision_stay(collision)
	if collision:impulse() > 50 and collision:distance() < -1 then
		local volume = math.min(1, (collision:impulse() - 50) / 300)
		owner.entity:audio_source():set_volume(volume)
		owner.entity:audio_source():play()
	end
end