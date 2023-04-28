local cls = require"class.lua"
local class = cls.class
local utils = require"utils.lua"
local Credits = require"Credits.lua"

local Activity = class"theincgi.Activity"

local _new = Activity.new
function Activity:new( ... )	
	local obj = _new( self )
	
	local args = utils.kwargs({
		{ os = "table" }, --not a class
		{ view = "class:theincgi.View"}
		--use :classname
		--{ name = "string" }, --name of this activity
	},...)
	
	obj.os = args.os
	obj.view = args.view
	--obj.appName = args.name
	
	return obj
end

--game started
function Activity:onInit( launchArgs )
end

--game shown on screen
function Activity:onFocus()
  self.view.visible = true
end

--not shown on screen anymore, prob home
function Activity:onUnfocus()
  self.view.visible = false
end

--tick
function Activity:onUpdate()
	self.os.view:clear()
	self.os.view:draw()
end

--background tick
function Activity:onBackgroundUpdate()
end

function Activity:getBackgroundTickDelay()
	return false
end

function Activity:getTitle()
	return "???", {name="consolas",size=12}
end

function Activity:getIcon()
end

--lists credits for parts of projects
function Activity:getCredits()
	local credits = Credits:new()
	local RGT = "Retro Gadgets Team"
	credits:addCategory{
		name=RGT
	}
	credits:addLine(RGT,"Marco")
	credits:addLine(RGT,"Merlo")
	credits:addLine(RGT,"aXon")
	
	local GGOS = "GameGear"
	credits:addCategory{
		name=GGOS
	}
	credits:addLine(GGOS,
	"Hardware Design - TheIncgi")
	credits:addLine(GGOS,"Lead OS Dev - TheIncgi")
	credits:addLine(GGOS,"Testing - TheIncgi")
end

return Activity