function msg(param, clr) if clr then reaper.ClearConsole() end reaper.ShowConsoleMsg(tostring(param).."\n") end function up() reaper.UpdateTimeline() reaper.UpdateArrange() end 

--[[
Dfk's Custom Toolbar Utility
CATEGORY OF USE: Workspace Utility
AUTHOR: Dafarkias
LEGAL RAMIFICATIONS: GPL v.3
COCKOS REAPER THREAD: https://forum.cockos.com/showthread.php?t=231684   
]]local VERSION = "0.83"--[[
REAPER: 6.03 (version used in development)
EXTENSIONS: js_ReaScriptAPI v0.999 (version used in development)

[v0.5] 
		*(script release)
[v0.6]
		*(complete overhaul)
[v0.61]
		*(various stuff)
[v.7]
		*.png images for buttons
[v.8]
		*bugs
		*script can be "paused" to reduce cpu usage
		*toggle state
[v.81]
		*bug
		*Added option to set background width and height, and autosize 
[v.81a]
		*quick-fix
[v.81b]
		*quick-fix
[v.82]
		*tooltip captions after hovering for 3+ seconds
		*automatically bring keyboard focus to arrange view after button/menu activation
[v.83]
		*run multiple instances of the script simultaneously by duplicating, renaming with a unique name, and loading into REAPER.
		*automatically bring keyboard focus to arrange view after button/menu activation (second attempt)
		*'Exit (save)' and 'Exit (discard changes)' added to main menu
		*'Escape' key no longer exits script
--]]

--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA
--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA
--
local Menu_Correction                   = 22.5    -- 22.5: adjust by small values to adjust the y-positioning of the Up-Menu
local Tool_Tips                         = true    -- true/false: whether or not 'tooltips' are enabled for the script
local Font_Type                         = "Arial" -- "Arial": "Times New Roman", "Helvetica" etc.
--
--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA
--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA

-- window vars
function getPath(str) return str:match("(.*[/\\])") end
local is_new_value,filename2,sectionID,cmdID,mode,resolution,val = reaper.get_action_context() local filename = getPath(filename2) local NAME = filename2:sub(filename:len()+1) if NAME:lower():find(".lua") then NAME=NAME:sub(1,NAME:len()-4)end 

local _,_,display_w,display_h = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true )
local window_name = NAME.." v"..VERSION
local window, window_timer = 0, reaper.time_precise()
local auto_window = nil

-- misc vars
local default_col = 8355711
local NEW_folder, GUI_folder, LOAD_folder = true, true, true
local fontSize = 20 
local snap = true
local grid = 50
local current_project = "What a strange name for a string" local cx, cy, cw, ch = gfx.x, gfx.y, gfx.w, gfx.h
local backgroundImage, bakw, bakh, BG_stretch = "", 0, 0, "Stretch"
local caption_timer, caption_timer2 = 0, 0
local counter = -1 
local kill = false
local SAVE = true
local quit = false

local pos = 0

function get_iid() counter = counter + 1 return counter end

function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end

if GUI_folder
then
--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES
--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES
--
local dClick_time           = .2    -- amount of time that left double-click action must be performed in, by user, in decimal seconds
font_changes                = false  -- enabling multiple fonts/font changes can greatly increase draw times
local mouseCursor_changes   = false -- dis/en-able multiple mouse cursors in script
local view_zoom_sensitivity = .03   -- sets sensitivity of mousewheel view zoom
local scroll_mCap           = 64    -- assigns mouse_cap for scrolling view
local set_caption_title     = true  -- determines whether or not object/button captions are displayed in the window title 
local blur_behind_obj       = true  -- whether to blur behind an object rectangle or not
--
--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES
--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES

gui = {}

V_Z     = 1     -- view zoom: a multiplier
V_Z_min = .1    -- view zoom minimum
V_Z_max = 5     -- view zoom maximum

V_S     = .5    -- view scroll sensitivity: a multiplier
V_H     = 0     -- view horizontal scroll: addition/subtraction
V_V     = 0     -- view vertical scroll: addition/subtraction

local click_watch = 0 
local dClick_watch = 0

mouse_cursor = {idx = 1, str = "arrow"}
mx, my = gfx.mouse_x, gfx.mouse_y
mouseGrab_x, mouseGrab_y = nil, nil
hover = {}
click = ""

sel_o, sel_b, sel_m = nil, nil, nil

function sort_obj_levels(tabel) 

	local dup = {}
	for a = 1, #tabel do dup[a] = tabel[a].level end 
	local indexes = {}

	for a = 1, #tabel do indexes[a] = a end 

  table.sort(indexes,function(a,b) return dup[a] < dup[b] end) 
	
	for a = 1, #tabel do dup[a] = tabel[a] end 
  
	  for a = 1, #tabel
	do
		tabel[a] = dup[indexes[a]] 
	end
	
	return tabel

end

function view_zoom() local V_Z1, V_Z2 = 100, 100
	
		if click == "" 
	then 
	
		local old_width = gfx.w/V_Z
		local old_height = gfx.h/V_Z
		
		V_Z = V_Z + ((gfx.mouse_wheel/120)*view_zoom_sensitivity)       -- set vertical zoom
		
		if V_Z < V_Z_min then V_Z = V_Z_min end                         -- enforce zoom minimum
		if V_Z > V_Z_max then V_Z = V_Z_max end                         -- enforce zoom maximum
		
		local new_width = gfx.w/V_Z
		local new_height = gfx.h/V_Z
		
		-- center scroll
			if gfx.mouse_wheel ~= 0
		then local mid_wid = (new_width-old_width)/2 local mid_hei = (new_height-old_height)/2
			V_H = V_H - mid_wid
			V_V = V_V - mid_hei
		end
		
	end 
	gfx.mouse_wheel = 0 
end

function fontFlags( str ) if str then local v = 0 for a = 1, str:len() do v = v * 256 + string.byte(str, a) end return v end end

function zoom_and_scroll( x, y, w, h, zoom, scroll, fs )
	
		if scroll
	then 
		if x then x = x - V_H end
		if y then y = y - V_V end
	end
		if zoom 
	then
		if x then x = x * V_Z end
		if y then y = y * V_Z end
		if w then w = w * V_Z end
		if h then h = h * V_Z end
		if fs then fs = fs * V_Z end
	end

	return x, y, w, h, fs

end

