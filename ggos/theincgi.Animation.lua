local cls = require"class.lua"
local class = cls.class
local utils = require"utils.lua"
local rUtils = require"retroUtils.lua"

local Anim = class"theincgi.Animation"

local _new = Anim.new
function Anim:new( ... )
	local obj = _new( self )
	
	local args = utils.kwargs({
		{millis ={"number"},0,"ms","milliseconds","millisecond"},
		{seconds="number",0,"s","second"},
		{minutes="number",0,"m","minute"},
		{hours="number",0,"h","hour"},
		{onStart={"function","nil"}},		{onUpdate={"function","nil"},nil,"onProgress"},		
		{onFinish={"function","nil"},nil,"onDone"},
		{easing = {"function"}}
	},...)
	--easing
	--seconds, minutes, hours
	obj.x=0
	obj.dir = 0
	obj.seconds =
		args.millis / 1000 +
		args.seconds +
		args.minutes * 60 +
		args.hours * 3600
	obj.onStart = args.onStart
	obj.onUpdate = args.onUpdate
	obj.onFinish = args.onFinish
	obj.easing = args.easing
	obj.done = true
	obj.lastTimestep = -1
	
	return obj
end
	

function Anim:start( reversed )
	self.dir = reversed and -1 or 1
	self.x = reversed and 1 or 0
	self.lastTimestep = rUtils.cpuTime()
	self.done = false
	if self.onStart then
		self.onStart()
	end
end

function Anim:reverse()
	self.dir = -self.dir
	self.done = false
	self.lastTimestep = rUtils.cpuTime()
end

function Anim:update()
	if self.done then return end
	local now = rUtils.cpuTime()
	local elapsed = now - self.lastTimestep
	
	if elapsed == 0 then return end
	
	self.lastTimestep = now
	
	local step = elapsed / self.seconds
	self.x = math.clamp(self.x+step*self.dir,0,1)
	
	local target = 
		self.dir ==  1 and 1 or
		self.dir == -1 and 0 or
		false
			
	if self.onUpdate then
		self.onUpdate( self:getValue() )
	end
	
	if self.x == target then
		self.done = true
		if self.onFinish then
			self.onFinish()
		end
	end	
	
end

function Anim:getProgress()
	return self.progress
end

function Anim:getValue()
	return self.easing( self.x )
end

return Anim