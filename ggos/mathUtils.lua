local mathUtils = {}

--map(x, iMin, iMax, oMin, oMax)
--maps x from input range to output range
function mathUtils.map(x, iMin, iMax, oMin, oMax)
  return (x - iMin) * (oMax - oMin) / (iMax - iMin) + oMin
end

return mathUtils