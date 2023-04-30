local mathUtils = {}

--map(x, iMin, iMax, oMin, oMax)
--maps x from input range to output range
function mathUtils.map(x, iMin, iMax, oMin, oMax)
  if oMin == oMax then return oMin end
  if iMin == iMax then return oMin end
  return (x - iMin) * (oMax - oMin) / (iMax - iMin) + oMin
end

return mathUtils