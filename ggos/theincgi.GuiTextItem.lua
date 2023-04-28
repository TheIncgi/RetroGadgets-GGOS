local cls = require"class.lua"
local class = cls.class
local GuiElement = require"GuiElement.lua"
local utils = require"utils.lua"

local GTE = class("theincgi.GuiTextItem", GuiElement)

local _new = GTE.new
function GTE:new( ... )
	local args = utils.kwargs({
		{	text = "string" },
	},...)
	
	--gdt.VideoChip0.draw
end

return GTE