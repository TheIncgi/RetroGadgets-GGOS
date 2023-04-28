-- Retro Gadgets
local View = require"theincgi.View.lua"

function test()
  local dataUtils = require"dataUtils.lua"
  print( 
    "DECODE:"
    ..dataUtils.dec64(
    "TWFueSBoYW5kcyBtYWtlIGxpZ2h0IHdvcmsu")
  )
	
	print(type(gdt.VideoChip0)) --userdata
	
  local t = ColorRGBA(0,0,255,0)
  print("Color is "..type(color.blue))
  local Font = require"theincgi.Font.lua"
  local consolas =
       Font:new{name="consolas",size=12}
	
  consolas:render{
	  x=10,
	  y=10,
	  text="Hello World",
	  color=function(x,y,v)
			return ColorRGBA(x*3, y*4, 255, 255)
	  end,
  }
	
	view = View:new{}
	local w,h = view:getSize()
	print(("Size: <%d,%d>"):format(w,h))
	view:drawBox(5,5,w-5,h-5,
		function(x,y,v)
			return ColorRGBA(
				255, 
				math.floor(x / w * 255),
				math.floor(y / h * 255),
				255
			)
		end
	)
	
	view:drawBox(50,50,100,100,color.blue)

  print"end"
end

local credits, view
function testCredits()
	local Credits = require"Credits.lua"
	credits = Credits:new()
	
	local GD = "Game Developers"
	credits:addCategory{
		name = GD
	}
	
	credits:addLine(GD, "Lead Dev - TheIncgi")
	credits:addLine(GD, "QA - TheIncgi")
	credits:addLine(GD, "GGOS - TheIncgi")
	credits:addLine(GD, "Foo - Bar")
	credits:addLine(GD, "Moo - Cow")
	
	credits:addSong(
	  gdt.ROM.User.AudioSamples[
			"starry-night.mp3"
		], 
	  --3*60+45
		25, --seconds
		10 --% volume
	)
	credits:setDuration()
	
	print"start"
	view = View:new{lbl="credits"}
	yield() --fixes bug where credits play before
	--it shows rendered anything
	credits:start( view )
end
function updateCredits()
	credits:update()
	view:draw()
end

local ggos = require"GGOS.lua"
function setup()
	ggos.setup()
	ggos.run( ggos.homeActivity )
end

local ERR = false
function loop()
	ggos.update()
end

local onErr = function(e) 	
	setFgColor(91)
	print( e )
	setFgColor(31)
	print(debug.traceback()) 
	setFgColor(97)
	ERR = true
end
--xpcall( test, onErr )
--GGOS
xpcall( setup, onErr )
--xpcall( testCredits,onErr )
-- update function is repeated every time tick
function update()
	if ERR then return end
	--xpcall( updateCredits, onErr )
	xpcall( loop, onErr )
end