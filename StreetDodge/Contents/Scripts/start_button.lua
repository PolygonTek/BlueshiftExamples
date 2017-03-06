local blueshift = require "blueshift"
local Input = blueshift.Input

m = {
    pressed = false
}

function start()
end

function on_pointer_down()    
    m.pressed = true
end

function on_pointer_up()
	if m.pressed then
		owner.game_world:restart_game("Contents/Maps/stage1.map")
	end
    m.pressed = false
end