function check_mouse() mx, my = gfx.mouse_x, gfx.mouse_y -- set 'click' to check-mode

	-- check/set hover states
		if click == "" and not hover[3]
	then
	
		hover = {} local once = false -- clear hover state and 'once' detection variable
		--[0] 'gui'
		--[1] 'obj'
		--[2] 'button'
		--[3] 'clicked mouse_cap'
		--[4] 'clicked function index'
	
		for g = 1, #gui do local obj = gui[g].obj for o = 1, #obj do if obj[o].hc then obj[o].hc = 0 for b = 1, #obj[o].button do if obj[o].button[b].hc then obj[o].button[b].hc = 0 end end end end end -- clear object/button current hover states
	
			for g = #gui, 1, -1
		do local obj = gui[g].obj
				for o = #obj, 1, -1
			do if not obj[o] then goto skip_object1 end local ax, ay, aw, ah = zoom_and_scroll( obj[o].x, obj[o].y, obj[o].w, obj[o].h, obj[o].can_zoom, obj[o].can_scroll ) 
				-- check/set hover for buttons (button hover has priority over object hover)
					for b = #obj[o].button, 1, -1 
				do obj[o].button[b].hc = 0 -- reset hover
					local ax,ay,aw,ah = zoom_and_scroll( obj[o].x+obj[o].button[b].x, obj[o].y+obj[o].button[b].y,obj[o].button[b].w, obj[o].button[b].h, obj[o].button[b].can_zoom, obj[o].button[b].can_scroll ) 
						if mx > ax and mx < ax+aw and my > ay and my < ay+ah 
					then	
							if obj[o].button[b].act_off ~= 2
						then
								if set_caption_title == true -- set title and set hover  
							then 
									if obj[o].button[b].caption == ""
								then
									reaper.JS_Window_SetTitle( window, window_name ) 
								else
									reaper.JS_Window_SetTitle( window, window_name.." ("..obj[o].button[b].caption..")" ) 
								end
							end                                                        
							once = true for z = 1, #obj do if obj[z].hc then obj[z].hc = 0 for y = 1, #obj[z].button do if obj[z].button[y].hc then obj[z].button[y].hc = 0 end end end end 
							obj[o].button[b].hc = 1 hover[0] = g hover[1] = o hover[2] = b break
						end
					end
				end
				-- check/set hover for object (only if there is no button hovering)
					if mx > ax and mx < ax+aw and my > ay and my < ay+ah and once == false 
				then 
						if obj[o].act_off ~= 2
					then 
							if set_caption_title == true -- set title and set hover  
						then 
								if obj[o].caption == ""
							then
								reaper.JS_Window_SetTitle( window, window_name ) 
							else
								reaper.JS_Window_SetTitle( window, window_name.." ("..obj[o].caption..")" ) 
							end
						end  
						once = true for z = 1, #obj do if obj[z].hc then obj[z].hc = 0 end end hover[0] = g obj[o].hc = 1 hover[1] = o                                                                   -- set hover
					end
				end
				if once == true then break end
				::skip_object1::
			end
			if once == true then break end
		end
		
		if once == false and set_caption_title == true and window ~= 0 then reaper.JS_Window_SetTitle( window, window_name ) end                                                                -- if no hover, set title to window_name
	end

	-- clicking + actions (hover[3] holds "clicked" mouse_cap, hover[4] holds "clicked" function index)
		if hover[1]
	then local o = hover[1] local b = hover[2] local m = 0 local obj = gui[hover[0]].obj
			if not hover[3]
		then
				if not b -- if object
			then
					for mc = 1, #obj[o].mouse
				do 
					if obj[o].act_off then break end           -- enforce act_off
					local mouse_cap = gfx.mouse_cap 
					if mouse_cap == obj[o].mouse[mc] then hover[3] = mouse_cap hover[4] = mc break end 
				end
			else        -- if object button
					for mc = 1, #obj[o].button[b].mouse
				do 
					if obj[o].button[b].act_off then break end -- enforce act_off
					local mouse_cap = gfx.mouse_cap 
					if mouse_cap == obj[o].button[b].mouse[mc] then hover[3] = mouse_cap hover[4] = mc break end 
				end
			end
		end
		
			if hover[3] and click ~= "done" 
		then m = hover[4]
				if gfx.mouse_cap == hover[3]
			then
		
					if not b -- if object is clicked (and not button)
				then
					----------------------------------------
					if not sel_o then sel_o, sel_m = o, m mouseGrab_x, mouseGrab_y = mx, my end
					obj[o].hc = 2 -- set hover status
						if not obj[o].func[0] or m ~= 1
					then
							if click == "" -- if object has no dclick action
						then
							obj[o].func[m](obj[o],o) dClick_watch = 0 if not obj[o].hold[m] then click = "done" end 
						end
					end
						if obj[o].func[0] and click ~= "done" 
					then
							if click == "dclick"
						then
							sel_m = 0 obj[o].func[0](obj[o],o) click = "done" dClick_watch = -1
						elseif click == ""
						then
							dClick_watch = reaper.time_precise()+dClick_time  click = "delay"  
						end
							if obj[o].hold[m] and reaper.time_precise() > dClick_watch and click ~= "done"
						then
							obj[o].func[m](obj[o],o) click = "hold" dClick_watch = -1
						end
					end
						if obj[o].hold[m] and m ~= 1 and click ~= "done"
					then
						obj[o].func[m](obj[o],o) click = "hold"
					end
					if m ~= 1 or not obj[o].func[0] then dClick_watch = -1 end 
					----------------------------------------
				else        -- if object button is clicked
					----------------------------------------
					if not sel_o then sel_o, sel_b, sel_m = o, b, m mouseGrab_x, mouseGrab_y = mx, my end
					obj[o].button[b].hc = 2 -- set hover status
						if not obj[o].button[b].func[0] or m ~= 1
					then
							if click == "" -- if object button no dclick action
						then
							obj[o].button[b].func[m](obj[o].button[b],o,b) dClick_watch = 0 if not obj[o].button[b].hold[m] then click = "done" end 
						end
					end
						if obj[o].button[b].func[0] and click ~= "done" 
					then
							if click == "dclick"
						then
							sel_m = 0 obj[o].button[b].func[0](obj[o].button[b],o,b) click = "done" dClick_watch = -1
						elseif click == ""
						then
							dClick_watch = reaper.time_precise()+dClick_time  click = "delay"  
						end
							if obj[o].button[b].hold[m] and reaper.time_precise() > dClick_watch and click ~= "done"
						then
							obj[o].button[b].func[m](obj[o].button[b],o,b) click = "hold" dClick_watch = -1
						end
					end
						if obj[o].button[b].hold[m] and m ~= 1 and click ~= "done"
					then
						obj[o].button[b].func[m](obj[o].button[b],o,b) click = "hold"
					end
					if m ~= 1 or not obj[o].button[b].func[0] then dClick_watch = -1 end 
					----------------------------------------
				end
				
			end -- if gfx.mouse_cap == hover[3]
			
		end -- if hover[3]
	
	end -- if hover[1]

	-- dClick_watch < reaper.time_precise()
	
		if hover[3] --(hover[3] holds "clicked" mouse_cap, hover[4] holds "clicked" function index)
	then
		-- check for m_rel
		local rel_check = false 
			if gui[hover[0]].obj[hover[1]].m_rel and not sel_b
		then
			if gui[hover[0]].obj[hover[1]].m_rel[hover[4]] then if gfx.mouse_cap&gui[hover[0]].obj[hover[1]].m_rel[hover[4]] == 0 then rel_check = true end end 
			elseif hover[2] and gui[hover[0]].obj[hover[1]].button[hover[2]].m_rel 
		then 
			if gui[hover[0]].obj[hover[1]].button[hover[2]].m_rel[hover[4]] then if gfx.mouse_cap&gui[hover[0]].obj[hover[1]].button[hover[2]].m_rel[hover[4]] == 0 then rel_check = true end end 
		end 
		-----------------
			if gfx.mouse_cap&hover[3] == 0 or rel_check == true
		then 
				if dClick_watch < reaper.time_precise()
			then
					if sel_o
				then local obj = gui[hover[0]].obj
						if not sel_b -- if object was clicked
					then
						if dClick_watch ~= -1 then 
						obj[sel_o].func[sel_m](obj[sel_o],sel_o, nil, 1) end obj[sel_o].func[sel_m](obj[sel_o],sel_o, 1)
					else             -- if object button was clicked
						if dClick_watch ~= -1 then obj[sel_o].button[sel_b].func[sel_m](obj[sel_o].button[sel_b],sel_o, sel_b, nil, 1) end 
						obj[sel_o].button[sel_b].func[sel_m](obj[sel_o].button[sel_b],sel_o, sel_b, 1)
					end
				end
				dClick_watch = 0 hover = {} click = "" sel_o, sel_b, sel_m = nil, nil, nil
			else
				click = "dclick" 
			end
		end
	end


