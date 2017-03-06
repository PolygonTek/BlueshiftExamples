local blueshift = require "blueshift"
local Common = blueshift.Common
local Math = blueshift.Math
local Vec3 = blueshift.Vec3

properties = {
	enemy1 = { label = "Enemy 1", type = "object", classname = "PrefabAsset", value = 0 },
	enemy2 = { label = "Enemy 2", type = "object", classname = "PrefabAsset", value = 0 },
	enemy3 = { label = "Enemy 3", type = "object", classname = "PrefabAsset", value = 0 },
	max_spawn_count = { label = "Max Spawn Count", type = "int", value = 5 },
	spawn_delay = { label = "Spawn Delay", type = "float", value = 5.0 }
}

property_names = {
    "enemy1",
    "enemy2",
    "enemy3",
    "max_spawn_count",
    "spawn_delay"
}

m = {
	children = blueshift.EntityPtrList(),
	timer = 0
}

function awake() 
	owner.entity:children(m.children)
end

function start()
end

function update()
	m.timer = m.timer - (owner.game_world:delta_time() / 1000)

	if m.timer <= 0 then
		local enemies = owner.game_world:find_entities_by_tag("Enemy")
		if enemies:count() < properties.max_spawn_count.value then
			local spot = m.children:at(math.random(0, m.children:count() - 1))
			local enemies = {}
			enemies[1] = properties.enemy1.value
			enemies[2] = properties.enemy2.value
			enemies[3] = properties.enemy3.value
			local enemy_prefab = enemies[math.random(1, 3)]
			local root = enemy_prefab:cast_prefab_asset():prefab():root_entity()
		    local enemy = owner.game_world:clone_entity(root)

		    local enemy_state = _G[enemy:script():sandbox_name()]
		    --enemy_state.properties.speed.value = 1.0 + math.random()

		    local scale = 1.0 + (math.random() - 0.5) * 0.1

	        enemy:transform():set_local_scale(Vec3(scale, scale, scale))
	        enemy:transform():set_origin(spot:transform():origin())
	        enemy:transform():set_axis(spot:transform():axis())
		end
	   	m.timer = properties.spawn_delay.value
	end
end