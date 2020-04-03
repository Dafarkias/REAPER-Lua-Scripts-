--[[
 * ReaScript Name: Dfk Mini Track Mixer
 * About: Small GUI workflow for mixing track volume and pan.
 * Author: Dfk
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: js_ReaScriptAPI v0.993 (version used in development)
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.00 (2020-04-03)
  + script release
--]]

local script_name = "Dfk's Mini Track Mixer" local VERSION = "1.0"


--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA
--
local Pin_Script_Window                   = false    -- true/false 
local Font                                = "Arial"  -- "Arial", "Times New Roman, "Helvetica", etc.
local Font_Size                           = 20       -- 10-30: default is 20
local Visualizer_Amplification            = 1.5      -- 1-3(recommended): multiplied ratio, 1=no amplification of signal
local Invert_Mouse_Scroll                 = false    -- true/false
local Mouse_Wheel_Sensitivity             = 10       -- 1+
--
--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA--USER--AREA

local Dev = true function msg(param) if Dev == true then reaper.ShowConsoleMsg(tostring(param).."\n") end end function up() reaper.UpdateTimeline() reaper.UpdateArrange() end

--window vars
local _,_,display_width,display_height = reaper.my_getViewport(0, 0, 0, 0, 0, 0, 0, 0, true )
local window_script = 0 --set in function init()

-- project vars
local project_name = script_name.." v"..VERSION
local set_title = 0

-- script vars
local initialW, initialH = 500, 500 local initialX, initialY =  (display_width/2)-(initialW/2), (display_height/2)-(initialH/2)
if Font_Size < 10 then Font_Size = 10 end if Font_Size > 30 then Font_Size = 30 end gfx.setfont( 1, Font, Font_Size )
local pan_display_height, pan_display_heightMin = Font_Size*2.5, 25 
local vertical_scroll = 0
local output_visual = false 
local change_pan = true


-- panel vars
local panel_width = 200 local panel_widthMin = 200
local db, dw, dh = 0, 0, 0 -- set in draw()

-- track area vars
local track_areaMin = 150

-- misc vars
local track_lastTouched = reaper.GetLastTouchedTrack()
local click = "" 
local hover = ""
local initial_load = 10
local ball_alphas = .4

-- tables
local slider = 0
local doubleClick = {} doubleClick.time = 0 doubleClick.num = 0 doubleClick.max = .2
local tracks = {}
local tracksPan = {}
local tracksVol = {}
local tracksSel = {} local tracksNSL = {}
local tracksMut = {}
local tracksSol = {}
local tracksFX = {}
local preset1 = {} preset1.track = {}
local preset2 = {} preset2.track = {}
local preset3 = {} preset3.track = {}

function dialog(title, def_value, descript)
	local change_it = tostring(def_value)
	local placement = string.find(change_it, ".", 1, true) if placement then change_it = string.sub(change_it, 1, placement+2) end 
  local ret, retvals = reaper.GetUserInputs(title, 1, descript, change_it)
  if ret then
    return retvals
  end
  return ret
end

function update_and_check_tracks() local skip_it = 0 local tempTra, tempSel, tempPan, tempVol, tempMut, tempSol, tempFX = {}, {}, {}, {}, {}, {}, {}
	if pan_display_height > gfx.h/2 then pan_display_height = gfx.h/2 end 
		for a = 1, reaper.CountTracks( 0 )
	do local track = reaper.GetTrack( 0, a-1 ) local fx = reaper.TrackFX_GetChainVisible( track ) if fx ~= -1 then fx = 0 end 
		if tracks[a]    ~= track                                              then skip_it = false end tempTra[a] = track
		if tracksSel[a] ~= tracksNSL[a]                                       then skip_it = false end tempSel[a] = tracksNSL[a]
		if tracksPan[a] ~= reaper.GetMediaTrackInfo_Value( track, "D_PAN" )+1 then skip_it = false end tempPan[a] = reaper.GetMediaTrackInfo_Value( track, "D_PAN" )+1
		if tracksVol[a] ~= reaper.GetMediaTrackInfo_Value( track, "D_VOL" )   then skip_it = false end tempVol[a] = reaper.GetMediaTrackInfo_Value( track, "D_VOL" )
		if tracksMut[a] ~= reaper.GetMediaTrackInfo_Value( track, "B_MUTE" )  then skip_it = false end tempMut[a] = reaper.GetMediaTrackInfo_Value( track, "B_MUTE" )
		if tracksSol[a] ~= reaper.GetMediaTrackInfo_Value( track, "I_SOLO" )  then skip_it = false end tempSol[a] = reaper.GetMediaTrackInfo_Value( track, "I_SOLO" )
		if tracksFX[a]  ~= fx                                                 then skip_it = false end tempFX[a]  = fx
	end
	tracks    = tempTra
	tracksSel = tempSel
	tracksNSL = tempSel
	if string.find( click, "Slider" ) == nil then tracksPan = tempPan end
	if string.find( click, "Slider" ) == nil then tracksVol = tempVol end
	tracksMut = tempMut
	tracksSol = tempSol
	tracksFX  = tempFX
	if skip_it == false then return skip_it end
end

function check_windowSize()
	-- check vertical
		if initialH > gfx.h 
	then
		local wd, wx, wy, ww, wh = gfx.dock( -1, 0, 0, 0, 0 ) 
		gfx.quit() gfx.init(project_name, ww, initialH, wd, wx, wy )
		window_script = reaper.JS_Window_Find( project_name, 1 ) if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
	end 
	-- check horizontal
		if initialW > gfx.w
	then
		local wd, wx, wy, ww, wh = gfx.dock( -1, 0, 0, 0, 0 )
		gfx.quit() gfx.init(project_name, initialW, wh, wd, wx, wy )
		window_script = reaper.JS_Window_Find( project_name, 1 ) if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
	end
