local blueshift = require "blueshift"
local Color3 = blueshift.Color3
local ComScript = blueshift.ComScript
local EntityPtrArray = blueshift.EntityPtrArray

properties = {
	target = { label = "Target", type = "object", classname = "Entity", value = nil },
	normal_color = { label = "Normal Color", type = "color3", value = Color3(1.0, 1.0, 1.0) },
	hover_color = { label = "Hover Color", type = "color3", value = Color3(0.8, 0.8, 0.8) },
	press_color = { label = "Press Color", type = "color3", value = Color3(0.5, 0.5, 0.5) },
    disable_color = { label = "Disable Color", type = "color3", value = Color3(0.3, 0.3, 0.3) },
    background = { label = "Background", type = "object", classname = "ComImage", value = nil },
    checkmark = { label = "Checkmark", type = "object", classname = "ComImage", value = nil },
    is_on = { label = "Is On", type = "bool", value = false },
	click_sound = { label = "Click Sound", type = "object", classname = "SoundResource", value = nil },
}

property_names = {
    "target",
    "normal_color",
    "hover_color",
	"press_color",
    "disable_color",
    "background",
    "checkmark",
    "is_on",
	"click_sound"
}

m = {
	pressed = false,
	hover = false,
    enabled = true,
	target_script_states = {},
}

function awake()
    m.checked = properties.is_on.value

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

    -- Background
    m.background_image = properties.background.value and properties.background.value:cast_image()

    -- Checkmark
    m.checkmark_image = properties.checkmark.value and properties.checkmark.value:cast_image()
    m.checkmark_image:set_alpha(m.checked and 1.0 or 0.0)
end

function start()
    m.background_image:set_color(properties.normal_color.value)
end

function set_enable(enable)
    m.enabled = enable
end

function set_disable(disable)
    set_enable(not disable)
end

function on_pointer_down()
    if not m.enabled then
        return
    end
    
    if m.checkmark_color_tweener then
        tween.cancel(m.checkmark_color_tweener)
    end
    
    m.checkmark_color_tweener = tween.add(tween.EaseOutQuadratic, 0.1, false, m.background_image:color(), properties.press_color.value, function(color)
        m.background_image:set_color(color)
    end)
    
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
    
    if m.checkmark_color_tweener then
        tween.cancel(m.checkmark_color_tweener)
    end
    
    tween.add(tween.EaseOutQuadratic, 0.1, false, m.background_image:color(), color, function(color)
        m.background_image:set_color(color)
    end)

	m.pressed = false
end

function on_pointer_enter()
    if not m.enabled then
        return
    end
    
    if m.checkmark_color_tweener then
        tween.cancel(m.checkmark_color_tweener)
    end
    
    local color
	if m.pressed then
        color = properties.press_color.value
    else
        color = properties.hover_color.value
    end

    m.checkmark_color_tweener = tween.add(tween.EaseOutQuadratic, 0.15, false, m.background_image:color(), color, function(color)
        m.background_image:set_color(color)
    end)

	m.hover = true
end

function on_pointer_exit()
    if not m.enabled then
        return
    end
    
    if m.checkmark_color_tweener then
        tween.cancel(m.checkmark_color_tweener)
    end
    
	tween.add(tween.EaseOutQuadratic, 0.15, false, m.background_image:color(), properties.normal_color.value, function(color)
        m.background_image:set_color(color)
    end)

	m.hover = false
end

function on_pointer_click()
    if not m.enabled then
        return
    end

    m.checked = not m.checked

    local target_alpha = m.checked and 1.0 or 0.0

    tween.add(tween.EaseOutQuadratic, 0.15, false, m.checkmark_image:alpha(), target_alpha, function(alpha)
        m.checkmark_image:set_alpha(alpha)
    end)

    if m.click_sound then
		m.click_sound:instantiate():play2d(1.0, false)
	end
            
    for i = 1, #m.target_script_states do
        m.target_script_states[i].on_clicked(owner.name)
    end
end

