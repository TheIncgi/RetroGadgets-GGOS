local cls = require"class.lua"
local class = cls.class
local utils = require"utils.lua"
local dataUtils = require"dataUtils.lua"

local Font = class"theincgi.Font"
Font.static = {
	loaded = {}
}

local _new = Font.new
function Font:new( ... )
	local args = utils.kwargs({
		{font="string","consolas","family","name"},
		{size="number",12}
	},...)
	
	local res = ("%s_%d.luafont"):format(
		args.font,
		args.size
	)
	
	if self.static.loaded[ res ] then
		return self.static.loaded[res]
	end
	
	local obj = _new( self )
	
	obj.font = args.font
	obj.size = args.size
	
	obj.data = require( res )
	if not obj.data then
	  error("Missing font data for '"..res.."'",2)
	end
	print("Decoding font "..res.."...")
	obj:_load()
	print" > Font Decoded"
	self.static.loaded[ res ] = obj
	return obj
end

function Font:_load()
	for style, styleData in pairs( self.data ) do
		styleData.height = 
			styleData.ascent + styleData.descent
		for codePoint, charData in pairs( styleData.chars ) do
			charData.data = 
					dataUtils.dec64( charData.data )
		end
	end
end

--width, height, leading (line space)
function Font:measure( ... )
	local args = utils.kwargs({
		{text={"string"},nil,"string","txt","str"},
		{bold="boolean",false},
		{italics="boolean",false},		
	},...)
	local styleName = self:getStyleName(
	  args.bold, 
	  args.italics
  )
	local styleData = self.data[styleName]
	local height = styleData.ascent
	              +styleData.descent
	local width = 0
	local t = args.text
	for c=1, #t do
		local codePoint = t:byte(c,c)
		local w = styleData.chars[codePoint].width
		width = width + w
	end
	return width, height, styleData.leading
end

function Font:render( ... )
	local args = utils.kwargs({
		{view={"class:theincgi.View","nil"}},
		{x="number"},
		{y="number"},
		{line="number",1},
		{text="string"},
		{bold="boolean",false},
		{italics="boolean",false},		
		{color={"vector","function"}, color.green},
		{vertAlign="string","top","vert","verticalAlignment","vAlign"},
		{horzAlign="string","left","horz","horizontalAlignment","hAlign"}
	},...)
	
	local args2 = utils.multiGet(args,{
		"view","x",args"y","text",
		"bold","italics","color","vertAlign"
	})
	local xOffset = 0
	if args.horzAlign=="center" then
		local w,h,l = self:measure{
			text=args.text,
			bold=args.bold,
			italics=args.italics
		}
		xOffset = -w/2
	elseif args.horzAlign=="right" then
		local w,h,l = self:measure{
			text=args.text,
			bold=args.bold,
			italics=args.italics
		}
		xOffset = -w
	elseif args.horzAlign=="left" then
	else
		error("invalid horzAlign, must be one of [left,center,right]",2)
	end
	xOffset = math.floor(xOffset)
	
	args2.x = args2.x + xOffset
	
	for i=1,#args.text do
		args2.codePoint = args.text:byte(i,i)
		args2.x = self:renderChar( args2 )
	end
end

---
---alignment can be "top","baseline","bottom"
function Font:renderChar( ... )
	local args = utils.kwargs({
		{view={"class:theincgi.View","nil"}},
		{x="number"},
		{y="number"},
		{line="number",1},
		{char="string",nil,{"codePoint","number"}},
		{bold="boolean",false},
		{italics="boolean",false},		
		{color={"vector","function"}, color.green},
		{vertAlign="string","top","vert","verticalAlignment"}
	},...)
	
	-------------------------------
	
	local codePoint = 
		args"char"=="codePoint"
		and args.codePoint 
		 or string.byte( args.char )
	local styleName = self:getStyleName(
	  args.bold, 
	  args.italics
  )
	local styleData = self.data[styleName]
	local charData = styleData.chars[codePoint]
	local height = styleData.height
	
	args.y = args.y + (args.line-1)
		* (height + styleData.leading)
	
	for y=1, height do
		for x=1, charData.width do
			local px = args.x + x -1
			local py = args.y + y -1
			if args.vertAlign=="top" then
			elseif args.vertAlign=="baseline" then
				py = py - styleData.ascent
			elseif args.vertAlign=="bottom" then
				py = py - height
			elseif args.vertAlign=="center" then
				py = math.floor(py - height/2)
			else
				error("incorrect font alignment '"..args.alignment.."'",2)
			end
			
			local pixel = (y-1) * charData.width + x
			local value =
					    charData.data:byte(pixel,pixel)	
			
			local c:color = 
					type(args.color)=="function" and
					args.color(px,py,args.view) or args.color	
			
			local argb = ColorRGBA( 
				c.R,
				c.G,
				c.B,
				value
			)
			
			
			
			if args.view then
				args.view:setPixel( px, py, argb )
			else
				gdt.VideoChip0:SetPixel(
							vec2(px,py),argb
				)
			end
		end
	end
	return args.x + charData.width
end

function Font:getStyleName( bold:boolean, italics:boolean )
	if not bold and not italics then
		return "plain"
	end
	if bold then
		if italics then
			return "bold+italics"
		end
		return "bold"
	end
	return "italics"
end

return Font