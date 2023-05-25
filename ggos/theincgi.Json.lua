--TheIncgi's custom Json library
--supports empty arrays and empty tables
local cls = require"class.lua"
local class = cls.class
local isClass = cls.isClass
local utils = require"utils.lua"

local Json = class"common.Json"

Json.static = {}

function Json.static.toString( value )
  if isClass( value ) then
    return value:toString()
  elseif type( value ) == "string" then
    return '"'..value..'"'
  elseif type( value ) == "number" then
    return tostring(value)
  elseif type( value ) == "boolean" then
    return value and "true" or "false"
  else
    error("Unsupported type '"..type(value).."'")
  end
end

function Json.static.fromString( value )
  assert(value,"fromString missing value")
  value = utils.trim(value)
  if value:sub(1,1) =='"' then
    return value:match[["([^"]+)"]]
  elseif value:sub(1,1) == "[" then
    return Json.static.JsonArray:new(value)
  elseif value:sub(1,1) == "{" then
    return Json.static.JsonObject:new(value)
  elseif value == "true" then
    return true
  elseif value == "false" then
    return false
  elseif tonumber( value ) then
    return tonumber( value )
  else
    error("Unexpected value: ->"..value.."<-")
  end
end

function Json.static.readTill( src, char, n )
  for i=n,#src do
    if src:sub(i,i):match(char) then
      return i
    end
  end
  return #src+1
end

--src:sub(start,start) == " 
--returns with quotes
function Json.static.readString( src, start )
  local skipNext = false
  for i=start+1, #src do
    if not skipNext then
      if src:sub(i,i) == "\\" then
        skipNext = true
      elseif src:sub(i,i) == '"' then
        return i, src:sub(start,i)
      end
    else
      skipNext = false
    end
  end
end
--src:sub(start,start) == { or [
function Json.static.readBlock( src, start )
  local blockStart = src:sub(start,start)
  local blockEnd = ({
    ["{"] = "}",
    ["["] = "]"
  })[blockStart]
  local lvl = 1
  for i=start+1, #src do
    if src:sub(i,i):match"[%]%}]" then
      lvl = lvl-1
      if lvl == 0 then
        return i, src:sub( start, i )
      end
    end
    if src:sub(i,i):match"[%[%{]" then
      lvl = lvl+1
    end
  end
  error"End of string reached, malformed json"
end

function Json.static.readValue( src, start )
  local x = src:sub(start,start)
  if x == '"' then
    local n, v = Json.static.readString( src, start )
    return n, v
  elseif x == '{' or x == "[" then
    return Json.static.readBlock( src, start )
  else
    for i=start,#src do
      if src:sub(i,i)==","
      or src:sub(i,i)=="]"
      or src:sub(i,i)=="}" then
        return i-1, src:sub( start, i-1 )
      end
    end
    return #src, utils.trim(src:sub(start))
  end
end

local _new = Json.new
function Json:new( src )
  if self==Json and not src then
    error("Json is abstract, can not call new without source")
  end
  
  if src then
    return Json.static.fromString( src )
  end
  return _new( self )
end

function Json:toString()
  error("not implemented!")
end

function Json:isObject()
  return false
end

function Json:isArray()
  return false
end

--------------------------------------------------------------

local JsonObject = class("common.JsonObject",Json)

local _new = JsonObject.new
function JsonObject:new( src )
  local obj = _new( self )
  obj.values = {}
  if src then
   --print("NEW|"..src)
    local n = 1
    src = utils.trim( src ):sub(2,-2)
    --print("TRIM|"..src)
    while true do
      local key, val = nil, nil
      n, key = Json.static.readString( src, n )
      if not n then break end
      --print("subn|"..tostring(src:sub(n)))
      n = Json.static.readTill(src,":", n+1)+1
      n = Json.static.readTill(src, "[^ ]", n)
      key = key:sub(2,-2)
      n, val = Json.static.readValue( src, n )
      --print(val)
      assert(val,"No val from readVal")
      val = Json.static.fromString( val )
      
      obj.values[key] = val
      n = Json.static.readTill(src, "[,}]", n)+1
      n = Json.static.readTill(src, "[^ ]", n)
      
    end
  end

  return obj
end

function JsonObject:put( key, val )
  self.values[key] = val
end

function JsonObject:get( key, def )
  return self.values[key] or def
end

function JsonObject:toString()
  local out = {}
  for k,v in pairs( self.values ) do
    table.insert( out, ([["%s":%s]]):format(
      k, Json.static.toString( v )
    ))
  end
  return "{"..table.concat( out, "," ).."}"
end

function JsonObject:isObject()
  return true
end

Json.static.JsonObject = JsonObject

--------------------------------------------------------------------------------

local JsonArray = class("common.JsonArray",Json)

local _new = JsonArray.new
function JsonArray:new( src )
  local obj = _new( self )
  obj.values = {}

  if src then
    local n = 1
    local val
    src = utils.trim( src ):sub(2,-2)
    while true do
      n, val = Json.static.readValue( src, n )
      if not val then break end
      assert(val,"No val from readVal")
      val = Json.static.fromString( val )
      --print("val:",val)
      table.insert( obj.values, val )
      n = Json.static.readTill(src, "[,%]]", n+1)+1
      n = Json.static.readTill(src, "[^ ]", n)
    end
  end

  return obj
end

function JsonArray:put( val, index )
  self.values[ index or (#self.values+1) ] = val
end

function JsonArray:get( key, def )
  return self.values[key] or def
end

function JsonArray:toString()
  local out = {}
  for i=1,#self.values do
    table.insert(out, Json.static.toString(self.values[i]))
  end
  return "["..table.concat( out, "," ).."]"
end

function JsonArray:isArray()
  return true
end

Json.static.JsonArray = JsonArray

return Json