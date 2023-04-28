local cls = require"class.lua"
local class = cls.class
local Font = require"theincgi.Font.lua"
local GUI = require"theincgi.GUI.lua"
local View = require"theincgi.View.lua"
local utils = require"utils.lua"
local cprint = utils.cprint
local rUtils = require"retroUtils.lua"
local ansiColor = utils.ansiColor
local Animation = 
        require"theincgi.Animation.lua"
local TitleCard = 
   require"theincgi.ggos.home.TitleCard.lua"

local Activity =
        require"theincgi.Activity.lua"
local Home = 
        class("theincgi.ggos.Home",Activity)

local consolas_12 =
             Font:new{name="consolas",size=12}

local _new = Home.new
function Home:new( ... )
	local obj = _new( self, ... )
	--games should use assigned view from onInit
	--instead
	
	obj.guiView = obj.view:subView{
		y=22,
		height=48,
		label="HomeTitleIcons"
	}
	obj.titleView = obj.view:subView{
		y=72,
		height = 32,
		label="HomeTitle"
	}
	
	obj.gui = GUI:new{
		view = obj.guiView,
		tileWidth = 48,
		tileHeight = 48,
	}
	
	obj.animations = {}
	obj.games = obj.os.games
	obj.cards = {}
	cprint(ansiColor.yellow,"Loaded GGOS Home")
	return obj
end

function Home:onInit( launchArgs )
	--self:_loadGames()
	self:_setupGUI()
end



function Home:_onSelectionChange(sel)
	local easings = require"easings.lua"
	local c,d=sel.newX,sel.newY
	local ox,oy=self.gui:getOrigin()
	local itemCenterX,itemCenterY = self.gui:getItemStart(c,d)
	local oldItem = sel.oldItem
	local newItem = sel.newItem
	local gui = self.gui
	local newOriginX = self.guiOffset-itemCenterX
	local map = require("mathUtils.lua").map
	
	local animNew = Animation:new{
		ms=1000,
		onUpdate=function( f )
			newItem.scale = 0.5 + f/2
			gui:setOrigin(
				math.floor(map(f,0,1,ox,newOriginX)),
				oy
			)
		end,
		onFinish=function()
			self.animations[ newItem ] = nil
		end,
		easing=easings.cubic
	}
	self.animations[newItem] = animNew
	animNew:start()
	if oldItem then
		local animOld = Animation:new{
			ms=1000,
			onUpdate=function( f )
				oldItem.scale = 1.0 - f/2
			end,
			onFinish=function()
				self.animations[ oldItem ] = nil
			end,
			easing=easings.cubic
		}
		self.animations[oldItem] = animOld
		animOld:start()
	end
	self:_updateTitle()
end

function Home:_setupGUI()
	self.os.view:clear()
	local n = 0
	for game, inst in pairs( self.games ) do
		n = n+1
		local card = TitleCard:new{
			game = inst
		}
		self.gui:addItem{
			item=card,
			x=n,
			y=1
		}
	end
	local w,h = self.guiView:getSize()
	self.guiOffset = w/2-self.gui:getTileWidth()/2
	
	self.gui:setOrigin(self.guiOffset,1)
	local obj = self
	self.gui:setOnChange(function(...)
		obj:_onSelectionChange(...)
	end)
	self:_onSelectionChange{
		newX=1,
		newY=1,
		newItem=self.gui:getSelection()
	}
	self:_updateTitle()
end

function Home:_updateTitle()
	self.titleView:clear()
	local card = self.gui:getSelection()
	local game = card.game
	local title,fontSpec = game:getTitle()
	local font = Font:new(fontSpec)
	local w,h = self.titleView:getSize()
	print("Render title: ",title)
	font:render{
		text=title,
		x=w/2,
		y=h/2,
		horzAlign="center",
		vertAlign="center",
		view=self.titleView,
		bold = fontSpec.bold or false,
		italics = fontSpec.italics or false,
		color = fontSpec.color or color.white
	}
	self.titleView:drawBox(1,1,w,h,color.green)
end

function Home:onFocus()
	self.gui:draw()
	self:super().onFocus( self )
end

function Home:onUnfocus()
	self:super().onUnfocus( self )
end

function Home:onUpdate()
	local inputs = rUtils.inputs()
	
	if inputs.dpad.left.buttonDown then
	  if self.gui:hasItem{dx=-1} then
	  	self.gui:moveSelection{dx=-1}
		end
	elseif inputs.dpad.right.buttonDown then
	  if self.gui:hasItem{dx=1} then
			self.gui:moveSelection{dx=1}
		end
	elseif inputs.button.a.ButtonDown then
	  local sel = self.gui:getSelection()
	  local game = sel.game
	  print( "Running: "..game:getTitle() )
	  self.os.run( game:className() )
	end
	
	for i,anim in pairs( self.animations ) do
		anim:update()
	end
	
	self.gui:draw()
	self:super().onUpdate( self )
end

function Home:onBackgroundUpdate()
end

function Home:getTitle()
	return "Home", "consolas_12"
end

function Home:drawIcon()
end

return Home