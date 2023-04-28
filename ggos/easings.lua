--Author: TheIncgi
--Sourced from: AdvancedMacros Minecraft Mod
local mathUtils = require"mathUtils.lua"

--all easings have args x, a, b
--a defaults 0
--b defaults 1
--x is always 0 to 1
--output is always a to b
--output at x = 0 must be a
--output at x = 1 must be b
--some may have extra args
local easings = {
	easeIn = {},
  easeOut = {},
  demo={}
}

local pi  = math.pi
local cos = math.cos
local sin = math.sin
local pow = math.pow
local abs = math.abs
local sqrt = math.sqrt
local clamp = math.clamp

--all implementations map x=0 to y=0 and x=1 to y=1,
--scaling is wrapped in later

--https://www.desmos.com/calculator/epmaowbdjy
function easings.smoothstep( x )
	local v = x*x*x*(x*(x*6 - 15) + 10)
	return v
end

--https://www.desmos.com/calculator/jlyyg1cxs4
--uses cosine... close enough
function easings.sine( x )
	return (cos(x * pi)/-2+.5)
end

--don't
function easings.linear( x )
	return x --such wow
end

--https://www.desmos.com/calculator/bxd7lrdmgq
function easings.stickSlip( x )
	x = 2 * x / 4.282916228
	local v = cos( pow(x, 2*x*pi+1) / (.1) * pi )
	v = -abs( v ) + 1
	return v
end

--https://www.desmos.com/calculator/5ji0wrk4kp
function easings.bezier( x, i, j )
	local y3 = 
	  i == .5 and x or
	  (i - sqrt(i*i - 2*i*x + x)) / (2*i-1)
	local y1 = x*j             --math.map( x, 0,1, 0, j)
	local y2 = x * (1-j) + j   --math.map( x, 0,1, j, 1)
	local v = (1-x)*y1 + x*y2--wavg(x,y1, y2)
	return v
end

local function gauss() return (math.random()+math.random()+math.random()+math.random()+math.random()+math.random()-math.random()-math.random()-math.random()-math.random()-math.random()-math.random())/12 end
function easings.chaos( x )
  local noiseScale = 5 * (.5-abs(x-.5))
	return gauss() * noiseScale + x
end
function easings.easeIn.chaos( x )
  local noiseScale = 2.5 * (abs(x-1))
	return gauss() * noiseScale + x
end
function easings.easeOut.chaos( x )
  local noiseScale = 2.5 * (abs(x-0))
	return gauss() * noiseScale + x
end

function easings.easeIn.sine( x )
	return 1 - cos((x * pi) / 2)
end
function easings.easeOut.sine( x )
	return sin((x * pi) / 2)
end

local function arc(x,st,en,h)
	return 1 - (1-h) * sin( (x-st)/(en-st)*pi )
end
--https://www.desmos.com/calculator/jxivfnirit
local function easeInBounce( x, b1, b2, b3, p1, p2, p3 )
  --bounce x (p123 in graph)
  b1 = b1 or .402
  b2 = b2 or .665
  b3 = b3 or .853
  --peaks (q123 in graph)
  p1 = p1 or .77
  p2 = p2 or .883
  p3 = p3 or .98

  if x < b1 then
  	return arc( x, -b1, b1, 0 )
  elseif x < b2 then
  	return arc( x, b1, b2, p1 )
  elseif x < b3 then
  	return arc( x, b2, b3, p2 )
  else
  	return arc( x, b3, 1, p3)
  end
end
local function easeOutBounce( x, ... )
	return 1-easings.easeIn.bounce( 1-x, ...)
end
function easings.bounce( x, b1,b2,b3,p1,p2,p3,  b4,b5,b6, p4,p5,p6)
	b4 = b4 or b1
	b5 = b5 or b2
	b6 = b6 or b3
	p4 = p4 or p1
	p5 = p5 or p2
	p6 = p6 or p3
	local M = .268
	if x > 0.5 then
		return easeInBounce( mathUtils.map(x,.5,1,M,1), b1,b2,b3,p1,p2,p3 )
	else
		return easeOutBounce( mathUtils.map(x,0,.5,0,1-M), b4,b5,b6,p4,p5,p6 )
	end
end

easings.easeIn.bounce = easeInBounce
easings.easeOut.bounce = easeOutBounce

--easings.net under here
--already had easings.sine [skip]
function easings.easeIn.cubic( x )
  return x*x*x
