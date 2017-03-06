local blueshift = require "blueshift"
local Input = blueshift.Input

properties = {
	target_script = { label = "Target", type = "object", classname = "ComScript", value = nil },
}

property_names = {
    "target_script"
}

m = {
	target_script = nil,
    pressed = false    
}

function start()
	m.target_script = properties.target_script.value:cast_script()
end

function on_pointer_down()
    m.pressed = true
end

function on_pointer_up()
	if m.pressed then
		target_script_state = _G[m.target_script:sandbox_name()]
		target_script_state.button_pressed(owner.name)
	end
    m.pressed = false
end