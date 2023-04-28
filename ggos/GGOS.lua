local retroUtils = require"retroUtils.lua"
local GAME_REGISTRY = require"GAME_REGISTRY.lua"
local utils = require"utils.lua"
local cprint = utils.cprint
local ansiColor = utils.ansiColor

local GGOS = {
	activities = {}, --string=instance
	currentActivity = false, --string
	games={}, --string=Activity
	view = false,
	--homeActivity = "theincgi.ggos.Home"
	homeActivity = "theincgi.3DTest"
}
--Model of OS model/view
--view is ViewOS

local View = require"theincgi.View.lua"


function GGOS.setup()
  cprint(ansiColor.lime, "GGOS Setup")
	local m = GGOS
	m.activities = {} --running stuff
	m.currentActivity = false
	local vChip = gdt.VideoChip0
	m.view = View:new{
		x=1, y=1,
		width = vChip.Width,
		height = vChip.Height,
		vChip = vChip,
		label = "GGOS-full"
	}
	
	GGOS._loadGames()
end

function GGOS._loadGames()
  
	cprint(ansiColor.lime,"Loading games...")
	local n = 0
	for i,game in ipairs( GAME_REGISTRY ) do
		cprint(ansiColor.darkGreen," [GGOS] Loading '"..game.."'")
		local ok, Activity = 
			         pcall(require,game..".lua")
		
		if not ok then
			--due to a bug, calling an RG function after an error caught by pcall will prevent code from continuing...
			--print used to show error until bug fixd
			print( "missing resource: "..game..", check spelling" )
			print( Activity )
			--cprint(ansiColor.red,"missing resource: "..game)
		else
		  local inst = Activity:new{
			  os = GGOS,
				view = GGOS.view:subView{
					lbl=Activity:className()
				}
		  }
		  GGOS.games[ game ] = inst
		  n+=1
	  end
	end
	cprint(ansiColor.gray, n.." titles loaded")
end

function GGOS.run( activity, ... )
	if not GGOS.activities[ activity ] then
		GGOS._start( activity, {
			os = GGOS,
			view = GGOS.view:subView{lbl=activity}
		}, ... )
	end
	if GGOS.currentActivity then
		if GGOS.currentActivity == activity then
			return
		end
		GGOS.getActivity():onUnfocus()
	end
	GGOS.currentActivity = activity
	GGOS.view:clear()
	GGOS.getActivity():onFocus()
end

function GGOS._start( activity:string, newArgs:{}, ... )
	local prgm=GGOS.games[activity]
	         or require(activity..".lua")
	if not prgm then
	  error("GGOS._start, could not get pgrm '"..activity.."'")
	end
	GGOS.activities[ activity ]=prgm:new(newArgs)
	GGOS.getActivity( activity ):onInit( ... )
	
end

function GGOS.getActivity( activ:string|nil )
	return
	  GGOS.activities[ activ or     
	              GGOS.currentActivity]
end

function GGOS.update()
	if retroUtils.isHome() then
	  print("Home")
		GGOS.run( GGOS.homeActivity )
	end
	local activity = GGOS.getActivity()
	if activity then
		activity:onUpdate()
	else
		print("No activity...")
		sleep(30)
	end
end

return GGOS