end -- end of check_mouse

function draw() 
	
		for g = 1, #gui
	do local obj = gui[g].obj
			for o = 1, #obj
		do local object = obj[o] if not object then goto skip_object end 
			-- draw objects
			gfx.set( object.r,object.g,object.b,object.a )
			if object.hc == 1 then     gfx.a = gfx.a - object.ha                                                             -- if mouse if hovering draw alpha 
			elseif object.hc == 2 then gfx.a = gfx.a - object.hca end                                                        -- if clicking draw alpha
			local xp, yp, wa, ha = zoom_and_scroll( object.x, object.y, object.w, object.h, object.can_zoom, object.can_scroll )
			if object.blur_under then gfx.x, gfx.y = xp, yp gfx.blurto( xp+wa,yp+ha ) end                                    -- blur under                                                     
			gfx.rect( xp, yp, wa, ha, object.f )                                                                             -- draw rectangle *(see end of for loop)*
			-- draw statics
				for s = 1, #object.static 
			do local static = object.static[s] local xp, yp, wa, ha, fs = zoom_and_scroll( object.x+static.x, object.y+static.y, static.w, static.h, static.can_zoom, static.can_scroll, static.fs )
				gfx.set( static.r,static.g,static.b,static.a ) 
					if static.type == "line"
				then 
					gfx.line(xp,yp,static.xx,static.yy,static.aa )                                                           -- draw line
					elseif static.type == "rect"
				then 
					gfx.rect( xp,yp,wa,ha,static.f )                                                                         -- draw rectangle
					gfx.set( static.ol.r,static.ol.g,static.ol.b,static.ol.a ) gfx.rect( xp,yp,wa,ha,0 )                     -- draw rectanle outline
					elseif static.type == "text"
				then
					if font_changes == true then gfx.setfont( 1,static.fo,fs,fontFlags(static.ff) ) end                      -- if font_changes = true then set font
					local subber = static.txt                                                                                -- resize title to fit button
						if gfx.measurestr( subber ) > wa 
					then                                         
						while gfx.measurestr( subber ) > wa do subber = string.sub(subber,1,string.len(subber)-1) if string.len(subber) == 0 then break end end 
						subber = string.sub(subber,1,string.len(subber)-3) subber = subber.."..."  
					end
					gfx.x, gfx.y = xp, yp gfx.drawstr( subber,static.th|static.tv,xp+wa,yp+ha )                              -- draw text
					elseif static.type == "circ"
				then
					gfx.circle( xp+static.rs,yp+static.rs,static.rs,static.f,static.aa )                                     -- draw circle
					gfx.set( static.ol.r,static.ol.g,static.ol.b,static.ol.a )
					gfx.circle( xp+static.rs,yp+static.rs,static.rs,0,static.aa )                                            -- draw circle outline
				end
			end -- for s 
			-- draw buttons
				for b = 1, #object.button
			do local button = object.button[b] local xp, yp, wa, ha, fs = zoom_and_scroll( object.x+button.x, object.y+button.y, button.w, button.h, button.can_zoom, button.can_scroll, button.fs ) 
				-- draw rect
				gfx.set( button.r,button.g,button.b,button.a ) 
				if button.hc == 1 then     gfx.a = gfx.a - button.ha                                                         -- if mouse if hovering draw alpha 
				elseif button.hc == 2 then gfx.a = gfx.a - button.hca end                                                    -- if clicking draw alpha
					if button.type == "rect"
				then
					gfx.rect( xp,yp,wa,ha,button.f )                                                                         -- draw rectangle
					gfx.set( button.ol.r,button.ol.g,button.ol.b,button.ol.a ) gfx.rect( xp,yp,wa,ha,0 )                     -- draw rectangle outline
					elseif button.type == "circ"
				then
					xp, yp, wa, ha, fs = zoom_and_scroll( object.x+button.x+button.rs, object.y+button.y+button.rs, button.rs, button.h, button.can_zoom, button.can_scroll, button.fs ) 
					gfx.circle( math.floor(xp),math.floor(yp),math.floor(wa),button.f,button.aa )                            -- draw circle
					gfx.set( button.ol.r,button.ol.g,button.ol.b,button.ol.a )
					gfx.circle( math.floor(xp),math.floor(yp),math.floor(wa),0,button.aa )                                   -- draw circle outline
					elseif button.type == "img"
				then 
					gfx.blit(button.iid,1,0,0,0,button.iw,button.ih,xp,yp,button.w,button.h)                                 -- draw image
				end
				-- draw text
					if button.txt ~= "" and button.type ~= "img"
				then
					gfx.set( button.rt,button.gt,button.bt,button.at ) gfx.x, gfx.y = xp, yp
					if font_changes == true then gfx.setfont( 1,button.fo,fs,fontFlags(button.ff) ) end                      -- if font_changes = true then set font
					local subber = button.txt                                                                                -- resize title to fit button
						if gfx.measurestr( subber ) > wa 
					then                                         
						while gfx.measurestr( subber ) > wa do subber = string.sub(subber,1,string.len(subber)-1) if string.len(subber) == 0 then break end end 
						subber = string.sub(subber,1,string.len(subber)-3) subber = subber.."..."  
					end
					gfx.drawstr( subber,button.th|button.tv,xp+wa,yp+ha )                                                    -- draw text
				end
				-- draw statics
					if button.static 
				then 
						for s = 1, #button.static 
					do local static = button.static[s] local xp, yp, wa, ha, fs = zoom_and_scroll( object.x+static.x, object.y+static.y, static.w, static.h, static.can_zoom, static.can_scroll, static.fs )
						gfx.set( static.r,static.g,static.b,static.a ) 
							if static.type == "line"
						then 
							gfx.line(xp,yp,static.xx,static.yy,static.aa )                                                   -- draw line
							elseif static.type == "rect"
						then 
							gfx.rect( xp,yp,wa,ha,static.f )                                                                 -- draw rectangle
							gfx.set( static.ol.r,static.ol.g,static.ol.b,static.ol.a ) gfx.rect( xp,yp,wa,ha,0 )             -- draw rectanle outline
							elseif static.type == "text"
						then
							if font_changes == true then gfx.setfont( 1,static.fo,fs,fontFlags(static.ff) ) end              -- if font_changes = true then set font
							local subber = static.txt                                                                                -- resize title to fit button
								if gfx.measurestr( subber ) > wa 
							then                       
								while gfx.measurestr( subber ) > wa do subber = string.sub(subber,1,string.len(subber)-1) if string.len(subber) == 0 then break end end 
								subber = string.sub(subber,1,string.len(subber)-3) subber = subber.."..."  
							end 
							gfx.x, gfx.y = xp, yp gfx.drawstr( subber,static.th|static.tv,xp+wa,yp+ha )                      -- draw text
							elseif static.type == "circ"
						then
							gfx.circle( xp+static.rs,yp+static.rs,static.rs,static.f,static.aa )                             -- draw circle
							gfx.set( static.ol.r,static.ol.g,static.ol.b,static.ol.a )
							gfx.circle( xp+static.rs,yp+static.rs,static.rs,0,static.aa )                                    -- draw circle outline
						end
					end -- for s 
				end
			end -- for b
			gfx.set( object.ol.r,object.ol.g,object.ol.b,object.ol.a ) gfx.rect( xp, yp, wa, ha,0 )                          -- *draw rectangle outline*
			::skip_object::
		end -- for o
	end -- for g

	if mouseCursor_changes == true then gfx.setcursor( mouse_cursor.idx, mouse_cursor.str ) end -- if multile mouse cursor are enabled in script, then set accordingly

