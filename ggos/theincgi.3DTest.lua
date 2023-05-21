local cls = require"class.lua"
local class = cls.class
local Font = require"theincgi.Font.lua"
local GUI = require"theincgi.GUI.lua"
local View = require"theincgi.View.lua"
local utils = require"utils.lua"
local cprint    = utils.cprint
local ansiColor = utils.ansiColor
local retroUtils = require"retroUtils.lua"

-- Render code --------------------------------
local linalg = require"linalg.lua"
local vec = linalg.vec
local mat = linalg.mat
print"obj"
local Object =
           require"theincgi.render.Object.lua"
local RBuff =
     require"theincgi.render.RenderBuffer.lua"
local Rast =
     --require"theincgi.render.Rasterizer.lua"
		require"Rasterizer.lua"
local Cam = require"theincgi.render.Camera.lua"
local cam
local objs = {}
local env = {}

local buffer, rast

local function loadObjects()
  cprint(ansiColor.yellow,"Making Objects")
  local cube = Object:new"cube"
  
  objs[1] = cube
  objs[1].yaw = 45
  objs[1].pitch = 45
end

local function setupEnv( view )
  cprint(ansiColor.yellow,"Env Setup")
  buffer = RBuff:new{ parent=view, lbl="3D-Test-Buffer" }
  rast = Rast:new()
	
	cam = Cam:new(.2,0,4.3)
	local w,h = retroUtils.screenSize()
	--int("SIZE",w,h) sleep(1)
	cam:setFov( 75, w, h )

  env.lightPos = vec(0,100,30)
  env.transform =
		linalg.identity(linalg.newMatrix(4,4))
	
	-- env.mode = "bary"
	env.mode = "tex"
	

end

local function renderObjects( view )
  cprint(ansiColor.yellow,"Render Objects...")
  buffer:clear()
  env.projection,	env.view = cam:createMatrix()
	env.invProjection = linalg.inverseMat( env.projection )
	for i,obj in ipairs(objs) do
	  cprint(ansiColor.yellow,i.." of "..#objs)
	  obj:render( env, rast, buffer )
  end
  cprint(ansiColor.yellow,"Render finished")
end

-- Activity logic -----------------------------

local Activity =
        require"theincgi.Activity.lua"
local GTest = 
        class("theincgi.3DTest",Activity)

local _new = GTest.new
function GTest:new( ... )
	local obj = _new( self, ... )
	
	return obj
end

function GTest:onInit()
  self:super().onInit( self )
  loadObjects()
  setupEnv( self.view )
end

function GTest:onFocus()
  local w,h = self.view:getSize()
  --buffer:drawLine(1,1,w,h,color.red)
	renderObjects( self.view )
	self:super().onFocus( self )
end

function GTest:onUnfocus()
	self:super().onUnfocus( self )
end

function GTest:onUpdate()
  self:super().onUpdate( self )
	
	local inputs = retroUtils.inputs()
	local redraw = false
	local dx, dy, dz = 0, 0, 0
	if inputs.dpad.down.buttonDown then
	  dy=-.1
	  redraw = true
	end
	if inputs.dpad.left.buttonDown then
	  dx = -.1
	  redraw = true
  end
  if inputs.dpad.up.buttonDown then
    dy = .1
	  redraw = true
  end
  if inputs.dpad.right.buttonDown then
    dx = .1
	  redraw = true
  end
  if inputs.button["1"].ButtonDown then
    dz = -.1
	  redraw = true
  end
  if inputs.button["2"].ButtonDown then
    dz = .1
	  redraw = true
  end
  if inputs.button.select.ButtonDown then
    env.mode = ({
      bary="tex",
      tex ="bary"
    })[env.mode]
	  redraw = true
  end
  local cube = objs[1]
  cube.yaw += inputs.axis.leftAnalog.X/50
  cube.pitch += inputs.axis.leftAnalog.Y/50
  
  if redraw or inputs.axis.leftAnalog.X ~= 0 or
inputs.axis.leftAnalog.Y ~= 0 then
    cam.x += dx
    cam.y += dy
    cam.z += dz
    print( ("Cam: <%.3f,%.3f,%.3f>"):format(cam.x, cam.y, cam.z))
    renderObjects( self.view )
  end

end

function GTest:getTitle()
	local _,defaultFont = self:super().getTitle(self)
	return "3D-Test", {
		name="orbitron",
		size=12,
		italics=false,
		color=color.blue
	}
end

return GTest