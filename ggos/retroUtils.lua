local retroUtils = {}

function retroUtils.cpuTime()
	return gdt.CPU0.Time
end

local prevDPad = {
  up={state=false,since=retroUtils.cpuTime()},
  down={state=false,since=retroUtils.cpuTime()},
  left={state=false,since=retroUtils.cpuTime()},
  right={state=false,since=retroUtils.cpuTime()}
}
local function state(name,after)
	local before = prevDPad[ name ].state
	local since = prevDPad[ name ].since
	local now = retroUtils.cpuTime()
	prevDPad[name].state = after
	if before and after then
		return {
			buttonDown=false,
			buttonState=true,
			buttonUp=false,
			seconds=now-since
		}
	elseif before and (not after) then
		prevDPad[ name ].since=now
		return {
			butonDown=false,
			buttonState=false,
			buttonUp=true,
			seconds=0
		}
	elseif (not before) and after then
		prevDPad[ name ].since=now
		return {
			buttonDown=true,
			buttonState=true,
			buttonUp=false,
			seconds = 0
		}
	else
		return {
			buttonDown=false,
			buttonState=false,
			buttonUp=false,
			seconds=now-since
		}
	end
end
function retroUtils.dpad()
	local up = gdt.DPad1.Y > 0
	local down = gdt.DPad1.Y < 0
	local left = gdt.DPad1.X < 0
	local right = gdt.DPad1.X > 0
	local now = {
		up   =state("up", up),
		down =state("down",down),
		left =state("left",left),
		right=state("right",right)
	}
	
	return now
end

function retroUtils.button()
	return {
		a = gdt.LedButton1,
		b = gdt.LedButton0,
		x = gdt.LedButton3,
		y = gdt.LedButton2,
		["1"] = gdt.LedButton9,
		["2"] = gdt.LedButton8,
		lb = gdt.LedButton7,
		rb = gdt.LedButton6,
		start=gdt.LedButton4,
		select=gdt.LedButton5
	}
end

function retroUtils.isHome()
	return gdt.LedButton10.ButtonDown
end

function retroUtils.axis()
	return {
		leftAnalog = gdt.Stick0,
		rightAnalog = gdt.Stick1,
		lt = false, --TODO
		rt = false  --TODO
	}
end

function retroUtils.inputs()
	return {
		axis = retroUtils.axis(),
		button = retroUtils.button(),
		dpad = retroUtils.dpad()
	}
end

function retroUtils.stopAllAudio()
	local cc = gdt.AudioChip0.ChannelsCount
	for i=1,cc do
		gdt.AudioChip0:Stop(cc)
	end
end

function retroUtils.screenSize()
	return gdt.VideoChip0.Width, gdt.VideoChip0.Height
end

return retroUtils