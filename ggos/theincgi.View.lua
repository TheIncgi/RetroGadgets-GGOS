local cls = require"class.lua"
local class = cls.class
local isClass = cls.isClass
local utils = require"utils.lua"
local gUtils = require"graphicsUtils.lua"
local linalg = require"linalg.lua"

local View = class"theincgi.View"

local _new = View.new
function View:new( ... )
	local args = utils.kwargs({
		{x="number",1},
		{y="number",1},
		{width={"number","nil"},nil,"w"},
		{height={"number","nil"},nil,"h"},
		{parent={"nil","class:theincgi.View"}},
		{chip="userdata", gdt.VideoChip0, "vChip"},
		{label="string",nil,"lbl","name"},
		{visible="boolean",true}
	},...)
	local obj = _new( self )
	obj.private = {}
	obj.private.dirty = false --requires redraw
	obj.private.x = args.x
	obj.private.y = args.y
	obj.visible = args.visible
	obj.label = args.label
	
	obj.private.width = 
		   args.width 
		or args.parent and args.parent.private.width    
		or args.chip.Width
			
	obj.private.height = 
	     args.height
	  or args.prent and args.parent.private.height
	  or args.chip.Height

	
	obj.private.vChip = args.chip
	obj.private.buffer = {}
	obj.private.children = {}
	obj.private.z = 1
	
	if args.parent then
		obj.private.parent = args.parent
		local pchil = args.parent.private.children
		pchil[ obj ] = true
	end
	
	return obj
end

function View:subView( ... )
	local args = utils.kwargs({
		{x="number",1},
		{y="number",1},
		{width="number",self:getWidth(),"w"},
		{height="number",self:getHeight(),"h"},
		{label="string",nil,"lbl","name"}
	},...)
	
	local sv = self:new{
		x=args.x,
		y=args.y,
		w=args.width,
		h=args.height,
		parent=self,
		label=args.label
	}
	return sv
end

function View:markDirty( state )
  state = state==nil or state
	if self.private.parent then
		self.private.parent:markDirty( state )
	else
	  self.private.dirty = state
	end
end

--true if parent (or self if no parent) is dirty
function View:isDirty()
  return self.private.parent
    and self.private.parent:isDirty()
     or self.private.dirty
end

--removes references in the parent so it can GC
function View:dispose()
	local parent = 	self.private.parent
	if not parent then return end
	parent.private.children[ self ] = nil
end

function View:inGlobalBounds( gX:number, gY:number )
	local x1,y1 = self:mapPixel(1,1)
	local x2,y2 = self:mapPixel(self:getSize())
	
	return 
		utils.inRect( gX, gY, x1,y1,x2,y2)
end

function View:inLocalBounds( viewX: number, viewY: number )
	return
		utils.inRect( viewX, viewY, 1, 1, self:getWidth(), self:getHeight())
end

function View:mapPixel( viewX: number, 
                                 viewY:number )
	
	local isIn = self:inLocalBounds( viewX, viewY )
	local x = viewX + self.private.x - 1
	local y = viewY + self.private.y - 1
	
	if self.private.parent then
		return self.private.parent:mapPixel( x, y )
	end
	return x, y, isIn
end

function View:setParent( parent )
  if not utils.typeMatches( parent, {"class:theincgi.View"}) then
		error("Expected View, got "..(
			isClass( parent ) and parent:className() 
					or type(parent) ))
	end

	self.private.parent = parent
	self.private.parent:markDirty()
end

function View:getWidth()
	return self.private.width
end

function View:getHeight()
	return self.private.height
end

function View:getSize()
	return self:getWidth(), self:getHeight()
end

function View:getX()
	return self.private.x
end

function View:getY()
	return self.private.y
end

function View:getPos()
	return self:getX(), self:getY()
end

function View:setX( x:number )
	self.private.x = x
end

function View:setY( y:number )
	self.private.y = y
end

function View:setPos( x:number, y:number )
	self:setX( x )
	self:setY( y )
end

function View:setWidth( w:number )
	self.private.width = w
end

function View:setHeight( h:number )
	self.private.height = h
end

function View:setSize( w:number, h:number )
	self:setWidth( w )
	self:setHeight( h )
end

function View:getZ()
	return self.private.z
end

function View:setZ(z:number)
	self.private.z = z
end

