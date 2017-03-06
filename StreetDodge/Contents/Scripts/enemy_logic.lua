--local common = require 'Contents/Scripts/common'
local blueshift = require "blueshift"
local Common = blueshift.Common
local Math = blueshift.Math
local Vec3 = blueshift.Vec3
local Entity = blueshift.Entity

properties = {
	hp = { label = "Hp", type = "int", minimum = 1, maximum = 100, value = 3 },
	speed = { label = "Speed", type = "float", minimum = 1.0, maximum = 2.0, value = 1.0 },
    attack_sensor = { label = "Attack Sensor", type = "object", classname = "PrefabAsset", value = 0 },
    attack_place = { label = "Attack Place", type = "object", classname = "ComTransform", value = 0 }
}

propertiy_names = {
    "hp",
    "speed",
    "attack_sensor",
    "attack_place"
}

m = {
    gravity = 9.8,
    velocity = Vec3(0, 0, 0),
    alive = true,
    dead_time = 0,
    attacking = false,
    attack_time = 0,
    sensor = nil
}

function start()
    m.velocity:set_from_scalar(0)

   	m.target_entity = owner.game_world:find_entity_by_tag("Player")
end

function update()
	if not m.alive then
		local elapsed_time = owner.game_world:time() - m.dead_time 

		-- sink to the ground
		if elapsed_time > 3200 then
			local pos = owner.transform:origin()
			pos:set_z(pos:z() - (owner.game_world:delta_time() / 1000) * blueshift.centi_to_unit(20))
			owner.transform:set_origin(pos)
		end

		if elapsed_time > 8000 then
			Entity.destroy(owner.entity, false)
		end
		return
	end

	local character_controller = owner.entity:character_controller()
	local skinned_mesh_renderer = owner.entity:skinned_mesh_renderer()	

    local angles = owner.transform:angles()
    local target_dist = 0	    

    if m.target_entity and _G[m.target_entity:script():sandbox_name()].properties.hp.value > 0 then
        local target_pos = m.target_entity:transform():origin()
        local current_pos = owner.transform:origin()

        local target_dir = target_pos - current_pos
        target_dist = target_dir:length()

        local target_yaw = Math.angle_normalize_360(target_dir:compute_yaw())
        local current_yaw = angles:yaw()
        local yaw_delta = Math.angle_normalize_180(target_yaw - current_yaw)

        current_yaw = current_yaw + yaw_delta * (owner.game_world:delta_time() / 1000) * 1.2
        angles:set_yaw(Math.angle_normalize_360(current_yaw))
    
	    angles:set_pitch(0)
	    angles:set_roll(0)

	    owner.transform:set_angles(angles)

	    if character_controller then
	        if character_controller:is_on_ground() then
	            m.velocity:set_z(0)
	        else
	            m.velocity:set_z(m.velocity:z() - m.gravity * (owner.game_world:delta_time() / 1000))
	        end

	        if skinned_mesh_renderer then
	            local translation_delta = skinned_mesh_renderer:translation_delta(owner.game_world:prev_time(), owner.game_world:time())
	            local move_delta = angles:to_mat3():mul_vec(translation_delta):mul_comp(owner.transform:scale())
	            move_delta:set_z(move_delta:z() + m.velocity:z() + (owner.game_world:delta_time() / 1000))
	            character_controller:move(move_delta)
	        end
	    end

	    if skinned_mesh_renderer then
	    	local scale = owner.transform:scale():x()
	        if target_dist > blueshift.meter_to_unit(1.0 + scale * character_controller:capsule_radius()) then
	            skinned_mesh_renderer:set_anim_parameter("speed", properties.speed.value)
       			skinned_mesh_renderer:set_anim_parameter("attacking", 0)
	        else
	       		skinned_mesh_renderer:set_anim_parameter("speed", 0)
	       		
	       		if _G[m.target_entity:script():sandbox_name()].properties.hp.value > 0 then
	       			skinned_mesh_renderer:set_anim_parameter("attacking", 1)
	       		end        	
	        end
	    end
	end

    if properties.hp.value <= 0 then
        skinned_mesh_renderer:set_anim_parameter("dead", 1)
    end
end

function on_dead()
	m.alive = false
	m.dead_time = owner.game_world:time()

	owner.entity:character_controller():enable(false)
end

function on_attack()
	m.attacking = true
    m.attack_time = owner.game_world:time()

    local entity = properties.attack_sensor.value:cast_prefab_asset():prefab():root_entity()
    m.sensor = owner.game_world:clone_entity(entity)
    if m.sensor then
        local sensor_transform = properties.attack_place.value:cast_transform()
        m.sensor:transform():set_origin(sensor_transform:origin())
        m.sensor:transform():set_axis(sensor_transform:axis())
    end
end