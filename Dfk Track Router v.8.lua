--dofile("C:/REAPER/Scripts/Dfk_Functions.lua") 
function msg() end function up() reaper.UpdateTimeline() reaper.UpdateArrange() end 
local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context() 
local startofit, endofit = string.find(filename, "Dfk Track Router v.8.lua")

dofile(string.sub(filename, 1, startofit-1).."Dfk_GUI_Functions.lua") 


--[[
NAME: Dfk's Track Router

CATEGORY OF USE: Project Workflow
AUTHOR: Dafarkias
LICENSE: GPL v.3
COCKOS REAPER THREAD: https://forum.cockos.com/showthread.php?t=227202
]]local VERSION = ".8"--[[
REAPER: 6.02 (version used in development)
EXTENSIONS: js_ReaScriptAPI v0.993 (version used in development), SWS/S&M 2.10.0 (version used in development)

[v0.5] 
	*(script release)
[v0.6]
	*Track colors now update into the script within .3 seconds.
	*Added 'S' and 'R' to track send and receive buttons for clarification.
	*Shift+left-click can now drag-scroll, just like middle-mouse-click.
[v0.61]
	*Worked on issue with track updating.
	*Menu options for track-box title and for main grid. Access with right-click.
[v0.7]
	*Parent-send now works in similtude to regular send: volume can be adjusted.
[v0.75]
	*Early stages of marquee-selection added. Current menu features updated to accomodate multi-selection.
[v0.8]
	*Corrected script handling of send receive button usage. 
	*Added MIDI/audio menu options to track menu and send menu (right-click).
	*Various improvements. 
	
	
--]]

--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA
--
local Pin_window                   = true    -- true/false 
local Crosshair_Size               = 15      -- 0+: 15
local Crosshair_Visibility         = .3      -- 0-1: .3
local Connection_Sends_Alpha       = .3      -- 0-1: .3
local Connection_Parents_Alpha     = .1      -- 0-1: .2
--
--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA

--global vars
script_name = "Dfk's Track Router v"..VERSION -- must be a global to interact with the gui library 
window      = 0              --set in function init()

-- window vars
local _,_,display_width,display_height = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true )
local window_xMin, window_xMax = 400, 20000
local window_yMin, window_yMax = 400, display_height
local window_zoom = 1 -- multiplication

-- project vars
local track_limit = 100
local grid_snap = false
local project_name = script_name.." v"..VERSION
local project_tracks = 0
local scrollGrab_x, scrollGrab_y, marquee_x, marquee_y = -1, -1, nil, nil 
local selectionMove = {x = {}, y = {}, o = {}}
local grid_size = 100
local grid_h    = 25
local grid_w    = 25

-- misc vars
local insert_x, insert_y, insert_name = nil, nil, nil
local update = {time = 0, delay = .3} 
local connector = {time = 0, delay = .1}
local folder, binary_folder = true, true

local channel_table = {[1] = 2, [2] = 4, [3] = 6, [4] = 8, [5] = 10, [6] = 12, [7] = 14, [8] = 16, [9] = 20, [10] = 24, [11] = 28, [12] = 32, [13] = 36, [14] = 40, [15] = 48, [16] = 56, [17] = 64}

if binary_folder == true then
	local oct2bin = {
		['0'] = '000',
		['1'] = '001',
		['2'] = '010',
		['3'] = '011',
		['4'] = '100',
		['5'] = '101',
		['6'] = '110',
		['7'] = '111'
	}
	function getOct2bin(a) return oct2bin[a] end
	function DecToBin(n)
		local s = string.format('%o', n)
		s = s:gsub('.', getOct2bin)
		return s
	end
end

