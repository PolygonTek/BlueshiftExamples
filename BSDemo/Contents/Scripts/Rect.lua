local blueshift = require "blueshift"
local Common = blueshift.Common
local Screen = blueshift.Screen
local Guid = blueshift.Guid
local Math = blueshift.Math
local Vec2 = blueshift.Vec2
local Vec3 = blueshift.Vec3
local ComTransform = blueshift.ComTransform
local ComScript = blueshift.ComScript

execute_in_edit_mode = true

properties = {
    anchor_min = { label = "Anchors/Min", type = "vec2", value = Vec2(0, 0), description = "Anchor position in [0, 1]. Ratio in screen size" },
    anchor_max = { label = "Anchors/Max", type = "vec2", value = Vec2(0, 0), description = "Anchor position in [0, 1]. Ratio in screen size" },
	anchored_position = { label = "Anchored Position", type = "vec2", value = Vec2(0, 0), description = "Anchored position relative to anchor" },
	size_delta = { label = "Size Delta", type = "vec2", value = Vec2(1, 1), description = "Size delta for each axis from anchor border" },
	pivot = { label = "Pivot", type = "vec2", value = Vec2(0.5, 0.5), description = "Pivot position" }
}

property_names = {
	"anchor_min",
	"anchor_max",
	"anchored_position",
	"size_delta",
	"pivot"
}

function start()
end

function awake()
	update_rect_transform()
end

function on_validate()
	update_rect_transform()
end	

function on_application_resize(width, height)
	update_rect_transform()
end

function compute_child_rect(parent_width, parent_height)
	local parent_half_width = parent_width * 0.5
	local parent_half_height = parent_height * 0.5

	local anchor_pos_x1 = parent_width * properties.anchor_min.value:at(0) - parent_half_width
	local anchor_pos_y1 = parent_height * properties.anchor_min.value:at(1) - parent_half_height

	local anchor_pos_x2 = parent_width * properties.anchor_max.value:at(0) - parent_half_width
	local anchor_pos_y2 = parent_height * properties.anchor_max.value:at(1) - parent_half_height
	
	local rect_x1 = anchor_pos_x1 + properties.anchored_position.value:at(0) - properties.size_delta.value:at(0) * properties.pivot.value:at(0)
	local rect_y1 = anchor_pos_y1 + properties.anchored_position.value:at(1) - properties.size_delta.value:at(1) * properties.pivot.value:at(1)

	local rect_x2 = anchor_pos_x2 + properties.anchored_position.value:at(0) + properties.size_delta.value:at(0) * (1.0 - properties.pivot.value:at(0))
	local rect_y2 = anchor_pos_y2 + properties.anchored_position.value:at(1) + properties.size_delta.value:at(1) * (1.0 - properties.pivot.value:at(1))

	return rect_x1, rect_x2, rect_y1, rect_y2
end

function update_rect_transform()
	local parent = owner.entity:parent()
	local parent_camera = parent:camera()

	if parent_camera then
		local parent_camera = parent_camera:cast_camera()

		local parent_extent_x = parent_camera:size()
		local parent_extent_y = parent_extent_x / parent_camera:aspect_ratio()

		local rect_x1, rect_x2, rect_y1, rect_y2 = compute_child_rect(parent_extent_x * 2, parent_extent_y * 2)

		local rect_w = rect_x2 - rect_x1
		local rect_h = rect_y2 - rect_y1

		-- We use left-up incremental coordinates so negate it to make to right-down
		owner.transform:set_local_origin(Vec3(
			owner.transform:local_origin():x(),
			-(rect_x1 + rect_w * 0.5),
			-(rect_y1 + rect_h * 0.5)))
		owner.transform:set_local_scale(Vec3(1, rect_w, rect_h))
	else
		--[[
		local script_components = parent:components(ComScript.meta_object)
		
		for i = 1, script_components:count() do
			local script_component = script_components:at(i - 1):cast_script()
			if Guid.equal(script_component:script_guid(), owner.script:script_guid()) then
				local parent_size_delta = _G[script_component:sandbox_name()].properties.size_delta.value
				local parent_w = parent_size_delta:x()
				local parent_h = parent_size_delta:y()

				local rect_x1, rect_x2, rect_y1, rect_y2 = compute_child_rect(parent_w, parent_h)

				local rect_w = rect_x2 - rect_x1
				local rect_h = rect_y2 - rect_y1

				owner.transform:set_local_origin(Vec3(
					owner.transform:local_origin():x(),
					-(rect_x1 + rect_w * 0.5),
					-(rect_y1 + rect_h * 0.5)))
				owner.transform:set_local_scale(Vec3(1, rect_w, rect_h))
				break
			end
		end]]
	end
end
