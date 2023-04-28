--is it really a car? idk
--but it's quicker to type

--orientation ref
-- +x is right
-- -y is forward
-- +z is up

local cls = require"class.lua"
local class = cls.class
local linalg = require"linalg.lua"
local utils = require"utils.lua"

local Car = class"theincgi.gRacer.Car"

local _new = Car.new
function Car:new( ... )
	local obj = _new( self )
	
	local args = utils.kwargs({
		{x="number",0},
		{y="number",0},
		{z="number",0},
		{mass="number",1500}, --kg
		{gripFactor="number",.85},
	},...)
	
	obj.pos = linalg.vec(
		args.x, args.y, args.z
	)
	
	obj.velocity = linalg.vec(
		0,0,0
	)
	
	obj.orient = linalg.identity(
		linalg.newMatrix(4,4)
	)
	
	obj.mass = args.mass
	
	obj.gripFactor = args.gripFactor
	obj.isOnGround = true
	
	
	return obj
end

--
function Car:applyForce( vec )
end