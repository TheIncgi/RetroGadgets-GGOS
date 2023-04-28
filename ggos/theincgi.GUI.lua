local cls = require"class.lua"
local utils = require"utils.lua"
local class = cls.class


local GUI = class("theincgi.GUI")

local _new = GUI.new
function GUI:new( ... )
  local obj = _new( self )
	local args = utils.kwargs({
		{ view="class:theincgi.View" },
		{ tileWidth="number", nil, "tw" },
		{ tileHeight="number", nil, "th" },
		{ margins="number", 4 },
		{ onChange={"function","nil"}}
	},...)
	obj.view = args.view
	obj.items = {}
	obj.selection = {1,1} --items
	obj.tileWidth = args.tileWidth
	obj.tileHeight = args.tileHeight
	obj.origin = {1,1} --pixels
	obj.margins = args.margins
	obj.onChange = args.onChange or false

	return obj
end

function GUI:setOnChange( f )
	self.onChange = f
end

function GUI:getSelection()	
	local s = self.selection
	return
		(self.items[s[1]] or {})[s[2]] or false
end

function GUI:addItem( ... )
	local args = utils.kwargs({
		{ item="class:theincgi.GuiElement",nil,"element","elem","tile" },
		{ x="number" },
		{ y="number" }
	},...)
	self.items[args.x] = self.items[args.x] or {}
	self.items[args.x][args.y] = args.item
	
	local itemView = self.view:subView{
		x=(args.x-1)*(self.margins+self.tileWidth)+1,
		y=(args.y-1)*(self.margins+self.tileHeight)+1,
		width=self.tileWidth,
		height=self.tileHeight,
		label=self.view.label.."-tile"
	}
	
	args.item:setView( itemView )
end

--ignores if real or not
--returns pixel location of item ignoring 
--origin transforms
--start = top left
--center = center
--end = bottom right
function GUI:getItemStart( itemX, itemY )
	local w = self.tileWidth + self.margins
	local h = self.tileHeight + self.margins
	local x = (itemX-1)*w + 1
	local y = (itemY-1)*h + 1
	return x,y
end
function GUI:getItemCenter( itemX, itemY )
	local x,y = self:getItemStart(itemX,itemY)
	return math.floor(x+self.tileWidth/2),
	       math.floor(y+self.tileHeight/2)
end
function GUI:getItemEnd( itemX, itemY )
	local x,y = self:getItemStart(itemX,itemY)
	return x+self.tileWidth,
	       y+self.tileHeight
end

function GUI:setOrigin( x, y )
	self.origin[1] = x
	self.origin[2] = y
end

function GUI:getOrigin()
	return self.origin[1], self.origin[2]
end

function GUI:draw()
	for x, row in pairs( self.items ) do
		for y, item in pairs( row ) do
			local ix,iy = self:getItemStart(x,y)
			item:getView():setPos(
				ix + self.origin[1] - 1,
				iy + self.origin[2] - 1
			)
			local selected = self.selection[1] == x
					   and self.selection[2] == y
			item:draw( self, selected )
		end
	end
end

function GUI:hasItem( ... )
	local args = utils.kwargs({
		{dx="number",0,"x"},
		{dy="number",0,"y"},
	},...)
	
	local x = args.x or self.selection[1]+args.dx
	local y = args.y or self.selection[2]+args.dy

	if not self.items[x] then return false end
	return not not self.items[x][y]
end

function GUI:moveSelection( ... )
	local args = utils.kwargs({
		{dx="number",0,"x"},
		{dy="number",0,"y"},
		{muteEvents="boolean",false}--prevent recursion
	},...)
	
	local oldX,oldY=table.unpack(self.selection)
	local oldItem=self:getSelection()
	
	local x,y
	if args"x" then
		x = args.x
	else
		x = args.dx + self.selection[1]
	end
	
	if args"y" then
		y = args.y
	else
		y = args.dy + self.selection[2]
	end
	
	self.selection = {x, y}
	
	if self.onChange and not args.muteEvents then
		self.onChange{
			oldX=oldX, oldY=oldY, oldItem=oldItem,
			newX=self.selection[1],
			newY=self.selection[2],
			newItem=self:getSelection()
		}
	end
end

function GUI:getTileWidth()
	return self.tileWidth
end
function GUI:getTileHeight()
	return self.tileHeight
end

return GUI