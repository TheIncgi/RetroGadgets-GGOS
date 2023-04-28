--RenderBuffer
--Extension of view with
--buffers for depth and emission

local cls = require"class.lua"
local class = cls.class
local utils = require"utils.lua"
local View = require"theincgi.View.lua"

local RBuff = class(
	"theincgi.render.RenderBuffer", 
	View
)

local _new = RBuff.new
function RBuff:new( ... )
	local obj = _new( self, ... )
	
	local args = utils.kwargs({
		{parent="class:theincgi.View",nil,"view","buffer"}
	},...)
	
	obj:setParent( args.parent )
	obj.extras = {}
	
	return obj
end

function RBuff:setExtra( 
	x:number,
	y:number,
	ch,
	v
)
	if not self.extras[x] then
		self.extras[x] = {}
	end
	if not self.extras[x][y] then
		self.extras[x][y] = {}
	end
	self.extras[x][y][ch] = v
end

function RBuff:getExtra( 
	x:number,
	y:number, 
	ch ) --optional
	if not self.extras[x]
	or not self.extras[x][y] then
		return nil
	end
	if ch then
		return self.extras[x][y][ch]
	end
	return self.extras[x][y]
end

function RBuff:clear()
  self:super().clear( self )
  self.extras = {}
end

return RBuff