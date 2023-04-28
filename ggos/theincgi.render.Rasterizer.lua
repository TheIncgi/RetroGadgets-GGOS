--Rasterizer
local cls = require"class.lua"
local class = cls.class
local utils = require"utils.lua"
local RBuff = 
	require"theincgi.render.RenderBuffer.lua"

local Rasterizer = class"theincgi.render.Rasterizer"

local _new = Rasterizer.new
function Rasterizer:new(...)
	local obj = _new( self )
	
	local args = utils.kwargs({
		{buffer=
			"class:theincgi.render.RenderBuffer"}
	},...)
	
	obj.buffer = args.buffer
	obj.vecs = {}
	obj.screenVec = {}
	obj.itter = false
	obj.USE_DEPTH = true
	
	return obj
end


function Rasterizer:size()
	return self.buffer:getSize()
end
Rasterizer.getSize = Rasterizer.size

function Rasterizer:glToScreen( x, y, z )
	local w, h = self:size()
	return (x/2+.5)*w, (-y/2+.5)*h, z
end

function Rasterizer:screenToGL( x, y )
	local w, h = self:size()
	return (x/w-.5)*2, (y/h-.5)*-2
end

--vertex approch https://en.wikipedia.org/wiki/Barycentric_coordinate_system
function Rasterizer:screenToBary( x, y )
	local a = self.vecs[1]
	local b = self.vecs[2]
	local c = self.vecs[3]
	local x1,x2,x3 = a[1],b[1],c[1]
	local y1,y2,y3 = a[2],b[2],c[2]
	local z1,z2,z3 = a[3],b[3],c[3]
	
	local det = x1 * (y2-y3) + x2 * (y3-y1) +  x3 * (y1-y2)
  --det is 2A
	local f = 1/(det)
	
	if not self.itter.lhs then
		local lhs =  { 
			{ x2*y3  - x3*y2,     y2-y3,     x3-x2 },
			{ x3*y1  - x1*y3,     y3-y1,     x1-x3  },
			{ x1*y2  - x2*y1,     y1-y2,     x2-x1  }
		}
		for r=1,3 do for c=1,3 do
			lhs[r][c] = lhs[r][c] * f
		end end		
		self.itter.lhs = lhs
	end
  local res = {{},{},{}}	
  local v = {{1},{x},{y}}
	for r=1,3 do for c=1,1 do
		for i=1,3 do
			res[r][c] = (res[r][c] or 0) + 
					self.itter.lhs[r][i] * v[i][c]
		end
	end	end 
  return res[1][1], res[2][1], res[3][1]
end

--https://stackoverflow.com/a/2049593
function Rasterizer:sign(p1, p2, p3)
	return (p1[1]-p3[1]) * (p2[2]-p3[2]) -(p2[1] -p3[1]) * (p1[2]-p3[2])
end
--https://stackoverflow.com/a/2049593
function Rasterizer:isInTri( x, y, p1, p2, p3 )
	
	local t = {x,y}
	local d1 = self:sign( t, p1, p2 )
	local d2 = self:sign( t, p2, p3 )
	local d3 = self:sign( t, p3, p1 )
	local hasNeg = math.min(d1,d2,d3) < 0
	local hasPos = math.max(d1,d2,d3) > 0
	return not (hasNeg and hasPos)
end

function Rasterizer:setVecs( vecs )
	self.vecs = vecs
  self.screenVec = {}

	local v= self.vecs
	
	local minX = math.min( v[1][1], v[2][1], v[3][1] )
	local minY = math.min( v[1][2], v[2][2], v[3][2] )
	local maxX = math.max( v[1][1], v[2][1], v[3][1] )
	local maxY = math.max( v[1][2], v[2][2], v[3][2] )
	minX, minY = self:glToScreen( minX, minY )
	maxX, maxY = self:glToScreen( maxX, maxY )
	minX, minY = math.floor( minX ), math.floor( minY )
	maxX, maxY = math.ceil( maxX ), math.floor( maxY )

	minX, maxX = math.min(minX, maxX), math.max(minX, maxX)
	minY, maxY = math.min(minY, maxY), math.max(minY, maxY)
	
  self.screenVec = {}
	for i=1,3 do
		self.screenVec[i] = {self:glToScreen( table.unpack(self.vecs[i]) )}
	end
	
	--can do face culling here if z out of range
	self.itter = {
		x = minX,
		y = minY,
		min = {minX, minY},
		max= {maxX, maxY}
	}
end


function Rasterizer:itterate( onFind )
 -----------------------------
	local a,b,c = table.unpack( self.screenVec )
  
  local x, y = self.itter.x, self.itter.y
  if self:isInTri( x+.5, y+.5, a,b,c ) then
    local bar = {self:screenToBary( self:screenToGL(x,y) )}
		local depth = self.screenVec[1][3] * bar[1] + self.screenVec[2][3] * bar[2] + self.screenVec[3][3] * bar[3]
		local isDepthOk = depth > 0
		local WID, HEI = self:size()
		if 1 <= x and x <= WID 
			and 1 <= y and y <= HEI then

			if isDepthOk and depth >= -1 then
				if self.USE_DEPTH then
					local cdepth = 
						self.buffer:getExtra(x,y,"depth")
						or math.huge
					if cdepth > depth then
						self.buffer:setExtra(
							x,y,"depth",
							depth
						)
					else
						isDepthOk = false
					end
				end
			end

			if isDepthOk then
				onFind( bar, x, y, self.buffer )
			end
		end
  end
  self.itter.x = x+1
  if x > self.itter.max[1] then
    self.itter.x = self.itter.min[1]
    self.itter.y = self.itter.y+1
    if self.itter.y > self.itter.max[2] then
      ITTER = nil
			return false
    end
  end
 	return true --has more to draw
end

return Rasterizer