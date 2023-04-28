local cls = require"class.lua"
local class = cls.class
local utils = require"utils.lua"

local View = require"theincgi.View.lua"

local GE = class"theincgi.GuiElement"

local _new = GE.new
function GE:new( ... )
	local obj = _new( self )
	obj.view = false	
	return obj
end

function GE:draw( gui, selected )
	if not self.view then return end
	self.view:drawLine()
end

function GE:setView( view )
	self.view = view
end

function GE:getView()
	return self.view
end

return GE