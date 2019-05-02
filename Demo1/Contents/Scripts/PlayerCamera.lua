local blueshift = require "blueshift"
local Math = blueshift.Math
local Vec3 = blueshift.Vec3
local Mat3 = blueshift.Mat3
local Physics = blueshift.Physics

properties = {
	max_distance = { label = "Max Distance", type = "float", value = 4.5 },
	z_offset = { label = "Z Offset", type = "float", value = 1.9 }
}

property_names = {
	"max_distance",
	"z_offset"
}

m = {
	target_camera_distance = 4.5,
	current_camera_distance = 4.5
}

function start()
	m.parent_transform = owner.entity:parent():transform()
end

function update()
	local start_pos = m.parent_transform:origin() + Vec3.unit_z * properties.z_offset.value
    local end_pos = start_pos - owner.transform:angles():to_forward() * properties.max_distance.value
    
    local cast_result = Physics.CastResult()
    Physics.ray_cast(start_pos, end_pos, 1, cast_result)
    
    m.target_camera_distance = (cast_result:fraction() - 0.1) * properties.max_distance.value

	local dt = owner.game_world:delta_time() * 0.001
    
    if m.target_camera_distance < m.current_camera_distance then 
    	m.current_camera_distance = m.target_camera_distance
    else
    	m.current_camera_distance = Math.lerp(m.current_camera_distance, m.target_camera_distance, dt * 2)
    end
    
    local camera_origin = start_pos - owner.transform:angles():to_forward() * m.current_camera_distance
        
	owner.transform:set_origin(camera_origin)
end