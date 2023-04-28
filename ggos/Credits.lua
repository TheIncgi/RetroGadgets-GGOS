local cls = require"class.lua"
local class = cls.class
local utils = require"utils.lua"
local Animation = require"theincgi.Animation.lua"
local easings = require"easings.lua"
local retroUtils = require"retroUtils.lua"
local Font = require"theincgi.Font.lua"

local Credits = class"Credits"
local Credit = require"Credit.lua"

local _new = Credits.new
function Credits:new( ... )
	local obj = _new( self )
	
	--can re-order as you like
	--lookup will auto update as needed
	obj.categories = {}
	obj.lookup = {}
	obj.seconds = 10
	obj.playlist = {}
	obj.currentSong = 0
	obj.onFinish = false
	obj.animation = false
	obj.view = false
	obj._queue = {}
	obj.yOffset = 0
	obj.songChannel = 1
	
	return obj
end

function Credits:addSong( asset:AudioSample, seconds:number, vol )

	table.insert(self.playlist, {
		audio = asset,
		seconds = seconds,
		vol = vol or 100
	})
end

function Credits:setDuration( seconds )
	if not seconds then 
		seconds = 0
		for _,song in ipairs(self.playlist) do
			seconds = seconds + song.seconds
		end
	end
	
	self.seconds = math.max(1,seconds)
end

function Credits:addCategory( ... )
	local args = utils.kwargs({
		{
		  name="string",
		  nil,
			"category","categoryName"
		},{
			font={"string","class:theincgi.Font"},
			"consolas_18",
			"categoryFont"
		},
		{color={"vector","function"},color.red,
			"categoryColor"}
	},...)
	
	if type(args.font)=="string" then
		local name, size =
				args.font:gmatch("([^_]+)_(.+)")()
		size = tonumber(size)
		args.font = Font:new{
			name=name,
			size=size
		}
	end
	
	table.insert( self.categories, {
		title = Credit:new{
			line=args.name,
			font=args.font,
			color=args.color
		},
		name = args.name,
		credits = {},
		unique = {}
	})
	
	self:recalcLookup()
end

function Credits:recalcLookup()
	self.lookup = utils.map(self.categories,
		function(k,v)
			return v.name, k
		end, 
		true
	)
end

function Credits:getCategory( name )
	local cat = self.lookup[ name ]
	if not cat then 
		self:recalcLookup()
		if not cat then
			error("Category '"..name.."' doesn't exist!",2)
		end
	end
	return self.categories[cat],cat
end

function Credits:addLine( category:string,
line:string )
	self:addCredit( category, Credit:new{
		line=line
	}, line )
end

function Credits:addCredit( category:string, credit, uniqueName )
	if not utils.typeMatches(credit,{"class:Credit"}) then
		error("expected Credit for arg 2")
	end
	
	local cat = self:getCategory(category)
	if uniqueName then
		if cat.unique[uniqueName] then return end
		table.insert( cat.credits, credit )
		if uniqueName then
			cat.unique[uniqueName] = true
		end
	end
end

--height of all elements without empty space
--before or after credits
function Credits:calculateHeight()
	local total = 0
	for i, cat in ipairs( self.categories ) do
		for j, cred in ipairs( cat.credits ) do
			total = total + cred:getHeight()
		end
	end
	return total
end

function Credits:finalHeight( view )
	return self:calculateHeight()
	     + view:getHeight()*2
end



function Credits:start( view )
	self.view = view
	local SCREEN_HEIGHT = view:getHeight()
	local FULL_HEIGHT = self:finalHeight( view )
	self.yOffset = SCREEN_HEIGHT
	self.currentSong = 0
	self:_buildQueue( view )
	retroUtils.stopAllAudio()
	
	print("Screen H: "..SCREEN_HEIGHT)
	print("FHeight:  "..FULL_HEIGHT)
	
	
	local obj = self
	self.animation = Animation:new{
		seconds = self.seconds,
		onFinish = function()
			if obj.onFinish then obj.onFinish() end
			retroUtils.stopAllAudio()
		end,
		onUpdate = function( p )
			obj.yOffset = math.floor(
           SCREEN_HEIGHT
			 -(p * FULL_HEIGHT)
			)
			view:clear()
			obj:_draw()
			obj:_updatePlaylist()
		end,
		easing = easings.linear --never thought I'd use that one...
	}
	self.animation:start()
end

function Credits:update()
	self.animation:update()
end

function Credits:setOnFinish( callback )
end

function Credits:setView( view )
end

function Credits:_addQueueItem( credit, view, offsetY )
	assert( credit, "credit item can't be nil!")
	table.insert(self._queue, function( drawAt )
			local drawY = offsetY + drawAt
			local isVis, why = credit:isVisible(
				view, 
				drawY
			)
			if not isVis then
				return isVis, why
			end
			credit:drawAt( view, drawY )
			return isVis
		end) --draw callback
	
	return credit:getHeight() + offsetY
end

function Credits:_buildQueue( view )
	self._queue = {}
	local offset = 0
	local q = self._queue
	local center = math.floor(view:getWidth()/2)
	for i,cat in ipairs(self.categories) do
		--Category Title
		offset = self:_addQueueItem(
			cat.title,
			view,
			offset
		)
		
		--Credit lines
		for j, cred in ipairs(cat.credits) do
			offset = self:_addQueueItem(
				cred,
				view,
				offset
			)
		end
	end
end

function Credits:_draw()
	local off = self.yOffset
	local i = 1
	repeat
		local item = self._queue[i]
		if not item then break end
		local vis, why = item( self.yOffset )
		if why=="done" then
			table.remove( self.queue, 1 )
		end
		i=i+1
	until not vis and why=="waiting"
end

--if no song playing, play next in queue
function Credits:_updatePlaylist()
	if not self.currentSong
	or not gdt.AudioChip0:IsPlaying(self.songChannel) 
	and self.playlist[self.currentSong+1] then
		self.currentSong = self.currentSong+1
		local song = self.playlist[self.currentSong]
		if song then

			gdt.AudioChip0:SetChannelVolume(
				song.vol,
				self.songChannel
			)

			gdt.AudioChip0:Play(
				song.audio,
				self.songChannel
			)
		end
	end
end

return Credits