end --draw()

function gui_funcs()

		for g = 1, #gui
	do
			for o = 1, #gui[g].obj
		do 
			if gui[g].obj[o].func[-1] then gui[g].obj[o].func[-1](gui[g].obj[o], g, o) end 
				for b = 1, #gui[g].obj[o].button 
			do 
				if gui[g].obj[o].button[b].func[-1] then gui[g].obj[o].button[b].func[-1](gui[g].obj[o].button[b], g, o, b) end 
			end
		end
	end

end --gui funcs()
end

function new_button( id, x, y, w, h, r, g, b, ASize, img, iid, iw, ih, txt, name, action, typer) --DEFINE BUTTON
	gui[1].obj[1].button[#gui[1].obj[1].button+1] = {
	img        = img,                                              -- button image directory
	ASize      = ASize,                                            -- whether length of button is snapped
	id         = id,                                               -- type of button
	iid        = iid,                                              -- image source id
	action     = action,                                           -- action (table)
	name       = name,                                             -- name (table)
	caption    = "left-click to activate, right-click for menu, shf+left-click to move",   -- caption display
	type       = typer,                                            -- draw type: "rect" or "circ"
	ol         = {r=1,g=1,b=1,a=1},                                -- rect: button's outline
	hc         = 0,                                                -- current hover alpha (default '0')
	ha         = .2,                                               -- hover alpha
	hca        = .3,                                               -- hover click alpha 
	r          = r,                                                -- r
	g          = g,                                                -- g
	b          = b,                                                -- b
	a          = 1,                                                -- a
	rt         = 0,                                                -- r     (text)
	gt         = 0,	                                               -- g     (text)
	bt         = 0,                                                -- b     (text)
	at         = 1,                                                -- alpha (text)
	x          = x,                                                -- x
	y          = y,                                                -- y
	w          = w,                                                -- w
	h          = h,                                                -- h
	iw         = iw,                                               -- image width
	ih         = ih,                                               -- image height
	f          = 1,                                                -- filled
	rs         = 10,                                               -- circle: radius
	aa         = true,                                             -- circle: antialias         
	txt        = txt,                                              -- text: "" disables text for button                                 
	th         = 1,                                                -- text 'h' flag
	tv         = 4,                                                -- text 'v' flag	
	fo         = "Arial",                                          -- font settings will have no affect unless: font_changes = true
	fs         = fontSize,                                         -- font size
	ff         = nil,                                              -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
	can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
	can_scroll = false,                                            -- whether object rectangle scrolls with global     
	static     = {},                                               -- index of static graphics that object holds
	func       = 
		{ -- functions receive object index and bool release ('r')
		-- always-run function
		[-1]      = function(self,g,o,b) end, 
		-- non-indexed function
		[0]      = function(self,o,b,r,d) if r then return else end end, 
		-- mouse_cap functions
		[1]      = 
		function(self,o,b,r,d) 
				if r and gfx.mouse_x > self.x and gfx.mouse_x < self.x+self.w and gfx.mouse_y > self.y and gfx.mouse_y < self.y+self.h
			then 
				if self.id > 1 
				then
					local temper = "" for a = 1, #self.name do temper = temper..self.name[a] if a < #self.name then temper = temper.."|" end end 
					if self.id == 2 then gfx.x, gfx.y = self.x, self.y-(#self.name*Menu_Correction) else gfx.x, gfx.y = self.x, self.y+self.h end local choice2 = gfx.showmenu(temper)
						for a = 1, #self.name
					do
							if choice2 == a 
						then
								if self.action[a]:len() < 6 and type(self.action[a]) == 'number'
							then 
								reaper.Main_OnCommand( tonumber(self.action[a]), 0 ) --reaper.JS_Window_SetFocus(reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000))
							else 
								reaper.Main_OnCommand( reaper.NamedCommandLookup(self.action[a]), 0 ) --reaper.JS_Window_SetFocus(reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000))						
							end
						end
					end
				else
						if self.action[1]:len() < 6 and type(tonumber(self.action[1])) == 'number'
					then 
						reaper.Main_OnCommand( tonumber(self.action[1]), 0 ) --reaper.JS_Window_SetFocus(reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000))
					else 
						reaper.Main_OnCommand( reaper.NamedCommandLookup(self.action[1]), 0 ) --reaper.JS_Window_SetFocus(reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000))						
					end
				end
			end 
		end, 
		[2]      = 
		function(self,o,b,r,d) 
				if r and gfx.mouse_x > self.x and gfx.mouse_x < self.x+self.w and gfx.mouse_y > self.y and gfx.mouse_y < self.y+self.h
			then 
				local chk, chk2 = "Set", "" if self.type == "img" then chk, chk2 = "Clear", "#" end 
				gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y local choice = gfx.showmenu("Edit Button|Delete Button|Change Button Color||"..chk2.."Turn Auto-sizing "..self.ASize.."|"..chk.." Button Image")
					if choice == 1 -- EDIT BUTTON
				then	
					local input, csv = "Name(-)Button type:,Width(-)Height: OR 0=autosize,", self.txt.."-"..self.id.."~"                 
					if self.ASize == "OFF" then csv = csv.."0~" else csv=csv..tostring(self.w).."-"..tostring(self.h).."~" end 
						for a = 1, 14 
					do 
						input = input.."Name(-)Action:" if a > 1 then input=input.." (if menu)" end if self.action[a] and self.name[a] then csv=csv..self.name[a].."-"..self.action[a] end if a ~= 14 then input = input.."," csv=csv.."~" end
					end
					local uiret, uireturn = reaper.GetUserInputs( "[user input]", 16, input..",extrawidth=250,separator=~", csv )
						if uiret
					then
						local my_action, my_name = {},{} local splt = split(uireturn, "~") local NW = {} NW = split(splt[1], "-") NW[2]=tonumber(NW[2]) local HW = {} HW[1],HW[2] = grid, grid local ASize = "ON"
						if splt[2] == "0" then ASize = "OFF" else local HT = split(splt[2], "-") HT[1], HT[2] = tonumber(HT[1]), tonumber(HT[2]) if type(HT[1]) == 'number' then HW[1] = HT[1] end if type(HT[2]) == 'number' then HW[2] = HT[2] end end 
							if type(NW[2]) == 'number' 
						then if NW[2] < 1 then NW[2] = 1 end if NW[2] > 3 then NW[2] = 3 end 
								for a = 3, #splt 
							do 
								local fi = splt[a]:find("-") if fi then local temp = {} temp[1] = splt[a]:sub(1,fi-1) temp[2] = splt[a]:sub(fi+1) my_name[#my_name+1] = temp[1] my_action[#my_action+1] = temp[2] else if splt[a] ~="" then my_name[#my_name+1] = NW[1] my_action[#my_action+1] = splt[a] end end 
							end
							if NW[2] == 1 then local tmp = my_name[1] my_name = {} my_name[1] = tmp tmp = my_action[1] my_action = {} my_action[1] = tmp end 
							if #my_action > 0 then self.txt, self.id, self.w, self.h, self.ASize, self.name, self.action = NW[1], NW[2], HW[1], HW[2], ASize, my_name, my_action end 
						end 
					end	
					elseif choice == 2 -- DELETE BUTTON
				then
					local button_num = #gui[1].obj[1].button for a = 1, button_num do if a == b then gui[1].obj[1].button[a] = nil end if a > b then gui[1].obj[1].button[a-1] = gui[1].obj[1].button[a] gui[1].obj[1].button[a] = nil end end 
					elseif choice == 3 -- CHANGE BUTTON COLOR
				then
					local retcol, colreturn = reaper.GR_SelectColor( reaper.JS_Window_GetFocus() )
					if retcol ~= 0 then self.r, self.g, self.b = reaper.ColorFromNative( colreturn ) self.r, self.g, self.b = self.r/255, self.g/255, self.b/255 end 
					elseif choice == 4 -- BUTTON AUTO SIZE
				then
					if self.ASize == "OFF" then self.w, self.h = grid, grid self.ASize = "ON" else if self.type ~= "img" then self.ASize = "OFF" end end
					elseif choice == 5 -- SET BUTTON IMAGE
				then
						if self.type == "rect" 
					then 
						local retvald, temperest = reaper.JS_Dialog_BrowseForOpenFiles( "Browse for image", "", "", "Image files\0*.png;*.jpg\0PNG files (.png)\0*.png\0JPG files (.jpg)\0*.jpg\0\0", false)
							if retvald > 0
						then 
							local new_id = get_iid() gfx.loadimg(new_id,temperest) self.iw, self.ih = gfx.getimgdim(new_id) self.img = temperest self.iid = new_id
							self.ASize = "ON" self.type = "img" current_project = "What a strange name for a string"
						end
					else 
						self.type = "rect" 
					end
				end
			end
		end, 
		[3]      = 
		function(self,o,b,r,d) if r then return end
			local tempX, tempY = gfx.mouse_x, gfx.mouse_y 
				if snap == true
			then
				tempX = math.floor(((tempX/grid)+.5))*grid 
				tempY = math.floor(((tempY/grid)+.5))*grid 
			end
			self.x, self.y = tempX, tempY if self.x < 0 then self.x = 0 end if self.y < 0 then self.y = 0 end if self.y+self.h > gfx.h then self.y = gfx.h-self.h end if self.x+self.w > gfx.w then self.x = gfx.w-self.w end 
		end, 
		},
	mouse      =
		{ -- index [1] must always be left-click
		[1]        = 1,                
		[2]        = 2,
		[3]        = 9
		},
	hold       = 
		{
		[1]        = false,
		[2]        = false,
		[3]        = true
		}
	}
	current_project = "What a strange name for a string"
