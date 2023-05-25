-- local JAVA = "C:/Users/TheIncgi/Programs/java/jdk-17.0.2/bin/java.exe"
local JAVA = "C:/Users/theincgi/Software/java/openjdk-18/bin/java.exe"
local LAUNCH_CMD = JAVA ..
" --module-path javafx-sdk-11.0.2/lib --add-modules=javafx.controls -jar LuaWindow-0.0.1-SNAPSHOT.jar %d %d"

local Canvas = {}

function Canvas:new(width, height)
  local obj = {
    width = width,
    height = height,
    channels = 3,
    pixels = {},
    fillColor = { R = 0, G = 0, B = 0 },
    window = false
  }

  for y = 1, obj.height do
    obj.pixels[y] = {}
  end

  self.__index = self
  setmetatable(obj, self)
  return obj
end

function Canvas:setPixel(x,y,color)
  self.pixels[y] = self.pixels[y] or {}
  self.pixels[y][x] = color
end

function Canvas:getPixel(x,y)
  return self.pixels[y][x] or self.fillColor
end

function Canvas:update()
  local out = {}
  for y=1,self.height do
    for x=1,self.width do
      local p = self:getPixel(x,y)
      table.insert(out, string.char(math.max(0,math.min(255,math.floor(p.R)))))
      table.insert(out, string.char(math.max(0,math.min(255,math.floor(p.G)))))
      table.insert(out, string.char(math.max(0,math.min(255,math.floor(p.B)))))
    end
  end
  local DU = require"dataUtils.lua"
  local data = table.concat(out)
  local enc = DU.enc64(data)
  -- local dec = DU.dec64(enc)
  -- print(dec==data)
  if not self.window then
    self.window = io.popen(LAUNCH_CMD:format(self.width, self.height), "w")
    if not self.window then
      print"Coudn't run jar, check JAVA config"
      return
    end
  end
  self.window:write(enc)
  local f = io.open("data.dat","wb")
  f:write(enc)
  f:close()
end

function Canvas:close()
  self.window:close()
end

return Canvas