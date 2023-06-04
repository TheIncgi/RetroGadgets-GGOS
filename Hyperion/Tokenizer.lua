local Tokenizer = {}


function Tokenizer.findEndOfString(str, start)
    local startChar = str:sub(start, start)
    local endChar = startChar
  
    if startChar == "[" then
      -- Long string literal, find closing bracket
      local quoteLevel = #(str:sub(start + 1):match("^=*"))
      local _, stringEnd = str:find("%]" .. ("="):rep(quoteLevel), start + 1)
      if not stringEnd then
        error("Unclosed string at position " .. start)
      end
      return stringEnd + 1
    end
  
    local i = start + 1
    while i <= #str do
      local char = str:sub(i, i)
      if char == "\\" then
        -- Escape sequence, skip next character
        i = i + 2
      elseif char == endChar then
        -- Matching quote found
        return i + 1
      else
        i = i + 1
      end
    end
  
    -- No matching quote found
    error("Unclosed string at position " .. start)
  end

function Tokenizer:new( ... )
  local obj = {
    cursorStart = 1,
    cursorEnd = 0,
    tokens = {}
  }



  setmetatable(obj, self)
  self.__index = self
  return obj
end

return Tokenizer