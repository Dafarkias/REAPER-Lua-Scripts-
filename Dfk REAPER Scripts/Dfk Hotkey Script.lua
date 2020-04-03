--[[
 * ReaScript Name: Dfk Hotkey Script
 * About: Project workflow utility for creating custom hotkeys. 
 * Author: Dfk
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: js_ReaScriptAPI v0.993 (version used in development)
 * Version: .62
--]]
 
--[[
 * Changelog:
 * v.5 (2020-04-03) 
	+(script release)  
 * v.6 (2020-04-03)
	+Added many more virtual keys to script. (There's around 96 unique keys available now) 
	+Added ability to create hotkeys with up to two modifiers. (Ex.: Ctr+a or Ctr+Shf+c)
	+Changed method of altering a hotkey's context. (New method is a popup-menu)
	+Fixed bug for when deleting multple hotkeys from script. (confirmation menu would appear multiple times)
 * v.6qf (2020-04-03)
	+Fixed issue with modifiers causing error.
 * v.61 (2020-04-03)
	+Added action input "exit", so that a hotkey can cause the script to exit itself.
 * v.62 (2020-04-03)
	+hotkeys are no longer activated when the action window has focus.
	+fixed bug with manually setting a 'hotkey action'. 
--]]

function msg(param, clr) if clr then reaper.ClearConsole() end reaper.ShowConsoleMsg(tostring(param).."\n") end function up() reaper.UpdateTimeline() reaper.UpdateArrange() end 
local is_new_value,filename,sectionID,cmdID,mode,resolution,val = reaper.get_action_context() 
local startofit, endofit = string.find(filename,".*\\") 


script_name = ""
window      = 0

--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES
--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES--MASTER SCRIPT ADJUSTABLE VARIABLES
--
local dClick_time           = .2    -- amount of time that left double-click action must be performed in, by user, in decimal seconds
font_changes                = true  -- enabling multiple fonts/font changes can greatly increase draw times
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


fontSize = 10
font = "default"

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
									reaper.JS_Window_SetTitle( window, script_name ) 
								else
									reaper.JS_Window_SetTitle( window, script_name.." ("..obj[o].button[b].caption..")" ) 
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
								reaper.JS_Window_SetTitle( window, script_name ) 
							else
								reaper.JS_Window_SetTitle( window, script_name.." ("..obj[o].caption..")" ) 
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
		
		if once == false and set_caption_title == true and window ~= 0 then reaper.JS_Window_SetTitle( window, script_name ) end                                                                -- if no hover, set title to script_name
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
					gfx.line(xp,yp,static.xx,static.yy,static.aa )                                                                         -- draw line
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
					gfx.x, gfx.y = xp, yp gfx.drawstr( subber,static.th|static.tv,xp+wa,yp+ha )                          -- draw text
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
				end
				-- draw text
					if button.txt ~= ""
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
							gfx.line(xp,yp,static.xx,static.yy,static.aa )                                                                 -- draw line
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
							gfx.x, gfx.y = xp, yp gfx.drawstr( subber,static.th|static.tv,xp+wa,yp+ha )                  -- draw text
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


--[[ 
~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~
-------------------------------------------------------------------------------------------
-- GFX OBJECT CREATION: use negative (-) values for non-indexed, hard coded objects such as horizontal scroll bar
gui[?].obj[#obj+1] = {
id         = 1,                                                -- object classification (optional)
caption    = "left-click to center, right-click to open menu", -- caption display
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
act_off    = 1,                                                -- if 1, object action is disabled. if 2, disabled & mouse input is passed through 
blur_under = true,                                             -- whether to blur under object rectangles w/ transparency
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
-- GFX STATIC LINE
gui[?].obj[#obj].static[#obj[#obj].static+1] = {
type       = "line",               -- draw type
r          = .7,                   -- r
g          =.6,                    -- g
b          = .2,                   -- b
a          = .5,                   -- a
x          = 0,                    -- x
y          = 0,                    -- y
xx         = 100,                  -- x2: always manual; bypasses can_zoom, can_scroll and its parent object's coordinates are not added
yy         = 15,                   -- y2: always manual; bypasses can_zoom, can_scroll and its parent object's coordinates are not added
aa         = 1,                    -- antialias
can_zoom   = true,                 -- whether static zooms with global
can_scroll = false                 -- whether static scrolls with global
}
-- GFX STATIC CIRCLE
gui[?].obj[#obj].static[#obj[#obj].static+1] = {
type = "circ",                     -- draw type
ol         = {r=1,g=1,b=1,a=.2},   -- circle static's outline
r          = .7,                                                -- r
g          =.6,                                                 -- g
b          = .2,                                                -- b
a          = .5,                                                -- a
x          = 0,                    -- x
y          = 0,                    -- y
rs         = 15,                   -- radius
f          = 1,                    -- filled	
aa         = true,                 -- antialias
can_zoom   = true,                 -- whether static zooms with global: font_changes must be true in order for font size to adjust
can_scroll = false                 -- whether static scrolls with global
} 
-- GFX STATIC RECTANGLE
gui[?].obj[#obj].static[#obj[#obj].static+1] = {
type       = "rect",               -- draw type
ol         = {r=1,g=1,b=1,a=.2},   -- rectangle static's outline
r          = .7,                   -- r
g          =.6,                    -- g
b          = .2,                   -- b
a          = .5,                   -- a
x          = 0,                    -- x
y          = 0,                    -- y
w          = 100,                  -- width
h          = 15,                   -- height
f          = 1,                    -- filled	
can_zoom   = true,                 -- whether static zooms with global
can_scroll = false                 -- whether static scrolls with global
}
-- GFX STATIC TEXT
gui[?].obj[#obj].static[#obj[#obj].static+1] = {
type       = "text",   -- draw type
r          = .7,       -- r
g          =.6,        -- g
b          = .2,       -- b
a          = .5,       -- a 
txt        = "hi!",    -- text
x          = 0,        -- x
y          = 0,        -- y
w          = 100,      -- width that text is cropped to
h          = 15,       -- height
th         = 1,        -- text 'h' flag
tv         = 4,        -- text 'v' flag	
fo         = "Arial",  -- font settings will have no affect unless: font_changes = true
fs         = 12,       -- font size
ff         = nil,      -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
can_zoom   = true,     -- whether static zooms with global: font_changes must be true in order for font size to adjust
can_scroll = false     -- whether static scrolls with global
} 							 
-- GFX BUTTON
gui[?].obj[#obj].button[#obj[#obj].button+1] = {
id         = 1,                                                -- button classification
caption    = "left-click to center, right-click to open menu", -- caption display
type       = "rect",                                           -- draw type: "rect" or "circ"
ol         = {r=1,g=1,b=1,a=.2},                               -- rect: button's outline
hc         = 0,                                                -- current hover alpha (default '0')
ha         = .05,                                              -- hover alpha
hca        = .1,                                               -- hover click alpha 
r          = .7,                                               -- r
g          =.6,                                                -- g
b          = .2,                                               -- b
a          = .5,                                               -- a
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
txt        = "hi!",                                            -- text: "" disables text for button                                 
th         = 1,                                                -- text 'h' flag
tv         = 4,                                                -- text 'v' flag	
fo         = "Arial",                                          -- font settings will have no affect unless: font_changes = true
fs         = 12,                                               -- font size
ff         = nil,                                              -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
can_zoom   = true,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
can_scroll = false,                                            -- whether object rectangle scrolls with global   
act_off    = 1,                                                -- if 1, button action is disabled. if 2, button action is disabled and passed through   
static     = {},                                               -- index of static graphics that object holds
func       = 
	{ -- functions receive object and button index, & bool release ('r')
	-- always-run function
	[-1]      = function(self,g,o,b) end, 
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
TO RUN TABLE FUNCTION
obj[id].button[#obj.button+1]:func[1](o,(b),r,d)

-------------------------------------------------------------------------------------------
~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~EXAMPLES~
]]

--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA
--
local Pin_Window                   = true    -- true/false 
local Bar_Size                     = 20      -- 10+: default 20
local Font_Size                    = 17      -- 10+: default 17
local Scroll_Sensitivity           = 10      -- .1+: default 10
--
--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA

--script vars
script_name = "Dfk's Hotkey Script".." v"..VERSION

-- window vars
local _,_,display_width,display_height = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true )
window = 0 --set in function init()
local window_xMin, window_xMax = 650, display_width
local window_yMin, window_yMax = 100, display_height


-- project vars
local exiter = false
local section = "Global"

-- script vars
local hotkey = {}
local press_key = nil
local folder = true
local UpDown_time, UpDown_delay = 0, .25
local draw_time, draw_delay = 0, .25

--VIRTUAL KEY CODES:
if folder then
	key_codes = {} for a = 1, 222 do key_codes[a] = "-1" end 
	key_codes[8] = "BCKSPACE"
	key_codes[9] = "TAB"
	key_codes[13] = "ENTER"
	key_codes[16] = "SHIFT"
	key_codes[17] = "CTRL"
	key_codes[18] = "ALT"
	key_codes[20] = "CAPS"
	key_codes[27] = "ESC"
	key_codes[32] = "SPACE"
	key_codes[37] = "LEFT"
	key_codes[38] = "UP"
	key_codes[39] = "RIGHT"
	key_codes[40] = "DOWN"
	key_codes[33] = "PGUP"
	key_codes[34] = "PGDOWN"
	key_codes[35] = "END"
	key_codes[36] = "HOME"
	key_codes[44] = "PRNTSCR"
	key_codes[45] = "INS"
	key_codes[46] = "DEL"
	key_codes[48] = "0"
	key_codes[49] = "1"
	key_codes[50] = "2"
	key_codes[51] = "3"
	key_codes[52] = "4"
	key_codes[53] = "5"
	key_codes[54] = "6"
	key_codes[55] = "7"
	key_codes[56] = "8"
	key_codes[57] = "9"
	key_codes[65] = "A"
	key_codes[66] = "B"
	key_codes[67] = "C"
	key_codes[68] = "D" 
	key_codes[69] = "E"
	key_codes[70] = "F"
	key_codes[71] = "G"
	key_codes[72] = "H"
	key_codes[73] = "I"
	key_codes[74] = "J"
	key_codes[75] = "K"
	key_codes[76] = "L"
	key_codes[77] = "M"
	key_codes[78] = "N"
	key_codes[79] = "O"
	key_codes[80] = "P"
	key_codes[81] = "Q"
	key_codes[82] = "R"
	key_codes[83] = "S"
	key_codes[84] = "T"
	key_codes[85] = "U"
	key_codes[86] = "V"
	key_codes[87] = "W"
	key_codes[88] = "X"
	key_codes[89] = "Y"
	key_codes[90] = "Z"
	key_codes[91] = "LWIN" 
	key_codes[92] = "RWIN" 
	key_codes[96] = "N0"
	key_codes[97] = "N1"
	key_codes[98] = "N2"
	key_codes[99] = "N3"
	key_codes[100] = "N4"
	key_codes[101] = "N5"
	key_codes[102] = "N6"
	key_codes[103] = "N7"
	key_codes[104] = "N8"
	key_codes[105] = "N9"
	key_codes[106] = "N*"
	key_codes[107] = "N+"
	key_codes[109] = "N-"
	key_codes[110] = "N."
	key_codes[111] = "N/"
	key_codes[112] = "F1"
	key_codes[113] = "F2"
	key_codes[114] = "F3"
	key_codes[115] = "F4"
	key_codes[116] = "F5"
	key_codes[117] = "F6"
	key_codes[118] = "F7"
	key_codes[119] = "F8"
	key_codes[120] = "F9"
	key_codes[121] = "F10"
	key_codes[122] = "F11"
	key_codes[123] = "F12"
	key_codes[144] = "NUMLCK"
	key_codes[186] = ";"
	key_codes[187] = "="
	key_codes[188] = ","
	key_codes[189] = "-"
	key_codes[190] = "."
	key_codes[191] = "/"
	key_codes[192] = "`"
	key_codes[219] = "["
	key_codes[220] = "\\"
	key_codes[221] = "]"
	key_codes[222] = "'"
end

function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function update_hotkey()
	gui[1] = {obj = {}} 
		for a = 1, #hotkey
	do
		gui[1].obj[a] = 
		{
			caption    = "", -- caption display
			hc         = 0,                                                -- current hover alpha (default '0')
			ha         = .1,                                              -- hover alpha
			hca        = .2,                                               -- hover click alpha 
			ol         = {r=1,g=1,b=1,a=.2},                               -- rect: object's outline
			r          = 0,                                               -- r
			g          = 0,                                                -- g
			b          = 0,                                               -- b
			a          = 1,                                               -- a
			f          = 1,                                                -- rect: filled	
			x          = 0,                                                -- x
			y          = Bar_Size*a,                                                -- y
			w          = gfx.w,                                                -- w
			h          = Bar_Size,                                                -- h
			can_zoom   = false,                                             -- whether object rectangle zooms with global
			can_scroll = true,                                            -- whether object rectangle scrolls with global 
			--act_off    = 1,                                                -- if 1, object action is disabled. if 2, disabled & mouse input is passed through 
			blur_under = false,                                             -- whether to blur under object rectangles w/ transparency
			static     = {},                                               -- index of static graphics that object holds
			func       = 
				{ -- functions receive object index and bool release ('r')
				-- always-run function
				[-1]      = 
				function(self,g,o)
				
					if self.sel then self.ol = {r=0,g=1,b=0,a=1} else self.ol = {r=1,g=1,b=1,a=.2} end 
					
						if mx > 0 and mx < gfx.w-Bar_Size and my > self.y and my < self.y+Bar_Size 
					then
						for a = 1, #self.button do self.button[a].a = .9 end
					else
						for a = 1, #self.button do self.button[a].a = 1 end
					end 
					
				end, 
				-- mouse_cap functions
				[1]      = function(self,o,r,d) if r then  return else  end end, 
				[2]      = 
				function(self,o,r,d) 
					-- SELECT
						if r 
					then 
						for a = 1, #gui[1].obj do if a ~= o then gui[1].obj[a].sel = nil end end 
						if not self.sel then self.sel = true else self.sel = nil end
					end 
				end, 
				[3]      = 
				function(self,o,r,d) 
					-- CTR SELECT
						if r 
					then
						if not self.sel then self.sel = true else self.sel = nil end
					end 
				end, 
				[4]      = 
				function(self,o,r,d) 
					-- SHF SELECT
						if r 
					then
						local counter, counter_id = 0, 0
							for a = 1, #hotkey
						do
							if gui[1].obj[a].sel then counter, counter_id = counter + 1, a end
						end
							if counter == 1
						then
								if counter_id > o
							then
								for a = o, counter_id do gui[1].obj[a].sel = true end 
								elseif counter_id < o 
							then
								for a = counter_id, o do gui[1].obj[a].sel = true end 
							end
						end
					end 
				end
				},
			mouse      =
				{ -- index [1] must always be left click
				[1]        = 1,             
				[2]        = 2,
				[3]        = 5,
				[4]        = 9
				},
			hold       = 
				{
				[1]        = true,
				[2]        = false,
				[3]        = false,
				[4]        = false
				},
			m_rel = 
				{
				[1] = nil,
				[2] = nil,
				[3] = 1,
				[4] = 1
				},
			button     = 
			{
				[1] = {
				caption    = "R: set REAPER action hotkey Up/Down: Move hotkey position(s) Del: delete hotkey(s)", -- caption display
				type       = "rect",                                           -- draw type: "rect" or "circ"
				ol         = {r=1,g=1,b=1,a=.2},                               -- rect: button's outline
				hc         = 0,                                                -- current hover alpha (default '0')
				ha         = .1,                                               -- hover alpha
				hca        = .2,                                               -- hover click alpha 
				r          = .65,                                               -- r
				g          = .65,                                                -- g
				b          = .65,                                               -- b
				a          = 1,                                               -- a
				rt         = 0,                                               -- r     (text)
				gt         = 0,	                                           -- g     (text)
				bt         = 0,                                               -- b     (text)
				at         = .9,                                               -- alpha (text)
				x          = 0,                                                -- x
				y          = 0,                                                -- y                     
				w          = 100,                                              -- width
				h          = Bar_Size,                                              -- height
				f          = 1,                                                -- filled
				rs         = 10,                                               -- circle: radius
				aa         = true,                                             -- circle: antialias         
				txt        = hotkey[a].name,                                   -- text: "" disables text for button                                 
				th         = 1,                                                -- text 'h' flag
				tv         = 4,                                                -- text 'v' flag	
				fo         = "Arial",                                          -- font settings will have no affect unless: font_changes = true
				fs         = Font_Size,                                               -- font size
				ff         = nil,                                              -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
				can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
				can_scroll = true,                                            -- whether object rectangle scrolls with global   
				static     = {},                                               -- index of static graphics that object holds
				func       = 
					{ -- functions receive object and button index, & bool release ('r')
					-- always-run function
					[-1]      = 
					function(self,g,o,b) 
						self.txt = hotkey[o].name
						if gui[1].obj[o].sel then self.r, self.g, self.b = .5, .5, .5 else self.r, self.g, self.b = .8, .8, .8 end 
					end, 
					-- mouse_cap functions
					[2]      = 
					function(self,o,b,r,d) 
							if r 
						then 
							if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
							local retval, retvals_csv = reaper.GetUserInputs( "[user input]", 1, "Input action hotkey: @separator=@extrawidth=720", "(a-z)(0-9)(;=,-./`[]\\)(n0-n9)(n*n+n-n.n/)(f1-f12)bckspace,tab,enter,shift,ctrl,alt,caps,esc,space,left,up,right,down,pgup,pgdown,end,home,prntscr,ins,del,lwin,rwin,numlck" )
								if retval 
							then retvals_csv = tostring(retvals_csv):sub( 1, 1 )
									if type(retvals_csv) == 'string'
								then
										for a = 1, #key_codes
									do
											if retvals_csv:upper() == key_codes[a]
										then
											hotkey[o].key = a hotkey[o].name = key_codes[a]:lower() break
										end
									end
								end
							end
							if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
						end 
					end, 
					[1]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[2](gui[1].obj[o],o,r,d)
					end,
					[3]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[3](gui[1].obj[o],o,r,d)
					end,
					[4]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[4](gui[1].obj[o],o,r,d)
					end
					},
				mouse      =
					{ -- index [1] must always be left click
					[1]        = 1,             
					[2]        = 2,
					[3]        = 5,
					[4]        = 9
					},
				hold       = 
					{
					[1]        = true,
					[2]        = false,
					[3]        = false,
					[4]        = false
					},
				m_rel = 
					{
					[1] = nil,
					[2] = nil,
					[3] = 1,
					[4] = 1
					}
				},
				[2] = {
				caption    = "R: set hotkey REAPER action Up/Down: Move hotkey position(s) Del: delete hotkey(s)", -- caption display
				type       = "rect",                                           -- draw type: "rect" or "circ"
				ol         = {r=1,g=1,b=1,a=.2},                               -- rect: button's outline
				hc         = 0,                                                -- current hover alpha (default '0')
				ha         = .1,                                               -- hover alpha
				hca        = .2,                                               -- hover click alpha 
				r          = .7,                                               -- r
				g          = .7,                                                -- g
				b          = .7,                                               -- b
				a          = 1,                                               -- a
				rt         = 0,                                               -- r     (text)
				gt         = 0,	                                           -- g     (text)
				bt         = 0,                                               -- b     (text)
				at         = .9,                                               -- alpha (text)
				x          = 100,                                                -- x
				y          = 0,                                                -- y                     
				w          = 100,                                              -- width
				h          = Bar_Size,                                              -- height
				f          = 1,                                                -- filled
				rs         = 10,                                               -- circle: radius
				aa         = true,                                             -- circle: antialias         
				txt        = hotkey[a].action,                                            -- text: "" disables text for button                                 
				th         = 1,                                                -- text 'h' flag
				tv         = 4,                                                -- text 'v' flag	
				fo         = "Arial",                                          -- font settings will have no affect unless: font_changes = true
				fs         = Font_Size,                                               -- font size
				ff         = nil,                                              -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
				can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
				can_scroll = true,                                            -- whether object rectangle scrolls with global   
				static     = {},                                               -- index of static graphics that object holds
				func       = 
					{ -- functions receive object and button index, & bool release ('r')
					-- always-run function
					[-1]      = 
					function(self,g,o,b) 
						if hotkey[a].action then self.txt = hotkey[a].action end
						if gui[1].obj[o].sel then self.r, self.g, self.b = .5, .5, .5 else self.r, self.g, self.b = .8, .8, .8 end 
					end, 
					-- mouse_cap functions
					[2]      = 
					function(self,o,b,r,d) 
							if r 
						then 
							if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
							local retval, retvals_csv = reaper.GetUserInputs( "[user input]", 1, "Input hotkey action", hotkey[o].action )
								if retval 
							then retvals_csv = tostring(retvals_csv) 
								hotkey[o].action = retvals_csv 
							end
							if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
						end 
					end, 
					[1]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[2](gui[1].obj[o],o,r,d)
					end,
					[3]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[3](gui[1].obj[o],o,r,d)
					end,
					[4]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[4](gui[1].obj[o],o,r,d)
					end
					},
				mouse      =
					{ -- index [1] must always be left click
					[1]        = 1,             
					[2]        = 2,
					[3]        = 5,
					[4]        = 9
					},
				hold       = 
					{
					[1]        = true,
					[2]        = false,
					[3]        = false,
					[4]        = false
					},
				m_rel = 
					{
					[1] = nil,
					[2] = nil,
					[3] = 1,
					[4] = 1
					}
				},
				[3] = {
				caption    = "R: set hotkey description Up/Down: Move hotkey position(s) Del: delete hotkey(s)", -- caption display
				type       = "rect",                                           -- draw type: "rect" or "circ"
				ol         = {r=1,g=1,b=1,a=.2},                               -- rect: button's outline
				hc         = 0,                                                -- current hover alpha (default '0')
				ha         = .1,                                               -- hover alpha
				hca        = .2,                                               -- hover click alpha 
				r          = .75,                                               -- r
				g          = .75,                                                -- g
				b          = .75,                                               -- b
				a          = 1,                                               -- a
				rt         = 0,                                               -- r     (text)
				gt         = 0,	                                           -- g     (text)
				bt         = 0,                                               -- b     (text)
				at         = .9,                                               -- alpha (text)
				x          = 200,                                                -- x
				y          = 0,                                                -- y                     
				w          = 200,                                              -- width
				h          = Bar_Size,                                              -- height
				f          = 1,                                                -- filled
				rs         = 10,                                               -- circle: radius
				aa         = true,                                             -- circle: antialias         
				txt        = hotkey[a].descript,                                            -- text: "" disables text for button                                 
				th         = 1,                                                -- text 'h' flag
				tv         = 4,                                                -- text 'v' flag	
				fo         = "Arial",                                          -- font settings will have no affect unless: font_changes = true
				fs         = Font_Size,                                               -- font size
				ff         = nil,                                              -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
				can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
				can_scroll = true,                                            -- whether object rectangle scrolls with global   
				static     = {},                                               -- index of static graphics that object holds
				func       = 
					{ -- functions receive object and button index, & bool release ('r')
					-- always-run function
					[-1]      = 
					function(self,g,o,b) 
						self.txt = hotkey[a].descript
						if gui[1].obj[o].sel then self.r, self.g, self.b = .5, .5, .5 else self.r, self.g, self.b = .8, .8, .8 end 
					end, 
					-- mouse_cap functions
					[2]      = 
					function(self,o,b,r,d) 
							if r 
						then 
							if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
							local retval, retvals_csv = reaper.GetUserInputs( "[user input]", 1, "Input hotkey descript", hotkey[o].descript )
								if retval 
							then retvals_csv = tostring(retvals_csv) 
								hotkey[o].descript = retvals_csv 
							end
							if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
						end 
					end, 
					[1]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[2](gui[1].obj[o],o,r,d)
					end,
					[3]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[3](gui[1].obj[o],o,r,d)
					end,
					[4]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[4](gui[1].obj[o],o,r,d)
					end
					},
				mouse      =
					{ -- index [1] must always be left click
					[1]        = 1,             
					[2]        = 2,
					[3]        = 5,
					[4]        = 9
					},
				hold       = 
					{
					[1]        = true,
					[2]        = false,
					[3]        = false,
					[4]        = false
					},
				m_rel = 
					{
					[1] = nil,
					[2] = nil,
					[3] = 1,
					[4] = 1
					}
				},
				[4] = {
				caption    = "R: set hotkey context Up/Down: Move hotkey position(s) Del: delete hotkey(s)", -- caption display
				type       = "rect",                                           -- draw type: "rect" or "circ"
				ol         = {r=1,g=1,b=1,a=.2},                               -- rect: button's outline
				hc         = 0,                                                -- current hover alpha (default '0')
				ha         = .1,                                               -- hover alpha
				hca        = .2,                                               -- hover click alpha 
				r          = .7,                                               -- r
				g          = .7,                                                -- g
				b          = .7,                                               -- b
				a          = 1,                                               -- a
				rt         = 0,                                               -- r     (text)
				gt         = 0,	                                           -- g     (text)
				bt         = 0,                                               -- b     (text)
				at         = .9,                                               -- alpha (text)
				x          = gfx.w-100-Bar_Size,                                                -- x
				y          = 0,                                                -- y                     
				w          = 100,                                              -- width
				h          = Bar_Size,                                              -- height
				f          = 1,                                                -- filled
				rs         = 10,                                               -- circle: radius
				aa         = true,                                             -- circle: antialias         
				txt        = hotkey[a].section,                                            -- text: "" disables text for button                                 
				th         = 1,                                                -- text 'h' flag
				tv         = 4,                                                -- text 'v' flag	
				fo         = "Arial",                                          -- font settings will have no affect unless: font_changes = true
				fs         = Font_Size,                                               -- font size
				ff         = nil,                                              -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
				can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
				can_scroll = true,                                            -- whether object rectangle scrolls with global   
				static     = {},                                               -- index of static graphics that object holds
				func       = 
					{ -- functions receive object and button index, & bool release ('r')
					-- always-run function
					[-1]      = 
					function(self,g,o,b) 
						self.txt = hotkey[a].section
						if gui[1].obj[o].sel then self.r, self.g, self.b = .5, .5, .5 else self.r, self.g, self.b = .8, .8, .8 end 
					end, 
					-- mouse_cap functions
					[2]      = 
					function(self,o,b,r,d) 
							if r 
						then 
							if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
							local arrange = "Arrange" if hotkey[o].section == "Arrange" then arrange = "!Arrange" end 
							local global = "Global" if hotkey[o].section == "Global" then global = "!Global" end 
							local MIDI = "MIDI" if hotkey[o].section == "MIDI" then MIDI = "!MIDI" end 
							gfx.x, gfx.y = self.x, gui[1].obj[o].y local gfxinput = gfx.showmenu( arrange.."|"..global.."|"..MIDI )
								if gfxinput == 1
							then
								hotkey[o].section = "Arrange"
								elseif gfxinput == 2
							then
								hotkey[o].section = "Global"
								elseif gfxinput == 3
							then
								hotkey[o].section = "MIDI"
							end
							if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
						end 
					end, 
					[1]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[2](gui[1].obj[o],o,r,d)
					end,
					[3]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[3](gui[1].obj[o],o,r,d)
					end,
					[4]      = 
					function(self,o,b,r,d) 
						gui[1].obj[o].func[4](gui[1].obj[o],o,r,d)
					end
					},
				mouse      =
					{ -- index [1] must always be left click
					[1]        = 1,             
					[2]        = 2,
					[3]        = 5,
					[4]        = 9
					},
				hold       = 
					{
					[1]        = true,
					[2]        = false,
					[3]        = false,
					[4]        = false
					},
				m_rel = 
					{
					[1] = nil,
					[2] = nil,
					[3] = 1,
					[4] = 1
					}
				}
			}                                               -- index of buttons that object holds	
		}
	end
end

function init()

	-- setup GUI window
	local d, w, h, x, y = 0,500,500,display_width/2-250,display_height/2-250
	if reaper.HasExtState( "Dfk Hotkey", "W_D" ) then d = reaper.GetExtState( "Dfk Hotkey", "W_D" ) end
	if reaper.HasExtState( "Dfk Hotkey", "W_W" ) then w = reaper.GetExtState( "Dfk Hotkey", "W_W" ) end
	if reaper.HasExtState( "Dfk Hotkey", "W_H" ) then h = reaper.GetExtState( "Dfk Hotkey", "W_H" ) end
	if reaper.HasExtState( "Dfk Hotkey", "W_X" ) then x = reaper.GetExtState( "Dfk Hotkey", "W_X" ) end
	if reaper.HasExtState( "Dfk Hotkey", "W_Y" ) then y = reaper.GetExtState( "Dfk Hotkey", "W_Y" ) end
	if reaper.HasExtState( "Dfk Hotkey", "V_V" ) then V_V = reaper.GetExtState( "Dfk Hotkey", "V_V" ) end
	gfx.init(script_name, w, h, d, x, y )
	window = reaper.JS_Window_Find( script_name, 1 ) if Pin_window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
	-------------------
	
	-- Read Dfk Hotkey Script.txt
	local file = io.open(string.sub(filename, 1, endofit).."Dfk Hotkey Script.txt", "a") file:close() file = io.input(string.sub(filename, 1, endofit).."Dfk Hotkey Script.txt")
		for line in file:lines() 
	do
		local tablet = line:split(", ") 		
		local id = #hotkey+1
		hotkey[id] = {name = tablet[1], key = tonumber(tablet[2]), mod = tablet[3], mod2 = tablet[4], action = tablet[5], descript = tablet[6], section = tablet[7] }
	end 
	file:close()
	-----------------------------
	update_hotkey()
	if folder then
		gui[2] = {obj = {}} gui[2].obj[1] = 
		{
			caption    = "L: add new hotkey", -- caption display
			hc         = 0,                                                -- current hover alpha (default '0')
			ha         = -.15,                                              -- hover alpha
			hca        = -.25,                                               -- hover click alpha 
			ol         = {r=0,g=0,b=0,a=.2},                               -- rect: object's outline
			r          = .7,                                               -- r
			g          =.6,                                                -- g
			b          = .2,                                               -- b
			a          = 1,                                               -- a
			f          = 1,                                                -- rect: filled	
			x          = 0,                                                -- x
			y          = 0,                                                -- y
			w          = gfx.w,                                                -- w
			h          = Bar_Size,                                                -- h
			can_zoom   = false,                                             -- whether object rectangle zooms with global
			can_scroll = false,                                            -- whether object rectangle scrolls with global 
			blur_under = false,                                             -- whether to blur under object rectangles w/ transparency
			button     = 
			{
				[1] = {
				caption    = "L: dock/undock window", -- caption display
				type       = "rect",                                           -- draw type: "rect" or "circ"
				ol         = {r=0,g=0,b=0,a=.2},                               -- rect: button's outline
				hc         = 0,                                                -- current hover alpha (default '0')
				ha         = .4,                                              -- hover alpha
				hca        = .5,                                               -- hover click alpha 
				r          = .4,                                               -- r
				g          = .3,                                                -- g
				b          = 0,                                               -- b
				a          = 1,                                               -- a
				rt         = 1,                                               -- r     (text)
				gt         = 1,	                                           -- g     (text)
				bt         = 1,                                               -- b     (text)
				at         = .9,                                               -- alpha (text)
				x          = 0,                                                -- x
				y          = 0,                                                -- y                     
				w          = 100,                                              -- width
				h          = Bar_Size,                                              -- height
				f          = 1,                                                -- filled
				rs         = 10,                                               -- circle: radius
				aa         = true,                                             -- circle: antialias         
				txt        = "Dock",                                            -- text: "" disables text for button                                 
				th         = 1,                                                -- text 'h' flag
				tv         = 4,                                                -- text 'v' flag	
				fo         = "Arial",                                          -- font settings will have no affect unless: font_changes = true
				fs         = Bar_Size-2,                                               -- font size
				ff         = "bi",                                              -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
				can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
				can_scroll = false,                                            -- whether object rectangle scrolls with global   
				static     = {},                                               -- index of static graphics that object holds
				func       = 
					{ -- functions receive object and button index, & bool release ('r')
					-- always-run function
					[-1]      = function(self,g,o,b) end, 
					-- non-indexed function
					[0]      = function(self,o,b,r,d) if r then  return else  end end, 
					-- mouse_cap functions
					[1]      = 
					function(self,o,b,r,d) 
							if r 
						then 
							local wd, _, _, _, _ = gfx.dock( -1, 0, 0, 0, 0 ) if wd == 1 then gfx.dock( 0 ) else gfx.dock( 1 ) end 
						end 
					end, 
					[2]      = function(self,o,b,r,d) if r then  return else  end end,
					[3]      = function(self,o,b,r,d) if r then  return else  end end, 
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
			},                                               -- index of buttons that object holds
			static     = 
			{
				[1] = {
				type       = "text",   -- draw type
				r          = 0,       -- r
				g          = 0,        -- g
				b          = 0,       -- b
				a          = 1,       -- a 
				txt        = "...Add New Hotkey...",    -- text
				x          = 100,        -- x
				y          = 0,        -- y
				w          = gfx.w-100,      -- width that text is cropped to
				h          = Bar_Size,       -- height
				th         = 1,        -- text 'h' flag
				tv         = 4,        -- text 'v' flag	
				fo         = "Arial",  -- font settings will have no affect unless: font_changes = true
				fs         = Bar_Size,       -- font size
				ff         = "b",      -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
				can_zoom   = false,     -- whether static zooms with global: font_changes must be true in order for font size to adjust
				can_scroll = false     -- whether static scrolls with global
				} 	
			},                                               -- index of static graphics that object holds
			func       = 
				{ -- functions receive object index and bool release ('r')
				-- always-run function
				[-1]      = function(self,g,o) end, 
				-- non-indexed function
				[0]      = function(self,o,r,d) if r then  return else  end end, 
				-- mouse_cap functions
				[1]      = 
				function(self,o,r,d) 
						if r
					then o = #hotkey+1
						if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
						local retval, retvals_csv = 
						reaper.GetUserInputs( "[user input]", 6, "Action hotkey:@Hotkey modifier (optional):@Hotkey modifier2 (optional):@Hotkey action:@Hotkey description (optional):@Hotkey context:@extrawidth=720@separator=@", 
						"(a-z)(0-9)(;=,-./`[]\\)(n0-n9)(n*n+n-n.n/)(f1-f12)bckspace,tab,enter,shift,ctrl,alt,caps,esc,space,left,up,right,down,pgup,pgdown,end,home,prntscr,ins,del,lwin,rwin,numlck@"..
						"(shift,ctrl,alt,lwin,rwin)@(shift,ctrl,alt,lwin,rwin)@E.g.: 40001, _a768e3f63ed2404882380ae1a8859f30 (input the word \"exit\" here and hotkey will cause script to exit)@(type action description here)@A = Arrange, G = Global, M = MIDI" )
							if retval 
						then 
							local tabler = retvals_csv:split("@") local namer, namer2 = ""
							--KEY
							local continue = false tabler[1] = tostring(tabler[1]):upper() hotkey[o] = {} 
								if type(tabler[1]) == 'string'
							then 
									for a = 1, #key_codes
								do 
										if tabler[1] == key_codes[a] and key_codes[a] ~= "-1"
									then 
										hotkey[o].key = a namer = key_codes[a]:upper() continue = true break
									end
								end
							end 
							--MOD (optional)
							tabler[2] = tostring(tabler[2]):upper()
							hotkey[o].mod = "nil"
							if tabler[2] == "SHIFT" then hotkey[o].mod = "16" tabler[2] = "shf" end 
							if tabler[2] == "CTRL"  then hotkey[o].mod = "17" tabler[2] = "ctr" end 
							if tabler[2] == "ALT"   then hotkey[o].mod = "18" tabler[2] = "alt" end 
							if tabler[2] == "LWIN"  then hotkey[o].mod = "91" tabler[2] = "lWn" end 
							if tabler[2] == "RWIN"  then hotkey[o].mod = "92" tabler[2] = "rWn" end 
							--MOD2 (optional)
							tabler[3] = tostring(tabler[3]):upper()
							hotkey[o].mod2 = "nil"
							if tabler[3] == "SHIFT" then hotkey[o].mod2 = "16" tabler[3] = "shf" end 
							if tabler[3] == "CTRL"  then hotkey[o].mod2 = "17" tabler[3] = "ctr" end 
							if tabler[3] == "ALT"   then hotkey[o].mod2 = "18" tabler[3] = "alt" end 
							if tabler[3] == "LWIN"  then hotkey[o].mod2 = "91" tabler[3] = "lWn" end 
							if tabler[3] == "RWIN"  then hotkey[o].mod2 = "92" tabler[3] = "rWn" end 
							--ACTION
							tabler[4] = tostring(tabler[4]) if tabler[4] == "" or tabler[4] == " " then continue = false end 
							hotkey[o].action = tabler[4] 
							--DESCRIPT (optional)
							tabler[5] = tostring(tabler[5]) 
							hotkey[o].descript = tabler[5] 
							--SECTION
							tabler[6] = tostring(tabler[6])
							hotkey[o].section = "Global"
								if tabler[6] == "A"
							then
								hotkey[o].section = "Arrange"
								elseif tabler[6] == "M"
							then
								hotkey[o].section = "MIDI"
							end
								if continue == true 
							then 
								hotkey[o].name = namer
								if hotkey[o].mod ~= "nil" then hotkey[o].name = tabler[2].."+"..namer end
								if hotkey[o].mod2 ~= "nil" then hotkey[o].name = tabler[3].."+"..hotkey[o].name end
								hotkey[o].name = hotkey[o].name:lower()
								update_hotkey() 
							else 
								hotkey[o] = nil 
							end					
							if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
						end
					end
				end, 
				[2]      = function(self,o,r,d) if r then  return else  end end, 
				[3]      = function(self,o,r,d) if r then  return else  end end, 
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
		gui[2].obj[2] = {
		caption    = "vertical scroll bar", -- caption display
		hc         = 0,                                                -- current hover alpha (default '0')
		ha         = .05,                                              -- hover alpha
		hca        = .1,                                               -- hover click alpha 
		ol         = {r=1,g=1,b=1,a=.2},                               -- rect: object's outline
		r          = .5,                                               -- r
		g          = .5,                                                -- g
		b          = .5,                                               -- b
		a          = 1,                                               -- a
		f          = 1,                                                -- rect: filled	
		x          = gfx.w-Bar_Size,                                                -- x
		y          = 0,                                                -- y
		w          = Bar_Size,                                                -- w
		h          = gfx.h,                                                -- h
		can_zoom   = false,                                             -- whether object rectangle zooms with global
		can_scroll = false,                                            -- whether object rectangle scrolls with global 
		act_off    = 1,                                                -- if 1, object action is disabled. if 2, disabled & mouse input is passed through 
		blur_under = false,                                             -- whether to blur under object rectangles w/ transparency
		button     = 
		{
			[1] = {
			caption    = "L: adjust window vertical scroll", -- caption display
			type       = "rect",                                           -- draw type: "rect" or "circ"
			ol         = {r=1,g=1,b=1,a=.2},                               -- rect: button's outline
			hc         = 0,                                                -- current hover alpha (default '0')
			ha         = .05,                                              -- hover alpha
			hca        = .1,                                               -- hover click alpha 
			r          = .4,                                               -- r
			g          = .4,                                                -- g
			b          = .4,                                               -- b
			a          = 1,                                               -- a
			rt         = .5,                                               -- r     (text)
			gt         = .5,	                                           -- g     (text)
			bt         = .5,                                               -- b     (text)
			at         = .5,                                               -- alpha (text)
			x          = 0,                                                -- x
			y          = 0,                                                -- y                     
			w          = Bar_Size,                                              -- width
			h          = Bar_Size,                                              -- height
			f          = 1,                                                -- filled
			rs         = 10,                                               -- circle: radius
			aa         = true,                                             -- circle: antialias         
			txt        = "",                                            -- text: "" disables text for button                                 
			th         = 1,                                                -- text 'h' flag
			tv         = 4,                                                -- text 'v' flag	
			fo         = "Arial",                                          -- font settings will have no affect unless: font_changes = true
			fs         = 12,                                               -- font size
			ff         = nil,                                              -- font flags ("b", "i", "u" = bold, italic, underlined. Flags can be combined, or value can be nil)
			can_zoom   = false,                                             -- whether object rectangle zooms with global: font_changes must be true in order for font size to adjust
			can_scroll = false,                                            -- whether object rectangle scrolls with global   
			static     = {},                                               -- index of static graphics that object holds
			func       = 
				{ -- functions receive object and button index, & bool release ('r')
				-- always-run function
				[-1]      = 
				function(self,g,o,b) 
					self.y = ((gfx.h-Bar_Size)/(((#hotkey+2)*Bar_Size)-gfx.h))*V_V if tostring(self.y) == "-1.#IND" then self.y = 0 end
				end, 
				-- non-indexed function
				[0]      = function(self,o,b,r,d) if r then  return else  end end, 
				-- mouse_cap functions
				[1]      = 
				function(self,o,b,r,d) 
					if r then end 
					--if #hotkey*Bar_Size <
					local mouser = gfx.mouse_y mouser = mouser - (Bar_Size/2) if mouser < 0 then mouser = 0 end if mouser > gfx.h-Bar_Size then mouser = gfx.h-Bar_Size end	
					V_V = (((#hotkey+2)*Bar_Size)-gfx.h)*(mouser/(gfx.h-Bar_Size )) if V_V > (((#hotkey+2)*Bar_Size)-gfx.h) then V_V = (((#hotkey+2)*Bar_Size)-gfx.h) end if V_V < 0 then V_V = 0 end 
				end, 
				[2]      = function(self,o,b,r,d) if r then  return else  end end,
				[3]      = function(self,o,b,r,d) if r then  return else  end end, 
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
		},                                               -- index of buttons that object holds
		static     = {},                                               -- index of static graphics that object holds
		func       = 
			{ -- functions receive object index and bool release ('r')
			-- always-run function
			[-1]      = function(self,g,o) end, 
			-- non-indexed function
			[0]      = function(self,o,r,d) if r then  return else  end end, 
			-- mouse_cap functions
			[1]      = function(self,o,r,d) if r then  return else  end end, 
			[2]      = function(self,o,r,d) if r then  return else  end end, 
			[3]      = function(self,o,r,d) if r then  return else  end end, 
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
	end -- end of folder
	main()
end

function dynamic_vars()
	gui[2].obj[1].w, gui[2].obj[1].static[1].w = gfx.w-Bar_Size, gfx.w-100-Bar_Size
		for a = 1, #gui[1].obj 
	do 
		gui[1].obj[a].w = gfx.w-Bar_Size 
		gui[1].obj[a].button[3].w = gfx.w-300-Bar_Size
		gui[1].obj[a].button[4].x = gfx.w-100-Bar_Size
	end
	local wd, _, _, _, _ = gfx.dock( -1, 0, 0, 0, 0 ) if wd == 1 then gui[2].obj[1].button[1].txt = "Undock" else gui[2].obj[1].button[1].txt = "Dock" end 
	gui[2].obj[2].x, gui[2].obj[2].h = gfx.w-Bar_Size, gfx.h
end

function resize_window()
		if reaper.JS_Mouse_GetState(1) == 0
	then
		local wd, wx, wy, ww, wh = gfx.dock( -1, 0, 0, 0, 0 )
		if ww < window_xMin then ww = window_xMin gfx.init("",window_xMin,wh,wd,wx,wy ) end 
		if ww > window_xMax then ww = window_xMax gfx.init("",window_xMax,wh,wd,wx,wy ) end 
		if wh < window_yMin then wh = window_yMin gfx.init("",ww,window_yMin,wd,wx,wy ) end 
		if wh > window_yMax then gfx.init("",ww,window_yMax,wd,wx,wy )end 
	end
end

--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~
function main()

		if reaper.JS_Window_FromPoint( reaper.GetMousePosition() ) == window or reaper.time_precise() > draw_time + draw_delay
	then 
		dynamic_vars()
		resize_window()
		if gfx.mouse_wheel ~= 0 then V_V = V_V + (gfx.mouse_wheel/120)*Scroll_Sensitivity gfx.mouse_wheel = 0 if V_V > ((#hotkey+2)*Bar_Size)-gfx.h then V_V = ((#hotkey+2)*Bar_Size)-gfx.h end if V_V < 0 then V_V = 0 end end 
		check_mouse()
		gui_funcs()
		draw()
		draw_time = reaper.time_precise()
	end
	
	if gfx.getchar() ~= -1 and gfx.getchar(27) ~= 1 and exiter == false then reaper.defer(main) end
	
	-- MOVE HOTKEYS 
	--UP
		if gfx.getchar(30064) > 0 and reaper.time_precise() > UpDown_time+UpDown_delay
	then
			if not gui[1].obj[1].sel
		then local seller = {}
				for a = 2, #gui[1].obj
			do 
					if gui[1].obj[a].sel
				then seller[a-1] = true
					local buffer = gui[1].obj[a] gui[1].obj[a] = gui[1].obj[a-1] gui[1].obj[a-1] = buffer
					buffer = hotkey[a] hotkey[a] = hotkey[a-1] hotkey[a-1] = buffer
				end
			end
		update_hotkey() for a = 1, #gui[1].obj do if seller[a] then gui[1].obj[a].sel = true end end 
		UpDown_time = reaper.time_precise()
		end
	end
	--DOWN
		if gfx.getchar(1685026670) > 0 and reaper.time_precise() > UpDown_time+UpDown_delay
	then 
			if not gui[1].obj[#gui[1].obj].sel
		then local seller = {}
				for a = #gui[1].obj-1, 1, -1
			do 
					if gui[1].obj[a].sel
				then seller[a+1] = true
					local buffer = gui[1].obj[a] gui[1].obj[a] = gui[1].obj[a+1] gui[1].obj[a+1] = buffer
					buffer = hotkey[a] hotkey[a] = hotkey[a+1] hotkey[a+1] = buffer
				end
			end
		update_hotkey() for a = 1, #gui[1].obj do if seller[a] then gui[1].obj[a].sel = true end end 
		UpDown_time = reaper.time_precise()
		end
	end
	--RESET UP/DOWN
	if gfx.getchar(30064) == 0 and gfx.getchar(1685026670) == 0 then UpDown_time = 0 end 
	
	-- DELETE HOTKEY
		if gfx.getchar(6579564) > 0 
	then local obj_num = #gui[1].obj local counter = 1
		if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "NOTOPMOST" ) end
		local checker = -1 for a = 1, obj_num do if gui[1].obj[a].sel then checker = reaper.MB( "Are you sure you would like to delete the selected hotkeys? Action cannot be undone.", "[user confirm]", 1 ) break end end 
		if Pin_Window == true then reaper.JS_Window_SetZOrder( window, "TOPMOST" ) end
			if checker == 1
		then
				for a = 1, obj_num
			do
					if gui[1].obj[counter].sel
				then 
						for b = counter, obj_num
					do 
						gui[1].obj[b] = gui[1].obj[b+1]
						hotkey[b] = hotkey[b+1]
					end
					obj_num = obj_num - 1 
				else
					counter = counter + 1 
				end
			end
			update_hotkey()
		end
	end
	-- GET CURRENT SECTION
	section = "Global"
	if reaper.MIDIEditor_GetActive() then section = "MIDI" end
	if reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), 1000) == reaper.JS_Window_GetFocus() then section = "Arrange" end 
	if reaper.GetCursorContext() > -1 and reaper.GetCursorContext() < 3 then section = "Arrange" end
	-- ACTIVATE HOTKEY
		if not press_key
	then
		local action_window = reaper.JS_Window_Find( "Actions", 1 )
		if action_window then if reaper.JS_Window_IsChild( action_window, reaper.JS_Window_GetFocus() ) or reaper.JS_Window_GetFocus() == action_window then goto skipper end end
			for a = 1, #hotkey
		do	-- Reliable way to get modifiers (using same structure as gfx.mouse_cap): msg( reaper.JS_Mouse_GetState( 8 ))
				if reaper.JS_VKeys_GetState( 0 ):byte(hotkey[a].key) ~= 0  
			then press_key = hotkey[a].key 
					if hotkey[a].section == section or hotkey[a].section == "Global"
				then local go = true 
					if hotkey[a].mod ~= "nil" then if reaper.JS_VKeys_GetState( 0 ):byte(hotkey[a].mod) == 0 then go = false end end
					if hotkey[a].mod2 ~= "nil" and go == true then if reaper.JS_VKeys_GetState( 0 ):byte(hotkey[a].mod2) == 0 then go = false end end
						if go == true 
					then
						if hotkey[a].action == "exit" then exiter = true break end
							if string.len(hotkey[a].action) < 6 
						then
							pcall( function () reaper.Main_OnCommand( tonumber(hotkey[a].action), 0 ) end ) 
						else
							pcall( function () reaper.Main_OnCommand( reaper.NamedCommandLookup( hotkey[a].action ), 0 ) end ) 
						end
					end
				end
			end
		end
		::skipper::
	else
		if reaper.JS_VKeys_GetState(0):byte(press_key) == 0 then press_key = nil end 
	end
	
end
--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~

function delete_ext_states()
	reaper.DeleteExtState( "Dfk Hotkey", "W_D", 1 ) 
	reaper.DeleteExtState( "Dfk Hotkey", "W_W", 1 ) 
	reaper.DeleteExtState( "Dfk Hotkey", "W_H", 1 ) 
	reaper.DeleteExtState( "Dfk Hotkey", "W_X", 1 ) 
	reaper.DeleteExtState( "Dfk Hotkey", "W_Y", 1 )	
	reaper.DeleteExtState( "Dfk Hotkey", "V_V", 1 )
end

function exit()
    local wd, wx, wy, ww, wh = gfx.dock( -1, 0, 0, 0, 0 )
    reaper.SetExtState( "Dfk Hotkey", "W_D",  wd, true )
	reaper.SetExtState( "Dfk Hotkey", "W_X",  wx, true )
	reaper.SetExtState( "Dfk Hotkey", "W_Y",  wy, true )
	reaper.SetExtState( "Dfk Hotkey", "W_W",  ww, true )
	reaper.SetExtState( "Dfk Hotkey", "W_H",  wh, true )
	reaper.SetExtState( "Dfk Hotkey", "V_V",  V_V, true )
	file = io.open(string.sub(filename, 1, endofit).."Dfk Hotkey Script.txt", "w") file:close() file = io.open(string.sub(filename, 1, endofit).."Dfk Hotkey Script.txt", "a")
		for a = 1, #hotkey
	do  
		file:write(hotkey[a].name..", "..hotkey[a].key..", "..hotkey[a].mod..", "..hotkey[a].mod2..", "..hotkey[a].action..", "..hotkey[a].descript..", "..hotkey[a].section)
		file:write("\n")
	end
	file:close()
end

--delete_ext_states()

reaper.atexit(exit)
init()

