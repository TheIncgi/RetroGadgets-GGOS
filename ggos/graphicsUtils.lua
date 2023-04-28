local utils = require"utils.lua"
local linalg = require"linalg.lua"
local mathUtils = require"mathUtils.lua"

local gUtils = {}

--https://en.wikipedia.org/wiki/Xiaolin_Wu%27s_line_algorithm
local function fpart( x )
	return x-math.floor(x)
end
local function rfpart( x )
	return 1 - fpart(x)
end

function gUtils.line(
	x1:number,
	y1:number,
	x2:number,
	y2:number,
	c,
	alias )
	local F = "graphicsUtils.line"
	utils.assertType("number",x1,F,"1(x1)")
	utils.assertType("number",y1,F,"2(y1)")
	utils.assertType("number",x2,F,"3(x2)")
	utils.assertType("number",y2,F,"4(y2)")
	utils.assertType({"vector","function"},c,F,"5(color)")
	if alias then
		gUtils._xwu_line(x1,y1,x2,y2,c)
	else
		if x1==x2 then
			--double invert
			gUtils._bres_line(y1,x1,y2,x2,c, true)
		else
			gUtils._bres_line(x1,y1,x2,y2,c)
		end
	end
end

function gUtils._bres_line(
	x0:number,
	y0:number,
	x1:number,
	y1:number,
	plot,
	flip )
  local dx = x1 - x0
  local dy = y1 - y0
  local D = 2*dy - dx
  local y = y0

  for x=x0,x1 do
    plot(flip and y or x, flip and x or y)
    if D > 0 then
      y = y + 1
      D = D - 2*dx
    end
    D = D + 2*dy
	end
end
function gUtils._xwu_line( 
	x0:number,
	y0:number,
	x1:number,
	y1:number,
	plot )
	local abs   = math.abs
	local round = math.round
	local ipart = math.floor
  local steep = abs(y1 - y0) > abs(x1 - x0)
    
  if steep then
    x0,y0 = y0,x0
    x1,y1 = y1,x1
  end
  if x0 > x1 then
    x0,x1 = x1,x0
    y0,y1 = y1,y0
  end
    
  local dx = x1 - x0
  local dy = y1 - y0
	
	local gradient
  if dx == 0.0 then
    gradient = 1.0
  else
    gradient = dy / dx
  end

  --handle first endpoint
  local xend = round(x0)
  local yend = y0 + gradient * (xend - x0)
  local xgap = rfpart(x0 + 0.5)
  local xpxl1 = xend -- this will be used in the main loop
  local ypxl1 = ipart(yend)
  if steep then
    plot(ypxl1,   xpxl1, rfpart(yend) * xgap)
    plot(ypxl1+1, xpxl1,  fpart(yend) * xgap)
  else
    plot(xpxl1, ypxl1  , rfpart(yend) * xgap)
    plot(xpxl1, ypxl1+1,  fpart(yend) * xgap)
  end
  local intery = yend + gradient -- first y-intersection for the main loop
    
  -- handle second endpoint
  xend = round(x1)
  yend = y1 + gradient * (xend - x1)
  xgap = fpart(x1 + 0.5)
  local xpxl2 = xend --this will be used in the main loop
  local ypxl2 = ipart(yend)
  if steep then
    plot(ypxl2  , xpxl2, rfpart(yend) * xgap)
    plot(ypxl2+1, xpxl2,  fpart(yend) * xgap)
  else
    plot(xpxl2, ypxl2,  rfpart(yend) * xgap)
    plot(xpxl2, ypxl2+1, fpart(yend) * xgap)
  end
    
  -- main loop
  if steep then
    for x=xpxl1 + 1,xpxl2 - 1 do
      plot(ipart(intery)  , x, rfpart(intery))
      plot(ipart(intery)+1, x,  fpart(intery))
      intery = intery + gradient
    end
  else
    for x=xpxl1 + 1, xpxl2 - 1 do
      plot(x, ipart(intery),  rfpart(intery))
      plot(x, ipart(intery)+1, fpart(intery))
      intery = intery + gradient
    end
  end
