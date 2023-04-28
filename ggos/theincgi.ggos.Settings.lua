local cls = require"class.lua"
local class = cls.class
local Font = require"theincgi.Font.lua"
local GUI = require"theincgi.GUI.lua"
local View = require"theincgi.View.lua"

local Activity =
        require"theincgi.Activity.lua"
local Settings = 
        class("theincgi.ggos.Settings",Activity)

Settings.static = {
	defaultSettings = {
		skipStartupLogo     = false,
		skipHealthAndSaftey = false,
		removeScreenLines   = true,
	}
}

local _new = Settings.new
function Settings:new( ... )
	local obj = _new( self, ... )
	obj:load()
	return obj
end

function Settings:load()
end

function Settings:save()
end

function Settings:getTitle()
	local _,defaultFont = self:super().getTitle(self)
	return "Settings", defaultFont
end

return Settings