function create_box( o, track, xer, yer, master, collapsed_state ) local returner = false

	local tname_retval, tname_buf = reaper.GetTrackName( track ) 
	local height = 100 if collapsed_state == "true" then collapsed_state = true height = 20 else collapsed_state = nil end msg(collapsed_state)
	if insert_x then xer = insert_x insert_x = nil end
	if insert_y then yer = insert_y insert_y = nil end
	if insert_name then reaper.GetSetMediaTrackInfo_String( track, "P_NAME", insert_name , 1) tname_buf = insert_name insert_name = nil end

	if folder then 
	--TRACK OBJECTS-------------------------------------------------------------------------
	gui[2].obj[o] =  {
	  id    = 1,            -- identifies object for looped-processing
	  caption = "R: menu, Shf+L: add to selection",
	  level = o,
	  hc    = 0,            -- current hover alpha (default '0')
	  ha    = .05,          -- hover alpha
	  hca   = .1,           -- hover click alpha 
	  ol    = {r=.7,g=.7,b=.7,a=1}, -- rect: button's outline ol    
	  r     = .3,           -- rect: red
	  g     = .3,            -- rect: green
	  b     = .3,           -- rect: blue
	  a     = .8,           -- rect: alpha
	  f     = 1,            -- rect: filled  
	  x     = xer,
	  y     = yer,
	  w     = 100,
	  h     = height,
	  can_zoom = true,
	  can_scroll = true,
	  blur_under = true,                  
	  button = {},
	  static = {},
	  collapsed = collapsed_state,
	  func = 
	  {
	  --[0] = function(o,r) if r then msg("release") return end  end, 
	  [1] = 
	  function(self,o,r,d) 

			if r 
		then 
			msg("release") 
			selectionMove.x, selectionMove.y = {}, {} 
			return 
		end
		
		  if d 
		then 
		  if not self.sel then for z = 1, #gui[2].obj do gui[2].obj[z].sel = nil end self.sel = true end
		  return 
		end
		
		if not self.sel then for z = 1, #gui[2].obj do gui[2].obj[z].sel = nil end self.sel = true end update.time = 0
		
		-- first click
			if #selectionMove.x < 1 
		then 
			selectionMove.x, selectionMove.y = {}, {} 
				for z = 1, #gui[2].obj 
			do local xy = #selectionMove.x+1
				if gui[2].obj[z].sel then selectionMove.x[xy], selectionMove.y[xy], selectionMove.o[xy] = gui[2].obj[z].x, gui[2].obj[z].y, z end 
			end
		end
		-------------
			for z = 1, #selectionMove.x
		do 
			gui[2].obj[selectionMove.o[z]].x, gui[2].obj[selectionMove.o[z]].y = selectionMove.x[z]+((mx-mouseGrab_x)/V_Z), selectionMove.y[z]+((my-mouseGrab_y)/V_Z) 
			if gui[2].obj[selectionMove.o[z]].x < 0 then gui[2].obj[selectionMove.o[z]].x = 0 end if gui[2].obj[selectionMove.o[z]].y < 0 then gui[2].obj[selectionMove.o[z]].y = 0 end -- enforce grid 0s
			if gui[2].obj[selectionMove.o[z]].x > (grid_w*grid_size)-self.w then gui[2].obj[selectionMove.o[z]].x = (grid_w*grid_size)-self.w end 										-- enforce grid width
			if gui[2].obj[selectionMove.o[z]].y > (grid_h*grid_size)-self.h then gui[2].obj[selectionMove.o[z]].y = (grid_h*grid_size)-self.h end 										-- enforce grid height
		end
		
	  end,
	  [2] = function(self,o,r,d) if not gui[2].obj[o].sel then for z = 1, #gui[2].obj do gui[2].obj[z].sel = nil end gui[2].obj[o].sel = true end update.time = 0
		  if r 
		then msg("release")
			gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y local choice = gfx.showmenu("Rename track(s)|Set track color(s)|Set track(s) coordinates|Delete track(s)|>Set track(s) channels|2|4|6|8|10|12|14|16|20|24|28|32|36|40|48|56|<64"..
			"||Set send MIDI/audio channels for selected track(s)||Collapse/Uncollapse track(s)" )
				if choice == 1 --RENAME
			then
				if Pin_window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
				local nmretval, nmretvals_csv = reaper.GetUserInputs( "[Input]", 1, "Track name", gui[2].obj[o].track_name )
					if nmretval 
				then 
						for z = 1, #gui[2].obj
					do
						if gui[2].obj[z].sel then reaper.GetSetMediaTrackInfo_String( gui[2].obj[z].track, "P_NAME", tostring(nmretvals_csv) , 1) end 
					end
				end
				if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
				elseif choice == 2 --SET TRACK COLOR
			then
				local clrretval, track_color = reaper.GR_SelectColor( window ) 
					if clrretval 
				then 
						for z = 1, #gui[2].obj
					do
						if gui[2].obj[z].sel then reaper.SetTrackColor( gui[2].obj[z].track, track_color ) end 
					end
				end
				elseif choice == 3 -- SET COORDINATES
			then
				if Pin_window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
				local chretval, chretvals_csv = reaper.GetUserInputs( "[Input]", 2, "X,Y", tostring(math.floor(gui[2].obj[o].x))..","..tostring(math.floor(gui[2].obj[o].y)) )
				local ret_x, ret_y = chretvals_csv:match("([^,]+),([^,]+)")
					if type(tonumber(ret_x)) == 'number' and type(tonumber(ret_y)) == 'number'
				then 
						for z = 1, #gui[2].obj
					do
							if gui[2].obj[z].sel 
						then 
							gui[2].obj[z].x, gui[2].obj[z].y = tonumber(ret_x), tonumber(ret_y) 
							if gui[2].obj[z].x < 0 then gui[2].obj[z].x = 0 end if gui[2].obj[z].y < 0 then gui[2].obj[z].y = 0 end -- enforce grid 0s
							if gui[2].obj[z].x > (grid_w*grid_size)-gui[2].obj[z].w then gui[2].obj[z].x = (grid_w*grid_size)-gui[2].obj[z].w end 	-- enforce grid width
							if gui[2].obj[z].y > (grid_h*grid_size)-gui[2].obj[z].h then gui[2].obj[z].y = (grid_h*grid_size)-gui[2].obj[z].h end 	-- enforce grid height
						end 
					end
				end
				if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
				elseif choice == 4 -- DELETE TRACKS
			then
					for z = 1, #gui[2].obj
				do
						if gui[2].obj[z].sel 
					then 
						reaper.DeleteTrack( gui[2].obj[z].track )
						returner = true
					end
				end 
				elseif choice > 4 and choice < 22 --SET TRACK CHANNELS
			then   
					for z = 1, #gui[2].obj
				do
						if gui[2].obj[z].sel 
					then msg(choice)
						reaper.SetMediaTrackInfo_Value( gui[2].obj[z].track, "I_NCHAN", channel_table[choice-4] ) 
					end
				end
				elseif choice == 22 -- SET SEND MIDI/AUDIO CHANNELS
			then
				-----------------------------------------------------------------------------------------------------------
				if Pin_window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
				
				local newretval, newretvals_csv = reaper.GetUserInputs( "[input]", 3, "Sending MIDI ch.,Receipt MIDI ch.,Audio ch.,Receipt audio ch.,extrawidth=50,separator=@", "(-1=none, 0=all, 1-16)@(-1=none, 0=all, 1-16)@(-1=none, 1-64)" )
				
				local result = {} local index = 1 for s in string.gmatch(newretvals_csv, "[^".."@".."]+") do result[index] = s index = index + 1 end
				
					for z = 1, #gui[2].obj
				do
						if gui[2].obj[z].sel
					then
							for s = 1, reaper.GetTrackNumSends( gui[2].obj[z].track, 0 ) 
						do
							
							local send_MIDI, rec_MIDI, aud = result[1], result[2], result[3] send_MIDI, rec_MIDI, aud = tonumber(send_MIDI), tonumber(rec_MIDI), tonumber(aud)
							local var = tostring( DecToBin( reaper.GetTrackSendInfo_Value( gui[2].obj[z].track, 0, s-1, "I_MIDIFLAGS" ) ) )

							if type(send_MIDI) ~= 'number' then send_MIDI = tonumber( string.sub( var, -5), 2 ) end
							if type(rec_MIDI) ~= 'number' then rec_MIDI = tonumber( string.sub( var, 1, var:len()-5 ), 2 ) end   
							if send_MIDI < -1 then send_MIDI = -1 end if send_MIDI > 16 then send_MIDI = 16 end
							if rec_MIDI < -1 then rec_MIDI = -1 end if rec_MIDI > 16 then rec_MIDI = 16 end
								if send_MIDI == -1 or rec_MIDI == -1 
							then 
								reaper.SetTrackSendInfo_Value( gui[2].obj[z].track, 0, s-1, "I_MIDIFLAGS", -1 ) 
							else
								msg("asdfffffffffffffffffffffffffffffffff")
								rec_MIDI = DecToBin(rec_MIDI) if rec_MIDI:len() > 5 then rec_MIDI = string.sub( rec_MIDI, -5 ) end
								send_MIDI = DecToBin(send_MIDI) while send_MIDI:len() < 5 do send_MIDI = "0"..send_MIDI end  if send_MIDI:len() > 5 then send_MIDI = string.sub( send_MIDI, -5 ) end
								reaper.SetTrackSendInfo_Value( gui[2].obj[z].track, 0, s-1, "I_MIDIFLAGS", tonumber(rec_MIDI..send_MIDI, 2) ) 
							end 

								if type(aud) == 'number' 
							then
								if aud < -1 then aud = -1 end if aud > 64 then aud = 64 end
								for x = 2, #channel_table do if aud <= channel_table[x] and aud > 2 then aud = channel_table[x] break end end 
									if reaper.GetMediaTrackInfo_Value( gui[2].obj[z].track, "I_NCHAN" ) < aud
								then
									local mb_input = reaper.MB( "Track contains less channels than your are attempting to assign this send.\n\nSet track channels to "..aud.."?", "[input]", 1 )
									if mb_input == 1 then reaper.SetMediaTrackInfo_Value( gui[2].obj[z].track, "I_NCHAN", aud ) else aud = -2 end 
								end
									if aud == -1
								then
									reaper.SetTrackSendInfo_Value( gui[2].obj[z].track, 0, s-1, "I_SRCCHAN", -1 ) 
									elseif aud == -2
								then
									-- nothing
									elseif aud == 1
								then
									reaper.SetTrackSendInfo_Value( gui[2].obj[z].track, 0, s-1, "I_SRCCHAN", 1024 ) 
									elseif aud == 2
								then
									reaper.SetTrackSendInfo_Value( gui[2].obj[z].track, 0, s-1, "I_SRCCHAN", 0 ) 
								else
									reaper.SetTrackSendInfo_Value( gui[2].obj[z].track, 0, s-1, "I_SRCCHAN", aud*512 ) 
								end
							end
							
						end -- for s (num of sends)
					end -- if sel
				end -- for z (obj)
				
				if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
				-----------------------------------------------------------------------------------------------------------
				elseif choice == 23 -- COLLAPSE TRACKS
			then
					for z = 1, #gui[2].obj
				do
						if gui[2].obj[z].sel or z == o
					then
						if not gui[2].obj[z].collapsed then gui[2].obj[z].h = 20 for a = 4, #gui[2].obj[z].button do gui[2].obj[z].button[a] = nil end gui[2].obj[z].collapsed = true update.time = 0 else gui[2].obj[z].collapsed = nil end 
					end
				end 
			end
			
		end -- if r
		
	  end, -- function[2] 
	  [3] = 
	  function(self,o,r,d) 
		if r then msg("release") return end  
		self.sel = true update.time = 0
	  end, 
	  },
	  mouse =
	  {
	  [1] = 1,
	  [2] = 2,
	  [3] = 9
	  },
	  hold = 
	  {
	  [1] = true,
	  [2] = false,
	  [3] = false
	  },
	  m_rel = 
	  {
	  [1] = nil,
	  [2] = nil,
	  [3] = 1
	  },
	  track = track,
	  track_name = tname_buf
	  }  
	--TRACK BOX TITLE-------------------------------------------------------------------------
	local cr, cg, cb = reaper.ColorFromNative( reaper.GetTrackColor( track ) ) cr,cg,cb = (cr/255)-(cr/510),(cg/255)-(cg/510),(cb/255)-(cb/510) --ensure colors aren't too bright
	gui[2].obj[o].button[1] = {
	  id    = 1,       -- identifies object for looped-processing
	  caption = "R: menu, Shf+L: add to selection, Dbl-L: un/collapse",
	  type  = "rect",  -- draw type: "rect" or "circ"
	  ol    = {r=0,g=0,b=0,a=1},  -- rect: button's outline
	  hc    = 0,       -- current hover alpha (default '0')
	  ha    = .1,      -- hover alpha
	  hca   = .2,      -- hover click alpha 
	  r     = cr,      -- r     (rect)
	  g     = cg,       -- g     (rect)
	  b     = cb,      -- b     (rect)
	  a     = .9,      -- alpha (rect)
	  rt    = 1,       -- r     (text)
	  gt    = 1,       -- g     (text)
	  bt    = 1,       -- b     (text)
	  at    = 1,       -- alpha (text)
	  x     = 0,       -- x
	  y     = 0,       -- y
	  w     = 100,     -- width
	  h     = 20,      -- height
	  f     = 1,       -- filled
	  txt   = "", -- text
	  th    = 1,       -- text 'h' flag
	  tv    = 4,       -- text 'v' flag  
	  fo    = "Arial", -- font settings will have no affect unless: font_changes = true
	  fs    = 12,      -- font size
	  ff    = "b",     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
	  can_zoom = true,
	  can_scroll = true,
	  static = 
	  {
		  [1] = 
		  {
			type       = "text",   -- draw type
			r          = 1,       -- r
			g          = 1,        -- g
			b          = 1,       -- b
			a          = 1,       -- a 
			txt        = gui[2].obj[o].track_name,    -- text
			x          = 20,        -- x
			y          = 0,        -- y
			w          = 60,      -- width that text is cropped to
			h          = 20,       -- height
			th         = 1,        -- text 'h' flag
			tv         = 4,        -- text 'v' flag	
			fo         = "Arial",  -- font settings will have no affect unless: font_changes = true
			fs         = 14,       -- font size
			ff         = "b",      -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
			can_zoom   = true,     -- whether static zooms with global: font_changes must be true in order for font size to adjust
			can_scroll = true     -- whether static scrolls with global
		  }
	  },
	  func  = 
	  { 
	  [0]   = 
	  function(self,o,b,r,d) 
			if r 
		then 
				for z = 1, #gui[2].obj
			do
					if gui[2].obj[z].sel or z == o
				then
					if not gui[2].obj[z].collapsed then gui[2].obj[z].h = 20 for a = 4, #gui[2].obj[z].button do gui[2].obj[z].button[a] = nil end gui[2].obj[z].collapsed = true update.time = 0 else gui[2].obj[z].collapsed = nil end 
				end
			end 
		end  
	  end, 
	  [1]   = 
	  function(self,o,b,r,d) 
		-- defer to main object's function
		gui[2].obj[o].func[1](gui[2].obj[o],o,r,d)
	  end,
	  [2]   = 
	  function(self,o,b,r,d) 
		-- defer to main object's function
		gui[2].obj[o].func[2](gui[2].obj[o],o,r,d)
	  end, 
	  [3]   = function(o,b,r) msg("Mclick") end
	  },
	  mouse =
	  {
	  [1]   = 1,
	  [2]   = 2,
	  [3]   = 64
	  },
	  hold  = 
	  {
	  [1]   = true,
	  [2]   = false,
	  [3]   = true
	  }
	  }   
	if returner == true then return end
	--RECEIVE BUTTON LINE-------------------------------------------------------------------------
	gui[2].obj[o].button[2] = {
		id    = -2,       -- identifies object for looped-processing
		caption = "L: disconnect sends of selected tracks",
		type  = "circ",  -- draw type: "rect" or "circ"
		ol    = {r=0,g=0,b=0,a=1},  -- rect: button's outline
		hc    = 0,       -- current hover alpha (default '0')
		ha    = .1,      -- hover alpha
		hca   = .2,      -- hover click alpha 
		r     = 1,       -- r     (rect)
		g     = 1,       -- g     (rect)
		b     = 0,       -- b     (rect)
		a     = .9,      -- alpha (rect)
		rt    = 1,       -- r     (text)
		gt    = 1,       -- g     (text)
		bt    = 1,       -- b     (text)
		at    = 0,       -- alpha (text)
		x     = 1,       -- x
		y     = 0,       -- y
		w     = 20,     -- width
		h     = 20,      -- height
		f     = 1,       -- filled
		rs         = 9,                                               -- circle: radius
		aa         = true,                                             -- circle: antialias    
		txt   = "",      -- text
		th    = 1,       -- text 'h' flag
		tv    = 4,       -- text 'v' flag  
		fo    = "Arial", -- font settings will have no affect unless: font_changes = true
		fs    = 12,      -- font size
		ff    = "b",     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
		can_zoom = true,
		can_scroll = true,
		static = 
		{
			[1] = 
				{
				-- GFX STATIC TEXT		  
				type       = "text",   -- draw type
				r          = 0,        -- r
				g          = 0,        -- g
				b          = 0,        -- b
				a          = 1,        -- a 
				txt        = "R",      -- text
				x          = 0,       -- x
				y          = 0,       -- y
				w          = 21,      -- width that text is cropped to
				h          = 21,       -- height
				th         = 1,        -- text 'h' flag
				tv         = 4,        -- text 'v' flag	
				fo         = "Arial",  -- font settings will have no affect unless: font_changes = true
				fs         = 22,       -- font size
				ff         = "b",      -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
				can_zoom   = true,     -- whether static zooms with global: font_changes must be true in order for font size to adjust
				can_scroll = true     -- whether static scrolls with global
				}
		},
		func  = 
		{ 
		--[0]   = function(o,b,r,d) end, 
		[1]   = 
		function(self,o,b,r,d)

				for z = 1, #gui[2].obj
			do  
					if gui[2].obj[z].sel 
				then	local tsnum = reaper.GetTrackNumSends( gui[2].obj[z].track, 0 )
						for a = tsnum, 1, -1
					do
							if reaper.GetTrackSendInfo_Value( gui[2].obj[z].track, 0, a-1, "P_DESTTRACK" ) == gui[2].obj[o].track 
						then 
							reaper.RemoveTrackSend( gui[2].obj[z].track, 0, a-1 ) hover[1], hover[2] = z, 3 sel_o, sel_b = z, 3
						end 
					end
				end
			end
		
		end,
		[2]   = function(o,b,r) msg("Rclick") end, 
		[3]   = function(o,b,r) msg("Mclick") end
		},
		mouse =
		{
		[1]   = 1,
		[2]   = 2,
		[3]   = 64
		},
		hold  = 
		{
		[1]   = true,
		[2]   = false,
		[3]   = true
		}
		}
	--SEND BUTTON-------------------------------------------------------------------------
	gui[2].obj[o].button[3] = {
		id    = -2,       -- identifies object for looped-processing
		caption = "L: create sends by connecting to a receive",
		type  = "circ",  -- draw type: "rect" or "circ"
		ol    = {r=0,g=0,b=0,a=1},  -- rect: button's outline
		hc    = 0,       -- current hover alpha (default '0')
		ha    = .1,      -- hover alpha
		hca   = .2,      -- hover click alpha 
		r     = 1,       -- r     (rect)
		g     = 1,       -- g     (rect)
		b     = 0,       -- b     (rect)
		a     = .9,      -- alpha (rect)
		rt    = 0,       -- r     (text)
		gt    = 0,       -- g     (text)
		bt    = 0,       -- b     (text)
		at    = 0,       -- alpha (text)
		x     = 80,       -- x
		y     = 0,       -- y
		w     = 20,     -- width
		h     = 20,      -- height
		f     = 1,       -- filled
		rs         = 9,                                               -- circle: radius
		aa         = true,                                             -- circle: antialias    
		txt   = "",      -- text
		th    = 1,       -- text 'h' flag
		tv    = 4,       -- text 'v' flag  
		fo    = "Arial", -- font settings will have no affect unless: font_changes = true
		fs    = 12,      -- font size
		ff    = "b",     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
		can_zoom = true,
		can_scroll = true,
		static = 
		{
			[1] = 
				{
				-- GFX STATIC TEXT		  
				type       = "text",   -- draw type
				r          = 0,        -- r
				g          = 0,        -- g
				b          = 0,        -- b
				a          = 1,        -- a 
				txt        = "S",      -- text
				x          = 80,       -- x
				y          = 0,       -- y
				w          = 19,      -- width that text is cropped to
				h          = 19,       -- height
				th         = 1,        -- text 'h' flag
				tv         = 4,        -- text 'v' flag	
				fo         = "Arial",  -- font settings will have no affect unless: font_changes = true
				fs         = 22,       -- font size
				ff         = "b",      -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
				can_zoom   = true,     -- whether static zooms with global: font_changes must be true in order for font size to adjust
				can_scroll = true     -- whether static scrolls with global
				}
		},
		func  = 
		{ 
		--[0]   = function(o,b,r,d) end, 
		[1]   = 
		function(self,o,b,r,d)  
		if not gui[2].obj[o].sel then for z = 1, #gui[2].obj do gui[2].obj[z].sel = nil end gui[2].obj[o].sel = true end
			for z = 1, #gui[2].obj
		do
				if gui[2].obj[z].sel
			then
					for a = -1, 1 
				do
					gui[2].obj[z].static[a+2] = {
						type       = "line",               -- draw type
						r          = 0,                    -- r
						g          = .3,                   -- g
						b          = 1,                    -- b
						a          = Connection_Sends_Alpha,                   -- a
						x          = 100,                   -- x
						y          = 10+a,                 -- y
						xx         = 100,                  -- x2
						yy         = 15,                   -- y2
						cc         = 1,                    -- bypass xx & yy processing
						aa         = 1,                    -- antialias
						can_zoom   = true,                 -- whether static zooms with global
						can_scroll = true                  -- whether static scrolls with global
						}
					gui[2].obj[z].static[a+5] = {
						type       = "line",               -- draw type
						r          = 0,                    -- r
						g          = .3,                   -- g
						b          = 1,                    -- b
						a          = Connection_Sends_Alpha,                   -- a
						x          = 100+a,                 -- x
						y          = 10,                   -- y
						xx         = 100,                  -- x2
						yy         = 15,                   -- y2
						cc         = 1,                    -- bypass xx & yy processing
						aa         = 1,                    -- antialias
						can_zoom   = true,                 -- whether static zooms with global
						can_scroll = true                  -- whether static scrolls with global
						}
				end

					for a = -1, 1 
				do
					gui[2].obj[z].static[a+2].xx = mx
					gui[2].obj[z].static[a+2].yy = my+a
					gui[2].obj[z].static[a+5].xx = mx+a
					gui[2].obj[z].static[a+5].yy = my
				end	
			end
		end -- for z 

			if r 
		then
				for z = 1, #gui[2].obj
			do
					if gui[2].obj[z].sel
				then
					for a = 1, 6 do gui[2].obj[z].static[a] = nil end 
				end
			end
			connector.time = reaper.time_precise()+connector.delay 
		end 

		msg("Lclick") 
		end,
		[2]   = function(o,b,r) msg("Rclick") end, 
		[3]   = function(o,b,r) msg("Mclick") end
		},
		mouse =
		{
		[1]   = 1,
		[2]   = 2,
		[3]   = 64
		},
		hold  = 
		{
		[1]   = true,
		[2]   = false,
		[3]   = true
		}
		}
	end -- if folder