end

--project vDir onto bounds line
--if the line shrinks return the new 
--vec, otherwise keep old vDir
local function shrinkProj(vStart,vDir, bx1,by1,bx2,by2)
	local vec = linalg.vec
	local mag = linalg.magnitude
	local q = linalg.vecProject(
		vDir,                 --line dir
		vec(bx2-bx1,by2-by1), --bounds Dir
		vStart,               --line start
		vec(bx1,by1)          --bounds start
	)
	
	if mag( q ) < mag( vDir ) then
		return q
	end
	return vDir
end

function gUtils.clipLine( x1, y1, x2, y2, --points
                  bx1,by1,bx2,by2 )--bounds
	inBox = utils.inRect
	local in1 = inBox( x1, y1, bx1,by1, bx2,by2 )
	local in2 = inBox( x2, y2, bx1,by1, bx2,by2 )
	
	local min,max = math.min, math.max
	local vec = linalg.vec
	bx1, bx2 = min(bx1,bx2),max(bx1,bx2)
	by1, by2 = min(by1,by2),max(by1,by2)
	
	local dx, dy = x2-x1, y2-y1
	
	if not in1 then
		local vDir   = vec(-dx, -dy)
		local vStart = vec( x2, y2 )
		if -dx < 0 then -- going left
			vDir = shrinkProj(
				vStart, vDir,
				bx1,by1,bx1,by2
			)
		elseif -dx > 0 then --going right
			vDir = shrinkProj(
				vStart, vDir,
				bx2,by1,bx2,by2
			)
		end
		if -dy < 0 then --screen min (up)
			vDir = shrinkProj(
				vStart, vDir,
				bx1,by1,bx2,by2
			)
		elseif -dy > 0 then --screen max (down)
			vDir = shrinkProj(
				vStart, vDir,
				bx1, by2, bx2, by2
			)
		end
		local q = linalg.addVec(vDir, vStart)
		x1,y1 = q.val[1], q.val[2]
	end
	if not in2 then
		local vDir   = vec( dx, dy )
		local vStart = vec( x1, y1 ) 
		if dx < 0 then --left
			vDir = shrinkProj(
				vStart, vDir,
				bx1, by1, bx1, by2
			)
		elseif dx > 0 then --right	
			vDir = shrinkProj(
				vStart, vDir,
				bx2, by1, bx2, by2
			)
		end
		if dy < 0 then --screen min (up)
			vDir = shrinkProj(
				vStart, vDir,
				bx1, by1, bx2, by1
			)
		elseif dy > 0 then --screen max (down)
			vDir = shrinkProj(
				vStart, vDir,
				bx1, by2, bx2, by2
			)
		end
		local q = linalg.addVec(vDir, vStart)
		x2,y2 = q.val[1], q.val[2]
	end
	
	return x1,y1, x2,y2
end

function gUtils.colorToVec( c:color )
	return
    linalg.vec(c.R/255,c.G/255,c.B/255,c.A/255)
end
function gUtils.vecToColor( v )
	local c = math.clamp
	return ColorRGBA(
		c(v.val[1]*255,0,255),
		c(v.val[2]*255,0,255),
		c(v.val[3]*255,0,255),
		c(v.val[4]*255,0,255)
	)
end

--(bottom, top)
function gUtils.blendAlpha( 
	C1:color,
	C2:color )
	
	local c1={C1.R/255,C1.G/255,C1.B/255,C1.A/255}
	local c2={C2.R/255,C2.G/255,C2.B/255,C2.A/255}
	local out = {}
	local tf = c2[4] --top
	local bf = 1-tf --bottom
	
	out[4] = (1-((1-c2[4])*(1-c1[4])))*255
	
	for i=1,3 do
		c1[i] = (c1[i])^2 --^2 for gamma
		c2[i] = (c2[i])^2 --^2 for gamma
		out[i] = math.sqrt(c2[i]*tf + c1[i]*bf)*255
	end
	
	return ColorRGBA( table.unpack(out) )
end

return gUtils