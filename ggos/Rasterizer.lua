--Improved rasterizer with suggested use
--of bres
--Points should be passed in as
--{
--  pos = vec,
--  uv  = vec,
--  norm = vec,
--  ...
--}
--all passed vectors are interpolated

local cls = require"class.lua"
local class = cls.class
local utils = require"utils.lua"
local linalg = require"linalg.lua"
local mathUtils = require"mathUtils.lua"

local Rast = class"Rasterizer"

local _new = Rast.new
function Rast:new( ... )
  local obj = _new( self )

  -- local args = utils.kwargs({
  --   {buffer = "class:theincgi.render.RenderBuffer",nil,"view","buf"},
  -- },...)  
	-- obj.buffer = args.buffer
	
  return obj
end

function Rast:_sortPoints( p1, p2, p3 )
	if p1.pos.val[2] < p2.pos.val[2] then
    p1, p2 = p2, p1
  end
  if p2.pos.val[2] < p3.pos.val[2] then
    p2, p3 = p3, p2
  end
  if p1.pos.val[2] < p2.pos.val[2] then
    p1, p2 = p2, p1
  end
  return p1, p2, p3 --descending order
end

function Rast:doTriangle( p1, p2, p3, onPixel )
	p1, p2, p3 = self:_sortPoints( p1, p2, p3 )
	if p2.pos.val[2] == p3.pos.val[2] then
	  self:doTopTriangle( p1, p2, p3, onPixel )
	elseif p1.pos.val[2] == p2.pos.val[2] then
	  self:doBottomTriangle( p1, p2, p3, onPixel )
	else
	  --similar triangles, solves for x offset from point 1 (top)
		local p4 = {
      pos = linalg.vec(
					math.floor(
						p1.pos.val[1] + (	(p2.pos.val[2] - p1.pos.val[2])/(p3.pos.val[2] - p1.pos.val[2])) * (p3.pos.val[1] - p1.pos.val[1]) + .5
					), 
					p2.pos.val[2],
					math.floor(
						p1.pos.val[3] + (	(p2.pos.val[2] - p1.pos.val[2])/(p3.pos.val[2] - p1.pos.val[2])) * (p3.pos.val[3] - p1.pos.val[3]) +.5
					)
    		)
  	} --end p4	
		
  	local f = mathUtils.map( p4.pos.val[2], p1.pos.val[2], p3.pos.val[2], 0, 1 )
  	for k,vals in pairs( p1 ) do
   	 if k ~= "pos" then --uv, norm, color, ...
				if linalg.isVec(p4[k]) or type(p4[k]) == "number" then
    	  	p4[k] = linalg.interpolate( f, p1[k], p3[k] )
				end
    	end
  	end
		self:doTopTriangle( p1, p2, p4, onPixel )
		self:doBottomTriangle( p2, p4, p3, onPixel )
	end
end

function Rast:_interpolateBundle( f, a, b, x, y, z )
  local q = {}
  for k,vals in pairs( a ) do
    if k ~= "pos" then --uv, norm, color, ...
      q[k] = linalg.interpolate( f, a[k], b[k] )
    end
  end
  if x then
    q.pos = linalg.vec(x,y,z)
  end
end

function Rast:_scanLine( y, pLeft, pRight, onPixel )
	utils.assertType("number", y, ":_scanLine", "y [arg 1])",2)
	utils.assertType("table", pLeft, ":_scanLine", "pLeft [arg 2]", 2)
	utils.assertType("table", pRight, ":_scanLine", "pRight [arg 3]", 3)
	utils.assertType("function", onPixel, ":_scanLine", "onPixel [arg 4]", 4)

	  for x=pLeft.pos.val[1], pRight.pos.val[1] do
    onPixel( 
			-- x, y, --screen space
			-- mathUtils.map( x, x1, x2, z1, z2 ), --screen space depth
      self:_interpolatedBundle( 
        (x-pLeft.pos.val[1]) / (pRight.pos.val[1]-pLeft.pos.val[1]),
        pLeft,
        pRight,
        x, y, mathUtils.map( x, pLeft.pos.val[1], pRight.pos.val[1], pLeft.pos.val[3], pRight.pos.val[3] )
      ) --interpolated vertex info, pos is still in screen space!
		)
  end
end
function Rast:doTopTriangle( p1, p2, p3, onPixel )
	--dx/dy pt 1 & 2
	local is1 = (p2.pos.val[1]-p1.pos.val[1])/(p2.pos.val[2]-p1.pos.val[2])
	--dx/dy pt 1 & 3
	local is2 = (p3.pos.val[1]-p1.pos.val[1])/(p3.pos.val[2]-p1.pos.val[2])
	
	local x1 = p1.pos.val[1]
	local x2 = x1
	
	for y = p1.pos.val[2], p2.pos.val[2] do
	  self:_scanLine(
			y,
      --pLeft ( y-start ) / (end - start)
      Rast:_interpolateBundle( 
				(y-p1.pos.val[2]) / (p2.pos.val[2] - p1.pos.val[2] ), 
				p1, 
				p2, 
				math.floor(x1), 
				y, 
				mathUtils.map( --z1
        	y,
        	p1.pos.val[2],
        	p2.pos.val[2],
        	p1.pos.val[3],
        	p3.pos.val[3]
      	) 
			),
      --pRight
      Rast:_interpolateBundle( 
				(y-p1.pos.val[2]) / (p2.pos.val[2] - p1.pos.val[2] ), 
				p1, 
				p3, 
				math.floor(x2), 
				y, 
				mathUtils.map( --z2
    	    y,
     	   p1.pos.val[2],
      	  p3.pos.val[2],
       	 p1.pos.val[3],
        	p3.pos.val[3]
      	) 
			),
			onPixel
	  )
	  --step x1 and x2
	  x1,x2 = x1+is1, x2+is2
	end
end


function Rast:doBottomTriangle( p1, p2, p3, onPixel )
  --inverted slope points 3 and 1
	local is1 =
	  (p3.pos.val[1]-p1.pos.val[1])/(p3.pos.val[2]-p1.pos.val[2])
	--inverted slope points 3 and 2
	local is2 = 
	  (p3.pos.val[1]-p2.pos.val[1])/(p3.pos.val[2]-p2.pos.val[2])
	
	local x1 = p3.pos.val[1]
	local x2 = x1
	
	for y = p3.pos.val[2], p1.pos.val[2]+1, -1 do
	  self:_scanLine( --x1,x2,y,z1,z1,pixl
			y,
      --pLeft
      linalg.interpolate( (y-p3.pos.val[2]) / (p1.pos.val[2] - p3.pos.val[2]), p3, p1 ),
      --pRight
      linalg.interpolate( (y-p3.pos.val[2]) / (p1.pos.val[2] - p3.pos.val[2]), p3, p2 ),
			onPixel
	  )
		--step x
		x1,x2 = x1-is1, x2-is2
	end
end

return Rast