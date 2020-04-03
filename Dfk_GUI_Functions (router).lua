--[[ LOAD FUNCTIONS: dofile("C:/REAPER/Scripts/Dfk_GUI_Functions.lua")

This library provides:

		*view_zoom()
		*check_mouse()
		*gui_funcs()
		*draw()
		
...and should be called in that order.

]]

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

gui = {obj = {}}

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
		
		if once == false and set_caption_title == true then reaper.JS_Window_SetTitle( window, script_name ) end                                                                -- if no hover, set title to script_name
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
							msg("object"..sel_o..": click") obj[o].func[m](obj[o],o) dClick_watch = 0 if not obj[o].hold[m] then click = "done" end 
						end
					end
						if obj[o].func[0] and click ~= "done" 
					then
							if click == "dclick"
						then
							sel_m = 0 msg("object"..sel_o..": Dclick") obj[o].func[0](obj[o],o) click = "done" dClick_watch = -1
						elseif click == ""
						then
							msg("object timer armed") dClick_watch = reaper.time_precise()+dClick_time  click = "delay"  
						end
							if obj[o].hold[m] and reaper.time_precise() > dClick_watch and click ~= "done"
						then
							msg("object"..sel_o..": hold") obj[o].func[m](obj[o],o) click = "hold" dClick_watch = -1
						end
					end
						if obj[o].hold[m] and m ~= 1 and click ~= "done"
					then
						msg("object"..sel_o..": hold") obj[o].func[m](obj[o],o) click = "hold"
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
							msg("object button"..sel_b..": click") obj[o].button[b].func[m](obj[o].button[b],o,b) dClick_watch = 0 if not obj[o].button[b].hold[m] then click = "done" end 
						end
					end
						if obj[o].button[b].func[0] and click ~= "done" 
					then
							if click == "dclick"
						then
							sel_m = 0 msg("object button"..sel_b..": Dclick") obj[o].button[b].func[0](obj[o].button[b],o,b) click = "done" dClick_watch = -1
						elseif click == ""
						then
							msg("object button timer armed") dClick_watch = reaper.time_precise()+dClick_time  click = "delay"  
						end
							if obj[o].button[b].hold[m] and reaper.time_precise() > dClick_watch and click ~= "done"
						then
							msg("object button"..sel_b..": hold") obj[o].button[b].func[m](obj[o].button[b],o,b) click = "hold" dClick_watch = -1
						end
					end
						if obj[o].button[b].hold[m] and m ~= 1 and click ~= "done"
					then
						msg("object button"..sel_b..": hold") obj[o].button[b].func[m](obj[o].button[b],o,b) click = "hold"
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
						if dClick_watch ~= -1 then msg("object"..sel_o.." (delay click)") 
						obj[sel_o].func[sel_m](obj[sel_o],sel_o, nil, 1) end obj[sel_o].func[sel_m](obj[sel_o],sel_o, 1)
					else             -- if object button was clicked
						if dClick_watch ~= -1 then msg("button"..sel_b.." (delay click)") obj[sel_o].button[sel_b].func[sel_m](obj[sel_o].button[sel_b],sel_o, sel_b, nil, 1) end 
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