end

function draw( go_to_main ) local skipit = true 

	if reaper.JS_Window_FromPoint( reaper.GetMousePosition() ) == window_script then skipit = false end 
	if reaper.GetPlayState() == 1                                               then skipit = false end
	if update_and_check_tracks() == false                                       then skipit = false end 
	if click ~= ""                                                              then skipit = false end 
	if reaper.JS_Window_IsVisible( window_script ) == false                     then skipit = true  end
	if skipit == true then if initial_load < 1 then --[[msg("skipping" )]] goto skip_it else initial_load = initial_load-1 --[[msg("initial")]] end end
		
	-- draw layer 1
		for a = 1, #tracks
	do local y_position = pan_display_height+((a-1)*Font_Size)
		local track = tracks[a] local pan = reaper.GetMediaTrackInfo_Value( track, "D_PAN" )+1  
		local r4, g4, b4 = reaper.ColorFromNative( reaper.GetTrackColor( track ) ) gfx.set(r4/255,g4/255,b4/255,ball_alphas) 
		-- track pan lines
		if change_pan == true then gfx.line(panel_width+(pan_display_height/2)+((gfx.w-panel_width-pan_display_height)*(pan/2)),pan_display_height,panel_width+(pan_display_height/2)+((gfx.w-panel_width-pan_display_height)*(pan/2)),vertical_scroll+(Font_Size/2)+y_position, 1 ) else gfx.rect( panel_width,math.floor(Font_Size/2)+y_position,gfx.w-panel_width,2,0 ) end 
		-- track display area
		if tracksSel[a] == true then gfx.a = 1 end
		gfx.rect( 0,vertical_scroll+y_position,panel_width,Font_Size,1 ) gfx.set(1,1,1,0.2) if tracksSel[a] == true then gfx.a = 1 end
		gfx.rect( 0,vertical_scroll+y_position,panel_width,Font_Size,0 ) gfx.a = .2
		gfx.rect( panel_width,vertical_scroll+y_position,gfx.w-panel_width,Font_Size,0 ) 
			-- track db text
			gfx.a = .8
			local voller = 20*math.log(reaper.GetMediaTrackInfo_Value( track, "D_VOL" ), 10)
				if tostring(voller) ~= "-1.#INF"
			then
				local change_it,after_it = -1, -1
				local placement = string.find(voller, ".", 1, true) if placement then change_it = string.sub(voller, 1, placement-1) after_it = string.sub(voller, placement, placement+1)  end 
				if change_it ~= -1 then gfx.x, gfx.y = 3+gfx.measurestr( "-00" )-gfx.measurestr( change_it ), vertical_scroll+y_position+1 gfx.drawstr( change_it ) end
				if after_it ~= -1 then gfx.x, gfx.y = 3+gfx.measurestr( "-00" ), vertical_scroll+y_position+1 gfx.drawstr( after_it ) end
			else 
				gfx.x, gfx.y = 3+gfx.measurestr( "-00" )-(gfx.measurestr( "OFF" )/2), vertical_scroll+y_position+1 gfx.drawstr( "OFF" )
			end 
			-- track buttons
			local x_position = 3+db
				-- mute
				gfx.set(.4,.4,.4, 1) if string.find(hover,"M")then if a==tonumber(string.sub(hover,2))then gfx.set(.3,.3,.3, 1)end end gfx.rect( 10+x_position,vertical_scroll+y_position+1,Font_Size,Font_Size-2,1 )
				if tracksMut[a] == 1 then gfx.set(1,0,0, .4) gfx.rect( 10+x_position,vertical_scroll+y_position+1,Font_Size,Font_Size-2,1 )end 
				gfx.set(.7,.7,.7,.7) gfx.rect( 10+x_position,vertical_scroll+y_position+1,Font_Size,Font_Size-2,0 )
				local mw, mh = gfx.measurestr( "M" ) gfx.set(1,0,0,.8) gfx.x, gfx.y = 10+x_position+(Font_Size/2)-(mw/2), vertical_scroll+y_position+(Font_Size/2)-(mh/2) gfx.drawstr( "M" )
				-- solo
				gfx.set(.4,.4,.4, 1) if string.find(hover,"S")then if a==tonumber(string.sub(hover,2))then gfx.set(.3,.3,.3, 1)end end gfx.rect( 10+x_position+Font_Size,vertical_scroll+y_position+1,Font_Size,Font_Size-2,1 )
				if tracksSol[a]>0 then gfx.set(1,1,0, .4) gfx.rect( 10+x_position+Font_Size,vertical_scroll+y_position+1,Font_Size,Font_Size-2,1 )end
				gfx.set(.7,.7,.7,.7) gfx.rect( 10+x_position+Font_Size,vertical_scroll+y_position+1,Font_Size,Font_Size-2,0 )
				local sw, sh = gfx.measurestr( "S" ) gfx.set(1,1,0,.8) gfx.x, gfx.y = 10+x_position+Font_Size+(Font_Size/2)-(sw/2), vertical_scroll+y_position+(Font_Size/2)-(sh/2) gfx.drawstr( "S" )
				-- FX
				gfx.set(.4,.4,.4, 1) if string.find(hover,"FX")then if a==tonumber(string.sub(hover,3))then gfx.set(.3,.3,.3, 1)end end gfx.rect( 10+x_position+(Font_Size*2),vertical_scroll+y_position+1,Font_Size,Font_Size-2,1 )
				if tracksFX[a]>-1 then gfx.set(0,1,0, .4) gfx.rect( 10+x_position+(Font_Size*2),vertical_scroll+y_position+1,Font_Size,Font_Size-2,1 )end
				gfx.set(.7,.7,.7,.7) gfx.rect( 10+x_position+(Font_Size*2),vertical_scroll+y_position+1,Font_Size,Font_Size-2,0 )
				local fxw, fxh = gfx.measurestr( "FX" ) gfx.set(0,0,0,.8) gfx.x, gfx.y = 10+x_position+(Font_Size*2)+(Font_Size/2)-(fxw/2), vertical_scroll+y_position+(Font_Size/2)-(fxh/2) gfx.drawstr( "FX" )
			
			-- track names
			x_position = 10+x_position+(Font_Size*3)+3
			local name_retval, name_buf = reaper.GetTrackName( track )
				if name_buf
			then
				local nw, nh = gfx.measurestr( name_buf ) while x_position+gfx.measurestr( name_buf ) > panel_width do name_buf = string.sub(name_buf, 1, string.len(name_buf)-1) end 
				gfx.set(1,1,1, 1) gfx.x, gfx.y = x_position, vertical_scroll+y_position+(Font_Size/2)-(nh/2) gfx.drawstr( name_buf )
			end
	end
	
	-- draw layer 2
		for a = 1, #tracks
	do y_position = pan_display_height+((a-1)*Font_Size)
		track = tracks[a] pan = reaper.GetMediaTrackInfo_Value( track, "D_PAN" )+1 local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL" ) 
		local setter = 0 local fact = 2 if change_pan == true then setter = pan else setter = vol fact = 3 end 
		
		-- sliders
		gfx.set(1,0,0,1) 
			for b = 0, pan_display_height-1
		do if gfx.r == 1 then gfx.r = .8 else gfx.r = 1 end
			gfx.line(b+panel_width+((gfx.w-panel_width-pan_display_height)*(setter/fact)),vertical_scroll+2+pan_display_height+((a-1)*Font_Size),b+panel_width+((gfx.w-panel_width-pan_display_height)*(setter/fact)),vertical_scroll+pan_display_height+(a*Font_Size)-2,1 )
		end
		gfx.set(.5,0,0,1) gfx.rect( panel_width+((gfx.w-panel_width-pan_display_height)*(setter/fact)),vertical_scroll+1+pan_display_height+((a-1)*Font_Size),pan_display_height,Font_Size-1,0 )
	end

	-- draw pan display background
	gfx.set(0,0,0,1)   gfx.rect( 0,0,gfx.w,pan_display_height,1 )
	gfx.set(1,1,1,0.2) gfx.rect( panel_width,0,gfx.w-panel_width,pan_display_height,1 )
	gfx.set(1,1,1,0.4) gfx.rect( panel_width,1,gfx.w-panel_width,pan_display_height-1,0 )
	-- draw toggle switch
	db, dw, dh = gfx.measurestr( "-00.0" ), gfx.measurestr( "PAN" ) 
	gfx.a = .1 if hover == "T" then gfx.a = .15  end gfx.rect( panel_width-Font_Size-dw,1,Font_Size+dw,pan_display_height-1,1 ) 
	gfx.a = .2 gfx.rect( panel_width-Font_Size-dw-1,1,Font_Size+dw+1,pan_display_height-1,0 )
		-- toggle switch position
			if change_pan == true
		then
			gfx.set(1,1,1,0.4) gfx.rect( panel_width-(Font_Size/2)-2,(Font_Size/2),4,(pan_display_height/2)-(Font_Size/2),1 )
			gfx.set(1,0,0,1) gfx.circle(panel_width-(Font_Size/2),(Font_Size/2),(Font_Size/2)*.7,1,1 )
			gfx.set(1,1,1,0.7) gfx.x, gfx.y = panel_width-Font_Size-dw, (Font_Size/2)-(dh/2) gfx.drawstr( "PAN" )
			gfx.a = .2 gfx.x, gfx.y = panel_width-Font_Size-dw, pan_display_height-(Font_Size*2)+dh gfx.drawstr( "VOL" )
		else
			gfx.set(1,1,1,0.4) gfx.rect( panel_width-(Font_Size/2)-2,(pan_display_height/2),4,(pan_display_height/2)-(Font_Size/2),1 )
			gfx.set(1,0,0,1) gfx.circle(panel_width-(Font_Size/2),pan_display_height-(Font_Size/2),(Font_Size/2)*.7,1,1 )
			gfx.set(1,1,1,0.2) gfx.x, gfx.y = panel_width-Font_Size-dw, (Font_Size/2)-(dh/2) gfx.drawstr( "PAN" )
			gfx.a = .7 gfx.x, gfx.y = panel_width-Font_Size-dw, pan_display_height-(Font_Size*2)+dh gfx.drawstr( "VOL" )
		end
	-- draw visualizer button
	if output_visual == true then gfx.set(0,1,0,0.2) gfx.rect( 1,pan_display_height/2,panel_width-(Font_Size+dw+2),pan_display_height/2, 1 ) end
	gfx.a = .1 if hover == "V" then gfx.a = .25 end gfx.rect( 1,pan_display_height/2,panel_width-(Font_Size+dw+2),pan_display_height/2, 1 ) local vw, vh = gfx.measurestr( "Visualizer" ) 
	gfx.set(1,1,1,0.6) gfx.x, gfx.y = ((panel_width-(Font_Size+dw))/2)-(vw/2), (pan_display_height*.75)-(vh/2) gfx.drawstr( "Visualizer" )
	-- draw presets
	gfx.a = .1 if hover == "P1" then gfx.a = .25 end gfx.rect( 1,1,(panel_width-Font_Size-dw)/3,pan_display_height/2, 1 ) 
	gfx.a = .1 if hover == "P2" then gfx.a = .25 end gfx.rect( (panel_width-Font_Size-dw)/3,1,(panel_width-Font_Size-dw)/3,pan_display_height/2, 1 ) 
	gfx.a = .1 if hover == "P3" then gfx.a = .25 end gfx.rect( (panel_width-Font_Size-dw)/1.5,1,((panel_width-Font_Size-dw)/3)-1,pan_display_height/2, 1 )
		-- face
		gfx.a = .1 gfx.rect( 1,1,((panel_width-Font_Size-dw)/3)-1,pan_display_height/2, 0 ) 
		gfx.rect( ((panel_width-Font_Size-dw)/3)*1,1,(panel_width-Font_Size-dw)/3,pan_display_height/2, 0 ) 
		gfx.rect( ((panel_width-Font_Size-dw)/3)*2,1,((panel_width-Font_Size-dw)/3)-1,pan_display_height/2, 0 ) 
		gfx.set(1,1,1,0.6) local pw, ph = gfx.measurestr( "P1" ) gfx.y = 1+(pan_display_height/4)-(ph/2)
		gfx.x = 1+((panel_width-Font_Size-dw)/6)-(pw/2) gfx.drawstr( "P1" ) pw, ph = gfx.measurestr( "P2" )
		gfx.x = ((panel_width-Font_Size-dw)/2)-(pw/2) gfx.drawstr( "P2" ) pw, ph = gfx.measurestr( "P3" )
		gfx.x = ((panel_width-Font_Size-dw)/1.2)-(pw/2) gfx.drawstr( "P3" )

	local soloed = false for b = 1, #tracks do if tracksSol[b] >0 then soloed = true end end 
	-- draw layer 3
		for a = 1, #tracks
	do local y_position = pan_display_height+((a-1)*Font_Size)
		local r5, g5, b5 = reaper.ColorFromNative( reaper.GetTrackColor( tracks[a] ) ) gfx.set(r5/255,g5/255,b5/255,ball_alphas) 
		-- pan display area 
		local peaker = 0
			if soloed == true and tracksSol[a] > 0 or soloed == false
		then 
				if output_visual == true and reaper.GetPlayState() == 1 
			then 
					if reaper.Track_GetPeakInfo( tracks[a], 0 )>0 
				then 
					peaker = reaper.Track_GetPeakInfo( tracks[a], 0 ) 
				else 
					peaker = reaper.Track_GetPeakInfo( tracks[a], 1 ) 
				end 
				peaker = peaker*Visualizer_Amplification peaker = peaker+.1 if peaker > .8 then peaker = .8 end 
			else peaker = .8 end
		end
		gfx.circle( panel_width+(pan_display_height/2)+((gfx.w-panel_width-pan_display_height)*((reaper.GetMediaTrackInfo_Value( tracks[a], "D_PAN" )+1)/2)),(pan_display_height/2),(pan_display_height/2)*peaker, 1, 1 )
	end

	-- scroll bar
	gfx.set(0,0,0,.4) for a = 0, math.floor(Font_Size/2) do gfx.roundrect(a+1,a+1+pan_display_height,(Font_Size/2)-(a*2),gfx.h-pan_display_height-(a+1*2),(Font_Size/2),1 ) end
	gfx.set(1,1,1,.8) gfx.circle(1+(Font_Size/4),((((gfx.h-(Font_Size/4))-(pan_display_height+(Font_Size/4)))/math.abs(gfx.h-((#tracks+5)*Font_Size)))*math.abs(vertical_scroll))+pan_display_height+(Font_Size/4)  ,(Font_Size/4),1,1 )

	-- mouse cursor
	--[[
	local arrow = false
	if hover == "horizontal" then gfx.setcursor( 2, "tcppane_resize" ) arrow = true end 
	if hover == "vertical"   then gfx.setcursor( 3, "toolbar_resize" ) arrow = true end
	if arrow == false then gfx.setcursor( 1, "arrow" ) end]]
	
	if go_to_main then main() end 
	::skip_it::
	
end 

function check_input() local fact, setter = 2, 0 if change_pan == false then fact = 3 end if click == "" then click = "none" end set_title = script_name.." v"..VERSION hover = ""

	-- mousewheel
		if gfx.mouse_wheel~=0
	then 
			if Invert_Mouse_Scroll==true 
		then 
			vertical_scroll=vertical_scroll+(gfx.mouse_wheel/120)*Mouse_Wheel_Sensitivity 
		else 
			vertical_scroll = vertical_scroll - (gfx.mouse_wheel/120)*Mouse_Wheel_Sensitivity 
		end gfx.mouse_wheel = 0 
		if ((#tracks+5)*Font_Size)+vertical_scroll < gfx.h then vertical_scroll = gfx.h-((#tracks+5)*Font_Size) end if vertical_scroll > 0 then vertical_scroll = 0 end
	end 
	
	-- resize windows with mouse
		if gfx.mouse_x  >= panel_width-2 and gfx.mouse_x <= panel_width+2 and gfx.mouse_y > pan_display_height and gfx.mouse_y < gfx.h or click == "horizontal"               
	then 
		hover = "horizontal" set_title = "adjust window horizontally..."
			if gfx.mouse_cap == 1 and click == "none" or click == "horizontal"  
		then click = "horizontal"
			panel_width = gfx.mouse_x if panel_width < panel_widthMin then panel_width = panel_widthMin end if panel_width > gfx.w-pan_display_height then panel_width = gfx.w-pan_display_height end 
		end
	end 
	if gfx.mouse_x  > panel_width and gfx.mouse_x < gfx.w and gfx.mouse_y >= pan_display_height-2 and gfx.mouse_y <= pan_display_height+2 or click == "vertical"
	then 
		hover = "vertical" set_title = "adjust window vertically..."
			if gfx.mouse_cap == 1 and click == "none" or click == "vertical"
		then click = "vertical"
			pan_display_height = gfx.mouse_y if pan_display_height > gfx.h/2 then pan_display_height = gfx.h/2 end if pan_display_height < pan_display_heightMin then pan_display_height = pan_display_heightMin end 
		end
	end

	-- unique hover interactions
		for z = 1, 1
	do if click~="none"then break end local p1,p2,p3,p4 = "[empty]","[empty]","[empty]",": left-click to load, right-click to save..."if#preset1.track>0then p1="[full]" end if#preset2.track>0then p2="[full]" end if #preset3.track>0 then p3 = "[full]" end 
		if gfx.mouse_x > 1 and gfx.mouse_x < (panel_width-Font_Size-dw)/3 and gfx.mouse_y > 1 and gfx.mouse_y < pan_display_height/2 then set_title = "Preset 1 "..p1..p4                                                                 hover = "P1"    break end
		if gfx.mouse_x > (panel_width-Font_Size-dw)/3 and gfx.mouse_x < (panel_width-Font_Size-dw)/1.5 and gfx.mouse_y > 1 and gfx.mouse_y < pan_display_height/2 then set_title = "Preset 2 "..p2..p4                                    hover = "P2"    break end  
		if gfx.mouse_x > (panel_width-Font_Size-dw)/1.5 and gfx.mouse_x < (panel_width-Font_Size-dw) and gfx.mouse_y > 1 and gfx.mouse_y < pan_display_height/2 then set_title = "Preset 3 "..p3..p4                                      hover = "P3"    break end 
		if gfx.mouse_x > panel_width-Font_Size-dw and gfx.mouse_x < panel_width and gfx.mouse_y > 1 and gfx.mouse_y < pan_display_height then set_title = "Toggle: choose which parameter sliders will affect..."                         hover = "T"     break end
		if gfx.mouse_x > 1 and gfx.mouse_x < panel_width-(Font_Size+dw) and gfx.mouse_y > pan_display_height/2 and gfx.mouse_y < pan_display_height then set_title = "Toggle: visualize track output (only active during playback)"       hover = "V"     break end
		if gfx.mouse_x > 0 and gfx.mouse_x < Font_Size/2 and gfx.mouse_y > pan_display_height and gfx.h then set_title = "vertical scroll bar..."                                                                                         hover = "SB"    break end
		-- automated "track" hover interactions 
			for a = 1, #tracks
		do
			local y_position = pan_display_height+((a-1)*Font_Size)
			if gfx.mouse_x > 13+db and gfx.mouse_x < 13+db+Font_Size and gfx.mouse_y > vertical_scroll+y_position+1 and gfx.mouse_y < vertical_scroll+y_position+Font_Size then set_title = "right-click to mute only..."                       hover = "M"..a  break end 
			if gfx.mouse_x > 13+db+Font_Size and gfx.mouse_x < 13+db+(Font_Size*2) and gfx.mouse_y > vertical_scroll+y_position+1 and gfx.mouse_y < vertical_scroll+y_position+Font_Size then set_title = "right-click to solo as only..."      hover = "S"..a  break end 
			if gfx.mouse_x > 13+db+(Font_Size*2) and gfx.mouse_x < 13+db+(Font_Size*3) and gfx.mouse_y > vertical_scroll+y_position+1 and gfx.mouse_y < vertical_scroll+y_position+Font_Size then set_title = "right-click to open as only..."  hover = "FX"..a break end 
			if gfx.mouse_x > 0 and gfx.mouse_x < panel_width and gfx.mouse_y > vertical_scroll+y_position+1 and gfx.mouse_y < vertical_scroll+y_position+Font_Size then set_title = "left-click to un/select track, right-click to only..."     hover = "tr"..a break end 
			if hover ~= "" then break end 
		end 
	end

	-- scroll bar
		if gfx.h-((#tracks+5)*Font_Size) < 0 
	then
			if gfx.mouse_cap == 1 and click == "none" and hover == "SB" or click == "scroll_bar"
		then click = "scroll_bar"
			local mouse_temp = gfx.mouse_y if mouse_temp < pan_display_height+(Font_Size/4) then mouse_temp = pan_display_height+(Font_Size/4) elseif mouse_temp > gfx.h-(Font_Size/4) then mouse_temp = gfx.h-(Font_Size/4) end
			vertical_scroll = 0-(math.abs((gfx.h-((#tracks+5)*Font_Size)))/((gfx.h-pan_display_height-(Font_Size/2))/(mouse_temp-pan_display_height-(Font_Size/4))))
		end
	end

	-- unique left-click interactions
		if gfx.mouse_cap == 1 and click == "none"
	then
		-- preset actions
			if hover == "P1" 
		then 
				for a = 1, #preset1.track
			do
				reaper.SetMediaTrackInfo_Value( tracks[a], "D_VOL",  preset1.vol[a] )
				reaper.SetMediaTrackInfo_Value( tracks[a], "D_PAN",  preset1.pan[a]-1 )
				reaper.SetMediaTrackInfo_Value( tracks[a], "B_MUTE", preset1.mute[a] )
				reaper.SetMediaTrackInfo_Value( tracks[a], "I_SOLO", preset1.solo[a] )
					if a == #preset1.track 
				then 
					if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "NOTOPMOST" ) end
					reaper.MB( "Preset 1 successfully loaded.", "[friendly message]", 0 ) 
					if Pin_Script_Window == true then  reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
				end  
			end     
		end
		-- preset actions
			if hover == "P2"
		then
				for a = 1, #preset2.track
			do
				reaper.SetMediaTrackInfo_Value( tracks[a], "D_VOL",  preset2.vol[a] )
				reaper.SetMediaTrackInfo_Value( tracks[a], "D_PAN",  preset2.pan[a]-1 )
				reaper.SetMediaTrackInfo_Value( tracks[a], "B_MUTE", preset2.mute[a] )
				reaper.SetMediaTrackInfo_Value( tracks[a], "I_SOLO", preset2.solo[a] )
					if a == #preset2.track 
				then 
					if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "NOTOPMOST" ) end
					reaper.MB( "Preset 2 successfully loaded.", "[friendly message]", 0 ) 
					if Pin_Script_Window == true then  reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
				end 
			end     
		end
		-- preset actions
			if hover == "P3"
		then
				for a = 1, #preset3.track
			do
				reaper.SetMediaTrackInfo_Value( tracks[a], "D_VOL",  preset3.vol[a] )
				reaper.SetMediaTrackInfo_Value( tracks[a], "D_PAN",  preset3.pan[a]-1 )
				reaper.SetMediaTrackInfo_Value( tracks[a], "B_MUTE", preset3.mute[a] )
				reaper.SetMediaTrackInfo_Value( tracks[a], "I_SOLO", preset3.solo[a] )
					if a == #preset3.track 
				then 
					if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "NOTOPMOST" ) end
					reaper.MB( "Preset 3 successfully loaded.", "[friendly message]", 0 ) 
					if Pin_Script_Window == true then  reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
				end 
			end     
		end
		-- get toggle context (action)
			if hover == "T"
		then 
			click = "toggle" if change_pan == true then change_pan = false else change_pan = true end 
		end
		-- toggle visualizer output
			if hover == "V"
		then 
			click = "output_visual" if output_visual == true then output_visual = false else output_visual = true end 
		end
	end
	
	-- unique right-click interactions
		if gfx.mouse_cap == 2 and click == "none"
	then
		-- preset actions
			if hover == "P1"
		then preset1.track = {} preset1.pan = {}preset1.vol = {} preset1.mute = {} preset1.solo = {}
				for a = 1, #tracks
			do
				preset1.track[a] = tracks[a]
				preset1.pan[a]   = tracksPan[a]
				preset1.vol[a]   = tracksVol[a]
				preset1.mute[a]  = tracksMut[a]
				preset1.solo[a]  = tracksSol[a]
			end     
			if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "NOTOPMOST" ) end
			reaper.MB( "Preset 1 successfully saved.\n\nPresets are only saved for duration of project, currently.", "[friendly message]", 0 )
			if Pin_Script_Window == true then  reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
		end
		-- preset actions
			if hover == "P2"
		then preset2.track = {} preset2.pan = {}preset2.vol = {} preset2.mute = {} preset2.solo = {}
				for a = 1, #tracks
			do
				preset2.track[a] = tracks[a]
				preset2.pan[a]   = tracksPan[a]
				preset2.vol[a]   = tracksVol[a]
				preset2.mute[a]  = tracksMut[a]
				preset2.solo[a]  = tracksSol[a]
			end     
			if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "NOTOPMOST" ) end
			reaper.MB( "Preset 2 successfully saved.\n\nPresets are only saved for duration of project, currently.", "[friendly message]", 0 )
			if Pin_Script_Window == true then  reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
		end
		-- preset actions
			if hover == "P3"
		then preset3.track = {} preset3.pan = {}preset3.vol = {} preset3.mute = {} preset3.solo = {}
				for a = 1, #tracks
			do
				preset3.track[a] = tracks[a]
				preset3.pan[a]   = tracksPan[a]
				preset3.vol[a]   = tracksVol[a]
				preset3.mute[a]  = tracksMut[a]
				preset3.solo[a]  = tracksSol[a]
			end     
			if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "NOTOPMOST" ) end
			reaper.MB( "Preset 3 successfully saved.\n\nPresets are only saved for duration of project, currently.", "[friendly message]", 0 )
			if Pin_Script_Window == true then  reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
		end
	end

	-- automated "track" click interactions
		for a = 1, #tracks
	do setter = tracksPan[a] if change_pan == false then setter = tracksVol[a] end local conv = 0
	
		-- track sliders
			if gfx.mouse_x >= panel_width+((gfx.w-panel_width-pan_display_height)*(setter/fact)) and gfx.mouse_x <= pan_display_height+panel_width+((gfx.w-panel_width-pan_display_height)*(setter/fact)) and gfx.mouse_y > vertical_scroll+pan_display_height+((a-1)*Font_Size) and gfx.mouse_y < vertical_scroll+pan_display_height+(a*Font_Size) or string.find( click, "Slider" )
		then 
			if click == "none" then set_title = "double-click to reset, and right-click to enter manual input..." end
				if gfx.mouse_cap == 1 and click == "none" or string.find( click, "Slider" )
			then local a_rep = tonumber( string.sub( click, 7 ) ) if click == "none" then a_rep = a end 
				if click == "none" then doubleClick.time = reaper.time_precise() doubleClick.num = doubleClick.num+1 if change_pan == true then slider = tracksPan[a_rep]-1 else slider = tracksVol[a_rep] end end click = "Slider"..a_rep
					if doubleClick.num > 1
				then
					for b = 1, #tracks do if tracksSel[b] then if change_pan == true then reaper.SetMediaTrackInfo_Value( tracks[b], "D_PAN", 0 ) else reaper.SetMediaTrackInfo_Value( tracks[b], "D_VOL", 1 ) end end end
					if change_pan == true then reaper.SetMediaTrackInfo_Value( tracks[a_rep], "D_PAN", 0 ) else reaper.SetMediaTrackInfo_Value( tracks[a_rep], "D_VOL", 1 ) end
				else
					conv = (fact/(gfx.w-panel_width-pan_display_height))*(gfx.mouse_x-panel_width-(pan_display_height/2))
					if conv < 0 then conv = 0 end if conv > fact then conv = fact end
						for b = 1, #tracks 
					do local prop = 0
							if tracksSel[b] and b ~= a_rep 
						then 
								if change_pan == true 
							then prop = slider-reaper.GetMediaTrackInfo_Value( tracks[a_rep], "D_PAN" ) local tempan = tracksPan[b]-prop-1 if tempan < -1 then tempan = -1 elseif tempan > 1 then tempan = 1 end
								reaper.SetMediaTrackInfo_Value( tracks[b], "D_PAN", tempan )
							else
								prop = slider-reaper.GetMediaTrackInfo_Value( tracks[a_rep], "D_VOL" ) local temvol = tracksVol[b]-prop if temvol < 0 then temvol = 0 elseif temvol > 3 then temvol = 3 end
								reaper.SetMediaTrackInfo_Value( tracks[b], "D_VOL", temvol ) 
							end 
						end 
					end     
					if change_pan == true then reaper.SetMediaTrackInfo_Value( tracks[a_rep], "D_PAN", conv-1 ) else reaper.SetMediaTrackInfo_Value( tracks[a_rep], "D_VOL", conv )  end 
				end
			end
				if gfx.mouse_cap == 2 and click == "none" 
			then click = "slider_manual_input"
					if change_pan == true 
				then
					if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "NOTOPMOST" ) end
					local new_pan = dialog("Set pan for selected tracks...", reaper.GetMediaTrackInfo_Value( tracks[a], "D_PAN" ), "-1 = Left +1 = Right" )
					if Pin_Script_Window == true then  reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
						if new_pan 
					then
							if type(new_pan)
						then new_pan = tonumber(new_pan) if new_pan < -1 then new_pan = -1 end if new_pan > 1 then new_pan = 1 end
							for b = 1, #tracks do if tracksSel[b] then reaper.SetMediaTrackInfo_Value(tracks[b], "D_PAN", new_pan) end end 
							reaper.SetMediaTrackInfo_Value(tracks[a], "D_PAN", new_pan)
						end
					end
				else
					if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "NOTOPMOST" ) end
					local new_vol = dialog("Set volume for selected tracks...", 20*math.log(reaper.GetMediaTrackInfo_Value( tracks[a], "D_VOL" ), 10), "db" )
					if Pin_Script_Window == true then  reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
					if not new_vol then
					elseif new_vol == "-inf" then
						new_vol = 0.0
					elseif not tonumber(new_vol) then
					else
						new_vol = tonumber(new_vol)
						if new_vol > 12 then 
							new_vol = 12
						end
						new_vol = 10^(new_vol / 20)
					end
						if type(new_vol) == 'number' 
					then 
						for b = 1, #tracks do if tracksSel[b] then reaper.SetMediaTrackInfo_Value(tracks[b], "D_VOL", new_vol) end end 
						reaper.SetMediaTrackInfo_Value(tracks[a], "D_VOL", new_vol) 
					end
				end
			end
		end
		-- track mute, solo, and FX
			-- mute
				if string.find( hover, "M" ) and a==tonumber(string.sub(hover,2)) and click == "none" and gfx.mouse_cap == 1
			then click = "mute" 
					if reaper.GetMediaTrackInfo_Value( tracks[a], "B_MUTE" ) == 0 
				then 
					for b = 1, #tracks do if tracksSel[b] then reaper.SetMediaTrackInfo_Value( tracks[b], "B_MUTE", 1 ) reaper.SetMediaTrackInfo_Value( tracks[b], "I_SOLO", 0 ) end end 
					reaper.SetMediaTrackInfo_Value( tracks[a], "B_MUTE", 1 ) reaper.SetMediaTrackInfo_Value( tracks[a], "I_SOLO", 0 ) 
				else 
					for b = 1, #tracks do if tracksSel[b] then reaper.SetMediaTrackInfo_Value( tracks[b], "B_MUTE", 0 ) end end
					reaper.SetMediaTrackInfo_Value( tracks[a], "B_MUTE", 0 ) 
				end  
			end
				-- mute right-click
					if string.find( hover, "M" ) and a==tonumber(string.sub(hover,2)) and click == "none" and gfx.mouse_cap == 2
				then click = "mute_only"
					for b = 1, #tracks do reaper.SetMediaTrackInfo_Value( tracks[b], "B_MUTE", 0 ) end reaper.SetMediaTrackInfo_Value( tracks[a], "B_MUTE", 1 )
				end
			-- solo
				if string.find( hover, "S" ) and a==tonumber(string.sub(hover,2)) and click == "none" and gfx.mouse_cap == 1
			then click = "soloed" 
					if reaper.GetMediaTrackInfo_Value( tracks[a], "I_SOLO" ) > 0 
				then
					for b = 1, #tracks do if tracksSel[b] then reaper.SetMediaTrackInfo_Value( tracks[b], "I_SOLO", 0 ) end end
					reaper.SetMediaTrackInfo_Value( tracks[a], "I_SOLO", 0 ) 
				else 
					for b = 1, #tracks do if tracksSel[b] then reaper.SetMediaTrackInfo_Value( tracks[b], "I_SOLO", 1 ) reaper.SetMediaTrackInfo_Value( tracks[b], "B_MUTE", 0 ) end end
					reaper.SetMediaTrackInfo_Value( tracks[a], "I_SOLO", 1 ) reaper.SetMediaTrackInfo_Value( tracks[a], "B_MUTE", 0 ) 
				end  
			end
				-- solo right-click
					if string.find( hover, "S" ) and a==tonumber(string.sub(hover,2)) and click == "none" and gfx.mouse_cap == 2
				then click = "solo_only"
					for b = 1, #tracks do reaper.SetMediaTrackInfo_Value( tracks[b], "I_SOLO", 0 ) end reaper.SetMediaTrackInfo_Value( tracks[a], "I_SOLO", 1 )
				end
			-- FX
				if string.find( hover, "FX" ) and a==tonumber(string.sub(hover,3)) and click == "none" and gfx.mouse_cap == 1
			then click = "FX" 
				if reaper.TrackFX_GetChainVisible( tracks[a] ) == -1 then reaper.TrackFX_Show( tracks[a], 0, 1 ) else reaper.TrackFX_Show( tracks[a], 0, 0 ) end 
			end
				-- FX right-click
					if string.find( hover, "FX" ) and a==tonumber(string.sub(hover,3)) and click == "none" and gfx.mouse_cap == 2
				then click = "solo_only"
					for b = 1, #tracks do reaper.TrackFX_Show( tracks[b], 0, 0 ) end reaper.TrackFX_Show( tracks[a], 0, 1 )
				end
		-- left-click track selection
			if string.find( hover, "tr" ) and a==tonumber(string.sub(hover,3)) and click == "none" and gfx.mouse_cap == 1
		then click = "lClick_track_selection"
			if tracksSel[a] == false then tracksNSL[a] = true track_lastTouched = tracks[a] else tracksNSL[a] = false end 
		end
		-- right-click track selection
			if string.find( hover, "tr" ) and a==tonumber(string.sub(hover,3)) and click == "none" and gfx.mouse_cap == 2
		then click = "rClick_track_selection"
			for b = 1, #tracks do tracksNSL[b] = false end tracksNSL[a] = true
		end
			-- [shift] track selection
				if string.find( hover, "tr" ) and a==tonumber(string.sub(hover,3)) and click == "none" and gfx.mouse_cap == 9
			then click = "track_shift_selection" local starter, ender, track_id = 0,0,reaper.GetMediaTrackInfo_Value( track_lastTouched, "IP_TRACKNUMBER" ) if a < track_id then starter = a ender = track_id else starter = track_id ender = a end
				for b = 1, #tracks do if b >= starter and b <= ender then tracksNSL[b] = true else tracksNSL[b] = false end end
			end
		if click ~= "none" then break end
	end 

	-- keyboard input
	  -- ctrl+a: un/select all tracks
			if gfx.getchar() == 1
		then local check_sel = false 
			for a = 1, #tracks do if tracksSel[a] == true then check_sel = true end end
				if check_sel == true
			then
				for a = 1, #tracks do tracksNSL[a] = false end
			else
				for a = 1, #tracks do tracksNSL[a] = true end
			end
		end
	
	if doubleClick.time+doubleClick.max < reaper.time_precise() then doubleClick.num = 0 end
	if click == "none" then if gfx.mouse_cap&1 == 1 or gfx.mouse_cap&2 == 2 then click = "empty_click" end end
	if gfx.mouse_cap&1 == 0 and gfx.mouse_cap&2 == 0 then click = "" end 
	if project_name ~= set_title then reaper.JS_Window_SetTitle( window_script, set_title ) project_name = set_title end 
	
end

--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~
function main() if reaper.JS_Window_FromPoint( reaper.GetMousePosition() ) == window_script then reaper.JS_Window_SetFocus( window_script ) end 

	draw()
	check_input()
	
	if gfx.getchar() ~= -1 and gfx.getchar(27) ~= 1 then reaper.defer(main) end

end
--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~--~~



function init()
	local d, w, h, x, y = 0,initialW,initialH,initialX,initialY
	if reaper.HasExtState( "Dfk_Mini_TMixer", "W_D" ) then d = reaper.GetExtState( "Dfk_Mini_TMixer", "W_D" ) end
	if reaper.HasExtState( "Dfk_Mini_TMixer", "W_W" ) then w = reaper.GetExtState( "Dfk_Mini_TMixer", "W_W" ) end
	if reaper.HasExtState( "Dfk_Mini_TMixer", "W_H" ) then h = reaper.GetExtState( "Dfk_Mini_TMixer", "W_H" ) end
	if reaper.HasExtState( "Dfk_Mini_TMixer", "W_X" ) then x = reaper.GetExtState( "Dfk_Mini_TMixer", "W_X" ) end
	if reaper.HasExtState( "Dfk_Mini_TMixer", "W_Y" ) then y = reaper.GetExtState( "Dfk_Mini_TMixer", "W_Y" ) end 
	if reaper.HasExtState( "Dfk_Mini_TMixer", "W_V" ) then output_visual = reaper.GetExtState( "Dfk_Mini_TMixer", "W_V" ) end if output_visual == "true" then output_visual = true else output_visual = false end 
	gfx.init(project_name, w, h, d, x, y )
	window_script = reaper.JS_Window_Find( project_name, 1 ) if Pin_Script_Window == true then reaper.JS_Window_SetZOrder( window_script, "TOPMOST" ) end
	for a = 1, reaper.CountTracks( 0 ) do tracksSel[a] = false tracksNSL[a] = false end 
	draw( true )
end

function exit()
  local wd, wx, wy, ww, wh = gfx.dock( -1, 0, 0, 0, 0 )
  reaper.SetExtState( "Dfk_Mini_TMixer", "W_D",  wd, true )
	reaper.SetExtState( "Dfk_Mini_TMixer", "W_X",  wx, true )
	reaper.SetExtState( "Dfk_Mini_TMixer", "W_Y",  wy, true )
	reaper.SetExtState( "Dfk_Mini_TMixer", "W_W",  ww, true )
	reaper.SetExtState( "Dfk_Mini_TMixer", "W_H",  wh, true )
	reaper.SetExtState( "Dfk_Mini_TMixer", "W_V",  tostring(output_visual), true )
end

--reaper.DeleteExtState( "Dfk_Mini_TMixer", "W_D", 1 ) reaper.DeleteExtState( "Dfk_Mini_TMixer", "W_W", 1 ) reaper.DeleteExtState( "Dfk_Mini_TMixer", "W_H", 1 ) reaper.DeleteExtState( "Dfk_Mini_TMixer", "W_X", 1 ) reaper.DeleteExtState( "Dfk_Mini_TMixer", "W_Y", 1 )
--reaper.atexit(exit)
init()
