local cls = require"class.lua"
local class = cls.class
local Font = require"theincgi.Font.lua"
local GUI = require"theincgi.GUI.lua"
local View = require"theincgi.View.lua"

local Activity =
        require"theincgi.Activity.lua"
local GR = 
        class("theincgi.games.G_Racer",Activity)

local _new = GR.new
function GR:new( ... )
	local obj = _new( self, ... )
	
	return obj
end

function GR:getTitle()
	local _,defaultFont = self:super().getTitle(self)
	return "G-Racer", {
		name="orbitron",
		size=12,
		italics=true,
		color=color.red
	}
end

return GR