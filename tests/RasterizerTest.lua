local Tester = require"TestRunner"
local Env = require"MockEnv"
local Proxy = require"MockProxy"

local linalg = require"linalg.lua"
local utils = require"utils.lua"
local Rasterizer = require"Rasterizer.lua"

tester = Tester:new()

-- up pointing, counter clockwise
local points_uneven = {
  {
    _DEBUG="p1",
    pos = linalg.vec(  55,  118, 0 ), --highest
  }, {
    _DEBUG="p2",
    pos = linalg.vec(   5,  19, 0 ),
  },{
    _DEBUG="p3",
    pos = linalg.vec(  105,  9, 0 ), --lowest
  },{
    _DEBUG="p4",
    pos = linalg.vec( 100, 19, 0 ) --right side point with p2's height
  }
}
-- up only, counter clockwise
local points_up = {
  {
    _DEBUG="p1",
    pos = linalg.vec(  10,  15, 0 ), --highest
  },{
    _DEBUG="p2",
    pos = linalg.vec( 5, 5, 0 ), --lowest
  },{
    _DEBUG="p3",
    pos = linalg.vec(  15, 5, 0 ), --lowest
  }
}
-- down only, counter clockwise
local points_down = {
  {
    _DEBUG="p1",
    pos = linalg.vec( 5,  15, 0 ), --highest
  },{
    _DEBUG="p2",
    pos = linalg.vec(  15,  15, 0 ), --highest
  },{
    _DEBUG="p3",
    pos = linalg.vec(  10, 5, 0 ), --lowest
  }
}


----------------------------------------------
-- Test utils                               --
----------------------------------------------
local function tableEquals( p1, p2 )
  return utils.serializeOrdered(p1) == utils.serializeOrdered(p2)
end

----------------------------------------------
-- Verify points sorted by y (desc)         --
----------------------------------------------
do
  -- given
  local rast = Rasterizer:new()
  local results = {}
  local p1, p2, p3 = table.unpack( points_uneven )

  -- test code
  local test = tester:add("shouldSortPoints", Env:new(), function()
    results[1] = {rast:_sortPoints( p1, p2, p3 )}
    results[2] = {rast:_sortPoints( p1, p3, p2 )}
    results[3] = {rast:_sortPoints( p2, p1, p3 )}
    results[4] = {rast:_sortPoints( p2, p3, p1 )}
    results[5] = {rast:_sortPoints( p3, p2, p1 )}
    results[6] = {rast:_sortPoints( p3, p1, p2 )}
  end)

  -- expects
  for i=1, 6 do
    test:var_eq(function()
      return results[i][1]._DEBUG
    end, "p1", "expected point `p3`, got point `$1` on result set "..i)
    test:var_eq(function()
      return results[i][2]._DEBUG
    end, "p2", "expected point `p1`, got point `$1` on result set "..i)
    test:var_eq(function()
      return results[i][3]._DEBUG
    end, "p3", "expected point `p2`, got point `$1` on result set "..i)
  end
end

----------------------------------------------
-- Draws bottom triangle only               --
----------------------------------------------
do
  -- given
  local rast = Rasterizer:new()
  local bottom = Proxy:new("doBottomTriangle", function() end)
  local top    = Proxy:new("doTopTriangle", function() end)
  local pixel  = Proxy:new("onPixel", function() end)

  rast.doBottomTriangle = bottom.proxy
  rast.doTopTriangle    = top.proxy
  local p1, p2, p3 = table.unpack( points_down )
  bottom{ rast, p1, p2, p3, pixel }.exact()
  
  -- test code
  local test = tester:add("shouldOnlyCall_doBottomTriangle", Env:new(), function()
    rast:doTriangle( p1, p2, p3, pixel )
  end)

  -- expects 
  test:var_eq(function()
    return bottom.records.totalCalls
  end, 1, "Expected exactly one call to `doBottomTriangle`, called $1 times")
  test:var_eq(function()
    return top.records.totalCalls
  end, 0, "Expected exactly zero calls to `doBottomTriangle`, called $1 times")
