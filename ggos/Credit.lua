local cls = require"class.lua"
local class = cls.class

local Credit = class"Credit"
local utils = require"utils.lua"

local Font = require"theincgi.Font.lua"
local defaultFont = 
        Font:new{name="consolas",size=12}

local _new = Credit.new
function Credit:new( ... )
	local obj = _new( self )
	
	local args = utils.kwargs({
		{name="string",nil,"line",{"logo","class:Image"}},
		{font="class:theincgi.Font", defaultFont},
		{color="vector",color.white}
	},...)
	
	if args"name" == "logo" then
		obj.logo = args.logo
		obj.height = obj.logo:getHeight()
	else
		obj.name = args.name
		obj.type = "name"
		obj.font = args.font
		obj.color = args.color
		local wid,hei,lead = args.font:measure{
			text=args.name,
		}
		obj.height = hei + lead
	end
	
	return obj
end

function Credit:getHeight()
	return self.height
end

--always centered
function Credit:drawAt( view, y )
	local floor = math.floor
	if self.type=="name" then
		self.font:render{
		  x = floor(view:getWidth()/2),
		  y=y,
	  	text=self.name,
	  	color=self.color,
			hAlign = "center"
	  }
	
	else
		local x = floor(
			view:getWidth()/2
     -self.logo:getWidth()/2
		)
		self.logo:draw(x,y)
	end
end

-- isVisible
-- done is if credits go up toward -Y
function Credit:isVisible( view, yStart )
	if yStart + self:getHeight() >= 1 then
		return true
	end
	if yStart <= view:getHeight() then
		return true
	end
	
	return false,
		yStart + self:getHeight() < 1 and "done","waiting"
end

return Credit