end

function connect_lines()

    if connector.time > reaper.time_precise()
  then

      if hover[0] == 2 or hover[0] == 4
    then
        if hover[1] and hover[2] == 2 
      then
			for z = 1, #gui[2].obj
		do
				if gui[2].obj[z].sel
			then
				reaper.CreateTrackSend( gui[2].obj[z].track, gui[hover[0]].obj[hover[1]].track )
			end
		end
        connector.time = 0  
      end 
    end
  else
    connector.object = 0
  end
end

function update_parents()
    for o = 1, #gui[2].obj
  do 
    local rc, gc, bc = .5, .5, .5 if reaper.GetMediaTrackInfo_Value( gui[2].obj[o].track, "B_MAINSEND" ) ~= 1 then rc, gc, bc = 1, .25, .25 end
    local num_buttons = reaper.GetTrackNumSends( gui[2].obj[o].track, 0 )+reaper.TrackFX_GetCount( gui[2].obj[o].track )+4
	local alpher, acter = 1, nil
	if gui[2].obj[o].collapsed then alpher, acter, num_buttons = 0, 2, 3 end 
	
    gui[2].obj[o].button[num_buttons+1] = {
      caption = "L: adjust parent send dB, R: enter dB manually, Shf+L: enable/disable send",
      mode   = 0,       -- script specific
      type   = "rect",  -- draw type: "rect" or "circ"
      ol     = {r=0,g=0,b=0,a=alpher}, -- rect: button's outline
      hc     = 0,       -- current hover alpha (default '0')
      ha     = 0,      -- hover alpha
      hca    = 0,      -- hover click alpha 
      r      = rc,     -- r     (rect)
      g      = gc,    -- g     (rect)
      b      = bc,     -- b     (rect)
      a      = alpher,       -- alpha (rect)
      rt     = 0,       -- r     (text)
      gt     = 0,        -- g     (text)
      bt     = 0,       -- b     (text)
      at     = 1,       -- alpha (text)
      x      = 0,       -- x
      y      = (#gui[2].obj[o].button-2)*20,   -- y
      w      = 100,     -- width
      h      = 20,      -- height
      f      = 1,       -- filled
      txt    = "", -- text
      th     = 1,       -- text 'h' flag
      tv     = 4,       -- text 'v' flag  
      fo     = "Arial", -- font settings will have no affect unless: font_changes = true
      fs     = 12,      -- font size
      ff     = nil,     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
      can_zoom = 1,
      can_scroll = 1,
      track = gui[2].obj[o].track,
      static = {},
	  act_off = acter,
	  m_rel = 
	  {
		  [1] = nil,
		  [2] = nil,
		  [3] = 1,
	  },
      func   = 
      {
      [-1]   =
      function(self,g,o2,b)
 
		if not reaper.ValidatePtr(self.track, 'MediaTrack*') then return end 
        local parent_track = reaper.GetParentTrack( self.track )
        local rcc, gcc, bcc = 1, 1, 0
        local r_o = 1
        local g2 = 2
          for c = 1, #gui[2].obj
        do
            if gui[2].obj[c].track == parent_track
          then
            r_o = c
          end
        end
        if parent_track == nil then g2 = 4 end
 
		-- update name w/ volume 
		local voller = reaper.GetMediaTrackInfo_Value( self.track, "D_VOL" ) if voller > 1 then voller = 1 end local db_title = 0

		local db = 20*math.log(reaper.GetMediaTrackInfo_Value( self.track, "D_VOL" ), 10)
		if string.find(db, ".", 1, true) then if string.len(db) > string.find(db, ".", 1, true)+2 then db = string.sub(db, 1, string.find(db, ".", 1, true)+2) end end db = " ("..db.."dB)"
		db_title = "Parent Send"..db
		------------------------

          if reaper.GetMediaTrackInfo_Value( self.track, "B_MAINSEND" ) ~= 1 or voller == 0
        then
		  db_title = "Parent Send (-1.#IdB)"
		  if reaper.GetMediaTrackInfo_Value( self.track, "B_MAINSEND" ) ~= 1 then self.txt = "Parent Send OFF" end 
          self.r, self.g, self.b = 1, .25, .25  
          rcc, gcc, bcc = 1, 0, 0
        else
          self.r, self.g, self.b = .5, .5, .5 
        end
		self.static[8] = 
			{
			type       = "text",   -- draw type
			r          = 0,       -- r
			g          = 0,        -- g
			b          = 0,       -- b
			a          = self.a,       -- a
			txt        = db_title,    -- text
			x          = 0,        -- x
			y          = self.y,        -- y
			w          = 100,      -- width
			h          = 20,       -- height
			th         = 1,        -- text 'h' flag
			tv         = 4,        -- text 'v' flag  
			fo         = "Arial",  -- font settings will have no affect unless: font_changes = true
			fs         = 12,       -- font size
			ff         = nil,      -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
			can_zoom   = true,     -- whether static zooms with global: font_changes must be true in order for font size to adjust
			can_scroll = true     -- whether static scrolls with global
			} 
			if reaper.GetMediaTrackInfo_Value( self.track, "B_MAINSEND" ) == 1
		then 
			-- draw lines
			  for a = -1, 1 -- -1, 1 
			do
			  local xx2, yy2 = (gui[g2].obj[r_o].x+a-V_H)*V_Z, (gui[g2].obj[r_o].y+10-V_V)*V_Z   
			  if parent_track == nil then xx2, yy2 = gui[4].obj[1].x+a, gui[4].obj[1].y+10  end 
			  self.static[a+2] = { -- a+2
			  type       = "line",               -- draw type
			  r          = rcc,                  -- r
			  g          = gcc,                  -- g
			  b          = bcc,                  -- b
			  a          = Connection_Parents_Alpha,
			  x          = 100+a,                 
			  y          = 10,
			  xx         = xx2,                 
			  yy         = yy2,  
			  aa         = 1,                    -- antialias
			  can_zoom   = true,                 -- whether static zooms with global
			  can_scroll = true                  -- whether static scrolls with global
			  }
			  xx2, yy2 = (gui[g2].obj[r_o].x-V_H)*V_Z, (gui[g2].obj[r_o].y+10+a-V_V)*V_Z  
			  if parent_track == nil then xx2, yy2 = gui[4].obj[1].x, gui[4].obj[1].y+10+a  end 
			  self.static[a+5] = {
			  type       = "line",               -- draw type
			  r          = rcc,                  -- r
			  g          = gcc,                  -- g
			  b          = bcc,                  -- b
			  a          = Connection_Parents_Alpha,    
			  x          = 100,                 
			  y          = 10+a,
			  xx         = xx2,                 
			  yy         = yy2,               
			  aa         = 1,                    -- antialias
			  can_zoom   = true,                 -- whether static zooms with global
			  can_scroll = true                  -- whether static scrolls with global
			  }
			end
			-- draw rectangle
			local alpheran = .6
			if hover[0] == g and hover[1] == o2 and hover[2] == b then alpheran = .8 end if self.a == 0 then alpheran = 0 end 
			self.static[7] = {
				type       = "rect",               -- draw type
				ol         = {r=1,g=1,b=1,a=alpheran},   -- rectangle static's outline
				r          = 1,                   -- r
				g          = 1,                    -- g
				b          = 0,                   -- b
				a          = alpheran,                   -- a
				x          = 0,                    -- x
				y          = self.y,                    -- y
				w          = 100*voller,                
				h          = 20,                   -- height
				f          = 1,                    -- filled  
				can_zoom   = true,                 -- whether static zooms with global
				can_scroll = true                 -- whether static scrolls with global
				}
		else
			for a = 1, 8 do self.static[a] = nil end  
		end
      
      end,
      --[0]    = function(self,o,b,r,d) end, 
		[1]    = 
			function(self,o,b,r,d) 
				for z = 1, #gui[2].obj
			do
					if gui[2].obj[z].sel or z == o
				then
					if reaper.GetMediaTrackInfo_Value( self.track, "B_MAINSEND" ) ~= 1 then return end
					if r then msg("release") return end
					local voller = math.ceil(mx-((gui[2].obj[z].x - V_H)*V_Z))/(math.floor(((gui[2].obj[z].x - V_H + 100)*V_Z))-math.ceil(((gui[2].obj[z].x - V_H)*V_Z))) 
					if voller < 0 then voller = 0 end if voller > 1 then voller = 1 end 
					
					reaper.SetMediaTrackInfo_Value( gui[2].obj[z].track, "D_VOL", voller )
				end
			end
		end,
		[2]    = 
		function(self,o,b,r,d) 
			if r then msg("release") return end  
			if reaper.GetMediaTrackInfo_Value( self.track, "B_MAINSEND" ) ~= 1 then return end
			local db = 20*math.log(reaper.GetMediaTrackInfo_Value( self.track, "D_VOL" ), 10) local db2 = db
			if string.find(db, ".", 1, true) then if string.len(db) > string.find(db, ".", 1, true)+2 then db = string.sub(db, 1, string.find(db, ".", 1, true)+2) end end db = " ("..db.."dB)"
			if Pin_window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
			local dbretval, db_csv = reaper.GetUserInputs( "[input]", 1, "Input dB (-150 to +12):", db2 ) db_csv = tonumber(db_csv)
			if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
				if type(db_csv) == 'number' 
			then  
				if db_csv < -150 then db_csv = -150 end if db_csv > 12 then db_csv = 12 end
					for z = 1, #gui[2].obj
				do
						if gui[2].obj[z].sel or z == o
					then
						reaper.SetMediaTrackInfo_Value( gui[2].obj[z].track, "D_VOL", 10 ^ (db_csv/20) )
					end
				end
			end 
		end, 
        [3]    = 
		function(self,o,b,r,d)
			if r then msg("release") return end  
				for z = 1, #gui[2].obj
			do
					if gui[2].obj[z].sel or z == o
				then
						if reaper.GetMediaTrackInfo_Value( gui[2].obj[z].track, "B_MAINSEND" ) == 1
					then
						reaper.SetMediaTrackInfo_Value( gui[2].obj[z].track, "B_MAINSEND", 0 )
					else
						reaper.SetMediaTrackInfo_Value( gui[2].obj[z].track, "B_MAINSEND", 1 )
					end
				end
			end
		end
      },
      mouse  =
      {
      [1]    = 1,
      [2]    = 2,
      [3]    = 9
      },
      hold   = 
      {
      [1]    = true,
      [2]    = false,
      [3]    = false
      }
      } 
    if not gui[2].obj[o].collapsed then local hsize = ((num_buttons+1)*20) if hsize < 100 then hsize = 100 end gui[2].obj[o].h = hsize else end
    for c = num_buttons+2, #gui[2].obj[o].button do gui[2].obj[o].button[c] = nil end 
  end
  update.time = reaper.time_precise() 
  
end

function update_sends()

  local num_tracks_sending = 0

    for o = 1, #gui[2].obj
  do
    local sending_track = gui[2].obj[o].track
    local num_sends   = reaper.GetTrackNumSends( sending_track, 0 ) 
    local num_buttons = reaper.TrackFX_GetCount( sending_track )+4
    
      for s = 1, num_sends
    do
      local receive_track = reaper.GetTrackSendInfo_Value( sending_track, 0, s-1, "P_DESTTRACK" ) num_tracks_sending = num_tracks_sending + 1    
      local tname, track_name = reaper.GetTrackName( receive_track ) if not tname then track_name = "[track "..tostring( reaper.GetMediaTrackInfo_Value( receive_track, "IP_TRACKNUMBER" )).."]" end 

	  -- ROUTING LINES
	  gui[4].obj[2].button[num_tracks_sending] = 
	    {
		id         = 1,                                                -- button classification
		caption    = "", -- caption display
		type       = "rect",                                           -- draw type: "rect" or "circ"
		ol         = {r=1,g=1,b=1,a=0},                               -- rect: button's outline
		hc         = 0,                                                -- current hover alpha (default '0')
		ha         = .05,                                              -- hover alpha
		hca        = .1,                                               -- hover click alpha 
		r          = .7,                                               -- r
		g          =.6,                                                -- g
		b          = .2,                                               -- b
		a          = 0,                                               -- a
		rt         = .5,                                               -- r     (text)
		gt         = .5,	                                           -- g     (text)
		bt         = .5,                                               -- b     (text)
		at         = .5,                                               -- alpha (text)
		x          = 0,                                                -- x
		y          = 0,                                                -- y                     
		w          = 100,                                              -- width
		h          = 100,                                              -- height
		f          = 1,                                                -- filled
		rs         = 10,                                               -- circle: radius
		aa         = true,                                             -- circle: antialias         
		txt        = "",                                            -- text: "" disables text for button                                 
		th         = 1,                                                -- text 'h' flag
		tv         = 4,                                                -- text 'v' flag	
		fo         = "Arial",                                          -- font settings will have no affect unless: font_changes = true
		fs         = 12,                                               -- font size
		ff         = nil,                                              -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
		can_zoom   = true,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
		can_scroll = false,                                            -- whether object rectangle scrolls with global   
		act_off    = 2,                                                -- if 1, button action is disabled. if 2, button action is disabled and passed through   
		static     = {},                                               -- index of static graphics that object holds
		send_track = sending_track,
		rec_track = receive_track,
		func       = 
			{ -- functions receive object and button index, & bool release ('r')
			-- always-run function
			[-1]      = function(self,g,hi,b) 
				if not reaper.ValidatePtr(self.rec_track, "MediaTrack*") or not reaper.ValidatePtr(self.send_track, "MediaTrack*") then return end 
			    local r_o = -1
				local o3  = 0
				  for c = 1, #gui[2].obj
				do
					if gui[2].obj[c].track == self.rec_track
				  then
					r_o = c
				  end
				end
				if r_o == -1 then return end
				  for c = 1, #gui[2].obj
				do
					if gui[2].obj[c].track == self.send_track
				  then
					o3 = c
				  end
				end
			  -- draw lines
				for a = -1, 1 
			  do
				self.static[a+2] = {
				type       = "line",               -- draw type
				r          = 0,                    -- r
				g          = .3,                   -- g
				b          = 1,                    -- b
				a          = Connection_Sends_Alpha,                   -- a
				x          = gui[2].obj[o3].x+100+a,                 
				y          = gui[2].obj[o3].y+10,
				xx         = (gui[2].obj[r_o].x+a-V_H)*V_Z,                 
				yy         = (gui[2].obj[r_o].y+10-V_V)*V_Z,  
				aa         = 1,                    -- antialias
				can_zoom   = true,                 -- whether static zooms with global
				can_scroll = true                  -- whether static scrolls with global
				}
				self.static[a+5] = {
				type       = "line",               -- draw type
				r          = 0,                    -- r
				g          = .3,                   -- g
				b          = 1,                    -- b
				a          = Connection_Sends_Alpha,                   -- a
				x          = gui[2].obj[o3].x+100,                 
				y          = gui[2].obj[o3].y+10+a,
				xx         = (gui[2].obj[r_o].x-V_H)*V_Z,                   
				yy         = (gui[2].obj[r_o].y+10+a-V_V)*V_Z,               
				aa         = 1,                    -- antialias
				can_zoom   = true,                 -- whether static zooms with global
				can_scroll = true                  -- whether static scrolls with global
				}
			  end
			end, 
			-- non-indexed function
			[0]      = function(self,o,b,r,d) if r then msg("release") return else msg("Dclick") end end, 
			-- mouse_cap functions
			[1]      = function(self,o,b,r,d) if r then msg("release") return else msg("Lclick") end end, 
			[2]      = function(self,o,b,r,d) if r then msg("release") return else msg("Rclick") end end,
			[3]      = function(self,o,b,r,d) if r then msg("release") return else msg("Mclick") end end, 
			},
		mouse      =
			{ -- index [1] must always be left click
			[1]        = 1,             
			[2]        = 2,
			[3]        = 64
			},
		hold       = 
			{
			[1]        = true,
			[2]        = false,
			[3]        = false
			}
		}
	  -- if object is collapsed
	  if gui[2].obj[o].collapsed then goto skipper end
	  -- ROUTING BUTTON
      gui[2].obj[o].button[num_buttons+s] = {
        caption = "L: adjust send dB, R: routing settings, Shf+L: delete send, Shf+R: enter dB manually",
        mode   = 0,       -- script specific
        type   = "rect",  -- draw type: "rect" or "circ"
        ol     = {r=0,g=0,b=0,a=1}, -- rect: button's outline
        hc     = 0,       -- current hover alpha (default '0')
        ha     = 0,      -- hover alpha
        hca    = 0,      -- hover click alpha 
        r      = .5,      -- r     (rect)
        g      = .5,      -- g     (rect)
        b      = .5,      -- b     (rect)
        a      = 1,       -- alpha (rect)
        rt     = 1,       -- r     (text)
        gt     = 1,        -- g     (text)
        bt     = 1,       -- b     (text)
        at     = 1,       -- alpha (text)
        x      = 0,       -- x
        y      = (num_buttons-3+s)*20,   -- y
        w      = 100,     -- width
        h      = 20,      -- height
        f      = 1,       -- filled
        txt    = "", -- text
        th     = 1,       -- text 'h' flag
        tv     = 4,       -- text 'v' flag  
        fo     = "Arial", -- font settings will have no affect unless: font_changes = true
        fs     = 12,      -- font size
        ff     = nil,     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
        can_zoom = 1,
        can_scroll = 1,
        track = sending_track,
        sid = s-1,
        sname = track_name,
		static = {},
		m_rel  =
		{
		[1] = nil,
		[2] = nil,
		[3] = 1,
		[4] = nil
		},
        func   = 
        {
        [-1]   =
        function(self,g,o2,b)
          -- draw rectangle
		  if not reaper.ValidatePtr(self.track, "MediaTrack*") then return end 
          local voller = reaper.GetTrackSendInfo_Value( self.track, 0, self.sid, "D_VOL" ) if voller > 1 then voller = 1 end
		  local alphera = .6 if hover[0] == g and hover[1] == o2 and hover[2] == b then alphera = .8 end
          self.static[1] = {
            type       = "rect",               -- draw type
            ol         = {r=1,g=1,b=1,a=.2},   -- rectangle static's outline
            r          = .25,                   -- r
            g          = .25,                    -- g
            b          = 1,                   -- b
            a          = alphera,                   -- a
            x          = 0,                    -- x
            y          = (num_buttons-3+s)*20,                    -- y
            w          = 100*voller,                
            h          = 20,                   -- height
            f          = 1,                    -- filled  
            can_zoom   = true,                 -- whether static zooms with global
            can_scroll = true                 -- whether static scrolls with global
            }
          local db = 20*math.log(reaper.GetTrackSendInfo_Value( self.track, 0, self.sid, "D_VOL" ), 10)
          if string.find(db, ".", 1, true) then if string.len(db) > string.find(db, ".", 1, true)+2 then db = string.sub(db, 1, string.find(db, ".", 1, true)+2) end end db = " ("..db.."dB)"
		  local wa = self.w * V_Z
		  local subber = self.sname                                                                             -- resize title to fit button
		  if font_changes == true then gfx.setfont( 1,self.fo,self.fs*V_Z,fontFlags(self.ff) ) end              -- if font_changes = true then set font
			  if gfx.measurestr( subber..db ) > wa 
		  then                                         
			  while gfx.measurestr( subber..db ) > wa do subber = string.sub(subber,1,string.len(subber)-1) if string.len(subber) == 0 then break end end 
			  subber = string.sub(subber,1,string.len(subber)-3) subber = subber.."..."  
		  end 
		  db = subber..db 
          -- draw text
          self.static[2] = {
            type       = "text",   -- draw type
            r          = 1,       -- r
            g          = 1,        -- g
            b          = 1,       -- b
            a          = 1,       -- a
            txt        = db,    -- text
            x          = 0,        -- x
            y          = gui[2].obj[o2].button[b].y,        -- y
            w          = 100,      -- width
            h          = 20,       -- height
            th         = 1,        -- text 'h' flag
            tv         = 4,        -- text 'v' flag  
            fo         = "Arial",  -- font settings will have no affect unless: font_changes = true
            fs         = 12,       -- font size
            ff         = nil,      -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
            can_zoom   = true,     -- whether static zooms with global: font_changes must be true in order for font size to adjust
            can_scroll = true     -- whether static scrolls with global
            } 
        end,
        [0]    = 
        function(self,o,b,r,d) if r then msg("release") return end end, 
        [1]    = 
        function(self,o,b,r,d) 
          if r then msg("release") return end
          local voller = math.ceil(mx-((gui[2].obj[o].x - V_H)*V_Z))/(math.floor(((gui[2].obj[o].x - V_H + 100)*V_Z))-math.ceil(((gui[2].obj[o].x - V_H)*V_Z))) 
          if voller < 0 then voller = 0 end if voller > 1 then voller = 1 end 
          
          reaper.SetTrackSendInfo_Value( self.track, 0, self.sid, "D_VOL", voller )
        end,
        [2]    = 
        function(self,o,b,r,d) 
          if r then msg("release") return end  
          
          local db = 20*math.log(reaper.GetTrackSendInfo_Value( self.track, 0, self.sid, "D_VOL" ), 10) 
            if string.find(db, ".", 1, true)
          then 
              if string.len(db) > string.find(db, ".", 1, true)+3
            then
              db = string.sub(db, 1, string.find(db, ".", 1, true)+3)
            end
          end 
          if Pin_window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
          local dbretval, db_csv = reaper.GetUserInputs( "[input]", 1, "Input dB (-150 to +12):", db ) db_csv = tonumber(db_csv)
          if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
            if type(db_csv) == 'number' 
          then  
            if db_csv < -150 then db_csv = -150 end if db_csv > 12 then db_csv = 12 end
            reaper.SetTrackSendInfo_Value( self.track, 0, self.sid, "D_VOL", 10 ^ (db_csv/20) ) 
          end 
        end, 
        [3]    = 
        function(self,o,b,r,d) 
          if r then msg("release") reaper.RemoveTrackSend( self.track, 0, self.sid ) return end  
        end,
		[4]	   =
		function(self,o,b,r,d) if not r then return end
			if Pin_window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
			
			local newretval, newretvals_csv = reaper.GetUserInputs( "[input]", 3, "Sending MIDI ch.,Receipt MIDI ch.,Audio ch.,Receipt audio ch.,extrawidth=50,separator=@", "(-1=none, 0=all, 1-16)@(-1=none, 0=all, 1-16)@(-1=none, 1-64)" )
			
			local result = {} local index = 1 for s in string.gmatch(newretvals_csv, "[^".."@".."]+") do result[index] = s index = index + 1 end

			local send_MIDI, rec_MIDI, aud = result[1], result[2], result[3] 
			
			send_MIDI, rec_MIDI, aud = tonumber(send_MIDI), tonumber(rec_MIDI), tonumber(aud)
			
			local var = tostring( DecToBin( reaper.GetTrackSendInfo_Value( self.track, 0, 0, "I_MIDIFLAGS" ) ) )

			if type(send_MIDI) ~= 'number' then send_MIDI = tonumber( string.sub( var, -5), 2 ) end
			if type(rec_MIDI) ~= 'number' then rec_MIDI = tonumber( string.sub( var, 1, var:len()-5 ), 2 ) end   
			if send_MIDI < -1 then send_MIDI = -1 end if send_MIDI > 16 then send_MIDI = 16 end
			if rec_MIDI < -1 then rec_MIDI = -1 end if rec_MIDI > 16 then rec_MIDI = 16 end
				if send_MIDI == -1 or rec_MIDI == -1 
			then 
				reaper.SetTrackSendInfo_Value( self.track, 0, self.sid, "I_MIDIFLAGS", -1 ) 
			else
				rec_MIDI = DecToBin(rec_MIDI) if rec_MIDI:len() > 5 then rec_MIDI = string.sub( rec_MIDI, -5 ) end
				send_MIDI = DecToBin(send_MIDI) while send_MIDI:len() < 5 do send_MIDI = "0"..send_MIDI end  if send_MIDI:len() > 5 then send_MIDI = string.sub( send_MIDI, -5 ) end
				reaper.SetTrackSendInfo_Value( self.track, 0, self.sid, "I_MIDIFLAGS", tonumber(rec_MIDI..send_MIDI, 2) ) 
			end 

				if type(aud) == 'number' 
			then
				if aud < -1 then aud = -1 end if aud > 64 then aud = 64 end
				for x = 2, #channel_table do if aud <= channel_table[x] and aud > 2 then aud = channel_table[x] break end end 
					if reaper.GetMediaTrackInfo_Value( self.track, "I_NCHAN" ) < aud
				then
					local mb_input = reaper.MB( "Track contains less channels than your are attempting to assign this send.\n\nSet track channels to "..aud.."?", "[input]", 1 )
					if mb_input == 1 then reaper.SetMediaTrackInfo_Value( self.track, "I_NCHAN", aud ) else aud = -2 end 
				end
					if aud == -1
				then
					reaper.SetTrackSendInfo_Value( self.track, 0, self.sid, "I_SRCCHAN", -1 ) 
					elseif aud == -2
				then
					-- nothing
					elseif aud == 1
				then
					reaper.SetTrackSendInfo_Value( self.track, 0, self.sid, "I_SRCCHAN", 1024 ) 
					elseif aud == 2
				then
					reaper.SetTrackSendInfo_Value( self.track, 0, self.sid, "I_SRCCHAN", 0 ) 
				else
					reaper.SetTrackSendInfo_Value( self.track, 0, self.sid, "I_SRCCHAN", aud*512 ) 
				end
			end
			
			if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
			
		end
        },
        mouse  =
        {
        [1]    = 1,
        [2]    = 10,
        [3]    = 9,
		[4]    = 2
        },
        hold   = 
        {
        [1]    = true,
        [2]    = false,
        [3]    = false,
		[4]	   = false
        }
        }  
	  ::skipper::
    end -- for s 
	for a = num_tracks_sending+1, #gui[4].obj[2].button do gui[4].obj[2].button[a] = nil end
  end -- for o
  
  update_parents()
  
end

function update_fx()

    for o = 1, #gui[2].obj
  do
	-- snap objects to grid
	if grid_snap == true then gui[2].obj[o].x = math.floor((((gui[2].obj[o].x)/100)+.5))*100 gui[2].obj[o].y = math.floor((((gui[2].obj[o].y)/100)+.5))*100 end
	-- check if object is selected
	if not gui[2].obj[o].sel then gui[2].obj[o].ol = {r=.7,g=.7,b=.7,a=1} else gui[2].obj[o].ol = {r=0,g=1,b=0,a=1} end 
	-- if object is collapsed
	if gui[2].obj[o].collapsed then goto skipper end
    --FX BUTTONS-------------------------------------------------------------------------
	local track = gui[2].obj[o].track local fxc = -1    
      for fx = 0, reaper.TrackFX_GetCount( track )-1
    do 
      local fx_retval, fx_buf = reaper.TrackFX_GetFXName( track, fx, "" )
      local red, blue, green = .5, .5, .5
      if not reaper.TrackFX_GetEnabled( track, fx ) then red, blue, green = 1, .5, .5 end 
      
      gui[2].obj[o].button[fx+4] = {
        id     = 2,       -- identifies object for looped-processing
        caption = "Dbl-L: open/close FX window, R: un/bypass, Shf+L delete FX",
        mode   = 0,       -- script specific
        type   = "rect",  -- draw type: "rect" or "circ"
        ol     = {r=0,g=0,b=0,a=1}, -- rect: button's outline
        hc     = 0,       -- current hover alpha (default '0')
        ha     = .2,      -- hover alpha
        hca    = .3,      -- hover click alpha 
        r      = red,      -- r     (rect)
        g      = green,      -- g     (rect)
        b      = blue,      -- b     (rect)
        a      = 1,       -- alpha (rect)
        rt     = 1,       -- r     (text)
        gt     = 1,        -- g     (text)
        bt     = 1,       -- b     (text)
        at     = 1,       -- alpha (text)
        x      = 0,       -- x
        y      = (fx+1)*20,   -- y
        w      = 100,     -- width
        h      = 20,      -- height
        f      = 1,       -- filled
        txt    = fx_buf, -- text
        th     = 1,       -- text 'h' flag
        tv     = 4,       -- text 'v' flag  
        fo     = "Arial", -- font settings will have no affect unless: font_changes = true
        fs     = 12,      -- font size
        ff     = nil,     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
        can_zoom = 1,
        can_scroll = 1,
        track = track,
		m_rel = 
		{
		[1] = nil,
		[2] = nil,
		[3] = 1
		},
        func   = 
        {
        [0]    = 
        function(self,o,b,r,d) 
        
          if r then msg("release") return end 
          msg(o.." "..hover[2])
            if not reaper.TrackFX_GetFloatingWindow( self.track, b-4 )
          then msg("open")
            reaper.TrackFX_Show( self.track, b-4, 3 )                                                                              
            reaper.JS_Window_SetZOrder( reaper.TrackFX_GetFloatingWindow( self.track, b-4 ), "TOPMOST" )            
          else msg("close")
            reaper.TrackFX_Show( self.track, b-4, 2 )  
          end  
        end, 
        [1]    = function(o,b,r) if r then msg("release") return end  end,
        [2]    = 
        function(self,o,b,r,d) 
          if r then msg("release") return end  
            if not reaper.TrackFX_GetEnabled( self.track, b-4 )
          then
            self.r, self.g, self.b = 1, .5, .5  reaper.TrackFX_SetEnabled( self.track, b-4, 1 )
          else
            self.r, self.g, self.b = .5, .5, .5 reaper.TrackFX_SetEnabled( self.track, b-4, 0 )
          end
        end, 
        [3]    = 
        function(self,o,b,r,d) 
          if r then msg("release") return end  
          reaper.TrackFX_Delete( self.track, b-4 )
        end
        },
        mouse  =
        {
        [1]    = 1,
        [2]    = 2,
        [3]    = 9
        },
        hold   = 
        {
        [1]    = false,
        [2]    = false,
        [3]    = false
        }
        } 
      if fx > reaper.TrackFX_GetCount( track )-2 then fxc = fx end 
    end -- for fx
    gui[2].obj[o].button[fxc+5] = {
      caption = "Dbl-L: add track FX",
      mode   = 0,       -- script specific
      type   = "rect",  -- draw type: "rect" or "circ"
      ol     = {r=0,g=0,b=0,a=1}, -- rect: button's outline
      hc     = 0,       -- current hover alpha (default '0')
      ha     = .2,      -- hover alpha
      hca    = .3,      -- hover click alpha 
      r      = .8,      -- r     (rect)
      g      = .8,      -- g     (rect)
      b      = .8,      -- b     (rect)
      a      = 1,       -- alpha (rect)
      rt     = 0,       -- r     (text)
      gt     = 0,        -- g     (text)
      bt     = 0,       -- b     (text)
      at     = 1,       -- alpha (text)
      x      = 0,       -- x
      y      = (reaper.TrackFX_GetCount( track )+1)*20,   -- y
      w      = 100,     -- width
      h      = 20,      -- height
      f      = 1,       -- filled
      txt    = "[add FX]", -- text
      th     = 1,       -- text 'h' flag
      tv     = 4,       -- text 'v' flag  
      fo     = "Arial", -- font settings will have no affect unless: font_changes = true
      fs     = 12,      -- font size
      ff     = nil,     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
      can_zoom = 1,
      can_scroll = 1,
      track = track,
      func   = 
      {
      [0]    = 
      function(self,o,b,r,d) 
      
        if r then msg("release") return end 
      
        if Pin_window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
        local track_sel = {}
        for a = 1, reaper.CountTracks( 0 ) do if reaper.IsTrackSelected( reaper.GetTrack( 0, a-1 ) ) then track_sel[#track_sel+1] = reaper.GetTrack( 0, a-1 ) end end
        reaper.SetOnlyTrackSelected( gui[2].obj[o].track ) up()
        reaper.Main_OnCommand( 40271, 0 )
        reaper.JS_Window_Update( window )
        local new_window = reaper.JS_Window_GetForeground()
        if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
        reaper.JS_Window_Update( window )
        reaper.JS_Window_SetZOrder( new_window, "TOPMOST" )
        reaper.SetTrackSelected( gui[2].obj[o].track, false )
        for a = 1, #track_sel do reaper.SetTrackSelected( track_sel[a], true ) end up()
        

      end, 
      [1]    = function(self,o,b,r,d) if r then msg("release") return end  end,
      [2]    = function(self,o,b,r,d) if r then msg("release") return end  end, 
      [3]    = function(self,o,b,r,d) if r then msg("release") return end  end
      },
      mouse  =
      {
      [1]    = 1,
      [2]    = 2,
      [3]    = 64
      },
      hold   = 
      {
      [1]    = false,
      [2]    = false,
      [3]    = true
      }
      } 
    while #gui[2].obj[o].button > reaper.TrackFX_GetCount( gui[2].obj[o].track )+4 do gui[2].obj[o].button[#gui[2].obj[o].button] = nil end 
	::skipper::
  end -- end of for o

  track = reaper.GetMasterTrack( 0 ) fxc = -1    
  --MASTER FX BUTTONS-------------------------------------------------------------------------
    for fx = 0, reaper.TrackFX_GetCount( track )-1
  do 
    local fx_retval, fx_buf = reaper.TrackFX_GetFXName( track, fx, "" )
    local red, blue, green = .5, .5, .5
    if not reaper.TrackFX_GetEnabled( track, fx ) then red, blue, green = 1, .5, .5 end 
    
    gui[4].obj[1].button[fx+3] = {
      id     = 2,       -- identifies object for looped-processing
      caption = "Dbl-L: open/close FX window, R: un/bypass, Shf+L: delete FX",
      mode   = 0,       -- script specific
      type   = "rect",  -- draw type: "rect" or "circ"
      ol     = {r=0,g=0,b=0,a=1}, -- rect: button's outline
      hc     = 0,       -- current hover alpha (default '0')
      ha     = .2,      -- hover alpha
      hca    = .3,      -- hover click alpha 
      r      = red,      -- r     (rect)
      g      = green,      -- g     (rect)
      b      = blue,      -- b     (rect)
      a      = 1,       -- alpha (rect)
      rt     = 1,       -- r     (text)
      gt     = 1,        -- g     (text)
      bt     = 1,       -- b     (text)
      at     = 1,       -- alpha (text)
      x      = 0,       -- x
      y      = (fx+1)*20,   -- y
      w      = 100,     -- width
      h      = 20,      -- height
      f      = 1,       -- filled
      txt    = fx_buf, -- text
      th     = 1,       -- text 'h' flag
      tv     = 4,       -- text 'v' flag  
      fo     = "Arial", -- font settings will have no affect unless: font_changes = true
      fs     = 12,      -- font size
      ff     = nil,     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
      can_zoom = 0,
      can_scroll = 0,
      track = track,
		m_rel = 
		{
		[1] = nil,
		[2] = nil,
		[3] = 1
		},
      func   = 
      {
      [0]    = 
      function(self,o,b,r,d) 
      
        if r then msg("release") return end 
        msg(o.." "..hover[2])
          if not reaper.TrackFX_GetFloatingWindow( self.track, b-4 )
        then msg("open")
          reaper.TrackFX_Show( self.track, b-3, 3 )                                                                              
          reaper.JS_Window_SetZOrder( reaper.TrackFX_GetFloatingWindow( self.track, b-3 ), "TOPMOST" )            
        else msg("close")
          reaper.TrackFX_Show( self.track, b-3, 2 )  
        end  
      end, 
      [1]    = function(o,b,r) if r then msg("release") return end  end,
      [2]    = 
      function(self,o,b,r,d) 
        if r then msg("release") return end  
          if not reaper.TrackFX_GetEnabled( self.track, b-3 )
        then
          self.r, self.g, self.b = 1, .5, .5  reaper.TrackFX_SetEnabled( self.track, b-3, 1 )
        else
          self.r, self.g, self.b = .5, .5, .5 reaper.TrackFX_SetEnabled( self.track, b-3, 0 )
        end
      end, 
      [3]    = 
        function(self,o,b,r,d) 
          if r then msg("release") return end 
          reaper.TrackFX_Delete( self.track, b-3 )
        end
      },
      mouse  =
      {
      [1]    = 1,
      [2]    = 2,
      [3]    = 9
      },
      hold   = 
      {
      [1]    = false,
      [2]    = false,
      [3]    = false
      }
      } 
    if fx > reaper.TrackFX_GetCount( track )-2 then fxc = fx end 
  end -- for fx
  gui[4].obj[1].button[fxc+4] = {
    caption = "Dbl-L: add track FX",
    mode   = 0,       -- script specific
    type   = "rect",  -- draw type: "rect" or "circ"
    ol     = {r=0,g=0,b=0,a=1}, -- rect: button's outline
    hc     = 0,       -- current hover alpha (default '0')
    ha     = .2,      -- hover alpha
    hca    = .3,      -- hover click alpha 
    r      = .8,      -- r     (rect)
    g      = .8,      -- g     (rect)
    b      = .8,      -- b     (rect)
    a      = 1,       -- alpha (rect)
    rt     = 0,       -- r     (text)
    gt     = 0,        -- g     (text)
    bt     = 0,       -- b     (text)
    at     = 1,       -- alpha (text)
    x      = 0,       -- x
    y      = (reaper.TrackFX_GetCount( track )+1)*20,   -- y
    w      = 100,     -- width
    h      = 20,      -- height
    f      = 1,       -- filled
    txt    = "[add FX]", -- text
    th     = 1,       -- text 'h' flag
    tv     = 4,       -- text 'v' flag  
    fo     = "Arial", -- font settings will have no affect unless: font_changes = true
    fs     = 12,      -- font size
    ff     = nil,     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
    can_zoom = false,
    can_scroll = false,
    track = track,
    func   = 
    {
    [0]    = 
    function(self,o,b,r,d) 
    
      if r then msg("release") return end 
    
      if Pin_window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
      reaper.Main_OnCommand( 40846, 0 ) up()
      reaper.JS_Window_Update( window )
      local new_window = reaper.JS_Window_GetForeground()
      if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
      reaper.JS_Window_Update( window )
      reaper.JS_Window_SetZOrder( new_window, "TOPMOST" )
      
    end, 
    [1]    = function(self,o,b,r,d) if r then msg("release") return end  end,
    [2]    = function(self,o,b,r,d) if r then msg("release") return end  end, 
    [3]    = function(self,o,b,r,d) if r then msg("release") return end  end
    },
    mouse  =
    {
    [1]    = 1,
    [2]    = 2,
    [3]    = 64
    },
    hold   = 
    {
    [1]    = false,
    [2]    = false,
    [3]    = true
    }
    } 
  while #gui[4].obj[1].button > reaper.TrackFX_GetCount( reaper.GetMasterTrack( 0 ) )+3 do gui[4].obj[1].button[#gui[4].obj[1].button] = nil end 
  update_sends()
end

function update_boxes() mx, my = gfx.mouse_x, gfx.mouse_y local breaker = 0
  
  local obj = gui[2].obj
  -- update track names and colors
  if reaper.time_precise() > update.time + update.delay 
      then
		for a = 1, #obj
	  do
		  if reaper.ValidatePtr(obj[a].track, 'MediaTrack*')
		then 
		  local tname_retval, tname_buf = reaper.GetTrackName( obj[a].track ) 
		  obj[a].r, obj[a].g, obj[a].b = reaper.ColorFromNative( reaper.GetTrackColor( obj[a].track ) ) obj[a].r, obj[a].g, obj[a].b = obj[a].r/255, obj[a].g/255, obj[a].b/255
		  obj[a].button[1].r, obj[a].button[1].g, obj[a].button[1].b = obj[a].r, obj[a].g, obj[a].b
		  if tname_buf == "Track "..tostring( math.floor( reaper.GetMediaTrackInfo_Value( obj[a].track, "IP_TRACKNUMBER" ) ) )  then tname_buf = "[track]" end 
		  obj[a].button[1].static[1].txt = tname_buf 
		end
	  end
  end

  -- energy saver
  if project_tracks == reaper.CountTracks( 0 ) or project_tracks >= track_limit then if reaper.time_precise() > update.time + update.delay then update_fx() end return end 
  
  -- remove 'bad' tracks
    for a = 1, #obj
  do local exists = 0
      for b = 1, reaper.CountTracks( 0 )
    do
      if obj[a].track == reaper.GetTrack( 0, b-1 ) then exists = 1 end
    end
      if exists == 0 
    then 
        for c = a, #obj
      do  local level_buf = obj[c].level 
		if obj[c+1] then obj[c] = obj[c+1] obj[c].level = level_buf else obj[c] = nil end
      end
      breaker = 1 break
    end
  end
  
  -- 'break' function if bad tracks are found; function will not add new tracks while bad tracks exist in table
  if breaker == 1 then return end 
  
  -- add new tracks, if all other tracks are 'good'
	for a = 1, reaper.CountTracks( 1 )
  do local exists = 0
	if #gui[2].obj >= track_limit then break end 
	  for b = 1, #obj
	do
	  if reaper.GetTrack( 0, a-1 ) == obj[b].track then exists = 1 end
	end
	  if exists == 0 
	then local xpos, ypos = 0,0
	  -- calculate new object position
		local empty = false 
		for h = 0, grid_h-1
	  do 
		  for w = 0, grid_w-1
		do empty = true 
			for box = 1, #obj 
		  do 
				if obj[box].x >= xpos-99 and obj[box].x <= xpos+99
			then
					if obj[box].y >= ypos-obj[box].h+1 and obj[box].y <= ypos+99
				then
					empty = false
				end
			end
		  end
		  if empty == true then break end
		  xpos = xpos + 100
		end
		if empty == true then break end
		xpos = 0 ypos = ypos + 100
	  end
	  --------------------------------
	  -- check if object XY positions already exist for the project
	  local pjxretval, pjxval = reaper.GetProjExtState( 0, "Dfk", reaper.GetTrackGUID( reaper.GetTrack( 0, a-1 ) ) ) if pjxretval > 0 then xpos = tonumber(pjxval) end
	  pjxretval, pjxval = reaper.GetProjExtState( 0, "Dfk2", reaper.GetTrackGUID( reaper.GetTrack( 0, a-1 ) ) ) if pjxretval > 0 then ypos = tonumber(pjxval) end
	  pjxretval, pjxval = reaper.GetProjExtState( 0, "Dfk", reaper.GetTrackGUID( reaper.GetTrack( 0, a-1 ) ).."CS" ) msg(pjxval)
	  create_box( #obj+1, reaper.GetTrack( 0, a-1 ), xpos, ypos, nil, pjxval )
	end
  end -- for a = 1
  
  project_tracks = reaper.CountTracks( 0 )
  if reaper.time_precise() > update.time + update.delay then update_fx() end 
  
end

function init()
  
  -- get window variables, if they exist
  local d, w, h, x, y = 0,500,500,display_width/2-250,display_height/2-250
  if reaper.HasExtState( script_name, "W_D" ) then d = reaper.GetExtState( script_name, "W_D" ) end
  if reaper.HasExtState( script_name, "W_W" ) then w = reaper.GetExtState( script_name, "W_W" ) end
  if reaper.HasExtState( script_name, "W_H" ) then h = reaper.GetExtState( script_name, "W_H" ) end
  if reaper.HasExtState( script_name, "W_X" ) then x = reaper.GetExtState( script_name, "W_X" ) end
  if reaper.HasExtState( script_name, "W_Y" ) then y = reaper.GetExtState( script_name, "W_Y" ) end
  gfx.init(project_name, w, h, d, x, y )
  window = reaper.JS_Window_Find( project_name, 1 ) if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
  
  -- get project variables, if they exist
  local pjxretval, pjxval = reaper.GetProjExtState( 0, "Dfk", "V_H" ) if pjxretval > 0 then V_H = tonumber(pjxval) end
  pjxretval, pjxval = reaper.GetProjExtState( 0, "Dfk", "V_Z" ) if pjxretval > 0 then V_Z = tonumber(pjxval) end
  pjxretval, pjxval = reaper.GetProjExtState( 0, "Dfk", "V_V" ) if pjxretval > 0 then V_V = tonumber(pjxval) end
  pjxretval, pjxval = reaper.GetProjExtState( 0, "Dfk", "G_S" ) if pjxretval > 0 then if pjxval == "false" then grid_snap = false else grid_snap = true end end
  
  -- gui objects
  if folder then
  
  for a = 1, 5 do gui[a] = {obj = {}} end
  --MARQUEE SELECTOR--------------------------------------------------------------------
  	gui[3].obj[1] = {
	id         = 1,                                                -- object classification (optional)
	caption    = "", -- caption display
	hc         = 0,                                                -- current hover alpha (default '0')
	ha         = .05,                                              -- hover alpha
	hca        = .1,                                               -- hover click alpha 
	ol         = {r=1,g=1,b=1,a=0},                               -- rect: object's outline
	r          = 0,                                               -- r
	g          = 1,                                                -- g
	b          = 0,                                               -- b
	a          = 0,                                               -- a
	f          = 0,                                                -- rect: filled	
	x          = 0,                                                -- x
	y          = 0,                                                -- y
	w          = 0,                                                -- w
	h          = 0,                                                -- h
	can_zoom   = false,                                             -- whether object rectangle zooms with global
	can_scroll = false,                                            -- whether object rectangle scrolls with global 
	act_off    = 2,                                                -- if 1, object action is disabled. if 2, disabled & mouse input is passed through 
	button     = {},                                               -- index of buttons that object holds
	static     = {},                                               -- index of static graphics that object holds
	func       = 
		{ -- functions receive object index and bool release ('r')
		-- always-run function
		[-1]      = function(self,g,o) end, 
		-- non-indexed function
		[0]      = function(self,o,r,d) if r then msg("release") return else msg("Dclick") end end, 
		-- mouse_cap functions
		[1]      = function(self,o,r,d) if r then msg("release") return else msg("Lclick") end end, 
		[2]      = function(self,o,r,d) if r then msg("release") return else msg("Rclick") end end, 
		[3]      = function(self,o,r,d) if r then msg("release") return else msg("Mclick") end end, 
		},
	mouse      =
		{ -- index [1] must always be left-click
		[1]        = 1,                
		[2]        = 2,
		[3]        = 18
		},
	hold       = 
		{
		[1]        = true,
		[2]        = false,
		[3]        = false
		}
	}
  --GRID OBJECT-------------------------------------------------------------------------
  gui[1].obj[1] =  {
    id    = -9,           -- identifies object for looped-processing
    caption = "M/Shf+L: scroll, R: menu",
    level = 1,
    sel   = false,       -- whether or not object is selected (for marquee)
    hc    = 0,           -- current hover alpha (default '0')
    ha    = 0,         -- hover alpha
    hca   = 0,          -- hover click alpha 
    ol    = {r=0,g=0,b=0,a=0}, -- rect: button's outline ol    
    r     = 0,            -- rect: red
    g     = 0,           -- rect: green
    b     = 0,           -- rect: blue
    a     = 0,           -- rect: alpha
    f     = 0,            -- rect: filled  
    x     = 0,
    y     = 0,
    w     = 0,
    h     = 0,
    can_zoom = false,
    can_scroll = false,
    button = {},
    static = {},
    func = 
      {
      --[0] = function(self,o,r,d) if r then msg("release") return end  end, 
      [1] = function(self,o,r,d) 
        if not marquee_x then marquee_x, marquee_y = gfx.mouse_x, gfx.mouse_y end
		local xx, yy, ww, hh = -1,-1,-1,-1
		if gfx.mouse_x > marquee_x then xx, ww = marquee_x, gfx.mouse_x-marquee_x else xx, ww = gfx.mouse_x, marquee_x-gfx.mouse_x end 
		if gfx.mouse_y > marquee_y then yy, hh = marquee_y, gfx.mouse_y-marquee_y else yy, hh = gfx.mouse_y, marquee_y-gfx.mouse_y end 
		gui[3].obj[1].a = 1
		gui[3].obj[1].x = xx
		gui[3].obj[1].y = yy
		gui[3].obj[1].w = ww
		gui[3].obj[1].h = hh

			if r 
		  then
				for z = 1, #gui[2].obj
			do
				gui[2].obj[z].sel = nil
			end
				for z = 1, #gui[2].obj
			do
				if gui[2].obj[z].x+100 > ((xx+(V_H*V_Z))/V_Z) and gui[2].obj[z].x < (((xx+ww)+(V_H*V_Z))/V_Z) and 
				gui[2].obj[z].y+gui[2].obj[z].h > ((yy+(V_V*V_Z))/V_Z) and gui[2].obj[z].y < (((yy+hh)+(V_V*V_Z))/V_Z) 
				then gui[2].obj[z].sel = true end update.time = 0
			end
			gui[3].obj[1].a = 0 marquee_x, marquee_y = nil, nil return 
		  end  
	  end, 
      [2] = 
	  function(self,o,r,d) 
        if r then msg("release") return end 
        if d then msg("delay") return end 
      
        -- view scrolling
        if mouseGrab_y then scrollGrab_x, scrollGrab_y = mouseGrab_x, mouseGrab_y mouseGrab_x, mouseGrab_y = nil, nil end
        V_V = V_V + ((scrollGrab_y-my)/V_Z)*V_S 
        V_H = V_H + ((scrollGrab_x-mx)/V_Z)*V_S 
        scrollGrab_x, scrollGrab_y = mx, my
        -------------------------------------
	  end, 
      [3]      = 
      function(self,o,r,d) 
      
        if r then msg("release") return end 
        if d then msg("delay") return end 
      
        -- view scrolling
        if mouseGrab_y then scrollGrab_x, scrollGrab_y = mouseGrab_x, mouseGrab_y mouseGrab_x, mouseGrab_y = nil, nil end
        V_V = V_V + ((scrollGrab_y-my)/V_Z)*V_S 
        V_H = V_H + ((scrollGrab_x-mx)/V_Z)*V_S 
        scrollGrab_x, scrollGrab_y = mx, my
        -------------------------------------
	  end,	
	  [4] = 
	  function(self,o,r,d)
			if r 
		then
			local g_snap = "" if grid_snap == true then g_snap = "!Disable snap-to-grid" else g_snap = "Enable snap-to-grid" end
			gfx.x, gfx.y = mx, my local choice = gfx.showmenu("Insert track||"..g_snap )
				if choice == 1
			then
				if Pin_window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
				local nmretval, nmretvals_csv = reaper.GetUserInputs( "[Input]", 1, "Track name", "[track]" )
					if nmretval
				then
					insert_x = math.floor(((((mx+(V_H*V_Z))/V_Z)/100)+.5))*100
					insert_y = math.floor(((((my+(V_V*V_Z))/V_Z)/100)+.5))*100
					insert_name = tostring(nmretvals_csv)
					reaper.InsertTrackAtIndex( 0, true )
				end
				if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
				elseif choice == 2
			then
				if grid_snap == true then grid_snap = false else grid_snap = true end
			end
		end
      end                      -- functions receive object index
      },
    mouse =
      {
      [1] = 1,
      [2] = 9,
      [3] = 64,
	  [4] = 2
      },
    hold = 
      {
      [1] = true,
      [2] = true,
      [3] = true,
	  [4] = false
      },
    }
  -- GRID STATIC RECTANGLES
  -- V LINES
    for g = 1, math.ceil(grid_w/2)
  do
    gui[1].obj[1].static[g] = {
    type       = "rect",               -- draw type
    ol         = {r=0,g=0,b=0,a=0},   -- rectangle static's outline
    r          = .3,                   -- r
    g          = .3,                   -- g
    b          = .3,                   -- b
    a          = .5,                   -- alpha
    x          = ((g-1)*grid_size)*2,                    -- x
    y          = 0,                    -- y
    w          = grid_size,                   -- width
    h          = grid_w*grid_size,                   -- height
    f          = 0,                    -- filled  
    can_zoom   = true,                 -- whether static zooms with global
    can_scroll = true                 -- whether static scrolls with global
    }
  end
  -- H LINES
    for h = 1, math.ceil(grid_h/2)
  do local g = #gui[1].obj[1].static+1
    gui[1].obj[1].static[g] = {
    type       = "rect",               -- draw type
    ol         = {r=0,g=0,b=0,a=0},   -- rectangle static's outline
    r          = .3,                   -- r
    g          = .3,                   -- g
    b          = .3,                   -- b
    a          = .5,                   -- alpha
    x          = 0,                    -- x
    y          = ((h-1)*grid_size)*2,                    -- y
    w          = grid_h*grid_size,                   -- width
    h          = grid_size,                   -- height
    f          = 0,                    -- filled  
    can_zoom   = true,                 -- whether static zooms with global
    can_scroll = true                 -- whether static scrolls with global
    }
  end
  -- HORIZONTAL SCROLL BAR
  gui[5].obj[1] = {
  id         = 2,                                                 -- object classification
  level      = 1,
  caption    = "L: adjust horizontal scroll",  -- caption display
  hc         = 0,                                                 -- current hover alpha (default '0')
  ha         = .05,                                                -- hover alpha
  hca        = .1,                                                -- hover click alpha 
  ol         = {r=1,g=1,b=1,a=.2},                                -- rect: object's outline
  r          = .5,                                                -- rect: red
  g          = .5,                                                -- rect: green
  b          = .5,                                                -- rect: blue
  a          = .97,                                                -- rect: alpha
  f          = 1,                                                 -- rect: filled  
  x          = 0,                                                 -- x
  y          = gfx.h-20,                                          -- y
  w          = gfx.w,                                             -- w
  h          = 20,                                                -- h
  can_zoom   = false,                                             -- whether object rectangle zooms with global
  can_scroll = false,                                             -- whether object rectangle scrolls with global     
  button     = {},                                                -- index of buttons that object holds
  static     = {},                                                -- index of static graphics that object holds
  func       = 
    { 
    -- non-indexed function
    --[0]      = function(o,r) if r then msg("release") return end  end,                     -- functions receive object index
    -- mouse_cap functions
    [1]      = 
    function(self,o,r,d) local gmx = gfx.mouse_x 
    
        if r
      then
        msg("release!")
        self.button[1].a = 0
        self.button[1].ol.a = 0
        return 
      end
    
      if gmx > gfx.w-25 then gmx = gfx.w-25 end if gmx < 25 then gmx = 25 end
      gmx = gmx - 25
      
      V_H = ((grid_size*grid_w)-(gfx.w/V_Z))*(gmx/(gfx.w-50)) --V_H = V_H / V_Z
        
      self.button[1].a = 1
      self.button[1].ol.a = .2
      local ax = (gfx.w-50)*   ( V_H / ((grid_size*grid_w)-(gfx.w/V_Z)) )
      self.button[1].x = ax
        
    end,                     -- functions receive object index
    [2]      = function(o,r) if r then msg("release") return end  end,                     -- functions receive object index 
    [3]      = function(o,r) if r then msg("release") return end  end                      -- functions receive object index
    },
  mouse      =
    { -- index [1] must always be left-click
    [1]        = 1,                
    [2]        = 2,
    [3]        = 64
    },
  hold       = 
    {
    [1]        = true,
    [2]        = false,
    [3]        = false
    }
  }
  gui[5].obj[1].button[1] = {
  id         = 1,                                                 -- button classification
  caption    = "",  -- caption display
  type       = "rect",                                            -- draw type: "rect" or "circ"
  ol         = {r=1,g=1,b=1,a=0},                                -- rect: button's outline
  hc         = 0,                                                 -- current hover alpha (default '0')
  ha         = .05,                                                -- hover alpha
  hca        = .1,                                                -- hover click alpha 
  r          = .1,                                                -- r     (rect)
  g          = .1,                                                -- g     (rect)
  b          = .1,                                                -- b     (rect)
  a          = 0,                                                 -- alpha (rect)
  rt         = .5,                                                -- r     (text)
  gt         = .5,                                                -- g     (text)
  bt         = .5,                                                -- b     (text)
  at         = .5,                                                -- alpha (text)
  x          = 0,                                                 -- x
  y          = 1,                                                 -- y
  w          = 50,                                                -- width
  h          = 18,                                                -- height
  f          = 1,                                                 -- filled
  rs         = 10,                                                -- circle: radius
  aa         = true,                                              -- circle: antialias         
  txt        = "",                                                -- text: "" disables text for button
  th         = 1,                                                 -- text 'h' flag
  tv         = 4,                                                 -- text 'v' flag  
  fo         = "Arial",                                           -- font settings will have no affect unless: font_changes = true
  fs         = 12,                                                -- font size
  ff         = nil,                                               -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
  can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
  can_scroll = false,                                             -- whether object rectangle scrolls with global   
  act_off    = 2,  
  func       = 
    { 
    -- non-indexed function
    [0]        = function(o,b,r) if r then msg("release") return end end,                 -- functions receive object and button index
    -- mouse_cap functions
    [1]        = function(o,b,r) if r then msg("release") return end end,                 -- functions receive object and button index
    [2]        = function(o,b,r) if r then msg("release") return end end,                 -- functions receive object and button index
    [3]        = function(o,b,r) if r then msg("release") return end end                  -- functions receive object and button index
    },
  mouse      =
    {
    [1]        = 1,             -- index [1] must always be left click
    [2]        = 2,
    [3]        = 64
    },
  hold       = 
    {
    [1]        = true,
    [2]        = false,
    [3]        = false
    }
  }
    gui[5].obj[1].button[2] = {
  id         = 1,                                                 -- button classification
  caption    = "L: center horizontal scroll on grid",    -- caption display
  type       = "rect",                                            -- draw type: "rect" or "circ"
  ol         = {r=1,g=1,b=1,a=.2},                                -- rect: button's outline
  hc         = 0,                                                 -- current hover alpha (default '0')
  ha         = .05,                                                -- hover alpha
  hca        = .1,                                                -- hover click alpha 
  r          = .1,                                                -- r     (rect)
  g          = .1,                                                -- g     (rect)
  b          = .1,                                                -- b     (rect)
  a          = .25,                                               -- alpha (rect)
  rt         = .5,                                                -- r     (text)
  gt         = .5,                                                -- g     (text)
  bt         = .5,                                                -- b     (text)
  at         = .5,                                                -- alpha (text)
  x          = (gfx.w/2)-25,                                      -- x
  y          = 1,                                                 -- y
  w          = 50,                                                -- width
  h          = 18,                                                -- height
  f          = 1,                                                 -- filled
  rs         = 10,                                                -- circle: radius
  aa         = true,                                              -- circle: antialias         
  txt        = "",                                                -- text: "" disables text for button
  th         = 1,                                                 -- text 'h' flag
  tv         = 4,                                                 -- text 'v' flag  
  fo         = "Arial",                                           -- font settings will have no affect unless: font_changes = true
  fs         = 12,                                                -- font size
  ff         = nil,                                               -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
  can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
  can_scroll = false,                                             -- whether object rectangle scrolls with global   
  func       = 
    { 
    -- non-indexed function
    --[0]        = function(o,b,r) msg("Dclick") end,                 -- functions receive object and button index
    -- mouse_cap functions
    [1]        = 
    function(self,o,b,r,d) local gmx = self.x+25
      
      self.a = 1
      if r then self.a = .25 end
      V_H = ((grid_size*grid_w)-(gfx.w/V_Z))*(gmx/(gfx.w-50)) --V_H = V_H / V_Z
      
    end,                                                                                    -- functions receive object and button index
    [2]        = function(o,b,r) if r then msg("release") return end  end,                 -- functions receive object and button index
    [3]        = function(o,b,r) if r then msg("release") return end  end                  -- functions receive object and button index
    },
  mouse      =
    {
    [1]        = 1,             -- index [1] must always be left click
    [2]        = 2,
    [3]        = 64
    },
  hold       = 
    {
    [1]        = true,
    [2]        = false,
    [3]        = false
    }
  }
  -- CROSSHAIR STATIC LINE
  gui[5].obj[1].static[1] = {
  type       = "line",               -- draw type
  r          = 1,
  g          = 0,
  b          = 0,
  a          = Crosshair_Visibility,
  x          = 0,                    -- x
  y          = 0,                    -- y
  xx         = 100,                  -- x2
  yy         = 15,                   -- y2
  aa         = 1,                    -- antialias
  can_zoom   = false,                -- whether static zooms with global
  can_scroll = false                 -- whether static scrolls with global
  }
    -- CROSSHAIR STATIC LINE
  gui[5].obj[1].static[2] = {
  type       = "line",               -- draw type
  r          = 1,
  g          = 0,
  b          = 0,
  a          = Crosshair_Visibility,
  x          = 0,                    -- x
  y          = 0,                    -- y
  xx         = 100,                  -- x2
  yy         = 15,                   -- y2
  aa         = 1,                    -- antialias
  can_zoom   = false,                -- whether static zooms with global
  can_scroll = false                 -- whether static scrolls with global
  }
  -- VERTICAL SCROLL BAR
  gui[5].obj[2] = {
  id         = 2,                                                 -- object classification
  caption    = "L: adjust vertical scroll",  -- caption display
  level = 2,
  hc         = 0,                                                 -- current hover alpha (default '0')
  ha         = .05,                                                -- hover alpha
  hca        = .1,                                                -- hover click alpha 
  ol         = {r=1,g=1,b=1,a=.2},                                -- rect: object's outline
  r          = .5,                                                -- rect: red
  g          = .5,                                                -- rect: green
  b          = .5,                                                -- rect: blue
  a          = .97,                                                -- rect: alpha
  f          = 1,                                                 -- rect: filled  
  x          = gfx.w-20,                                                 -- x
  y          = 0,                                          -- y
  w          = 20,                                             -- w
  h          = gfx.h,                                                -- h
  can_zoom   = false,                                             -- whether object rectangle zooms with global
  can_scroll = false,                                             -- whether object rectangle scrolls with global     
  button     = {},                                                -- index of buttons that object holds
  static     = {},                                                -- index of static graphics that object holds
  func       = 
    { 
    -- non-indexed function
    --[0]      = function(o,r) if r then msg("release") return end  end,                     -- functions receive object index
    -- mouse_cap functions
    [1]      = 
    function(self,o,r,d) local gmy = gfx.mouse_y 
    
        if r
      then
        msg("release!")
        self.button[1].a = 0
        self.button[1].ol.a = 0
        return
      end
    
      if gmy > gfx.h-45 then gmy = gfx.h-45 end if gmy < 25 then gmy = 25 end
      gmy = gmy - 25
      
      V_V = ((grid_size*grid_w)-(gfx.h/V_Z))*(gmy/(gfx.h-70)) --V_V = V_V / V_Z
        
      self.button[1].a = 1
      self.button[1].ol.a = .2
      local ay = (gfx.h-70)*   ( V_V / ((grid_size*grid_w)-(gfx.h/V_Z)) )
      self.button[1].y = ay
    
    end,                     -- functions receive object index
    [2]      = function(o,r) if r then msg("release") return end  end,                     -- functions receive object index 
    [3]      = function(o,r) if r then msg("release") return end  end                      -- functions receive object index
    },
  mouse      =
    { -- index [1] must always be left-click
    [1]        = 1,                
    [2]        = 2,
    [3]        = 64
    },
  hold       = 
    {
    [1]        = true,
    [2]        = false,
    [3]        = false
    }
  }
  gui[5].obj[2].button[1] = {
  id         = 1,                                                 -- button classification
  caption    = "",  -- caption display
  type       = "rect",                                            -- draw type: "rect" or "circ"
  ol         = {r=1,g=1,b=1,a=0},                                -- rect: button's outline
  hc         = 0,                                                 -- current hover alpha (default '0')
  ha         = .05,                                                -- hover alpha
  hca        = .1,                                                -- hover click alpha 
  r          = .1,                                                -- r     (rect)
  g          = .1,                                                -- g     (rect)
  b          = .1,                                                -- b     (rect)
  a          = 0,                                                 -- alpha (rect)
  rt         = .5,                                                -- r     (text)
  gt         = .5,                                                -- g     (text)
  bt         = .5,                                                -- b     (text)
  at         = .5,                                                -- alpha (text)
  x          = 0,                                                 -- x
  y          = -100,                                              -- y
  w          = 18,                                                -- width
  h          = 50,                                                -- height
  f          = 1,                                                 -- filled
  rs         = 10,                                                -- circle: radius
  aa         = true,                                              -- circle: antialias         
  txt        = "",                                                -- text: "" disables text for button
  th         = 1,                                                 -- text 'h' flag
  tv         = 4,                                                 -- text 'v' flag  
  fo         = "Arial",                                           -- font settings will have no affect unless: font_changes = true
  fs         = 12,                                                -- font size
  ff         = nil,                                               -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
  can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
  can_scroll = false,                                             -- whether object rectangle scrolls with global   
  act_off    = 2,  
  func       = 
    { 
    -- non-indexed function
    [0]        = function(o,b,r) if r then msg("release") return end end,                 -- functions receive object and button index
    -- mouse_cap functions
    [1]        = function(o,b,r) if r then msg("release") return end end,                                                          -- functions receive object and button index
    [2]        = function(o,b,r) if r then msg("release") return end end,                 -- functions receive object and button index
    [3]        = function(o,b,r) if r then msg("release") return end end                  -- functions receive object and button index
    },
  mouse      =
    {
    [1]        = 1,             -- index [1] must always be left click
    [2]        = 2,
    [3]        = 64
    },
  hold       = 
    {
    [1]        = true,
    [2]        = false,
    [3]        = false
    }
  }
    gui[5].obj[2].button[2] = {
  id         = 1,                                                 -- button classification
  caption    = "L: center vertical scroll on grid",    -- caption display
  type       = "rect",                                            -- draw type: "rect" or "circ"
  ol         = {r=1,g=1,b=1,a=.2},                                -- rect: button's outline
  hc         = 0,                                                 -- current hover alpha (default '0')
  ha         = .05,                                                -- hover alpha
  hca        = .1,                                                -- hover click alpha 
  r          = .1,                                                -- r     (rect)
  g          = .1,                                                -- g     (rect)
  b          = .1,                                                -- b     (rect)
  a          = .25,                                               -- alpha (rect)
  rt         = .5,                                                -- r     (text)
  gt         = .5,                                                -- g     (text)
  bt         = .5,                                                -- b     (text)
  at         = .5,                                                -- alpha (text)
  x          = 0,                                      -- x
  y          = 100,                                                 -- y
  w          = 18,                                                -- width
  h          = 50,                                                -- height
  f          = 1,                                                 -- filled
  rs         = 10,                                                -- circle: radius
  aa         = true,                                              -- circle: antialias         
  txt        = "",                                                -- text: "" disables text for button
  th         = 1,                                                 -- text 'h' flag
  tv         = 4,                                                 -- text 'v' flag  
  fo         = "Arial",                                           -- font settings will have no affect unless: font_changes = true
  fs         = 12,                                                -- font size
  ff         = nil,                                               -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
  can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
  can_scroll = false,                                             -- whether object rectangle scrolls with global   
  func       = 
    { 
    -- non-indexed function
    --[0]        = function(o,b,r) if r then msg("release") return end  end,                 -- functions receive object and button index
    -- mouse_cap functions
    [1]        = 
      function(self,o,b,r) local gmy = self.y-25
      
        self.a = 1
        if r then self.a = .25 end
        V_V = ((grid_size*grid_w)-(gfx.h/V_Z))*(gmy/(gfx.h-70)) --V_V = V_V / V_Z
          
      end,                                                                               -- functions receive object and button index
    [2]        = function(o,b,r) if r then msg("release") return end  end,                 -- functions receive object and button index
    [3]        = function(o,b,r) if r then msg("release") return end  end                  -- functions receive object and button index
    },
  mouse      =
    {
    [1]        = 1,             -- index [1] must always be left click
    [2]        = 2,
    [3]        = 64
    },
  hold       = 
    {
    [1]        = true,
    [2]        = false,
    [3]        = false
    }
  }
  end
  -- MASTER TRACK
  if folder then 
    local track = reaper.GetMasterTrack( 0 )
    local tname_retval, tname_buf = reaper.GetTrackName( track ) 
    --TRACK OBJECT-------------------------------------------------------------------------
    gui[4].obj[1] =  {
      id    = 1,            -- identifies object for looped-processing
      caption = "",
      level = 1,
      sel   = false,        -- whether or not object is selected (for marquee)
      hc    = 0,            -- current hover alpha (default '0')
      ha    = 0,            -- hover alpha
      hca   = 0,           -- hover click alpha 
      ol    = {r=.7,g=.7,b=.7,a=1}, -- rect: button's outline ol    
      r     = .3,           -- rect: red
      g     = .3,            -- rect: green
      b     = .3,           -- rect: blue
      a     = .97,           -- rect: alpha
      f     = 1,            -- rect: filled  
      x     = gfx.w-120,
      y     = 0,
      w     = 100,
      h     = gfx.h-20,
      can_zoom = false,
      can_scroll = false,
      blur_under = true,                  
      button = {},
      static = {},
      func = 
      {
      [0] = function(o,r) if r then msg("release") return end  end, 
      [1] = function(self,o,r,d) end,
      [2] = function(o,r) if r then msg("release") return end  end, 
      [3] = function(o,r) if r then msg("release") return end  end, 
      },
      mouse =
      {
      [1] = 1,
      [2] = 2,
      [3] = 64
      },
      hold = 
      {
      [1] = true,
      [2] = false,
      [3] = true
      },
      track = track,
      track_name = tname_buf
      }  
    --BOX TITLE-------------------------------------------------------------------------
    local cr, cg, cb = reaper.ColorFromNative( reaper.GetTrackColor( track ) ) cr,cg,cb = (cr/255)-(cr/510),(cg/255)-(cg/510),(cb/255)-(cb/510) --ensure colors aren't too bright
    gui[4].obj[1].button[1] = {
      id    = 1,       -- identifies object for looped-processing
      caption = "master track",
      type  = "rect",  -- draw type: "rect" or "circ"
      ol    = {r=0,g=0,b=0,a=1},  -- rect: button's outline
      hc    = 0,       -- current hover alpha (default '0')
      ha    = .1,      -- hover alpha
      hca   = .2,      -- hover click alpha 
      r     = cr,      -- r     (rect)
      g     = cg,       -- g     (rect)
      b     = cb,      -- b     (rect)
      a     = .9,      -- alpha (rect)
      rt    = 1,       -- r     (text)
      gt    = 1,       -- g     (text)
      bt    = 1,       -- b     (text)
      at    = 1,       -- alpha (text)
      x     = 0,       -- x
      y     = 0,       -- y
      w     = 100,     -- width
      h     = 20,      -- height
      f     = 1,       -- filled
      txt   = tname_buf, -- text
      th    = 1,       -- text 'h' flag
      tv    = 4,       -- text 'v' flag  
      fo    = "Arial", -- font settings will have no affect unless: font_changes = true
      fs    = 12,      -- font size
      ff    = "b",     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
      can_zoom = false,
      can_scroll = false,
      func  = 
      { 
      [0]   = function(self,o,b,r,d) end, 
      [1]   = function(o,b,r) msg("Lclick *") end,
      [2]   = function(o,b,r) msg("Rclick") end, 
      [3]   = function(o,b,r) msg("Mclick") end
      },
      mouse =
      {
      [1]   = 1,
      [2]   = 2,
      [3]   = 64
      },
      hold  = 
      {
      [1]   = false,
      [2]   = false,
      [3]   = true
      }
      }   
    --RECEIVE BUTTON LINE-------------------------------------------------------------------------
    gui[4].obj[1].button[2] = {
      id    = -2,       -- identifies object for looped-processing
      caption = "track receive: click-and-drag from a send",
      type  = "circ",  -- draw type: "rect" or "circ"
      ol    = {r=0,g=0,b=0,a=1},  -- rect: button's outline
      hc    = 0,       -- current hover alpha (default '0')
      ha    = .1,      -- hover alpha
      hca   = .2,      -- hover click alpha 
      r     = 1,       -- r     (rect)
      g     = 1,       -- g     (rect)
      b     = 0,       -- b     (rect)
      a     = .9,      -- alpha (rect)
      rt    = 1,       -- r     (text)
      gt    = 1,       -- g     (text)
      bt    = 1,       -- b     (text)
      at    = 0,       -- alpha (text)
      x     = -1,       -- x
      y     = 0,       -- y
      w     = 20,     -- width
      h     = 20,      -- height
      f     = 1,       -- filled
      rs         = 9,                                               -- circle: radius
      aa         = true,                                             -- circle: antialias    
      txt   = "",      -- text
      th    = 1,       -- text 'h' flag
      tv    = 4,       -- text 'v' flag  
      fo    = "Arial", -- font settings will have no affect unless: font_changes = true
      fs    = 12,      -- font size
      ff    = "b",     -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
      can_zoom = false,
      can_scroll = false,
      func  = 
      { 
      --[0]   = function(o,b,r,d) end, 
      [1]   = 
      function(o,b,r) 
        msg("Lclick") 
      end,
      [2]   = function(o,b,r) msg("Rclick") end, 
      [3]   = function(o,b,r) msg("Mclick") end
      },
      mouse =
      {
      [1]   = 1,
      [2]   = 2,
      [3]   = 64
      },
      hold  = 
      {
      [1]   = true,
      [2]   = false,
      [3]   = true
      }
      }
    
  end -- if folder
  -- gui[4].obj[2] (LINES)
  if folder then
  gui[4].obj[2] = {
	id         = 1,                                                -- object classification (optional)
	caption    = "", -- caption display
	hc         = 0,                                                -- current hover alpha (default '0')
	ha         = .05,                                              -- hover alpha
	hca        = .1,                                               -- hover click alpha 
	ol         = {r=1,g=1,b=1,a=.2},                               -- rect: object's outline
	r          = .7,                                               -- r
	g          =.6,                                                -- g
	b          = .2,                                               -- b
	a          = .5,                                               -- a
	f          = 1,                                                -- rect: filled	
	x          = 0,                                                -- x
	y          = 0,                                                -- y
	w          = 0,                                                -- w
	h          = 0,                                                -- h
	can_zoom   = true,                                             -- whether object rectangle zooms with global
	can_scroll = false,                                            -- whether object rectangle scrolls with global 
	act_off    = 2,                                                -- if 1, object action is disabled. if 2, disabled & mouse input is passed through 
	blur_under = false,                                             -- whether to blur under object rectangles w/ transparency
	button     = {},                                               -- index of buttons that object holds
	static     = {},                                               -- index of static graphics that object holds
	func       = 
		{ -- functions receive object index and bool release ('r')
		-- always-run function
		[-1]      = function(self,o,r,d) end, 
		-- non-indexed function
		[0]      = function(self,o,r,d) if r then msg("release") return else msg("Dclick") end end, 
		-- mouse_cap functions
		[1]      = function(self,o,r,d) if r then msg("release") return else msg("Lclick") end end, 
		[2]      = function(self,o,r,d) if r then msg("release") return else msg("Rclick") end end, 
		[3]      = function(self,o,r,d) if r then msg("release") return else msg("Mclick") end end, 
		},
	mouse      =
		{ -- index [1] must always be left-click
		[1]        = 1,                
		[2]        = 2,
		[3]        = 18
		},
	hold       = 
		{
		[1]        = true,
		[2]        = false,
		[3]        = false
		}
	}
  end
  
  main()
end

function resize_window()
    if reaper.JS_Mouse_GetState(1) == 0
  then
    local wd, wx, wy, ww, wh = gfx.dock( -1, 0, 0, 0, 0 )
    if ww < window_xMin then ww = window_xMin gfx.init("",window_xMin,wh,wd,wx,wy )end 
    if ww > window_xMax then ww = window_xMax gfx.init("",window_xMax,wh,wd,wx,wy )end 
    if wh < window_yMin then wh = window_yMin gfx.init("",ww,window_yMin,wd,wx,wy )end 
    if wh > window_yMax then gfx.init("",ww,window_yMax,wd,wx,wy )end 
  end
end

function update_dynamic_variables()

  -- grid
  gui[1].obj[1].w = gfx.w
  gui[1].obj[1].h = gfx.h

  -- horizontal scroll bar
  gui[5].obj[1].y = gfx.h-20
  gui[5].obj[1].w = gfx.w
  gui[5].obj[1].button[2].x = (gfx.w/2)-25
  
    -- crosshair
    gui[5].obj[1].static[1].x, gui[5].obj[1].static[1].xx = (gfx.w/2)-(Crosshair_Size/2)-gui[5].obj[1].x, (gfx.w/2)+(Crosshair_Size/2) 
    gui[5].obj[1].static[1].y, gui[5].obj[1].static[1].yy = (gfx.h/2)-(Crosshair_Size/2)-gui[5].obj[1].y, (gfx.h/2)+(Crosshair_Size/2)
    gui[5].obj[1].static[2].x, gui[5].obj[1].static[2].xx = (gfx.w/2)-(Crosshair_Size/2)-gui[5].obj[1].x, (gfx.w/2)+(Crosshair_Size/2)
    gui[5].obj[1].static[2].y, gui[5].obj[1].static[2].yy = (gfx.h/2)+(Crosshair_Size/2)-gui[5].obj[1].y, (gfx.h/2)-(Crosshair_Size/2)
  
  --vertical scroll bar
  gui[5].obj[2].x = gfx.w-20
  gui[5].obj[2].h = gfx.h-20
  gui[5].obj[2].button[2].y = (gfx.h/2)-25
  
  -- master track box
  gui[4].obj[1].x, gui[4].obj[1].h = gfx.w-120, gfx.h-20

end

--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~
function main() 

  update_boxes()
  connect_lines()

  resize_window()
  update_dynamic_variables()
  
  view_zoom()
  check_mouse() 
  gui_funcs()
  draw()
  --msg((gfx.mouse_x+(V_H*V_Z))/V_Z)
  if gfx.getchar() ~= -1 and gfx.getchar(27) ~= 1 then reaper.defer(main) end

end
--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~

function delete_ext_states()
  --delete window ext states
  reaper.DeleteExtState( script_name, "W_D", 1 ) 
  reaper.DeleteExtState( script_name, "W_W", 1 ) 
  reaper.DeleteExtState( script_name, "W_H", 1 ) 
  reaper.DeleteExtState( script_name, "W_X", 1 ) 
  reaper.DeleteExtState( script_name, "W_Y", 1 )
  --delete project ext states
  reaper.SetProjExtState(0, "Dfk", "", "")
  reaper.SetProjExtState(0, "Dfk2", "", "")
end

function exit()
  -- save window data
  local wd, wx, wy, ww, wh = gfx.dock( -1, 0, 0, 0, 0 )
  reaper.SetExtState( script_name, "W_D",  wd, true )
  reaper.SetExtState( script_name, "W_X",  wx, true )
  reaper.SetExtState( script_name, "W_Y",  wy, true )
  reaper.SetExtState( script_name, "W_W",  ww, true )
  reaper.SetExtState( script_name, "W_H",  wh, true )
  
  --save project data
  local obj = gui[2].obj
    for a = 1, #obj
  do  
      if reaper.ValidatePtr(obj[a].track, 'MediaTrack*')
    then
	  -- tracks
      reaper.SetProjExtState( 0, "Dfk", reaper.GetTrackGUID( obj[a].track ), obj[a].x )
      reaper.SetProjExtState( 0, "Dfk2", reaper.GetTrackGUID( obj[a].track ), obj[a].y )
	  -- collapsed state
	  reaper.SetProjExtState( 0, "Dfk", reaper.GetTrackGUID( obj[a].track ).."CS", tostring(obj[a].collapsed) )
    end
  end
  reaper.SetProjExtState( 0, "Dfk", "V_H", V_H )
  reaper.SetProjExtState( 0, "Dfk", "V_V", V_V )
  reaper.SetProjExtState( 0, "Dfk", "V_Z", V_Z )
  reaper.SetProjExtState( 0, "Dfk", "G_S", tostring(grid_snap) )
  
end

--delete_ext_states()
reaper.atexit(exit)
init()


