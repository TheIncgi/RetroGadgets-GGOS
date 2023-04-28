package.path = package.path..";.\\tests\\?.lua"
require"RG_Emulate"

tests = {
  "RasterizerTest"
}

local totalPassed = 0
local totalFailed = 0

for i, testName in ipairs( tests ) do
  local tester = require(testName)
  local results = tester:run()
  print(("="):rep(60))
  print("Test suite: "..testName)
  print(("  %d of %d passed"):format(results.passed, results.total))
  if results.failed > 0 then
    print((" -"):rep(30))
    local wid = 1
    for test in pairs(results.tests) do 
      if not test.passed then
        wid = math.max(wid, #test.name)
      end
    end
    for test in pairs(results.tests) do
      if not test.passed then
        print(("  %-"..wid.."s | %s | %s"):format(test.name, test.passed and "PASS" or "FAIL", test.reason))
      end
    end
  end
  totalPassed = totalPassed + results.passed
  totalFailed = totalFailed + results.failed
end

print("====== All Tests ======")
print(("%8s %4d"):format("TOTAL:",  totalPassed + totalFailed))
print(("%8s %4d"):format("PASSED:", totalPassed              ))
print(("%8s %4d"):format("FAILED:", totalFailed              ))