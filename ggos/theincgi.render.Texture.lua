--Texture

local cls = require"class.lua"
local class = cls.class
local utils = require"utils.lua"
local dataUtils = require"dataUtils.lua"

local Tex = class"theincgi.render.Texture"

Tex.static = {
  loaded = {}
}

Tex.MISSING = Tex:new{
	w=2,h=2,
	data=table.concat{
		string.char(
			--r g b
			255, 0, 255,
			  0, 0,   0,
			  0, 0,   0,
			255, 0,   0
		)
	}
}

--data is if already b64 decoded
local _new = Tex.new
function Tex:new(...)
	local obj = _new( self )
	
	local args = utils.kwargs({
		{width="number",nil,"w","wid"},
		{height="number",nil,"h","hei"},
		{channels="number",3,"ch"},
		{isColor="boolean",true},
		{chunks="table",nil,{"data","string"}},
		{wrapX="boolean",true},
		{wrapY="boolean",true}
	},...)
	
	obj.width = args.width
	obj.height = args.height
	obj.channels = args.channels
	obj.isColor = args.isColor
	obj.wrapX = args.wrapX
	obj.wrapY = args.wrapY
	
	if args.data then
		obj.data = args.data
	else
		local tmp = {}
		for i,chunk in ipairs( args.chunks ) do
			table.insert(tmp, dataUtils.dec64(chunk))
			utils.autoYield()
		end
		obj.data = table.concat(tmp)
		utils.autoYield()
	end
	
	return obj
end

function Tex:get( name, isColor )
	local res = ("%s.tex"):format(name)
	if Tex.static.loaded[res] then
	  return Tex.static.loaded[res]
	end
	local ok, val = pcall( require, res )
	if not ok then
		print("Texture error ["..res.."]: "..tostring(val))
		print(debug.traceback())
		return self.MISSING
	end
	local tex = Tex:new{
	  width    = val.width,
	  height   = val.height,
	  channels = val.channels or 4,
	  isColor  = isColor,
		chunks   = val.chunks
	}
	Tex.static.loaded[res] = tex
	return tex
end

function Tex:_getBytes( start, n )
  n = n or 1
  return self.data:byte( start, start + n - 1 )
end

function Tex:getPixel( x, y )
	local ch = self.channels
	if self.wrapX then
		x = (x-1) % self.width + 1
	else
		x = math.max(0, math.min(1, x))
	end
	if self.wrapY then
		y = (y-1) % self.height + 1
	else
		y = math.max(0, math.min(1, y))
	end
	local start = ((y-1)*self.width + (x-1))*ch + 1
	
	local out = {}
	for i = 1, ch do
		out[i]=self.data:byte(start+i-1)
			--dataUtils.readNum(
			--self.data,
			--start+i-1,
			--1,
			--false
		--)
	end
	--local utils = require"utils.lua"
  --print( utils.serializeOrdered(out))
	if self.isColor and self.channels == 4 then
		local a,r,g,b = table.unpack(out)
		return r,g,b,a
	end
	return table.unpack(out)
end

function Tex:uvToPixel(u, v)
	return 
		u * (self.width  - 1) + 1,
		v * (self.height - 1) + 1
end

function Tex:sampleNearest( u, v )
	local x, y = self:uvToPixel( u, v )
  x = math.floor( x + 0.5 )
  y = math.floor( y + 0.5 )
  local color = {self:getPixel( x, y )}
	for i=1,self.channels do
		color[i] = color[i]/255
	end
  return table.unpack( color )
end

function Tex:_blend( f, a, b )
  --print(f,a,b)
  if not a or not b then
    --return a or b
    error("expected value",2)
  end
  if self.isColor then
    a = a * a
    b = b * b
    return math.sqrt( (1-f)*a + f*b )
  else
    return (1-f)*a + f*b
  end
end

function Tex:sampleLinear( u, v )
	local x, y = self:uvToPixel( u, v )
  local x1 = math.floor( x )
  local y1 = math.floor( y )
  local x2 = math.ceil( x )
  local y2 = math.ceil( y )
  local xf = x-x1
  local yf = y-y1
  local c11 = { self:getPixel( x1, y1 ) }
  local c12 = { self:getPixel( x1, y2 ) }
  local c21 = { self:getPixel( x2, y1 ) }
  local c22 = { self:getPixel( x2, y2 ) }
  
  for _,c in ipairs{ c11, c12, c21, c22 } do
    for i=1,#c do
      c[i] = c[i] / 255
      --print(("%d$%.2f"):format(i,c[i]))
    end
  end
  local out = {}
  for i=1,self.channels do
    --print( "TEX", c12[i] )
    out[i] = self:_blend( 
      yf,
      self:_blend( xf, c11[i], c21[i] ),
      self:_blend( xf, c12[i], c22[i] )
    )
  end
  return table.unpack( out )
end

return Tex