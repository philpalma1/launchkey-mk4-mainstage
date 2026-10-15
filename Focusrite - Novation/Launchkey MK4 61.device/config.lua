DEVICE_NAME = 'Launchkey MK4 61'
DEVICE_PID = 0x14 -- MK4 full-size SKUs (25/37/49/61/88). Mini SKUs use 0x13.
HAS_FADERS = true
-- !! VERIFY: these must match the DAW port endpoint names that macOS shows for the MK4
-- (Audio MIDI Setup > MIDI Studio > Launchkey MK4 61 > Ports, or MIDI Monitor's source list).
DAW_IN = 'DAW In'
DAW_OUT = 'DAW Out'

-- SysEx helpers ---------------------------------------------------------------
-- sx(...) builds F0 00 20 29 02 <PID> <...> F7 as a flat table.
function sx(...)
	local m = {0xF0, 0x00, 0x20, 0x29, 0x02, DEVICE_PID}
	for _, v in ipairs({...}) do
		table.insert(m, v)
	end
	table.insert(m, 0xF7)
	return m
end

function append(dst, src)
	for _, v in ipairs(src) do
		table.insert(dst, v)
	end
	return dst
end

-- MK4 display targets / commands (Programmer's Reference, "Controlling the screen")
DISPLAY_STATIONARY = 0x20
CMD_CONFIGURE_DISPLAY = 0x04
CMD_SET_TEXT = 0x06
CFG_CANCEL = 0x00
CFG_TRIGGER = 0x7F
CFG_NAME_VALUE_TEXT = 0x61 -- arrangement 1 (Name + text Value), auto temp-display on change/touch
CFG_TITLE_NAME_VALUE = 0x02 -- arrangement 2 (Title / Name / Value)

-- While a fader/encoder is moving, only refresh its screen text when the control has moved at
-- least this many steps (0-127) since the last refresh. 1 = every step (most precise, but a fast
-- sweep can flood the screen and make it lag); 2-4 = fewer messages, so it keeps up better.
-- The two ends (0 and 127) always update.
PARAM_STEP = 1

-- The MK4 screen fits 16 characters per line, and the 3-line layout has three text fields.
LINE_CHARS = 16

-- Word-wrap text into at most 3 lines of LINE_CHARS characters (ASCII only).
-- Anything that still doesn't fit is abbreviated with string.crunch().
function wrap_text(text)
	text = string.gsub(text, "[^\032-\126]", "")
	if #text > LINE_CHARS * 3 then
		text = string.crunch(text, LINE_CHARS * 3)
	end
	local lines = {}
	local line = ""
	for word in string.gmatch(text, "%S+") do
		while #word > LINE_CHARS do
			if line ~= "" then
				table.insert(lines, line)
				line = ""
			end
			table.insert(lines, string.sub(word, 1, LINE_CHARS))
			word = string.sub(word, LINE_CHARS + 1)
		end
		if line == "" then
			line = word
		elseif #line + 1 + #word <= LINE_CHARS then
			line = line .. " " .. word
		else
			table.insert(lines, line)
			line = word
		end
	end
	if line ~= "" then
		table.insert(lines, line)
	end
	-- wasted space at word breaks can still push us past 3 lines: abbreviate the tail
	if #lines > 3 then
		local rest = table.concat(lines, " ", 3)
		lines = {lines[1], lines[2], string.crunch(rest, LINE_CHARS)}
	end
	return lines
end

-- Returns the three field texts {title, name, value}. One line sits on the middle line;
-- two lines use the middle and bottom; three lines use all of them.
function patch_lines(text)
	local lines = wrap_text(text)
	local out = {" ", " ", " "}
	if #lines == 1 then
		out[2] = lines[1]
	elseif #lines == 2 then
		out[2] = lines[1]
		out[3] = lines[2]
	elseif #lines >= 3 then
		out = {lines[1], lines[2], lines[3]}
	end
	return out
end

controls = {
	{name='Keyboard', label=DEVICE_NAME, objectType='Keyboard', midiType='Keyboard', startKey=36, numberKeys=61, midi={0x90,MIDI_Wildcard,MIDI_Wildcard}},
	{name='Pitch Bend', label='Pitch', objectType='Wheel', midi={0xE0,MIDI_MSB,MIDI_LSB}},
	{name='Modulation', label='Mod', objectType='Wheel', midi={0xB0,0x01,MIDI_LSB}},
	{name='Sustain Pedal', label='Sustain', objectType='Sustain Pedal', midiType='Momentary', midi={0xB0,0x40,MIDI_LSB}},
	--{name='Expression Pedal', label='Expr', objectType='Pedal', midi={0xB0,0x0B,MIDI_LSB}},
	
	{name='Master Fader', inport=DAW_OUT, outport=DAW_IN, objectType='VFader', midi={0xBF,0x0D,MIDI_LSB}},
	
	{name='Knob 1', inport=DAW_OUT, outport=DAW_IN, objectType='Knob', midi={0xBF,0x15,MIDI_LSB}},
	{name='Knob 2', inport=DAW_OUT, outport=DAW_IN, objectType='Knob', midi={0xBF,0x16,MIDI_LSB}},
	{name='Knob 3', inport=DAW_OUT, outport=DAW_IN, objectType='Knob', midi={0xBF,0x17,MIDI_LSB}},
	{name='Knob 4', inport=DAW_OUT, outport=DAW_IN, objectType='Knob', midi={0xBF,0x18,MIDI_LSB}},
	{name='Knob 5', inport=DAW_OUT, outport=DAW_IN, objectType='Knob', midi={0xBF,0x19,MIDI_LSB}},
	{name='Knob 6', inport=DAW_OUT, outport=DAW_IN, objectType='Knob', midi={0xBF,0x1A,MIDI_LSB}},
	{name='Knob 7', inport=DAW_OUT, outport=DAW_IN, objectType='Knob', midi={0xBF,0x1B,MIDI_LSB}},
	{name='Knob 8', inport=DAW_OUT, outport=DAW_IN, objectType='Knob', midi={0xBF,0x1C,MIDI_LSB}},
	
	{name='Fader 1', inport=DAW_OUT, outport=DAW_IN, objectType='VFader', midi={0xBF,0x05,MIDI_LSB}},
	{name='Fader 2', inport=DAW_OUT, outport=DAW_IN, objectType='VFader', midi={0xBF,0x06,MIDI_LSB}},
	{name='Fader 3', inport=DAW_OUT, outport=DAW_IN, objectType='VFader', midi={0xBF,0x07,MIDI_LSB}},
	{name='Fader 4', inport=DAW_OUT, outport=DAW_IN, objectType='VFader', midi={0xBF,0x08,MIDI_LSB}},
	{name='Fader 5', inport=DAW_OUT, outport=DAW_IN, objectType='VFader', midi={0xBF,0x09,MIDI_LSB}},
	{name='Fader 6', inport=DAW_OUT, outport=DAW_IN, objectType='VFader', midi={0xBF,0x0A,MIDI_LSB}},
	{name='Fader 7', inport=DAW_OUT, outport=DAW_IN, objectType='VFader', midi={0xBF,0x0B,MIDI_LSB}},
	{name='Fader 8', inport=DAW_OUT, outport=DAW_IN, objectType='VFader', midi={0xBF,0x0C,MIDI_LSB}},
	
	{name='Track Left', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x67,MIDI_LSB}},
	{name='Track Right', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x66,MIDI_LSB}},
	{name='Scene Up', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x6A,MIDI_LSB}},
	{name='Scene Down', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x6B,MIDI_LSB}},
	
	{name='Button 1', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x25,MIDI_LSB}},
	{name='Button 2', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x26,MIDI_LSB}},
	{name='Button 3', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x27,MIDI_LSB}},
	{name='Button 4', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x28,MIDI_LSB}},
	{name='Button 5', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x29,MIDI_LSB}},
	{name='Button 6', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x2A,MIDI_LSB}},
	{name='Button 7', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x2B,MIDI_LSB}},
	{name='Button 8', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x2C,MIDI_LSB}},
	{name='Arm/Select', inport=DAW_OUT, outport=DAW_IN, objectType='Button', midiType='Momentary', midi={0xBF,0x2D,MIDI_LSB}},
	
	{name='Drum Pads', label='Drum Pads', inport=DAW_OUT, outport=DAW_IN, objectType='Keyboard', midiType='Keyboard', startKey=36, numberKeys=24, midi={0x99,MIDI_Wildcard,MIDI_Wildcard}},
	{name='Drum Pad 1', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x28,MIDI_LSB}},
	{name='Drum Pad 2', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x29,MIDI_LSB}},
	{name='Drum Pad 3', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x2A,MIDI_LSB}},
	{name='Drum Pad 4', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x2B,MIDI_LSB}},
	{name='Drum Pad 5', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x30,MIDI_LSB}},
	{name='Drum Pad 6', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x31,MIDI_LSB}},
	{name='Drum Pad 7', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x32,MIDI_LSB}},
	{name='Drum Pad 8', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x33,MIDI_LSB}},
	{name='Drum Pad 9', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x24,MIDI_LSB}},
	{name='Drum Pad 10', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x25,MIDI_LSB}},
	{name='Drum Pad 11', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x26,MIDI_LSB}},
	{name='Drum Pad 12', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x27,MIDI_LSB}},
	{name='Drum Pad 13', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x2C,MIDI_LSB}},
	{name='Drum Pad 14', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x2D,MIDI_LSB}},
	{name='Drum Pad 15', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x2E,MIDI_LSB}},
	{name='Drum Pad 16', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x99,0x2F,MIDI_LSB}},
	
	{name='Pad 1', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x60,MIDI_LSB}},
	{name='Pad 2', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x61,MIDI_LSB}},
	{name='Pad 3', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x62,MIDI_LSB}},
	{name='Pad 4', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x63,MIDI_LSB}},
	{name='Pad 5', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x64,MIDI_LSB}},
	{name='Pad 6', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x65,MIDI_LSB}},
	{name='Pad 7', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x66,MIDI_LSB}},
	{name='Pad 8', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x67,MIDI_LSB}},
	{name='Pad 9', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x70,MIDI_LSB}},
	{name='Pad 10', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x71,MIDI_LSB}},
	{name='Pad 11', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x72,MIDI_LSB}},
	{name='Pad 12', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x73,MIDI_LSB}},
	{name='Pad 13', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x74,MIDI_LSB}},
	{name='Pad 14', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x75,MIDI_LSB}},
	{name='Pad 15', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x76,MIDI_LSB}},
	{name='Pad 16', inport=DAW_OUT, outport=DAW_IN, objectType='Drumpad', midiType='Note', midi={0x90,0x77,MIDI_LSB}},
}

