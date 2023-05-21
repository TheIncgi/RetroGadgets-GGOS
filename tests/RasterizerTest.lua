local Tester = require"TestRunner"
local Env = require"MockEnv"

local matchers = require"MockProxy".static
local eq = matchers.eq
local any = matchers.any

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
    pos = linalg.vec( 50,  150, 0 ), --highest
  },{
    _DEBUG="p2",
    pos = linalg.vec(  150,  150, 0 ), --highest
  },{
    _DEBUG="p3",
    pos = linalg.vec(  100, 50, 0 ), --lowest
  }
}
-- multipart, left pointing
local points_left = {
  {
    _DEBUG="p1",
    pos = linalg.vec( 130, 167, 0 ), --highest
  },{
    _DEBUG="p2",
    pos = linalg.vec(   8,  85, 0 ), --mid
  },{
    _DEBUG="p3",
    pos = linalg.vec(  129, 11, 0 ), --lowest
  }
}

-- multipart, left pointing, with extra
local points_left_extra = {
  {
    _DEBUG="p1",
    pos = linalg.vec( 130, 167, 0 ), --highest
    vertex = linalg.vec( 1, 0, 0)
  },{
    _DEBUG="p2",
    pos = linalg.vec(   8,  85, 0 ), --mid
    vertex = linalg.vec( 0, 1, 0)
  },{
    _DEBUG="p3",
    pos = linalg.vec(  129, 11, 0 ), --lowest
    vertex = linalg.vec( 0, 0, 1)
  }
}