--only called on base view
--children views do not have this called
function View:draw( doColorCorrect )
  --self:markDirty()
  if not self:isDirty() 
  or not self.visible then
    return
  end
	for y=1, self:getHeight() do
	local adjust = ColorRGBA(0,0,0,125)
		for x=1, self:getWidth() do
			local c = self:getFinalPixel(x,y)
			
			if doColorCorrect and x<30 and y%2==0 then
				c = gUtils.blendAlpha(c, adjust)
			end
			--c= color.white
			self.private.vChip:SetPixel(vec2(x-1,y-1),c)
		end
	end
	self:markDirty( false )
end

--f is only used if c is a function
--used by to indicate alpha for things like
--lines
--f is [0,1]
function View:setPixel( x:number, y:number, c:any, f:any )
	if not self:inLocalBounds( x, y ) then
	  return
	end
	--TODO if visible
	--if not covered
	if type(c)=="function" then
		c = c(x,y,f or 1)
		if type(c)~="vector" then
			error("setPixel color function did not return a color vector, got '"..type(c).."'",2)
		end
	elseif type(c)~="vector" then
		error("View:setPixel expects arg3 to be color or function, got "..type(c),2)
	end
	
	self.private.buffer[x]=self.private.buffer[x] or {}
	self.private.buffer[x][y] = c
	
	self:markDirty()
	--x,y = self:mapPixel(x,y)
	--if x then
		--self.private.vChip:SetPixel(vec2(x-1,y-1),c)
	--end
	utils.autoYield()
end

function View:drawLine(
	x1:number,
	y1:number,
	x2:number,
	y2:number,
	clr:any
)
	gUtils.line(
		x1,
		y1,
		x2,
		y2,
		function(x,y,f)
			self:setPixel( x, y, clr )
		end
	)
end

function View:drawBox(
	x1:number, --left
	y1:number, --top
	x2:number, --right
	y2:number, --bottom
	clr:any )
	local dx, dy = x2-x1, y2-y1
	-- +/- 1 to avoid duplicate pixels
	self:drawLine(x1,y1,x2,y1,clr) --top
	if dy ~= 0 then
		self:drawLine(x1,y1+1,x1,y2,clr) --left
		if dx ~= 0 then
			self:drawLine(x2,y1+1,x2,y2,clr) --right
			self:drawLine(x1,y2,x2,y2,clr) --bottom
		end
	end
end

function View:fillRect(
	x1:number,
	y1:number,
	x2:number,
	y2:number,
	clr )

	self.private.buffer = {}
	
	--if type(clr)=="vector" then
		--gdt.VideoChip0:FillRect(
		--	vec2( self:mapPixel(x1,y1) ),
			--vec2( self:mapPixel(x2,y2) ),
			--clr
		--)
	--else
		for y=1,self:getHeight() do
			for x=1,self:getWidth() do
				self:setPixel( x, y, clr )
			end
		end
	--end
end

function View:getPixel( x, y )	
	if self.visible then
	  return self.visible and ((self.private.buffer[x] or {})[y]) or
    
	  ColorRGBA(0,0,0,
	    self.private.parent and 0 or 255)
	else
	  return false --ColorRGBA(0,0,0,0)
	end
end

--implements
--return a<b
--reversed so largest z first
local function sortZ(a,b)
	return a.z > b.z
end

function View:getFinalPixel( x, y )
	local d = self:getPixel( x, y )
	
	local colors = {}
	if d then
  	colors[1] =
	  	{c=d,z=-math.huge}
  end
	for child in pairs(self.private.children) do
		local childZ = child:getZ()
		local localX = x - child:getX() + 1
		local localY = y - child:getY() + 1
		if child.visible
		and child:inLocalBounds(localX,localY) then
			table.insert( colors, {
				c=child:getFinalPixel(
					localX, localY
				),
				z=childZ
			})
		end
	end
	local N = #colors
	if N==0 then
		return false
	elseif N==1 then
		return colors[1].c
	end
	
	table.sort( colors,sortZ )
	local out = ColorRGBA(0,0,0,0)
	for _,clr in ipairs(colors) do
	  local c = clr.c
		out = gUtils.blendAlpha(out, c)
		
		if clr.A == 255 or out.A == 255 then
			break
		end
	end
	
	return out
end

--TODO toggle bg fill
function View:clear()
	local clr = color.black
	self.private.buffer = {}
	
	--gdt.VideoChip0:FillRect(
		--vec2( self:mapPixel(0,0) ), --BUG
			--1,1 is correct, but 0,0 is needed
			-- to clear the whole screen
		--vec2( self:mapPixel( self:getSize() ) ),
		--clr
	--)
	self:markDirty( true )
end
return View