function controller_info()
	if not HAS_FADERS then
		for i=#controls,1,-1 do
			if string.sub(controls[i].name, 1, 6) == 'Button' or string.sub(controls[i].name, 1, 5) == 'Fader' or controls[i].name == 'Arm/Select' then
				table.remove(controls, i)
			end
		end
	end
	return {
		model = DEVICE_NAME,
		manufacturer = 'Focusrite - Novation',
		copyright = "Copyright © 2021 Michael Kuron",
		items =  controls,
	}
end

function controller_initialize(appName, deviceNewlyDetected)
	local m = {
		-- DAW Mode
		0x9f, 0x0c, 0x7f, -2,
		-- surface modes (CC on channel 7, DAW port)
		0xb6, 0x54, 0x01, -2, -- let the DAW own the drum pads (colours + notes on the DAW port)
		0xb6, 0x1d, 0x01, -2, -- pads: drum layout
		0xb6, 0x1e, 0x02, -2, -- encoders: plugin  (CC 0x15-0x1C on channel 16)
		0xb6, 0x1f, 0x01, -2, -- faders: volume    (CC 0x05-0x0D on channel 16)
	}
	-- stationary display: 3-line layout, only the middle line (Name) is used for the patch name
	append(m, sx(CMD_CONFIGURE_DISPLAY, DISPLAY_STATIONARY, CFG_TITLE_NAME_VALUE))
	append(m, sx(CMD_SET_TEXT, DISPLAY_STATIONARY, 0, " "))
	append(m, sx(CMD_SET_TEXT, DISPLAY_STATIONARY, 1, " "))
	append(m, sx(CMD_SET_TEXT, DISPLAY_STATIONARY, 2, " "))
	append(m, sx(CMD_CONFIGURE_DISPLAY, DISPLAY_STATIONARY, CFG_TRIGGER))
	return {midi = m, outport = DAW_IN}