-- multipart left side lower with extra
local points_left_extra_2 = {
  {
    _DEBUG="p1",
    pos = linalg.vec(  144, 120, 0 ), --highest
    bar = linalg.vec( 0, 0, 1) --blue vertex
  },{
    _DEBUG="p2",
    pos = linalg.vec( 172,  63, 0 ), --mid
    bar = linalg.vec( 0, 1, 0) --green vertex
  },{
    _DEBUG="p3",
    pos = linalg.vec(  87, 38, 0 ), --lowest
    bar = linalg.vec( 1, 0, 0) --red vertex
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
  local env = Env:new()
  local results = {}
  local p1, p2, p3 = table.unpack( points_uneven )

  -- test code
  local test = tester:add("Sort points", env, function()
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
  local env = Env:new()
  local bottom = env:proxy("doBottomTriangle", function() end)
  local top    = env:proxy("doTopTriangle", function() end)
  local pixel  = env:proxy("onPixel", function() end)

  rast.doBottomTriangle = bottom.proxy
  rast.doTopTriangle    = top.proxy
  local p1, p2, p3 = table.unpack( points_down )
  bottom{ rast, p1, p2, p3, pixel }.exact()
  
  -- test code
  local test = tester:add("Only call doBottomTriangle", env, function()
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
  local env = Env:new()
  local bottom = env:proxy("doBottomTriangle", function() end)
  local top    = env:proxy("doTopTriangle", function() end)
  local pixel  = env:proxy("onPixel", function() end)

  rast.doBottomTriangle = bottom.proxy
  rast.doTopTriangle    = top.proxy
  local p1, p2, p3 = table.unpack( points_up )
  top{ rast, p1, p2, p3, pixel }.exact()
  
  -- test code
  local test = tester:add("Only call doTopTriangle", env, function()
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
  local env = Env:new()
  local bottom = env:proxy("doBottomTriangle", function() end)
  local top    = env:proxy("doTopTriangle", function() end)
  local pixel  = env:proxy("onPixel", function() end)

  rast.doBottomTriangle = bottom.proxy
  rast.doTopTriangle    = top.proxy
  local p1, p2, p3, p4 = table.unpack( points_uneven )
  local p4Match = function( value )
    return type(value)=="table" and linalg.isVec(value.pos) and linalg.magnitude( linalg.subVec(p4.pos, value.pos) ) < .01 --fix p4
  end
  top{    eq(rast), eq(p1),  eq(p2), p4Match, eq(pixel) }.matched()
  bottom{ eq(rast), eq(p2), p4Match,  eq(p3), eq(pixel) }.matched()
  
  -- test code
  local test = tester:add("Draws top & bottom triangle", env, function()
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
  local env = Env:new()
  local onPixel  = env:proxy("onPixel", function() end)

  local p1, p2, p3, p4 = table.unpack( points_uneven )
  local pixelMatch = function( x, y, z )
    return function( ibundle )
      return x == ibundle.pos.val[1]
         and y == ibundle.pos.val[2]
         and z == ibundle.pos.val[3]
    end
  end
  --used blender to help with point selection
  --expected pixels
  onPixel{ pixelMatch(20,  31, 0) }.matched()
  onPixel{ pixelMatch(55, 111, 0) }.matched()
  onPixel{ pixelMatch(95,  21, 0) }.matched()
  onPixel{ pixelMatch(53,  19, 0) }.matched()
  
  --unexpected pixels
  onPixel{ pixelMatch( 7,  30, 0) }.matchedNever()
  onPixel{ pixelMatch(48, 110, 0) }.matchedNever()
  onPixel{ pixelMatch(60, 112, 0) }.matchedNever()
  onPixel{ pixelMatch(97,  31, 0) }.matchedNever()
  onPixel{ pixelMatch(73,  17, 0) }.matchedNever()
  
  --default
  onPixel{ any() }.always()

  -- test code
  local test = tester:add("Draws correct pixels - Top", env, function()
    rast:doTopTriangle( p1, p2, p4, onPixel.proxy )
  end)
  
end

----------------------------------------------
-- Hits correct pixels for bottom triangle  --
----------------------------------------------
do
  -- given
  local rast = Rasterizer:new()
  local env = Env:new()
  local onPixel  = env:proxy("onPixel", function() end)

  local p1, p2, p3 = table.unpack( points_down )
  local pixelMatch = function( x, y, z )
    return function( ibundle )
      return x == ibundle.pos.val[1]
         and y == ibundle.pos.val[2]
         and z == ibundle.pos.val[3]
    end
  end
  --used blender to help with point selection
  --expected pixels
  onPixel{ pixelMatch( 51, 149, 0) }.matched()
  onPixel{ pixelMatch(150, 150, 0) }.matched()
  onPixel{ pixelMatch(149, 149, 0) }.matched()
  onPixel{ pixelMatch(100,  50, 0) }.matched()
  onPixel{ pixelMatch( 83, 115, 0) }.matched()
  onPixel{ pixelMatch(128, 137, 0) }.matched()
  
  --unexpected pixels
  onPixel{ pixelMatch(  58, 151, 0) }.matchedNever()
  onPixel{ pixelMatch(  52, 144, 0) }.matchedNever()
  onPixel{ pixelMatch( 148, 144, 0) }.matchedNever()
  onPixel{ pixelMatch( 103, 54, 0) }.matchedNever()
  onPixel{ pixelMatch( 98,  52, 0) }.matchedNever()
  
  --default
  onPixel{ any() }.always()

  -- test code
  local test = tester:add("Draws correct pixels - Bottom", env, function()
    rast:doBottomTriangle( p1, p2, p3, onPixel.proxy )
  end)
  
end

----------------------------------------------
-- Doesn't double draw                      --
----------------------------------------------
do
  -- given
  local rast = Rasterizer:new()
  local env = Env:new()
  local onPixel  = env:proxy("onPixel", function() end)

  local p1, p2, p3 = table.unpack( points_left )
  local pixelMatch = function( x, y, z )
    return function( ibundle )
      return x == ibundle.pos.val[1]
         and y == ibundle.pos.val[2]
         and z == ibundle.pos.val[3]
    end
  end
  --used blender to help with point selection
  --expected single call pixels
  local topPoint    = onPixel{ pixelMatch( 51, 149, 0) }.matched()
  local midPoint    = onPixel{ pixelMatch( 70,  85, 0) }.matched()
  local bottomPoint = onPixel{ pixelMatch( 96,  64, 0) }.matched()
  
  
  --default
  onPixel{ any() }.always()

  -- test code
  local test = tester:add("Draw correct pixels - Top & Bottom", env, function()
    rast:doBottomTriangle( p1, p2, p3, onPixel.proxy )
  end)

  -- expects
  test:var_eq(function()
    return topPoint.hits
  end, 1, "top test pixel called $1 times instead of once")
  test:var_eq(function()
    return midPoint.hits
  end, 1, "middle test pixel called $1 times instead of once")
  test:var_eq(function()
    return bottomPoint.hits
  end, 1, "bottom test pixel called $1 times instead of once")
end

----------------------------------------------
-- Interpolates extras                      --
----------------------------------------------
do
  --given
  local rast = Rasterizer:new()
  local env = Env:new()
  local onPixel = env:proxy("onPixel", function() end)

  local p1, p2, p3 = table.unpack( points_left_extra )
  onPixel(any()):always() --don't care about details

  --test code
  local test = tester:add("Interpolates extras", env, function()
    rast:doTriangle(p1, p2, p3, onPixel.proxy)
  end)

  test:var_isTrue(function()
    for i, callArgs in ipairs(onPixel.records.call) do
      if not callArgs[1].vertex then
        --string is not true, counts as failure
        return "onPixel call #"..i.." of "..#onPixel.records.call.." "..utils.serializeOrdered(callArgs[1]).." does not contain the vertex attribute"
      end
      if callArgs[1].vertex.val[1] ~= callArgs[1].vertex.val[1] then
        return "onPixel call #"..i.." of "..#onPixel.records.call.." "..utils.serializeOrdered(callArgs[1]).." contains a vertex with NaN"
      end
    end
    return true
  end, "$1" )
end

----------------------------------------------------------------
-- Interpolates extras Correctly for left side lower triangle --
----------------------------------------------------------------
do
  --given
  local rast = Rasterizer:new()
  local env = Env:new()
  local onPixel = env:proxy("onPixel",function() end)

  local p1, p2, p3 = table.unpack( points_left_extra_2 )
  onPixel(any()):always() --don't care

  --test code
  local test = tester:add("Interpolates extras correctly", env, function()
    rast:doTriangle(p1, p2, p3, onPixel.proxy)
  end)

  
  --helper
  local function dist(bar, r,g,b)
    local br, bg, bb = table.unpack(bar.val)
    local dr, dg, db = r-br, g-bg, b-bb
    return math.sqrt( dr*dr + dg*dg + db*db )
  end
  --checks
  test:var_isTrue(function()
    local TEST_X, TEST_Y = 105, 63
    for i, callArgs in ipairs(onPixel.records.call) do
      if not callArgs[1].bar then
        --string is not true, counts as failure
        return "onPixel call #"..i.." of "..#onPixel.records.call.." "..utils.serializeOrdered(callArgs[1]).." does not contain the bar attribute"
      end

      local point = callArgs[1]
      local px, py = point.pos.val[1], point.pos.val[2]

      if point.bar.val[1] < 0
      or point.bar.val[2] < 0
      or point.bar.val[3] < 0 then
        return ("onPixel call at {%d, %d} has a bar value of {%.3f, %.3f, %.3f}, No values should be < 0"):format(
          TEST_X, TEST_Y, 
          point.bar.val[1],point.bar.val[2],point.bar.val[3]
        )
      end

      if px == TEST_X and py == TEST_Y then
        local d = dist( point.bar, 0,1,0 )
        if d > .7 then
          return ("onPixel call at {%d, %d} has a bar value of {%.3f, %.3f, %.3f}, expected proximity to {0,1,0} to be low, actual distance %.3f"):format(
            TEST_X, TEST_Y, 
            point.bar.val[1],point.bar.val[2],point.bar.val[3],
            d
          )
        end
        return true
      end
    end
    return ("onPixel not called for pixel {%d, %d}"):format(TEST_X, TEST_Y)
  end, "$1")
end

return tester