end
function easings.easeOut.cubic( x )
	return 1 - pow(1 - x, 3)
end
function easings.cubic( x )
	return x < .5 and (4*x*x*x) or (1-pow(-2*x+2,3)/2)
end

function easings.easeIn.quad( x )
	return x*x
end
function easings.easeOut.quad( x )
	return 1 - (1 - x) * (1 - x)
end
function easings.quad( x )
	return x < .5 and (
		2 * x * x
	) or (
	  1 - pow(-2 * x + 2, 2) / 2
	)
end

function easings.easeIn.quint( x )
	return x*x*x*x*x
end
function easings.easeOut.quint( x )
	return 1 - pow(1-x, 5)
end
function easings.quint( x )
	return x < .5 and (16*x*x*x*x*x) or (1-pow(-2*x+2,5)/2)
end

function easings.easeIn.quart( x )
	return x * x * x * x
end
function easings.easeOut.quart( x )
	return 1 - pow(1 - x, 4)
end
function easings.quart( x )
	return x < .5 and (
		8 * x * x * x * x
	) or (
		1 - pow(-2 * x + 2, 4) / 2
	)
end

function easings.easeIn.expo( x )
	return pow(2, 10 * x - 10)
end
function easings.easeOut.expo( x )
	return 1 - pow(2, -10 * x)
end
function easings.expo( x )
	return x < .5 and (
		pow(2, 20 * x - 10) / 2
	) or (
		(2 - pow(2, -20 * x + 10)) / 2
	)
end

function easings.easeIn.circ( x )
	return 1 - sqrt(1-(x*x))
end
function easings.easeOut.circ( x )
	return sqrt(1 - pow(x-1,2))
end
function easings.circ( x )
	return x < .5 and
	  ((1 - sqrt(1 - pow(2 * x, 2))) / 2) or
	  ((sqrt(1 - pow(-2 * x + 2, 2)) + 1) / 2)
end

function easings.easeIn.back( x )
	local c1 = 1.70158
	local c3 = c1 + 1
	return c3 * x * x * x - c1 * x * x
end
function easings.easeOut.back( x )
  local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
end
function easings.back( x )
	local c1 = 1.70158
	local c2 = c1 * 1.525
	local c3 = c1 + 1
	return x < .5 and (
		(pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
	) or (
		(pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
	)
end

function easings.easeIn.elastic( x )
	local c4 = (2*pi)/3
	return -pow(2, 10 * x - 10) * sin((x * 10 - 10.75) * c4) --x is always (0,1) because of wrapper (not [0,1])
end
function easings.easeOut.elastic( x )
	local c4 = (2*pi)/3
	return pow(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1
end
function easings.elastic( x )
	local c5 = (2 * pi) / 4.5
	return x <.5 and (
		  -(pow(2, 20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2
	  ) or (
	    (pow(2, -20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1
	  )
end

--easings.net bounce uses -= on an arg....

--todo random easings & composite?
------------------------------------------
-- end of easings
------------------------------------------

--make sure it always starts/ends at a/b (no floating point issues where it's .99999 of b or something)
local function wrap( func )
  return function( x, a, b, ... )
	  x = clamp( x, 0, 1 )
		a = a or 0
		b = b or 1

	  if x <= 0 then return a end
	  if 1 <= x then return b end
	  
	  return func( x, ... ) * (b-a) + a
  end
end

for fName,func in pairs(easings) do
	if type(func) == "function" then
	  easings[ fName ] = wrap( func )
	end
end
for fName,func in pairs(easings.easeIn) do
	if type(func) == "function" then
	  easings.easeIn[ fName ] = wrap( func )
	end
end
for fName,func in pairs(easings.easeOut) do
	if type(func) == "function" then
	  easings.easeOut[ fName ] = wrap( func )
	end
end



easings.demo.links = {
	smoothstep = "https://www.desmos.com/calculator/epmaowbdjy",
	       sin = "https://www.desmos.com/calculator/jlyyg1cxs4",
      linear = "https://www.desmos.com/calculator/h5ftdgvsoc",
   stickSlip = "https://www.desmos.com/calculator/bxd7lrdmgq", --made this by accident
      bezier = "https://www.desmos.com/calculator/5ji0wrk4kp",
      bounce = "https://www.desmos.com/calculator/jxivfnirit",
      others = "easings.net"
}


return easings
