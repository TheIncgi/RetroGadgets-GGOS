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
    pos = linalg.vec( -0.5, -0.5, 0 ),
  },{
    _DEBUG="p2",
    pos = linalg.vec(  0.5, -0.6, 0 ), --lowest
  },{
    _DEBUG="p3",
    pos = linalg.vec(  0.0,  0.5, 0 ), --highest
  }
}
-- up only, counter clockwise
local points_uneven = {
  {
    _DEBUG="p1",
    pos = linalg.vec( -0.5, -0.5, 0 ), --lowest
  },{
    _DEBUG="p2",
    pos = linalg.vec(  0.5, -0.5, 0 ), --lowest
  },{
    _DEBUG="p3",
    pos = linalg.vec(  0.0,  0.5, 0 ), --highest
  }
}
-- down only, counter clockwise
local points_uneven = {
  {
    _DEBUG="p1",
    pos = linalg.vec( -0.5,  0.5, 0 ), --highest
  },{
    _DEBUG="p2",
    pos = linalg.vec(  0.5,  0.5, 0 ), --highest
  },{
    _DEBUG="p3",
    pos = linalg.vec(  0.0, -0.5, 0 ), --lowest
  }
}

local rast = Rasterizer:new()

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
    end, "p3", "expected point `p3`, got point `$1` on result set "..i)
    test:var_eq(function()
      return results[i][2]._DEBUG
    end, "p1", "expected point `p1`, got point `$1` on result set "..i)
    test:var_eq(function()
      return results[i][3]._DEBUG
    end, "p2", "expected point `p2`, got point `$1` on result set "..i)
  end
end

return tester