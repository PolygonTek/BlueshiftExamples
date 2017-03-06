local blueshift = require "blueshift"
local Common = blueshift.Common
local Vec3 = blueshift.Vec3

m = {
	local_origin = Vec3(0, 0, 0)
}

function start()
	local_origin = owner.transform:local_origin()
end

function update()
end