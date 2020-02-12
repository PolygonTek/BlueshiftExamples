local blueshift = require "blueshift"
local Vec3 = blueshift.Vec3
local Color3 = blueshift.Color3
local ComTransform = blueshift.ComTransform
local ComScript = blueshift.ComScript
local EntityPtrArray = blueshift.EntityPtrArray

--[properties]--
properties = {
	target = { label = "Target", type = "object", classname = "Entity", value = nil },
	normal_color = { label = "Normal Color", type = "color3", value = Color3(1.0, 1.0, 1.0) },
	hover_color = { label = "Hover Color", type = "color3", value = Color3(0.82, 0.82, 0.82) },
	press_color = { label = "Press Color", type = "color3", value = Color3(0.5, 0.5, 0.5) },
    disable_color = { label = "Disable Color", type = "color3", value = Color3(0.3, 0.3, 0.3) },
    disable_material = { label = "Disable Material", type = "object", classname = "MaterialResource", value = nil },
	click_sound = { label = "Click Sound", type = "object", classname = "SoundResource", value = nil },
	translation = { label = "Translation", type = "float", value = 2.0 }
}

m = {
	pressed = false,
	hover = false,
    enabled = true,
    translation = Vec3(0, 0, 0),
	target_script_states = {},
	renderables = {}
}

function awake()
    if properties.click_sound.value then
		m.click_sound = properties.click_sound.value:cast_asset():sound()		
	end

    -- List up target script states
    m.target_script_states = {}
    local target_entity = properties.target.value and properties.target.value:cast_entity()
    if target_entity then
        local script_components = target_entity:components(ComScript.meta_object)
        for i = 0, script_components:count() - 1 do
            local script = script_components:at(i):cast_script()
            local script_state = _G[script:sandbox_name()]
            
            if script_state.on_clicked then
               table.insert(m.target_script_states, script_state)
            end
        end
    end

	-- List up renderables
    m.renderables = {}
	m.renderables[1] = owner.entity:renderable()

	local children = EntityPtrArray()
	owner.entity:children_recursive(children)

	for i = 0, children:count() - 1 do
        local child = children:at(i)
		if child:renderable() and child:renderable():color() == Color3.white then
			table.insert(m.renderables, children:at(i):renderable())
		end
	end
    
    m.original_material = owner.entity:image():material()
end

function on_enable()
    set_button_color(properties.normal_color.value)
end

function on_disable()
    m.button_color_tweener = nil
end

function update()
    if m.button_color_tweener then
        if not tween.update(m.button_color_tweener, owner.game_world:unscaled_delta_time()) then
            m.button_color_tweener = nil
        end
    end
end

function get_button_color()
    for i = 1, #m.renderables do
		return m.renderables[i]:color()
	end
end

function set_button_color(color)
	for i = 1, #m.renderables do
		m.renderables[i]:set_color(color)
	end
end

function set_enable(enable)
    m.enabled = enable
    
    local material = m.original_material
    if not enable then
        material = properties.disable_material.value:cast_asset():material()
    end
    owner.entity:image():set_material(material)
end

function set_disable(disable)
    set_enable(not disable)
end

function on_pointer_down()
    if not m.enabled then
        return
    end
    
    m.button_color_tweener = tween.create(tween.EaseOutQuadratic, 100, get_button_color(), properties.press_color.value, function(color)
        set_button_color(color)
    end)
    
    m.translation:set(properties.translation.value, -properties.translation.value, 0.0)
    
    owner.transform:translate(m.translation, ComTransform.TransformSpace.WorldSpace)

    m.pressed = true
end

function on_pointer_up()
    if not m.enabled then
        return
    end
    
	local color
	if m.hover then
		color = properties.hover_color.value
	else
		color = properties.normal_color.value
	end
      
    m.button_color_tweener = tween.create(tween.EaseOutQuadratic, 100, get_button_color(), color, function(color)
        set_button_color(color)
    end)

    owner.transform:translate(-m.translation, ComTransform.TransformSpace.WorldSpace)
    
    m.translation:set(0, 0, 0)

	m.pressed = false
end

function on_pointer_enter()
    if not m.enabled then
        return
    end   
    
    local color
	if m.pressed then
	    m.translation:set(properties.translation.value, -properties.translation.value, 0.0)
    
        owner.transform:translate(m.translation, ComTransform.TransformSpace.WorldSpace)

        color = properties.press_color.value
    else
        color = properties.hover_color.value
    end

    m.button_color_tweener = tween.create(tween.EaseOutQuadratic, 150, get_button_color(), color, function(color)
        set_button_color(color)
    end)

	m.hover = true
end

function on_pointer_exit()
    if not m.enabled then
        return
    end

	m.button_color_tweener = tween.create(tween.EaseOutQuadratic, 150, get_button_color(), properties.normal_color.value, function(color)
        set_button_color(color)
    end)

	owner.transform:translate(-m.translation, ComTransform.TransformSpace.WorldSpace)
    
    m.translation:set(0, 0, 0)

	m.hover = false
end

function on_pointer_click()
    if not m.enabled then
        return
    end
    
    if m.click_sound then
		m.click_sound:instantiate():play2d(1.0, false)
	end
            
    for i = 1, #m.target_script_states do
        m.target_script_states[i].on_clicked(owner.name)
    end
end

