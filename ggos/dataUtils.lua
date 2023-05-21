local dataUtils = {}
utils = require"utils.lua"

local base64='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function dataUtils.getBit(x:number, pos:number)
	return bit32.band(1,bit32.rshift(x, pos))
end

function dataUtils.enc64(data)
	local out = {}
	local b64 = base64:sub(1, 64) -- Use the first 64 characters of the base64 string
	
	for i = 1, #data, 3 do
	  if i % 32 == 0 then utils.autoYield() end
	  local bytes = {data:byte(i, i + 2)} -- Get the next three bytes
	  
	  -- Calculate the Base64 characters for each set of three bytes
	  local encoded = {}
	  encoded[1] = b64:sub(math.floor(bytes[1] / 4) + 1, math.floor(bytes[1] / 4) + 1)
	  encoded[2] = b64:sub(math.floor(((bytes[1] % 4) * 16) + (bytes[2] / 16)) + 1, math.floor(((bytes[1] % 4) * 16) + (bytes[2] / 16)) + 1)
	  encoded[3] = b64:sub(math.floor(((bytes[2] % 16) * 4) + (bytes[3] / 64)) + 1, math.floor(((bytes[2] % 16) * 4) + (bytes[3] / 64)) + 1)
	  encoded[4] = b64:sub(math.floor(bytes[3] % 64) + 1, math.floor(bytes[3] % 64) + 1)
	  
	  -- Handle padding for the last group of bytes
	  if #bytes < 3 then
		encoded[4] = "="
		if #bytes < 2 then
		  encoded[3] = "="
		end
	  end
	  
	  table.insert(out, table.concat(encoded))
	end
	
	return table.concat(out)
  end

--base64 to bytes as string
function dataUtils.dec64( data )
	local out = {}
	local ls = bit32.lshift
	local rs = bit32.rshift
	local bor = bit32.bor
	local band = bit32.band
	
	for x = 1, #data, 4 do
		if x % 32 == 0 then utils.autoYield() end
		local v = data:sub( x, x+3 ).."=="
		local n = --bytes after padding 
			(data:sub(x+2,x+2) == "=" and 1 or 0)
		 +(data:sub(x+3,x+3) == "=" and 1 or 0)
		n = 3 - n
		for byte=0,n-1 do
			local sum = 0
			for bit=0,7 do
				local g = byte*8 + bit

				local char = math.floor(g / 6) + 1
				local localBit = g % 6
				local baseChar = v:sub( char, char)
				local pos = base64:find(baseChar)-1			
				local localValue = dataUtils.getBit(
					pos,
					5-localBit
				)
				
				sum = bor(ls(sum,1),localValue )
			end
			table.insert(out,string.char(sum))
		end 
	end
	return table.concat(out)
end

function dataUtils.readNum( data, start, n, signed )
	local sum = 0
	
	for i=0,n-1 do
		sum = bit32.lshift( sum, 8 )
		local b = data:byte( start + i )
		bit32.bor( sum, b )		
	end
	
	if signed and bit32.band( 0x80, data:byte(start) ) > 0 then
		sum = bit32.bnot(sum)-1
	end
	
	return sum
end

return dataUtils