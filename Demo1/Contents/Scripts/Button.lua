local blueshift = require "blueshift"
local Vec3 = blueshift.Vec3
local Color3 = blueshift.Color3
local ComTransform = blueshift.ComTransform
local ComScript = blueshift.ComScript
local EntityPtrArray = blueshift.EntityPtrArray

properties = {
	target = { label = "Target", type = "object", classname = "Entity", value = nil },
	normal_color = { label = "Normal Color", type = "color3", value = Color3(1.0, 1.0, 1.0) },
	hover_color = { label = "Hover Color", type = "color3", value = Color3(0.82, 0.82, 0.82) },
	press_color = { label = "Press Color", type = "color3", value = Color3(0.5, 0.5, 0.5) },
    disable_color = { label = "Disable Color", type = "color3", value = Color3(0.3, 0.3, 0.3) },
    disable_material = { label = "Disable Material", type = "object", classname = "MaterialResource", value = nil },
	button_sound = { label = "Button Sound", type = "object", classname = "SoundResource", value = nil },
	translation = { label = "Translation", type = "float", value = 2.0 }
}

property_names = {
    "target",
    "normal_color",
    "hover_color",
	"press_color",
    "disable_color",
    "disable_material",
	"button_sound",
	"translation"
}

m = {
	pressed = false,
	hover = false,
    enabled = true,
    translation = Vec3(0, 0, 0),
	target_script_states = {},
	images = {}
}

function awake()
    if properties.button_sound.value then
		m.button_sound = properties.button_sound.value:cast_asset():sound()		
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
    m.images = {}
	m.images[1] = owner.entity:image()

	local children = EntityPtrArray()
	owner.entity:children(children)

	for i = 0, children:count() - 1 do
        local child = children:at(i)
		if child:image() and child:image():color() == Color3.white then
			table.insert(m.images, children:at(i):image())
		end
	end
    
    m.original_material = owner.entity:image():material()
end

function start()
	set_button_color(properties.normal_color.value)
end

function get_button_color()
    for i = 1, #m.images do
		return m.images[i]:color()
	end
end

function set_button_color(color)
	for i = 1, #m.images do
		m.images[i]:set_color(color)
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
    
    if m.button_color_tweener then
        tween.cancel(m.button_color_tweener)
    end
    
    m.button_color_tweener = tween.add(tween.EaseOutQuadratic, 0.1, false, get_button_color(), properties.press_color.value, function(color)
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
    
    if m.button_color_tweener then
        tween.cancel(m.button_color_tweener)
    end
    
    tween.add(tween.EaseOutQuadratic, 0.1, false, get_button_color(), color, function(color)
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
    
    if m.button_color_tweener then
        tween.cancel(m.button_color_tweener)
    end
    
	if m.pressed then
	    m.button_color_tweener = tween.add(tween.EaseOutQuadratic, 0.1, false, get_button_color(), properties.press_color.value, function(color)
            set_button_color(color)
        end)

	    m.translation:set(properties.translation.value, -properties.translation.value, 0.0)
    
        owner.transform:translate(m.translation, ComTransform.TransformSpace.WorldSpace)
    else
        m.button_color_tweener = tween.add(tween.EaseOutQuadratic, 0.1, false, get_button_color(), properties.hover_color.value, function(color)
            set_button_color(color)
        end)
    end

	m.hover = true
end

function on_pointer_exit()
    if not m.enabled then
        return
    end
    
    if m.button_color_tweener then
        tween.cancel(m.button_color_tweener)
    end
    
	tween.add(tween.EaseOutQuadratic, 0.1, false, get_button_color(), properties.normal_color.value, function(color)
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
    
    if m.button_sound then
		m.button_sound:instantiate():play2d(1.0, false)
	end
            
    for i = 1, #m.target_script_states do
        m.target_script_states[i].on_clicked(owner.name)
    end
end

