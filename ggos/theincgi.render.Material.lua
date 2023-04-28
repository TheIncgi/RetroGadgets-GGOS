--Material
local cls = require"class.lua"
local class = cls.class

local Material = class"theincgi.render.Material"

local _new = Material.new
function Material:new( name )
  local obj = _new( self )
  local mtl = require(name..".mtl")

  --[name] = {...}
  obj.materials = mtl

  
  return obj
end

return Material