end

function controller_finalize()
	return { midi = {0x9f, 0x0c, 0x00}, outport = DAW_IN}
end

function controller_midi_in(midi, port)
	-- make sure the echoed activation message doesn't mess up the chord display
	if (port == DAW_OUT) and (midi[0] == 0x9f) and (midi[1] == 0x0c) then 
		return {}
	end
	return nil
end

function controller_names(channel)
	if channel == 15 then
		names = {
			[0x33] = "Device Select",
			[0x34] = "Device Lock",
			[0x4A] = "Capture MIDI",
			[0x4B] = "Quantize",
			[0x4C] = "Click",
			[0x4D] = "Undo",
			[0x73] = "Play",
			[0x74] = "Stop",
			[0x75] = "Record",
			[0x76] = "Loop",
		}
		for _,control in pairs(controls) do
			if control["inport"] == DAW_OUT and control["midi"][1] == 0xBF then
				names[control["midi"][2]] = control["name"]
			end
		end
		
		return names
	elseif channel == 0 then
		return {
			[0x01] = "Modulation",
			[0x0B] = "Expression",
			[0x40] = "Sustain",
			[0x6C] = "Shift",
			[0x68] = "Session",
			[0x69] = "Stop/Solo/Mute",
		}
	else
		return nil
	end