end

----------------------------------------------
-- Draws top triangle only               --
----------------------------------------------
do
  -- given
  local rast = Rasterizer:new()
  local bottom = Proxy:new("doBottomTriangle", function() end)
  local top    = Proxy:new("doTopTriangle", function() end)
  local pixel  = Proxy:new("onPixel", function() end)

  rast.doBottomTriangle = bottom.proxy
  rast.doTopTriangle    = top.proxy
  local p1, p2, p3 = table.unpack( points_up )
  top{ rast, p1, p2, p3, pixel }.exact()
  
  -- test code
  local test = tester:add("shouldOnlyCall_doTopTriangle", Env:new(), function()
    rast:doTriangle( p1, p2, p3, pixel )
  end)

  -- expects 
  test:var_eq(function()
    return bottom.records.totalCalls
  end, 0, "Expected exactly one call to `doBottomTriangle`, called $1 times")
  test:var_eq(function()
    return top.records.totalCalls
  end, 1, "Expected exactly zero calls to `doBottomTriangle`, called $1 times")
end

----------------------------------------------
-- Draws multipart triangle                 --
----------------------------------------------
do
  -- given
  local rast = Rasterizer:new()
  local bottom = Proxy:new("doBottomTriangle", function() end)
  local top    = Proxy:new("doTopTriangle", function() end)
  local pixel  = Proxy:new("onPixel", function() end)

  rast.doBottomTriangle = bottom.proxy
  rast.doTopTriangle    = top.proxy
  local p1, p2, p3, p4 = table.unpack( points_uneven )
  local eq = Proxy.static.eq
  local p4Match = function( value )
    return type(value)=="table" and linalg.isVec(value.pos) and linalg.magnitude( linalg.subVec(p4.pos, value.pos) ) < .01 --fix p4
  end
  top{    eq(rast), eq(p1),  eq(p2), p4Match, eq(pixel) }.matched()
  bottom{ eq(rast), eq(p2), p4Match,  eq(p3), eq(pixel) }.matched()
  
  -- test code
  local test = tester:add("shouldCallTopAndBottomTriangle", Env:new(), function()
    rast:doTriangle( p1, p2, p3, pixel )
  end)

  -- expects 
  test:var_eq(function()
    return bottom.records.totalCalls
  end, 1, "Expected exactly one call to `doBottomTriangle`, called $1 times")
  test:var_eq(function()
    return top.records.totalCalls
  end, 1, "Expected exactly zero calls to `doBottomTriangle`, called $1 times")
end

----------------------------------------------
-- Hits correct pixels for top triangle     --
----------------------------------------------
do
  -- given
  local rast = Rasterizer:new()
  local onPixel  = Proxy:new("onPixel", function() end)

  local p1, p2, p3 = table.unpack( points_uneven )
  local eq = Proxy.static.eq
  local pixelMatch = function( x, y, z )
    return function( ibundle )
      return x == ibundle.pos.val[1]
         and y == ibundle.pos.val[2]
         and z == ibundle.pos.val[3]
    end
  end
  --used blender to help with point selection
  --expected pixels
  onPixel{ 20,  31, 0 }.exact()
  onPixel{ 55, 111, 0 }.exact()
  onPixel{ 95,  21, 0 }.exact()
  --unexpected pixels
  onPixel{  7,  30, 0 }.exactNever()
  onPixel{ 48, 110, 0 }.exactNever()
  onPixel{ 60, 112, 0 }.exactNever()
  onPixel{ 97,  31, 0 }.exactNever()
  onPixel{ 73,  17, 0 }.exactNever()
  
  -- test code
  local test = tester:add("shouldDrawCorrectPixels", Env:new(), function()
    rast:doTopTriangle( p1, p2, p3, onPixel )
  end)
  
end

return tester