package.path = package.path..";C:\\Users\\theincgi\\Documents\\GitHub\\That-s-No-Moon-\\?.lua" --Mock testing
package.path = package.path..";.\\ggos\\?.lua" --no .lua to allow require with .lua to work, conbined with searcher

----------------------------------------------------
-- Luau loader                                    --
----------------------------------------------------

local function findEndOfString(str, start)
  local startChar = str:sub(start, start)
  local endChar = startChar

  if startChar == "[" then
    -- Long string literal, find closing bracket
    local quoteLevel = #(str:sub(start + 1):match("^=*"))
    local _, stringEnd = str:find("%]" .. ("="):rep(quoteLevel), start + 1)
    if not stringEnd then
      error("Unclosed string at position " .. start)
    end
    return stringEnd + 1
  end

  local i = start + 1
  while i <= #str do
    local char = str:sub(i, i)
    if char == "\\" then
      -- Escape sequence, skip next character
      i = i + 2
    elseif char == endChar then
      -- Matching quote found
      return i + 1
    else
      i = i + 1
    end
  end

  -- No matching quote found
  error("Unclosed string at position " .. start)
end

local function isFunctionCall(src, start)
  return src:sub(start):match"^:[%w_]+[%(%{]"
end


local function luauToLua(src)
  -- initialize some variables
  local i = 1

  while i <= #src do
    local char = src:sub(i, i)

    if char == "\"" or char == "'" or src:sub(i):match"%[=*%[" then
      -- String literal, find end and append
      local stringEnd = findEndOfString(src, i)
      local str = src:sub(i, stringEnd - 1)
      i = stringEnd
    elseif char == ":" and not isFunctionCall(src, i) then
      local typeMatch = src:sub(i):match("^: *[%w_%|]+") or src:sub(i):match("^:{}")
      if typeMatch then
        src = src:sub(1, i - 1) .. src:sub(i + #typeMatch)
        i = i - 1
      else
        i = i + 1
      end
    elseif ("+-/*"):find(char,1,true) and src:sub(i+1,i+1) == "=" then
      local before = src:sub(1,i-1):match"[%w_%.%[%]\"']+$"
      local expanded = ("= %s %s "):format(before, char)
      src = src:sub(1,i-1)..expanded..src:sub(i+2)
      i = i + #expanded
    elseif src:sub(i,i+1)=="--" then
      i = i+2
      if src:sub(i):match"%[=*%[" then
        i = findEndOfString(src, i)
      else
        i = i + #src:sub(i):match"[^\n]+"
      end
    else
      i = i + 1
    end
  end

  return src
end

function luauLoader( src, chunkName )
  local luaSrc = luauToLua( src )
  local loaded, err = load( luaSrc, chunkName )
  if err then
    error("Could not load "..chunkName..":\n"..err)
  end
  return loaded
end


local test = [===[
  local foo:number = 10
  function blarg:blorb(x:number, y:string)
  end
  blorp:blorb(3,"x:y")

  m.view = View:new{
		x=1, y=1,
		width = vChip.Width,
		height = vChip.Height,
		vChip = vChip,
		label = "GGOS-full"
	}

function View:inLocalBounds( viewX: number, viewY: number )
	return
		utils.inRect( viewX, viewY, 1, 1, self:getWidth(), self:getHeight())
end

  local class = {}
  local classMeta = { 
    __index = baseClass,
    __class = className 
  }
  setmetatable( class, classMeta )

  function class:new( ... )
    ...
  end

  function class:class()
    ...
  end
  
  function class:__enableMetaEvents()
    ...
  end

  class.className = function() return classMeta.__class end
  
  function class:super()
    return baseClass
  end

  function class:isA( someClass )
    if not self then error("Self can not be nil", 2) end
    if not cls.isClass(someClass) then error("Argument provided is not a class",2) end
    local current = class
    while current do
      if current == someClass then
        return true
      end
      current = current:super()
    end
    return false
  end

  function class:isInstance()
    return getmetatable( self ).__instance or false
  end

  return class
end
]===]
local r = luauToLua( test )

table.insert(package.loaders, function(moduleName)
  if moduleName:sub(-4) == ".lua" or moduleName:match".luafont$" then
    for i, loader in ipairs(package.loaders) do
      
      local path = "./ggos/"..moduleName
      local f = assert(io.open( path, "r" ))
      if f then
        local sourceCode = f:read"*all"
        f:close()
        return luauLoader( sourceCode, path ), path
      end

    end
    return "no module matching '"..moduleName:sub(1,-5).."'"
  end
end)

----------------------------------------------------
-- global proxies                                 --
----------------------------------------------------
function asUserdata(mock)
  getmetatable(mock.proxy).__type = "userdata"
end
local nativeType = type
type = function(x)
  if nativeType(x)=="table" and getmetatable(x) and getmetatable(x).__type then
      return getmetatable(x).__type
  end
  return nativeType(x)
end

local MockProxy = require"MockProxy"

__RG_MOCK__ = {}
local rgProxy = __RG_MOCK__
rgProxy.CPU0 = MockProxy:new("CPU0",{
  Time = 0
})

rgProxy.gdt = MockProxy:new("gdt",{
    CPU0 = rgProxy.CPU0
})

rgProxy.VideoChip0_setPixel = MockProxy:new("VideoChip0.SetPixel",function() end)
rgProxy.VideoChip0 = MockProxy:new("VideoChip0",{
  Width = 800,
  Height = 500,
  SetPixel = rgProxy.VideoChip0_setPixel.proxy
})
asUserdata( rgProxy.VideoChip0 )
rgProxy.gdt.VideoChip0 = rgProxy.VideoChip0.proxy

gdt = rgProxy.gdt.proxy
setFgColor = function() end
setBgColor = function() end
debug.info = debug.getinfo