end

old_patch = ""
updateObjectsAfterPatchChange = {}
function controller_select_patch(programchangeNumber, patchname, setname, concertname, patchlist, currentSetIndex, currentPatchIndex)
	new_patch = patchname .. setname .. concertname
	if new_patch == old_patch then
		return {}
	end
	old_patch = new_patch

	-- show the patch name on the stationary display, word-wrapped across its three lines
	event = {}
	local pl = patch_lines(patchname)
	for f=0,2 do
		append(event, sx(CMD_SET_TEXT, DISPLAY_STATIONARY, f, pl[f+1]))
	end
	append(event, sx(CMD_CONFIGURE_DISPLAY, DISPLAY_STATIONARY, CFG_TRIGGER))

	if HAS_FADERS then
		-- turn off fader-button LEDs (MK4: colour/off for CC-type LEDs goes on channel 1, status 0xB0)
		for i=0x25,0x2d do
			updateObjectsAfterPatchChange[0xBF * 0x100 + i] = {midi={0xB0, i, 0x00}, outport=DAW_IN}
		end
	end
	-- turn off pad LEDs
	for i=0x24,0x33 do
		updateObjectsAfterPatchChange[0x99 * 0x100 + i] = {midi={0x99, i, 0x00}, outport=DAW_IN}
	end
	-- cancel per-control name/value displays (target == the control's CC number); the
	-- Launchkey falls back to its default numeric readout until MainStage reports a new name.
	for cc=0x15,0x1C do
		updateObjectsAfterPatchChange[0xBF * 0x100 + cc] = {midi=sx(CMD_CONFIGURE_DISPLAY, cc, CFG_CANCEL), outport=DAW_IN}
		labelDisplayCache[cc] = nil
		valueDisplayCache[cc] = nil
		lastSentValue[cc] = nil
	end
	if HAS_FADERS then
		for cc=0x05,0x0D do
			updateObjectsAfterPatchChange[0xBF * 0x100 + cc] = {midi=sx(CMD_CONFIGURE_DISPLAY, cc, CFG_CANCEL), outport=DAW_IN}
			labelDisplayCache[cc] = nil
			valueDisplayCache[cc] = nil
			lastSentValue[cc] = nil
		end
	end
	return {midi=event, outport=DAW_IN}
end

function controller_select_patch_done(programchangeNumber, patchname, setname, concertname)
	return updateObjectsAfterPatchChange
end

COLORS = {0x616161, 0xB3B3B3, 0xDDDDDD, 0xFFFFFF, 0xFFB3B3, 0xFF6161, 0xDD6161, 0xB36161, 0xFFF3D5, 0xFFB361, 0xDD8C61, 0xB37661, 0xFFEEA1, 0xFFFF61, 0xDDDD61, 0xB3B361, 0xDDFFA1, 0xC2FF61, 0xA1DD61, 0x81B361, 0xC2FFB3, 0x61FF61, 0x61DD61, 0x61B361, 0xC2FFC2, 0x61FF8C, 0x61DD76, 0x61B36B, 0xC2FFCC, 0x61FFCC, 0x61DDA1, 0x61B381, 0xC2FFF3, 0x61FFE9, 0x61DDC2, 0x61B396, 0xC2F3FF, 0x61EEFF, 0x61C7DD, 0x61A1B3, 0xC2DDFF, 0x61C7FF, 0x61A1DD, 0x6181B3, 0xA18CFF, 0x6161FF, 0x6161DD, 0x6161B3, 0xCCB3FF, 0xA161FF, 0x8161DD, 0x7661B3, 0xFFB3FF, 0xFF61FF, 0xDD61DD, 0xB361B3, 0xFFB3D5, 0xFF61C2, 0xDD61A1, 0xB3618C, 0xFF7661, 0xE9B361, 0xDDC261, 0xA1A161, 0x61B361, 0x61B38C, 0x618CD5, 0x6161FF, 0x61B3B3, 0x8C61F3, 0xCCB3C2, 0x8C7681, 0xFF6161, 0xF3FFA1, 0xEEFC61, 0xCCFF61, 0x76DD61, 0x61FFCC, 0x61E9FF, 0x61A1FF, 0x8C61FF, 0xCC61FC, 0xEE8CDD, 0xA17661, 0xFFA161, 0xDDF961, 0xD5FF8C, 0x61FF61, 0xB3FFA1, 0xCCFCD5, 0xB3FFF6, 0xCCE4FF, 0xA1C2F6, 0xD5C2F9, 0xF98CFF, 0xFF61CC, 0xFFC261, 0xF3EE61, 0xE4FF61, 0xDDCC61, 0xB3A161, 0x61BA76, 0x76C28C, 0x8181A1, 0x818CCC, 0xCCAA81, 0xDD6161, 0xF9B3A1, 0xF9BA76, 0xFFF38C, 0xE9F9A1, 0xD5EE76, 0x8181A1, 0xF9F9D5, 0xDDFCE4, 0xE9E9FF, 0xE4D5FF, 0xB3B3B3, 0xD5D5D5, 0xF9FFFF, 0xE96161, 0xAA6161, 0x81F661, 0x61B361, 0xF3EE61, 0xB3A161, 0xEEC261, 0xC27661}
GREYS = {[0x00] = 0x61, [0x01] = 0xB3, [0x02] = 0xDD, [0x03] = 0xFF}

function redmean2(r1, g1, b1, r2, g2, b2)
	rb = (r1+r2)/2
	dR = r1-r2
	dG = g1-g2
	dB = b1-b2
	
	return (2+rb/256)*dR*dR + 4*dG*dG + (2+(255-rb)/256)*dB*dB
end

color_map = {}
function find_nearest_color_id(color)
	if color_map[color] ~= nil then
		return color_map[color]
	end
	
	offset = GREYS[0x00]
	
	r = bit32.band(color, 0xFF0000) / 0x10000
	g = bit32.band(color, 0x00FF00) / 0x100
	b = bit32.band(color, 0x0000FF)
	
	best_dist2 = 0xffffffffffff
	color_id = -1
	
	if math.abs(r-g) <= 4 and math.abs(g-b) <= 4 then
		for i, k in pairs(GREYS) do
			k = (k - offset) / (0xFF - offset) * 0xff
			
			dist2 = (r - k)*(r - k)
			if dist2 < best_dist2 then
				best_dist2 = dist2
				color_id = i
			end
		end
	else
		for i,c in pairs(COLORS) do
			r2 = bit32.band(c, 0xFF0000) / 0x10000
			g2 = bit32.band(c, 0x00FF00) / 0x100
			b2 = bit32.band(c, 0x0000FF)
			
			r2 = (r2 - offset) / (0xFF - offset) * 0xff
			g2 = (g2 - offset) / (0xFF - offset) * 0xff
			b2 = (b2 - offset) / (0xFF - offset) * 0xff
		
			dist2 = redmean2(r, g, b, r2, g2, b2)
			if dist2 < best_dist2 then
				best_dist2 = dist2
				color_id = i-1
			end
		end
	end
	
	color_map[color] = color_id
	return color_id
end

valueDisplayCache = {}
labelDisplayCache = {}

-- MK4: the display target for an encoder/fader is simply its CC number.
-- First time a name is seen (or when it changes) configure the display, then set name + value;
-- afterwards only the value line (field 1) is rewritten.
lastSentValue = {}
function show_parameter(cc, name, valueString, ccValue)
	name = string.gsub(name, "⅓", " 1/3")
	name = string.gsub(name, "⅗", " 3/5")
	name = string.gsub(name, "⅔", " 2/3")
	if name == labelDisplayCache[cc] and valueString == valueDisplayCache[cc] then
		return nil
	end
	if type(ccValue) == "number" and name == labelDisplayCache[cc] and ccValue ~= 0 and ccValue ~= 127 then
		local last = lastSentValue[cc]
		if last ~= nil and math.abs(ccValue - last) < PARAM_STEP then
			return nil
		end
	end
	lastSentValue[cc] = ccValue
	val = string.gsub(valueString, "㏈", "dB")
	val = string.gsub(val, "∞", "oo")
	val = string.gsub(val, "㎳", "ms")
	val = string.gsub(val, "㎐", "Hz")
	local ev = {}
	local nameChanged = (name ~= labelDisplayCache[cc])
	if nameChanged then
		append(ev, sx(CMD_CONFIGURE_DISPLAY, cc, CFG_NAME_VALUE_TEXT))
		append(ev, sx(CMD_SET_TEXT, cc, 0, string.crunch(name, 16)))
		labelDisplayCache[cc] = name
	end
	append(ev, sx(CMD_SET_TEXT, cc, 1, string.crunch(val, 16)))
	if not nameChanged then
		-- value-only update (e.g. while a fader/encoder is being moved): re-trigger the temporary
		-- display so a display that is already up redraws with the new text instead of keeping
		-- the text from when the movement started. Skipped when the name changes (first use after
		-- a patch change) so patch-change feedback doesn't cover the patch name.
		append(ev, sx(CMD_CONFIGURE_DISPLAY, cc, CFG_TRIGGER))
	end
	valueDisplayCache[cc] = valueString
	updateObjectsAfterPatchChange[0xBF * 0x100 + cc] = nil
	return {midi=ev, outport=DAW_IN}
end

function controller_midi_out(midiEvent, name, valueString, color)
	if midiEvent[0] == 0xBF then
		local cc = midiEvent[1]
		if cc >= 0x15 and cc <= 0x1C then
			-- encoders
			return show_parameter(cc, name, valueString, midiEvent[2])
		elseif HAS_FADERS and cc >= 0x05 and cc <= 0x0D then
			-- faders + master fader
			return show_parameter(cc, name, valueString, midiEvent[2])
		elseif HAS_FADERS and cc >= 0x25 and cc <= 0x2D then
			-- fader buttons: on the MK4 the LED is coloured by a CC on channel 1 (status 0xB0) with the
			-- same CC number as the button; the value is a palette index (0 = off).
			updateObjectsAfterPatchChange[0xBF * 0x100 + cc] = nil
			local idx = 0
			if midiEvent[2] ~= nil and midiEvent[2] > 0 then
				if color ~= nil then
					idx = find_nearest_color_id(math.floor(color.r * 0xFF) * 0x10000 + math.floor(color.g * 0xFF) * 0x100 + math.floor(color.b * 0xFF))
				else
					idx = 3 -- white
				end
			end
			return {midi={0xB0, cc, idx}, outport=DAW_IN}
		end
	-- color the drum pads
	elseif midiEvent[0] == 0x99 then
		colorcode = find_nearest_color_id(math.floor(color.r * 0xFF) * 0x10000 + math.floor(color.g * 0xFF) * 0x100 + math.floor(color.b * 0xFF))
		event = {0x99, midiEvent[1], colorcode}
		updateObjectsAfterPatchChange[0x99 * 0x100 + midiEvent[1]] = nil
		return {midi=event, outport=DAW_IN}
	end
	return nil
end