end

if NEW_folder --DEFINE GLOBAL MENU
then
local rr, gg, bb = 0,0,0 if reaper.HasExtState( NAME, "BakC" ) then rr,gg,bb = reaper.ColorFromNative( tonumber(reaper.GetExtState( NAME, "BakC" )) ) rr,gg,bb=rr/255,gg/255,bb/255 end 
gui[1] = {obj = {}}
gui[1].obj[1] = {
caption    = "right-click for menu", -- caption display
hc         = 0,                                                -- current hover alpha (default '0')
ha         = 0,                                                -- hover alpha
hca        = 0,                                                -- hover click alpha 
ol         = {r=1,g=1,b=1,a=0},                                -- rect: object's outline
r          = rr,                                               -- r
g          = gg,                                               -- g
b          = bb,                                               -- b
a          = 0,                                                -- a
f          = 1,                                                -- rect: filled	
x          = 0,                                                -- x
y          = 0,                                                -- y
w          = 0,                                                -- w
h          = 0,                                                -- h
can_zoom   = false,                                            -- whether object rectangle zooms with global
can_scroll = false,                                            -- whether object rectangle scrolls with global 
button     = {},                                               -- index of buttons that object holds
static     = {},                                               -- index of static graphics that object holds
func       = 
	{ -- functions receive object index and bool release ('r')
	-- always-run function
	[-1]      = function(self,g,o) end, 
	-- non-indexed function
	[0]      = function(self,o,r,d) if r then return else end end, 
	-- mouse_cap functions
	[1]      = function(self,o,r,d) if r then return else end end, 
	[2]      = 
	function(self,o,r,d) 
			if r 
		then local word = "Enable" if snap == true then word = "Disable" end local greyitout = "" if backgroundImage == "" then greyitout = "#" end 
			gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y local choice = gfx.showmenu("New Button||Set Font Size ("..tostring(fontSize)..")||"..word.." Snap|Grid Size ("..tostring(grid)..")||Set Color of New Buttons||Set Background Color|Set Background Image|"..greyitout.."Set Background Image Width/Height|"..BG_stretch.." Background Image to Window||Pause Script (right-click to reactivate)||Exit Script (discard changes)|Exit Script (save)")
				if choice == 1 -- NEW BUTTON
			then
				local input, csv = "Name(-)Button type:,Width(-)Height: OR 0=autosize,", "(Ex: New Track)-(1=button 2=up-menu 3=down-menu)~"..tostring(grid).."-"..tostring(grid).." OR 0~(Ex:) New Track-40001 OR _XENAKIOS_INSNEWTRACKTOP"
					for a = 1, 14 
				do 
					input = input.."Name(-)Action:" if a > 1 then input=input.." (if menu)" end if a ~= 14 then input = input.."," end
				end
				local uiret, uireturn = reaper.GetUserInputs( "[user input]", 16, input..",extrawidth=250,separator=~", csv )
					if uiret
				then
					local rrr, ggg, bbb = reaper.ColorFromNative(default_col) rrr, ggg, bbb = rrr/255, ggg/255, bbb/255 local my_action, my_name = {},{} local splt = split(uireturn, "~") local HW = {} HW[1],HW[2] = grid, grid local ASize = "ON"
					local NW = {} NW = split(splt[1], "-") NW[2]=tonumber(NW[2])
					if splt[2] == "0" then ASize = "OFF" else local HT = split(splt[2], "-") HT[1], HT[2] = tonumber(HT[1]), tonumber(HT[2]) if type(HT[1]) == 'number' then HW[1] = HT[1] end if type(HT[2]) == 'number' then HW[2] = HT[2] end end			
						if type(NW[2]) == 'number' 
					then if NW[2] < 1 then NW[2] = 1 end if NW[2] > 3 then NW[2] = 3 end 
							for a = 3, #splt 
						do 
							local fi = splt[a]:find("-") if fi then local temp = {} temp[1] = splt[a]:sub(1,fi-1) temp[2] = splt[a]:sub(fi+1) my_name[#my_name+1] = temp[1] my_action[#my_action+1] = temp[2] else if splt[a]~="" then my_action[#my_action+1] = splt[a] my_name[#my_name+1] = NW[1] end end 
						end 	
						if NW[2] == 1 then local tmp = my_name[1] my_name = {} my_name[1] = tmp tmp = my_action[1] my_action = {} my_action[1] = tmp end 
						if #my_action > 0 then new_button( NW[2], gfx.x, gfx.y, HW[1], HW[2], rrr, ggg, bbb, ASize, "", -1, -1, -1, NW[1], my_name, my_action, "rect") end
					end 
				end				
				elseif choice == 2 --FONT SIZE
			then
				local uiret4, uireturn4 = reaper.GetUserInputs( "[user input]", 1, "Font size:", tostring(fontSize) )
					if uiret4
				then 
					uireturn4 = tonumber(uireturn4) if type(uireturn4) == 'number' then if uireturn4 > 50 then uireturn4 = 50 end if uireturn4 < 10 then uireturn4 = 10 end fontSize = uireturn4 end gfx.setfont( 1,Font_Type, fontSize )
				end
				elseif choice == 3 --ENABLE/DISABLE SNAP
			then
				if snap == true then snap = false else snap = true end
				elseif choice == 4 --GRID SIZE
			then
				local uiret7, uireturn7 = reaper.GetUserInputs( "[user input]", 1, "Grid size:", tostring(grid) )
					if uiret7
				then 
					uireturn7 = tonumber(uireturn7) if type(uireturn7) == 'number' then if uireturn7 > 200 then uireturn7 = 200 end if uireturn7 < 10 then uireturn7 = 10 end grid = uireturn7 end 
				end
				elseif choice == 5 --SET COLOR OF NEW BUTTONS
			then
				local retcol, colreturn = reaper.GR_SelectColor( reaper.JS_Window_GetFocus() )
				if retcol ~= 0 then default_col = colreturn end
				elseif choice == 7 --SET BACKGROUND IMAGE
			then
				local retvald, temperest = reaper.JS_Dialog_BrowseForOpenFiles( "Browse for image", "", "", "Image files\0*.png;*.jpg\0PNG files (.png)\0*.png\0JPG files (.jpg)\0*.jpg\0\0", false)
					if retvald > 0
				then backgroundImage = temperest current_project = "What a strange name for a string"
					gfx.loadimg(100,backgroundImage) bakw, bakh = gfx.getimgdim(100) 
				end
				elseif choice == 8 --SET BACKGROUND IMAGE WIDTH/HEIGHT
			then
				local add_info, add_info2 = "", "" if bakw ~= 0 and bakw ~= 0 then add_info, add_info2 = " (original width = "..tostring(bakw)..")", " (original height = "..tostring(bakh)..")" end 
				local tempWW, tempHH = tostring(gfx.w), tostring(gfx.h) if BG_W then tempWW = tostring(BG_W) end if BG_H then tempHH = tostring(BG_H) end
				local uiret8, uireturn8 = reaper.GetUserInputs( "[user input]", 2, "Background Image Width:,Background Image Height:,extrawidth=100", tempWW..add_info..","..tempHH..add_info2 )
					if uiret8
				then 
						if uireturn8:find(",")
					then
						uireturn8 = split(uireturn8, ",") uireturn8[1], uireturn8[2] = tonumber(uireturn8[1]), tonumber(uireturn8[2])
						if type(uireturn8[1]) == 'number' and type(uireturn8[2]) == 'number' then BG_W = uireturn8[1] BG_H = uireturn8[2] end 
					end
				end
				elseif choice == 6 --SET BACKGROUND COLOR
			then
				local retcolo, coloreturn = reaper.GR_SelectColor( reaper.JS_Window_GetFocus() )
					if retcolo 
				then current_project = "What a strange name for a string"
					backgroundImage = "" gui[1].obj[1].r, gui[1].obj[1].g, gui[1].obj[1].b = reaper.ColorFromNative( coloreturn ) gui[1].obj[1].r, gui[1].obj[1].g, gui[1].obj[1].b = gui[1].obj[1].r/255, gui[1].obj[1].g/255, gui[1].obj[1].b/255 
				end
				elseif choice == 9 -- STRETCH BACKGROUND IMAGE TO WINDOW
			then
				if BG_stretch == "Stretch" then BG_stretch = "Don't Stretch" else BG_stretch = "Stretch" end 
				elseif choice == 10 --PAUSE SCRIPT
			then
				if kill == false then kill = true else kill = false end
				elseif choice == 11 --EXIT SCRIPT DON'T SAVE
			then
				quit = true SAVE = false
				elseif choice == 12 --EXIT SCRIPT AND SAVE
			then
				quit = true
			end
		end 
		
	end, 
	[3]      = function(self,o,r,d) if r then return else end end, 
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

if LOAD_folder --LOAD STORED BUTTONS
then
local loader = {}
	if  reaper.file_exists( filename..NAME..".ini" ) == true 
then 
	local file = io.open(filename..NAME..".ini", "r")
		for line in file:lines() 
	do
		table.insert (loader, line)
	end
	file:close()
end 
	for a = 1, #loader 
do 
	local ld_name, ld_action = {}, {} local ld = split(loader[a], "~") for z = 1, 6 do ld[z] = tonumber(ld[z]) end for z = 10, #ld, 2 do ld_name[#ld_name+1], ld_action[#ld_action+1] = ld[z], ld[z+1] end  
	local ld_r, ld_g, ld_b = reaper.ColorFromNative(ld[6]) ld_r, ld_g, ld_b = ld_r/255, ld_g/255, ld_b/255 
	local nid, iiw, iih, ttype = -1, -1, -1, "rect" if reaper.file_exists(ld[8]) == true then nid = get_iid() gfx.loadimg(nid,ld[8]) iiw, iih = gfx.getimgdim(nid) ttype = "img" end 	
	new_button( ld[1], ld[2], ld[3], ld[4], ld[5], ld_r, ld_g, ld_b, ld[7], ld[8], nid, iiw, iih, ld[9], ld_name, ld_action, ttype ) 
end 
loader = nil
end

function drawer() 
	local dont = true if cx == gfx.x and cy == gfx.y and cw == gfx.w and ch == gfx.h then dont = false end if dont == true then current_project = "What a strange name for a string" cx, cy, cw, ch = gfx.x, gfx.y, gfx.w, gfx.h end 
		if current_project == reaper.GetProjectName( 0, "" )
	then
			if reaper.JS_Window_FromPoint( reaper.GetMousePosition() ) ~= window 
		then 
			if window_timer == 0 then window_timer = reaper.time_precise() end if window_timer+.3 < reaper.time_precise() then return end 
		else
			window_timer = 0
		end
	else
		current_project = reaper.GetProjectName( 0, "" )
	end	
	-- draw background
		if backgroundImage ~= "" 
	then -- draw background image
		local tempW, tempH = bakw, bakh if BG_W then tempW = BG_W end if BG_H then tempH = BG_H end if BG_stretch == "Don't Stretch" then tempW, tempH = gfx.w, gfx.h end
		gfx.x, gfx.y=0,0 gfx.blit(100,1,0,0,0,bakw,bakh,0,0,tempW,tempH) 
	else -- draw background color
		gfx.set(gui[1].obj[1].r, gui[1].obj[1].g, gui[1].obj[1].b, 1) gfx.rect(0,0,gfx.w,gfx.h,1)
	end
	--^^^^^^^^^^^^^^^^
	-- draw grid
		if snap == true
	then
			for a = 1, math.floor((gfx.w/grid))
		do
			gfx.set(1,1,1,1) gfx.line(a*grid,0,a*grid,gfx.h,1 )
		end
			for a = 1, math.floor((gfx.h/grid))
		do
			gfx.set(1,1,1,1) gfx.line(0,a*grid,gfx.w,a*grid,1 )
		end
	end
	--^^^^^^^^
	dynamic_vars() 
	check_mouse()
	draw() 
		if reaper.JS_Window_GetFocus() == window and gfx.mouse_y > 0 
	then 
			if auto_window and reaper.JS_Window_IsWindow( auto_window ) 
		then 
			reaper.JS_Window_SetFocus(auto_window) 
		else
			reaper.JS_Window_SetFocus(reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000)) 
		end
	else 
		auto_window = reaper.JS_Window_GetFocus() 
	end
end

function init()
	local d, w, h, x, y = 0,display_w/2,300,display_w/4,200
	if reaper.HasExtState( NAME, "W_D" ) then d = reaper.GetExtState( NAME, "W_D" ) end
	if reaper.HasExtState( NAME, "W_W" ) then w = reaper.GetExtState( NAME, "W_W" ) end
	if reaper.HasExtState( NAME, "W_H" ) then h = reaper.GetExtState( NAME, "W_H" ) end
	if reaper.HasExtState( NAME, "W_X" ) then x = reaper.GetExtState( NAME, "W_X" ) end
	if reaper.HasExtState( NAME, "W_Y" ) then y = reaper.GetExtState( NAME, "W_Y" ) end
	if reaper.HasExtState( NAME, "BG_W" ) then BG_W = tonumber(reaper.GetExtState( NAME, "BG_W" )) end
	if reaper.HasExtState( NAME, "BG_H" ) then BG_H = tonumber(reaper.GetExtState( NAME, "BG_H" )) end
	if reaper.HasExtState( NAME, "BG_S" ) then BG_stretch = reaper.GetExtState( NAME, "BG_S" ) end
	if reaper.HasExtState( NAME, "snap" )  then snap           = reaper.GetExtState( NAME, "snap" ) if snap == "true" then snap = true else snap = false end end
	if reaper.HasExtState( NAME, "grid" )  then grid           = reaper.GetExtState( NAME, "grid" ) grid = tonumber(grid) end
	if reaper.HasExtState( NAME, "fontS" ) then fontSize       = reaper.GetExtState( NAME, "fontS" ) fontSize = tonumber(fontSize) end
	if reaper.HasExtState( NAME, "DCol" ) then default_col     = reaper.GetExtState( NAME, "DCol" ) default_col = tonumber(default_col) end
	if reaper.HasExtState( NAME, "iBak" ) then backgroundImage = reaper.GetExtState( NAME, "iBak" ) if reaper.file_exists( backgroundImage ) == true then gfx.loadimg(100,backgroundImage) bakw, bakh = gfx.getimgdim(100) else backgroundImage ="" end end
	gfx.init(NAME, w, h, d, x, y )
	window = reaper.JS_Window_Find( NAME, 1 ) 
	gfx.setfont( 1,Font_Type, fontSize )
	main()
end

function dynamic_vars()
	gui[1].obj[1].w, gui[1].obj[1].h = gfx.w, gfx.h local cpt = ""
		for a = 1, #gui[1].obj[1].button 
	do
		--CAPTION
			if gfx.mouse_x > gui[1].obj[1].button[a].x and gfx.mouse_x < gui[1].obj[1].button[a].x+gui[1].obj[1].button[a].w and gfx.mouse_y > gui[1].obj[1].button[a].y and gfx.mouse_y < gui[1].obj[1].button[a].y+gui[1].obj[1].button[a].h 
		then
			if caption_timer == 0 then caption_timer = reaper.time_precise() end cpt = gui[1].obj[1].button[a].caption
		end
		--^^^^^^^
		gui[1].obj[1].button[a].a = 1
			if gui[1].obj[1].button[a].id == 1 
		then  
				if gui[1].obj[1].button[a].action[1]:len() < 6 and type(tonumber(gui[1].obj[1].button[a].action[1])) == 'number'
			then
				if reaper.GetToggleCommandState( tonumber(gui[1].obj[1].button[a].action[1]) ) == 0 then gui[1].obj[1].button[a].a = .5 end 
			else
				if reaper.GetToggleCommandState(reaper.NamedCommandLookup(gui[1].obj[1].button[a].action[1])) == 0 then gui[1].obj[1].button[a].a = .5 end   
			end
		end
		local xm, ym = gfx.measurestr(gui[1].obj[1].button[a].txt) xm = xm + 4 
		if gui[1].obj[1].button[a].ASize == "OFF" then gui[1].obj[1].button[a].h = ym end
			if snap == true 
		then 
			gui[1].obj[1].button[a].x = math.floor(((gui[1].obj[1].button[a].x/grid)+.5))*grid 
			gui[1].obj[1].button[a].y = math.floor(((gui[1].obj[1].button[a].y/grid)+.5))*grid 
		end 
		if gui[1].obj[1].button[a].ASize == "OFF" then xm = math.ceil((xm/grid))*grid gui[1].obj[1].button[a].w = xm end
	end 
	--CAPTION
		if Tool_Tips == true
	then
		if cpt == "" then caption_timer = 0 if caption_timer2 == 0 then caption_timer2 = reaper.time_precise() end else caption_timer2 = 0 if reaper.time_precise() > caption_timer+3 and caption_timer ~= -1 then local mmx, mmy = reaper.GetMousePosition() reaper.TrackCtl_SetToolTip( "left-click to activate, right-click for menu, shf+left-click to move", mmx+12, mmy, 1 ) caption_timer = -1 end end 
		if reaper.time_precise() > caption_timer2+3 and caption_timer2 > 0 then local mmmx, mmmy = reaper.GetMousePosition() reaper.TrackCtl_SetToolTip( "right-click for menu", mmmx+12, mmmy, 1 ) caption_timer2 = -1 end 
	end
	--^^^^^^^
end


--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~
function main() 


		if kill == false
	then
		drawer()
	else
		if gfx.mouse_x > 0 and gfx.mouse_x < gfx.w and gfx.mouse_y > 0 and gfx.mouse_y < gfx.h and reaper.JS_Mouse_GetState(2) == 2 then kill = 2 end 
		-- draw background
			if backgroundImage ~= "" 
		then -- draw background image
			local tempW, tempH = bakw, bakh if BG_W then tempW = BG_W end if BG_H then tempH = BG_H end if BG_stretch == "Don't Stretch" then tempW, tempH = gfx.w, gfx.h end
			gfx.x, gfx.y=0,0 gfx.blit(100,1,0,0,0,bakw,bakh,0,0,tempW,tempH) 
		else -- draw background color
			gfx.set(gui[1].obj[1].r, gui[1].obj[1].g, gui[1].obj[1].b, 1) gfx.rect(0,0,gfx.w,gfx.h,1)
		end
	end if kill == 2 and reaper.JS_Mouse_GetState(2) == 0 then kill = false end 
	
	if gfx.getchar() ~= -1 and quit == false then reaper.defer(main) end

end
--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~

function delete_ext_states()
	reaper.DeleteExtState( NAME, "W_D", 1 ) 
	reaper.DeleteExtState( NAME, "W_W", 1 ) 
	reaper.DeleteExtState( NAME, "W_H", 1 ) 
	reaper.DeleteExtState( NAME, "W_X", 1 ) 
	reaper.DeleteExtState( NAME, "W_Y", 1 )
	reaper.DeleteExtState( NAME, "snap", 1 )
	reaper.DeleteExtState( NAME, "grid", 1 )
	reaper.DeleteExtState( NAME, "fontS", 1 )
	reaper.DeleteExtState( NAME, "DCol", 1 )
	reaper.DeleteExtState( NAME, "iBak", 1 )
	reaper.DeleteExtState( NAME, "BakC", 1 )
	reaper.DeleteExtState( NAME, "BG_W", 1 )
	reaper.DeleteExtState( NAME, "BG_H", 1 )
	reaper.DeleteExtState( NAME, "BW_S", 1 )
end

function exit()
		if SAVE == true
	then
		local wd, wx, wy, ww, wh = gfx.dock( -1, 0, 0, 0, 0 )
		reaper.SetExtState( NAME, "W_D",  wd, true )
		reaper.SetExtState( NAME, "W_X",  wx, true )
		reaper.SetExtState( NAME, "W_Y",  wy, true )
		reaper.SetExtState( NAME, "W_W",  ww, true )
		reaper.SetExtState( NAME, "W_H",  wh, true )
		reaper.SetExtState( NAME, "snap", tostring(snap), true )
		reaper.SetExtState( NAME, "grid", tostring(grid), true )
		reaper.SetExtState( NAME, "fontS", tostring(fontSize), true )
		reaper.SetExtState( NAME, "DCol", tostring(default_col), true )
		reaper.SetExtState( NAME, "iBak", backgroundImage, true )
		if BG_W then reaper.SetExtState( NAME, "BG_W", BG_W, true ) end 
		if BG_H then reaper.SetExtState( NAME, "BG_H", BG_H, true ) end 
		reaper.SetExtState( NAME, "BG_S", BG_stretch, true ) 
		reaper.SetExtState( NAME, "BakC", reaper.ColorToNative( (gui[1].obj[1].r*255), (gui[1].obj[1].g*255), (gui[1].obj[1].b*255) ), true )
		local file = io.open(filename..NAME..".ini", "w")
			for a = 1, #gui[1].obj[1].button
		do
			--[[BUTTON ID]]     file:write(gui[1].obj[1].button[a].id) file:write("~") 
			--[[BUTTON X]]      file:write(gui[1].obj[1].button[a].x) file:write("~")
			--[[BUTTON Y]]      file:write(gui[1].obj[1].button[a].y) file:write("~")
			--[[BUTTON W]]      file:write(gui[1].obj[1].button[a].w) file:write("~")
			--[[BUTTON H]]      file:write(gui[1].obj[1].button[a].h) file:write("~")
			--[[BUTTON COLOR]]  file:write(reaper.ColorToNative( (gui[1].obj[1].button[a].r*255), (gui[1].obj[1].button[a].g*255), (gui[1].obj[1].button[a].b*255) ) ) file:write("~")
			--[[BUTTON ASIZE]]  file:write(gui[1].obj[1].button[a].ASize) file:write("~")
			--[[BUTTON IMG]]    file:write(gui[1].obj[1].button[a].img) file:write("~")
			--[[BUTTON TXT]]    file:write(gui[1].obj[1].button[a].txt) file:write("~")
				if gui[1].obj[1].button[a].id == 1
			then
			--[[BUTTON NAME]]   file:write(gui[1].obj[1].button[a].name[1]) file:write("~")
			--[[BUTTON ACTION]] file:write(gui[1].obj[1].button[a].action[1]) 
			else
			for b = 1, #gui[1].obj[1].button[a].name
			do
			--[[BUTTON NAME]]   file:write(gui[1].obj[1].button[a].name[b]) file:write("~")
			--[[BUTTON ACTION]] file:write(gui[1].obj[1].button[a].action[b]) if b < #gui[1].obj[1].button[a].name then file:write("~") end
			end 
			end
			file:write("\n")
		end
		file:close()
	end
end

--delete_ext_states()
reaper.atexit(exit)
init()







reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "W_D", 1 ) 
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "W_W", 1 ) 
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "W_H", 1 ) 
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "W_X", 1 ) 
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "W_Y", 1 )
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "snap", 1 )
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "grid", 1 )
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "fontS", 1 )
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "DCol", 1 )
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "iBak", 1 )
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "BakC", 1 )
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "BG_W", 1 )
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "BG_H", 1 )
reaper.DeleteExtState( "Dfk's Custom Toolbar Utility", "BW_S", 1 )














