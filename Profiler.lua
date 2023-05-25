local Json = require"theincgi.Json.lua"
local JsonObject = Json.static.JsonObject
local JsonArray = Json.static.JsonArray

local Profiler = {}

local Timer = {}

function Timer:new()
  local obj = {startTime = false, total = 0}
  setmetatable(obj,Timer)
  Timer.__index = self
  return obj
end

function Timer:start()
  self.startTime = self.startTime or os.clock()
end

function Timer:stop()
  if self.startTime then
    self.total = self.total + os.clock() - self.startTime
    self.startTime = false
  end
end

function Timer:getTime()
  return self.total
end

local function wrap(self, func)
  return function(...)
    func(self, ...)
  end
end

function Profiler:new()
  local obj = {
    stack = {
      --main
      subCalls = {}
    },
    totalTime = Timer:new(),
    nativeHook = false,
    window = false,
    _n = 0
  }
  obj.stackTop = obj.stack

  Profiler.__index = self
  setmetatable(obj,Profiler)
  return obj
end

function Profiler:onHook(event)
  local info = debug.getinfo(3,"nS")
  local file = info.short_src or "[?]"
  local func = info.name or "[?]"
  local line = info.linedefined or 0

  file = file:gsub("\\","/"):gsub('"','\\"')

  local thisKey = file..":"..func..":"..line

  if event:find"call" and file~="[C]" then
    local call = self.stackTop.subCalls[thisKey] or {
      calls = 0,
      cpuTime = Timer:new(),
      stackTime = Timer:new(),
      subCalls = {},
      file = file,
      func = func,
      line = line
    }
    call.cpuTime:start()
    call.stackTime:start()
    call.calls = call.calls + 1

    if self.stackTop then --old top
      call.returnTo  = self.stackTop
      if self.stackTop.cpuTime then
        self.stackTop.cpuTime:stop()
      end
    end

    self.stackTop.subCalls[thisKey] = call
    self.stackTop = call or self.stack

  elseif event == "return" then
    local call = self.stackTop
    if call and call.cpuTime then
      call.cpuTime:stop()
    end
    if call and call.stackTime then
      call.stackTime:stop()
    end
    
    self.stackTop = call and call.returnTo or self.stack
    call = self.stackTop
    if call and call.cpuTime then
      call.cpuTime:start()
    end
  end

  self._n = self._n + 1
  -- if self._n == 10000 then
  --   print(self:toJson():toString())
  -- end

  if self.nativeHook then
    local f, mask, count = table.unpack(self.nativeHook)
    if (mask:find"c" and event:find"call") or
       (mask:find"r" and event=="return") or
       (mask:find"l" and event=="line") then
        f(event)
    end
  end
end

function Profiler:start()
  self.totalTime:start()
  self.nativeHook = {debug.gethook()}
  --include `l` (line) if other hook needs it
  local mask = self.nativeHook and self.nativeHook[2] and self.nativeHook[2]:find"l" and "clr" or "cr"
  debug.sethook( wrap(self, self.onHook), mask )
end

function Profiler:stop()
  self.totalTime:stop()
  if self.nativeHook then
    debug.sethook( table.unpack(self.nativeHook) )
  else
    debug.sethook(nil)
  end
end

function Profiler:callToJson( call )
  local obj = JsonObject:new()
  obj:put("file", call.file)
  obj:put("func", call.func)
  obj:put("line", call.line)
  obj:put("calls", call.calls)
  obj:put("stackTime", call.stackTime:getTime())
  obj:put("cpuTime",call.cpuTime:getTime())
  obj:put("subCalls", self:subCallsToJson( call.subCalls ))
  return obj
end

function Profiler:subCallsToJson( calls )
  local array = JsonArray:new()
  for k,v in pairs( calls ) do
    array:put( self:callToJson(v) )
  end
  return array
end

function Profiler:toJson()
  local json = JsonObject:new()
  json:put("time",self.totalTime:getTime())
  json:put("calls", self:subCallsToJson( self.stack.subCalls ))
  return json
end

function Profiler:save(file)
  local f = io.open(file, "w")
  assert(f, "Could not open file '"..file.."' for saving")
  f:write( self:toJson():toString() )
  f:close()
end

function Profiler:openViewer()
  if self.window then self.window:close() end
  self.window = require"java".run("luaVisualizer.jar")
end

function Profiler:show()
  if not self.window then
    self:openViewer()
  end
  self.window:write(self:toJson():toString()..'$"$')
end

return Profiler