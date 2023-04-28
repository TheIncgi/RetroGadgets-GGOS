--ggos home TitleCard
local cls = require"class.lua"
local class = cls.class
local GE = require"theincgi.GuiElement.lua"
local utils = require"utils.lua"

local TitleCard =
         class("theincgi.ggos.home.TitleCard", GE)

--view is set after constructor
local _new = TitleCard.new
function TitleCard:new( ... )
	local obj = _new( self, ... )
	local args = utils.kwargs({
		{game="class:theincgi.Activity"}
	},...)
	
	obj.game = args.game
	obj.scale = 0.5
	
	return obj
end

function TitleCard:draw( gui, selected )
	local w,h = self.view:getSize()
	local w2,h2 = w/2,h/2
	local s = self.scale
	local x1,y1 = w2-w2*s+1, h2-h2*s+1
	local x2,y2 = w2+w2*s, h2+h2*s
	self.view:fillRect(1,1,w,h,color.black)
	self.view:drawBox(
		math.floor(x1),
		math.floor(y1),
		math.floor(x2),
		math.floor(y2),
		color.white
	)
end

return TitleCard