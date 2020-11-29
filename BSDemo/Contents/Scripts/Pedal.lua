local blueshift = require "blueshift"
local Vec2 = blueshift.Vec2

--[properties]--
properties = {
    target_car = { label = "Target Car", type = "object", classname = "Entity", value = nil }
}

m = {
	initial_size_delta = Vec2(0, 0)
}

function start()
    m.car = properties.target_car.value:cast_entity()

    m.initial_size_delta:assign(owner.entity:rect_transform():size_delta())
end

function update()
	if m.pedal_down_tweener then
        if not tween.update(m.pedal_down_tweener, owner.game_world:unscaled_delta_time()) then
            m.pedal_down_tweener = nil
        end
    end
end

function on_pointer_down()
	local current_size_delta = owner.entity:rect_transform():size_delta()

    m.pedal_down_tweener = tween.create(tween.EaseOutQuadratic, 50, current_size_delta:y(), m.initial_size_delta:y() * 0.8, function(size_delta_y)
    	local size_delta = Vec2(m.initial_size_delta:x(), size_delta_y)    	
        owner.entity:rect_transform():set_size_delta(size_delta)
    end)
    
    _G[m.car:script():sandbox_name()].on_button(owner.name, true)
end

function on_pointer_up()
	local current_size_delta = owner.entity:rect_transform():size_delta()

    m.pedal_down_tweener = tween.create(tween.EaseOutQuadratic, 50, current_size_delta:y(), m.initial_size_delta:y(), function(size_delta_y)
    	local size_delta = Vec2(m.initial_size_delta:x(), size_delta_y)
        owner.entity:rect_transform():set_size_delta(size_delta)
    end)
    	
	_G[m.car:script():sandbox_name()].on_button(owner.name, false)
end

