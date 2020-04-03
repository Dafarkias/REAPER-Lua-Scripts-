 --[[
NAME: Dafarkias' Transient Guru

Accuracy:

    Accuracy is the time-length of audio in samples used to formulate the average db and average frequency values. Left-click this button to set the "Accuracy" 
    length to the length of your time selection. It is best to ensure this value is set large enough to maintain accurate transient detection, yet small enough 
    to eliminate the possibility of reading transients that potentially may be nearby your stretch-markers (a.k.a., the ‘sweet spot’). 

Threshold:

    The threshold refers to the variable amount that each stretch-marker may differ from your chosen stretch-marker's average db or frequency (or else it will get
    removed!). For instance, a value of 10 threshold would mean that all stretch-markers within the workflow item must range within a multiplied variance of 10 in 
    order to remain. Threshold defaults a 10000, which essentially just ensures that no stretch-markers are removed prior to a user deliberately adjusting this 
    threshold setting. More blatantly, 10000 = bypass, 0 = 100% filtration. 

Choose SM:
    
    In order to select a stretch-marker, left-click the "Choose SM" button and hold: move your mouse over the desired stretch-marker inside your workflow item, and 
    release.

[UP/DOWN] Keys:
    
    These keys micro-adjust the threshold variable when the "Transient Guru" window is focused. Focus the window simply by clicking inside the window, or on its 
    title-bar.

Settings:

    Settings contains three different options for calculation of/and stretch-marker removal.
    
    0: Default: Calculation is based off both the average db and average frequency values.
    1: Spectrum: Calculation is determined using only the average frequency data.
    2: Volume: Calculation is determined using only the average db data.
		
Create Dyn. Midi:

		Creates a MIDI track item and populates with midi notes correlating to stretch-marker data. These notes are velocity sensitive, and are PPQ accurate. 

Extra Notes:
    
    Right-click the "Threshold" value to adjust the db threshold used to calculate average frequency.
    
    Right-click the "Accuracy" value to manually input a positive integer accuracy value.
    
    Shoutout to X-Raym for the portion of his code I used to figure out the frequency detection portion of this script. https://forum.cockos.com/showthread....63#post2146763
    
    URL to Cockos-Reaper thread (includes tutorial videos): 
    
    https://forum.cockos.com/showthread.php?t=221862

Suggested Instructions/Recommended Use:
    
    1. Select one item (see “Extra Notes” for more details about this, and for a link to my tutorial videos).
    
    1. Place stretch-markers in your workflow item using Reaper’s “Dynamic Split,” ensuring that stretch-markers are applied to all consequential transients. 
    
    2. Run the “Dfk Transient Guru” script.
    
    3. Place a time selection around the transient you want to use to create a filter and then left-click “Accuracy” (this step is optional, but preferred: you can just leave 
    the “Accuracy” set to “500”).
    
    4. Now, select the stretch-marker that correlates with this time selection, following the instructions listed under “Choose SM.” Consequently, if you did not manually adjust 
    your “Accuracy” setting, simply choose a stretch-marker to create a filter with.
    
    5. Set your “Threshold” setting to “0.” This will remove all stretch-markers other than you chosen stretch-marker. Use the up/down keys to slowly increase the “Threshold” 
    value until only your preferred transients are assigned stretch-markers (see “[UP/DOWN] Keys”). 

CATEGORY OF USE: Frequency Detection/Stretch-Marker Processing
AUTHOR: Dafarkias
LEGAL RAMIFICATIONS: GPL v.3
COCKOS REAPER THREAD: https://forum.cockos.com/showthread.php?t=221862
]]local version = 1.1--[[
REAPER: 5.978
EXTENSIONS: SWS/S&M 2.10.0, js_ReaScriptAPI .987

[v1.01] 
    -Altered algorithm for transient detection.
    -Fixed issue where mouse would active buttons on the GUI even if window wasn't focused.
    -Removed the ability to input "0" as an accuracy value (pointless, and caused errors.)
    -Added support for stereo tracks.
    -Added "Update SM's" button to the GUI. 
    -Added support for pre-stretched stretch-markers.
[v1.02] 
    -Added "average frequency" detection.
    -Added 3 settings for stretch-marker filtration.
    -Added shadows to GUI.
    -Added maximum-limit for accuracy setting of 1-second of samples (typically 44100+). 
    -Bolstered "Help" documentation.
    -Removed minor bugs.
    -Removed all calls to Main_OnCommand.
    -Removed stretch-marker "Slope" viewer-detail.
    -Improved script speed/efficiency.
[v1.03]
    -Added an undo point at startup of script for renewing any undesired removal of stretch-markers.
    -Configured “out-of-bound” stretch-marker message only to show when applicable. 
    -Removed "Fingerprint" nonsense, replaced with factual content.
[v1.1]
    FEATURE: "Create Dyn. Midi"
		-Optimized script. Now handles multiple items simultaneously. 
		-Enhanced overall script speed.

--]]
function Msg(param) reaper.ShowConsoleMsg(tostring(param).."\n") end function Up() reaper.UpdateTimeline() end    

--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE
local Thresh_dB = -90
--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE--DEV--VALUE

--GLOBAL VARIABLES
local mx, my = reaper.GetMousePosition()
local abs, max = math.abs, math.max
local break_script = false

local settings = 1 
local buffer = {}
local puffer = {}
local calcer = {}
local freqer = {}
local freq2 = {}
local calc = 0
local freq = 0
local depth = 500 --500!  
local d_thresh = 48000 -- maximum depth 
local v_thresh = 10000
local value = v_thresh
local micro = .01
local item = {}
local take = {}
local t_off = {}
local source = {}
local chans = {}
local s_rate = {}
local b_rate = {}
local aa = 0

local click = 0

--CALIBRATE VARIABLES
local calibrating = false
local p = 1

--SM VARIABLES
local pos = {}
local src = {}
local SM_ID = {} SM_ID[1] = -1 SM_ID[2] = -1 -- 1 = hover, 2 = selected
local TK_ID = {} TK_ID[1] = -1 TK_ID[2] = -1 -- 1 = hover, 2 = selected

-- GFX VARIABLES
local gx, gy = 352, 300
local font = "Times New Roman" 
local f_h = .7 -- font highlight
local load_A = 0 local load_V = .01

--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI
--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI--GUI
local gui = {"Accuracy", "Threshold", "Choose SM", "Update Take/SM's", "Help", "Settings", "SM H_Box", "SSM H_Box", "Choose_H"} 
---------r,g,b,a,         x,y,w,h,filled          r,g,b,a,x,y,",font 
gui[1]={.5,.2,.5,1,       0,0,176,30,1,            1,1,1,1,0,0,"Accuracy:",24}        gui[1][14]=gui[1][5]+2 gui[1][15]=gui[1][6]+2
---------r,g,b,a,         x,y,w,h,filled          r,g,b,a,x,y,",font 
gui[2]={.2,.5,.5,1,       0,30,176,30,1,           1,1,1,1,0,0,"Threshold:",24}    gui[2][14]=gui[2][5]+2 gui[2][15]=gui[2][6]+2
---------r,g,b,a,         x,y,w,h,filled          r,g,b,a,x,y,",font 
gui[3]={.6,.3,.2,1,       0,60,176,30,1,           1,1,1,1,0,0,"Choose SM",24}     gui[3][14]=gui[3][5]+2 gui[3][15]=gui[3][6]+2
---------r,g,b,a,         x,y,w,h,filled          r,g,b,a,x,y,",font 
gui[4]={.5,.5,.0,1,       0,90,176,30,1,           1,1,1,1,0,0,"Update SM's",24}   gui[4][14]=gui[4][5]+2 gui[4][15]=gui[4][6]+2 
---------r,g,b,a,         x,y,w,h,filled          r,g,b,a,x,y,",font 
gui[5]={.5,.3,.4,1,       0,120,176/2,30,1,        1,1,1,1,0,0,"Help",24}          gui[5][14]=gui[5][5]+2 gui[5][15]=gui[5][6]+2
---------r,g,b,a,         x,y,w,h,filled          r,g,b,a,x,y,",font 
gui[6]={.5,.5,.5,1,       176/2,120,176/2,30,1,     1,1,1,1,0,0,"Settings",24}      gui[6][14]=gui[6][5]+2 gui[6][15]=gui[6][6]+2
---------r,g,b,a,         x,y,w,h,filled          r,g,b,a,x,y,",font 
gui[7]={1,0,0,0,          0, gy/2,352,gy/2,1,      1,1,1,1,0,0,"",24}
---------r,g,b,a,         x,y,w,h,filled          r,g,b,a,x,y,",font 
gui[8]={.5,.2,.2,.2,      0,gy,352,gy/2,1,         1,1,1,1,0,0,"",24}
---------r,g,b,a,         x,y,w,h,filled          r,g,b,a,x,y,",font 
gui[9]={1,0,0,0,          0,60,176,30,1,           0,0,0,0,0,0,"Choose SM",24} gui[9][14]=gui[3][5]+2 gui[9][15]=gui[3][6]+2
---------r,g,b,a,         x,  y,w,  h, filled        r,g,b,a,x,  y,",font 
gui[10]={.8,.7,.1,1,      176,0,176,30,1,            1,1,1,1,176,0,"Create Dyn. Midi",24}  
--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT
--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT
local txt = {"SM ID:", "Avg. db:", "Avg. Freq.:", "Position:", "Source:","Selected SM ID:", "Avg. db:", "Avg. Freq.:", "Position:", "Source:"} 
--------r,g,b,a,x,y,  "",font
txt[1]={1,1,1,1,2,154,"TK: ",20} 
--------r,g,b,a,x,y,  "",font
txt[11]={1,1,1,1,90,154,"SM: ",20} 
---------r,g,b,a,x, y,  "",font
txt[2]={1,1,1,1,2,184,"Fingerprint: ",20} 
--------r,g,b,a,x,y,  "",font
txt[3]={1,1,1,1,2,214,"Avg. Freq.: ",20}
--------r,g,b,a,x,y,  "",font
txt[4]={1,1,1,1,2,244,"Position: ",20} 
--------r,g,b,a,x,y,  "",font
txt[5]={1,1,1,1,2,274,"Source: ",20} 
--------r,g,b,a,x,y,  "",font
txt[6]={1,1,1,1,2,304,"*TK: ",20} 
--------r,g,b,a,x,y,  "",font
txt[12]={1,1,1,1,90,304,"*SM: ",20} 
---------r,g,b,a,x, y,  "",font
txt[7]={1,1,1,1,2,334,"Fingerprint: ",20} 
--------r,g,b,a,x,y,  "",font
txt[8]={1,1,1,1,2,364,"Avg. Freq.: ",20} 
--------r,g,b,a,x,y,  "",font
txt[9]={1,1,1,1,2,394,"Position: ",20} 
 --------r,g,b,a,x,y,  "",font
txt[10]={1,1,1,1,2,424,"Source: ",20} 
--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT
--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT--TEXT

function draw_gui() 

    for a = 1, #gui 
  do
  --RECTANGLE
    gfx.r, gfx.g, gfx.b, gfx.a = gui[a][1], gui[a][2], gui[a][3], gui[a][4] 
    gfx.rect(gui[a][5],gui[a][6],gui[a][7],gui[a][8], gui[a][9] ) 
    -- Shadow
    gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, .1
    gfx.rect(gui[a][5]+2,gui[a][6]+2,gui[a][7]-4,gui[a][8]-4, gui[a][9] ) 
  --TEXT
    gfx.r, gfx.g, gfx.b, gfx.a = gui[a][10], gui[a][11], gui[a][12], gui[a][13]
    gfx.setfont(1, font, gui[a][17]) gfx.x, gfx.y = gui[a][14], gui[a][15] gfx.drawstr(gui[a][16]) 
  end
    for a = 1, #txt 
  do
    --TEXT
    gfx.r, gfx.g, gfx.b, gfx.a = txt[a][1], txt[a][2], txt[a][3], txt[a][4] gfx.setfont(1, font, txt[a][8])
    gfx.x, gfx.y = txt[a][5], txt[a][6] gfx.drawstr(txt[a][7])
  end
  gfx.update()
  
end

function SM_filter() 

		for z = 1, #take
	do

  reaper.DeleteTakeStretchMarkers( take[z], 0, 10000 )

			for a = 1, #pos[z] 
		do
		
				if settings == 1 --BOTH
			then 

					if calcer[z][a] <= calcer[z][SM_ID[2]]+(calcer[z][SM_ID[2]]*value) and calcer[z][a] >= calcer[z][SM_ID[2]]-(calcer[z][SM_ID[2]]*value) 
				then 
						if freq2[z][a] <= freq2[z][SM_ID[2]]+(freq2[z][SM_ID[2]]*value) and freq2[z][a] >= freq2[z][SM_ID[2]]-(freq2[z][SM_ID[2]]*value) 
					then 
						reaper.SetTakeStretchMarker( take[z], -1, pos[z][a], src[z][a] )
					end
				end
				
				elseif settings == 2 -- FREQ
			then
			
					if freq2[z][a] <= freq2[z][SM_ID[2]]+(freq2[z][SM_ID[2]]*value) and freq2[z][a] >= freq2[z][SM_ID[2]]-(freq2[z][SM_ID[2]]*value) 
				then
					reaper.SetTakeStretchMarker( take[z], -1, pos[z][a], src[z][a] )
				end
				
			else -- settings == 3 VOL
			
					if calcer[z][a] <= calcer[z][SM_ID[2]]+(calcer[z][SM_ID[2]]*value) and calcer[z][a] >= calcer[z][SM_ID[2]]-(calcer[z][SM_ID[2]]*value) 
				then
						reaper.SetTakeStretchMarker( take[z], -1, pos[z][a], src[z][a] )
				end
				
			end -- SETTINGS END

		end -- A END 
		
	end -- Z END
  
  Up()

end -- function SM_filter()

function clicky() if reaper.JS_Window_GetFocus() ~= reaper.JS_Window_Find( "Dfk's Transient Guru", 1 ) and click ~= 3 then return end local int = 0

    if gfx.mouse_y < 0 or gfx.mouse_y > gfx.h or gfx.mouse_x < 0  or gfx.mouse_x > gfx.w 
    then
      if reaper.JS_Mouse_GetState(1) == 1 and click == 0 then click = 999 end
    end
		
--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY--ACCURACY
        if gfx.mouse_y > gui[1][6] and gfx.mouse_y < (gui[1][6]+gui[1][8]) and gfx.mouse_x > gui[1][5]  and gfx.mouse_x < (gui[1][5]+gui[1][7]) 
    then gui[1][4] = f_h
      if reaper.JS_Mouse_GetState(1) == 1 and click == 0 then
				if reaper.GetSelectedMediaItem( 0, 0 ) == nil then reaper.MB("Ensure an item is selected, and a time selection has been set.", "[error]", 0) return end
        local ts_start, ts_end = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 ) if (ts_start-ts_end) == 0 then reaper.MB("Ensure an item is selected, and a time selection has been set.", "[error]", 0) return end 
        depth = math.floor((ts_end - ts_start)*reaper.GetMediaSourceSampleRate( reaper.GetMediaItemTake_Source( reaper.GetActiveTake( reaper.GetSelectedMediaItem( 0, 0 ) ) ) ) ) if depth > d_thresh then depth = d_thresh end
        calibrate() 
      end
        if reaper.JS_Mouse_GetState(2) == 2 and click == 0 and reaper.JS_Mouse_GetState(1) == 0 
      then
        ::incorrect::
        local _, dummy = reaper.GetUserInputs( "", 1, "Enter sample accuracy", "1-"..d_thresh ) 
        if dummy ~= "1-"..d_thresh then dummy = tonumber(dummy)
          if type(dummy) ~= 'number' then reaper.MB( "Ensure that input is a positive integer and less than "..d_thresh..".", "[error]", 0 ) goto incorrect end
          dummy = math.floor(dummy) if dummy < 1 then dummy = 1 end if dummy > d_thresh then dummy = d_thresh end
          depth = dummy calibrate()
        end
      end
    else gui[1][4] = 1 
    end
--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD--THRESHOLD   
      if gfx.mouse_y > gui[2][6] and gfx.mouse_y < (gui[2][6]+gui[2][8]) and gfx.mouse_x > gui[2][5]  and gfx.mouse_x < (gui[2][5]+gui[2][7]) 
    then gui[2][4] = f_h
      if reaper.JS_Mouse_GetState(2) == 2 and click == 0 then
        click = 2 
        ::incorrect2::
        local _, dummy = reaper.GetUserInputs( "[current setting: "..Thresh_dB.."]", 1, "Enter freq. detection floor (db):", "-192 to -64" ) 
        if dummy ~= "-192 to -64" then dummy = tonumber(dummy)
          if type(dummy) ~= 'number' then reaper.MB( "Ensure that input is a negative number, and between -192 to -64.", "[error]", 0 ) goto incorrect2 end
          if dummy > -64 then dummy = -64 end if dummy < -192 then dummy = -192 end
          Thresh_dB = dummy calibrate()
        end
      end
      if reaper.JS_Mouse_GetState(1) == 1 and click == 0 then
        click = 2 
        ::incorrect2::
        local _, dummy = reaper.GetUserInputs( "", 1, "Enter variable threshold", "0-"..tostring(v_thresh) ) 
        if dummy ~= "0-"..tostring(v_thresh) then dummy = tonumber(dummy)
          if type(dummy) ~= 'number' then reaper.MB( "Ensure that input is a positive number, and between 0-"..tostring(v_thresh)..".", "[error]", 0 ) goto incorrect2 end
          if dummy < 0 then dummy = 0 end if dummy > v_thresh then dummy = v_thresh end
          value = dummy
          if TK_ID[2] ~= -1 and SM_ID[2] ~= -1 then SM_filter() end
        end
      end
    else gui[2][4] = 1
    end
--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM--CHOOSE SM
      if gfx.mouse_y > gui[3][6] and gfx.mouse_y < (gui[3][6]+gui[3][8]) and gfx.mouse_x > gui[3][5]  and gfx.mouse_x < (gui[3][5]+gui[3][7]) 
    then gui[3][4] = f_h
      if reaper.JS_Mouse_GetState(1) == 1 and click == 0 then
        click = 3
      end 
    else gui[3][4] = 1
    end
--UPDATE TAKE/SM--UPDATE TAKE/SM--UPDATE TAKE/SM--UPDATE TAKE/SM--UPDATE TAKE/SM--UPDATE TAKE/SM--UPDATE TAKE/SM--UPDATE TAKE/SM--UPDATE TAKE/SM--UPDATE TAKE/SM--UPDATE TAKE/SM
      if gfx.mouse_y > gui[4][6] and gfx.mouse_y < (gui[4][6]+gui[4][8]) and gfx.mouse_x > gui[4][5]  and gfx.mouse_x < (gui[4][5]+gui[4][7]) 
    then gui[4][4] = f_h
      if reaper.JS_Mouse_GetState(1) == 1 and click == 0 then
        click = 4 collect_data()
      end 
    else gui[4][4] = 1
    end
--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP--HELP   
      if gfx.mouse_y > gui[5][6] and gfx.mouse_y < (gui[5][6]+gui[5][8]) and gfx.mouse_x > gui[5][5]  and gfx.mouse_x < (gui[5][5]+gui[5][7]) 
    then gui[5][4] = f_h
      if reaper.JS_Mouse_GetState(1) == 1 and click == 0 then click = 5
        reaper.MB( "Accuracy:\n\nAccuracy is the time-length of audio in samples used to formulate the average db and average frequency values. Left-click this button to set ".. 
        "the \"Accuracy\" length to the length of your time selection. It is best to ensure this value is set large enough to maintain accurate transient detection, yet small ".. 
        "enough to eliminate the possibility of reading transients that potentially may be nearby your stretch-markers (a.k.a., the ‘sweet spot’).\n\nThreshold:\n\n"..
        "The threshold refers to the variable amount that each stretch-marker may differ from your chosen stretch-marker's average db or frequency (or else it will get removed!). ".. 
        "For instance, a value of 10 threshold would mean that all stretch-markers within the workflow item must range within a multiplied variance of 10 in order to remain. ".. 
        "Threshold defaults a 10000, which essentially just ensures that no stretch-markers are removed prior to a user deliberately adjusting this threshold setting. More ".. 
        "blatantly, 10000 = bypass, 0 = 100% filtration.\n\nChoose SM:\n\nIn order to select a stretch-marker, left-click the \"Choose SM\" button and hold: move your mouse ".. 
        "over the desired stretch-marker inside your workflow item, and release.\n\n[UP/DOWN] Keys:\n\nThese keys micro-adjust the threshold variable when the \"Transient ".. 
        "Guru\" window is focused. Focus the window simply by clicking inside the window, or on its title-bar.\n\nSettings:\n\nSettings contains three different options ".. 
        "for calculation of/and stretch-marker removal.\n\n0: Default: Calculation is based off both the average db and average frequency values.\n1: Spectrum: Calculation ".. 
        "is determined using only the average frequency data.\n2: Volume: Calculation is determined using only the average db data.\n\nCreate Dyn. Midi:\n\nCreates a MIDI track "..
				"item and populates with midi notes correlating to stretch-marker data. These notes are velocity sensitive, and are PPQ accurate.\n\nExtra Notes:\n\nRight-click the "..
				"\"Threshold\" value to adjust the db threshold used to calculate average frequency.\n\nRight-click the \"Accuracy\" value to manually input a positive integer accuracy "..
				"value.", "Dfk's Transient Guru v"..version..", GPL v.3", 0 )
      end 
    else gui[5][4] = 1 
    end
--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS--SETTINGS
    if gfx.mouse_y > gui[6][6] and gfx.mouse_y < (gui[6][6]+gui[6][8]) and gfx.mouse_x > gui[6][5]  and gfx.mouse_x < (gui[6][5]+gui[6][7]) 
  then gui[6][4] = f_h
	
      if reaper.JS_Mouse_GetState(1) == 1 and click == 0 
    then click = 6
		
		  local inputted = reaper.MB( "The following settings determine how the stretch-marker threshold is calculated and applied:\n\n\nSetting 1 (abort):\n\nCalculation is based off both the average db and average frequency values. [DEFAULT SETTING]\n\n\nSetting 2 (retry):\n\nCalculation is determined using only the average frequency data.\n\n\nSetting 3 (ignore):\n\nCalculation is determined using only the average db data.", "[current setting: "..settings.."]", 2 )
			
				if inputted == 3
			then
				settings = 1
				elseif inputted == 4
			then
				settings = 2
				elseif inputted == 5
			then
				settings = 3
			end

		end
		
  else 
		gui[6][4] = 1 
  end
--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI--CREATE MIDI
      if gfx.mouse_y > gui[10][6] and gfx.mouse_y < (gui[10][6]+gui[10][8]) and gfx.mouse_x > gui[10][5]  and gfx.mouse_x < (gui[10][5]+gui[10][7]) 
    then gui[10][4] = f_h
				if reaper.JS_Mouse_GetState(1) == 1 and click == 0 
			then click = 5 local hi = 0 local low = 100000 local hi2 = 0 local low2 = 10

				reaper.InsertTrackAtIndex( reaper.GetMediaTrackInfo_Value( reaper.GetMediaItem_Track( item[1] ), "IP_TRACKNUMBER" )-1, 0 )
				local tracked = reaper.GetTrack( 0, reaper.GetMediaTrackInfo_Value( reaper.GetMediaItem_Track( item[1] ), "IP_TRACKNUMBER" )-2 )
				
					for a = 1, #take
				do local kute = reaper.GetMediaItemInfo_Value( item[a], "D_POSITION" )+reaper.GetMediaItemInfo_Value( item[a], "D_LENGTH" )
					if kute > hi then hi = kute end 
					if reaper.GetMediaItemInfo_Value( item[a], "D_POSITION" ) < low then low = reaper.GetMediaItemInfo_Value( item[a], "D_POSITION" ) end
						for b = 1, #pos[a]
					do
						if calcer[a][b] < low2 then low2 = calcer[a][b] end
						if calcer[a][b] > hi2 then hi2 = calcer[a][b] end
					end
				end
				
				local itemed = reaper.CreateNewMIDIItemInProj( tracked, low, hi )

				
					for a = 1, #take
				do
						for b = 1, #pos[a]
					do
						local _, pos34, _ = reaper.GetTakeStretchMarker( take[a], b )
						local item_pos34 = reaper.GetMediaItemInfo_Value( item[a], "D_POSITION" )
						local ratior = 127/(hi2-low2)
						reaper.MIDI_InsertNote( reaper.GetActiveTake( itemed ), 1, 0, reaper.MIDI_GetPPQPosFromProjTime( reaper.GetActiveTake( itemed ), item_pos34+pos34 ), reaper.MIDI_GetPPQPosFromProjTime( reaper.GetActiveTake( itemed ), item_pos34+pos34 )+100, 1, 60, 124-math.floor( (calcer[a][b]-low)*(121/(hi2-low2)) ), 0 )  
					end
				end

      end Up()
    else gui[10][4] = 1 
    end
	
    
    if reaper.JS_Mouse_GetState(1) == 0 then
      if click == 3 then 
        if SM_ID[1] > 0 and TK_ID[1] > 0 then SM_ID[2] = SM_ID[1] TK_ID[2] = TK_ID[1]
        local _, k, l, m, _ = gfx.dock(-1,1,1,1,1 ) 
        gfx.quit()
        gfx.init("Dfk's Transient Guru", m, 450, 0, k, l)
        end
      end
      click = 0 
    end

end -- function click()

function calibrate() freq2[p] = {} calcer[p] = {} buffer[p] = {} calibrating = true
		
		--Msg(p)
		
		reaper.DeleteTakeStretchMarkers( take[p], 0, 10000 ) Up() -- delete all stretch markers for reading item source data
		aa = reaper.CreateTakeAudioAccessor( take[p] )  
			for a = 1, #pos[p] 
		do
			freq = 0 calc = 0
			buffer[p][a] = reaper.new_array(depth*chans[p]) -- 1 based
			reaper.GetAudioAccessorSamples( aa, s_rate[p], chans[p], src[p][a]-t_off[p], depth, buffer[p][a] ) -- 0 based
			puffer = reaper.new_array(depth * 3) puffer.clear() -- max, min, spectral each chan(but now 1 chan only)

			retval = reaper.GetMediaItemTake_Peaks(take[p], s_rate[p], src[p][a]-t_off[p], 1--[[only supports one channel]], depth, 115--[[want extra type]], puffer)
			--SPECTRUM--SPECTRUM--SPECTRUM--SPECTRUM--SPECTRUM--SPECTRUM--SPECTRUM--SPECTRUM--SPECTRUM--SPECTRUM--SPECTRUM--SPECTRUM--SPECTRUM
			local spl_cnt  = (retval & 0xfffff)        -- sample_count
			local ext_type = (retval & 0x1000000)>>24  -- extra_type was available
			local out_mode = (retval & 0xf00000)>>20   -- output_mode
			------------------
			freqer = {}
			if spl_cnt > 0 and ext_type > 0 then
				for i = 1, depth do
					local r = #freqer
					freqer[r+1] = puffer[i]             -- max peak
					freqer[r+2] = puffer[depth + i]    -- min peak
					--------------
					local spectral = puffer[depth*2 + i]    -- spectral peak
					-- freq and tonality from spectral peak --
					freqer[r+3] = spectral&0x7fff       -- low 15 bits frequency
					freqer[r+4] = (spectral>>15)/16384  -- tonality norm value 
				end
			end
			local Thresh = 10 ^ (Thresh_dB/20)
				for b = 1, #freqer, 4 
			do
				local max_peak, min_peak = freqer[b], freqer[b+1]
					if max(abs(max_peak), abs(min_peak)) > Thresh 
				then
					local tonal = freqer[b+3] freq = freq + freqer[b+2] 
				end --[[if max(abs(max_peak), abs(min_peak)) > Thresh ]] 
			end --[[for i = 1, #peaks, 4 ]]
			--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS
			--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS--RESULTS
				for z = 1, depth 
			do
				calc = calc + math.abs(buffer[p][a][z]) --Msg("calculation: "..calc)
			end
			freq2[p][a] = (freq/depth)
			calcer[p][a] = (calc/(depth*chans[p])) --Msg(calcer[p][a])
			
		end -- for a = 1, #pos[p]  do
		
		reaper.DestroyAudioAccessor( aa ) p = p + 1
	
		--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX
    load_A = load_A + load_V if load_A > 1 or load_A < 0 then load_V = load_V * -1 end gui[4][1],gui[4][2],gui[4][3],gui[4][4],gui[4][16] = .2,.5,.7,load_A, "Calibrating" draw_gui()
    --GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX
  
    if p <= #take then --STILL CALIBRATING
      reaper.defer(calibrate)
    else               --FINISHED CALIBRATING
			p = 1 calibrating = false gui[4][1],gui[4][2],gui[4][3],gui[4][4],gui[4][16] = .5,.5,0,1, "Update Take/SM's"
				for j = 1, #take
			do
					for k = 1, #pos[j] 
				do
					reaper.SetTakeStretchMarker( take[j], -1, pos[j][k], src[j][k] )
				end
			end Up()
    end 

end -- function calibrate() 

function collect_data() 

			for a = 1, reaper.CountSelectedMediaItems( 0 )
		do
			
			item[a] = reaper.GetSelectedMediaItem( 0, a-1) take[a] = reaper.GetActiveTake( item[a] ) 
			t_off[a] = reaper.GetMediaItemTakeInfo_Value( take[a], "D_STARTOFFS" ) 
			source[a] = reaper.GetMediaItemTake_Source( take[a] ) chans[a] = reaper.GetMediaSourceNumChannels( source[a] )
			s_rate[a] = reaper.GetMediaSourceSampleRate( source[a] )  
			b_rate[a] = reaper.CF_GetMediaSourceBitDepth( source[a] )
				 
			--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs
			pos[a] = {} src[a] = {}
				for b = 1, reaper.GetTakeNumStretchMarkers( take[a] )
			do
				local _, poss, srcc = reaper.GetTakeStretchMarker( take[a], b-1 )
					if poss >= 0 and poss <= reaper.GetMediaItemInfo_Value( item[a], "D_LENGTH" )
				then
					_, pos[a][#pos[a]+1], src[a][#src[a]+1] = reaper.GetTakeStretchMarker( take[a], b-1 )
				end
			end
			reaper.DeleteTakeStretchMarkers( take[a], 0, 10000 ) Up() -- delete all stretch markers for reading item source data
				for b = 1, #pos[a]
			do
				 reaper.SetTakeStretchMarker( take[a], -1, pos[a][b], src[a][b] )
			end
			--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs--STORE SMs
			
			--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS
			if chans[a] > 2 then reaper.MB( "The selected item must not contain more than 2 channels. Please convert item"..
			"and rerun script.", "[error]", 0 ) break_script = true break end 
			--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS--ERRORS
				
		end
		
		calibrate()
    
end -- function collect_data() 

function check_key()
      
      if gfx.getchar(30064) == 1 then -- UP
        if value + micro <= v_thresh then value = value + micro end
        if TK_ID[2] > 0 and SM_ID[2] > 0 then SM_filter() end
      end -- if gfx.getchar(30064) == 1 then
      
      if gfx.getchar(1685026670) == 1 then -- DOWN
        if value - micro >= 0 then value = value - micro end
        if TK_ID[2] > 0 and SM_ID[2] > 0 then SM_filter() end
      end -- if gfx.getchar(30064) == 1 then
  
end -- function check_key()

function main()
    
    --GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX
    --GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX
    --VARIABLE--VARIABLE--VARIABLE--VARIABLE--VARIABLE--VARIABLE--VARIABLE--VARIABLE
    SM_ID[1] = -1 reaper.BR_GetMouseCursorContext()
		
			for a = 1, #take
		do
				if reaper.BR_GetMouseCursorContext_Take() == take[a] 
			then 
				SM_ID[1] = reaper.BR_GetMouseCursorContext_StretchMarker() + 1 
				TK_ID[1] = a
			end 
		end
     
      if SM_ID[1] < 1
    then 
      SM_ID[1] = -1 gui[7][4] = 0 
      txt[1][7]  = "TK: "
			txt[11][7] = "SM: "
      txt[2][7]  = "Avg. db: "
      txt[3][7]  = "Avg. Freq.: "
      txt[4][7]  = "Position: "
      txt[5][7]  = "Source: "
    else
      gui[7][4] = .2 
      txt[1][7]  = "TK: "..TK_ID[1]
			txt[11][7] = "SM: "..SM_ID[1]
      txt[2][7]  = "Avg. db: "..tostring((20*math.log(calcer[TK_ID[1]][SM_ID[1]], 10)))  
      txt[3][7]  = "Avg. Freq.: "..tostring(freq2[TK_ID[1]][SM_ID[1]])
      txt[4][7]  = "Position: "..pos[TK_ID[1]][SM_ID[1]]
      txt[5][7]  = "Source: "..src[TK_ID[1]][SM_ID[1]]
    end
		
    if click == 3 then gui[9][4]=.5 gui[9][13]=1 else gui[9][4]=0 gui[9][13]=0 end
		
      if SM_ID[2] ~= -1 and TK_ID[2] ~= -1 
    then
      txt[6][7] = "*TK: "..TK_ID[2]
			txt[12][7] = "*SM: "..SM_ID[2]
      txt[7][7] = "Avg. db: "..tostring((20*math.log(calcer[TK_ID[2]][SM_ID[2]], 10)))
      txt[8][7] = "Avg. Freq.: "..tostring(freq2[TK_ID[2]][SM_ID[2]])
      txt[9][7] = "Position: "..pos[TK_ID[2]][SM_ID[2]]
      txt[10][7] = "Source: "..src[TK_ID[2]][SM_ID[2]]
    end
    --STATIC--STATIC--STATIC--STATIC--STATIC--STATIC--STATIC--STATIC--STATIC--STATIC
    gui[1][16] = "Accuracy: "..depth
    gui[2][16] = "Threshold: "..value
    --GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX
    --GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX--GFX
    
      if calibrating == false 
    then 
      clicky()
      check_key()
      draw_gui()
    end

    if gfx.getchar() ~= -1 and break_script == false then reaper.defer(main) else gfx.quit() end 

end -- function main()

	if reaper.MB( "In order for this script to maximize efficiency, please note that all non-visible stretch markers before & after the confines of your workflow items will be removed.\n\nWould you still like to execute this script?", "[inquiry]", 4 ) == 6 
then 
		if reaper.CountSelectedMediaItems( 0 ) < 1 
	then 
		reaper.MB( "Please select at least 1 item before initiating script.", "[user error]", 0 ) 
	else
		--UNDO MARK--UNDO MARK--UNDO MARK--UNDO MARK--UNDO MARK--UNDO MARK
		reaper.Undo_BeginBlock() 
		reaper.AddProjectMarker( 0, 0, 5000000, 0, "", 5000000 ) Up()
		reaper.Undo_EndBlock( "Dfk Transient Guru Start-Position", 8 )
		reaper.DeleteProjectMarker( 0, 5000000, 0 )
		--UNDO MARK--UNDO MARK--UNDO MARK--UNDO MARK--UNDO MARK--UNDO MARK
		
		mx, my = reaper.GetMousePosition()
    gfx.init("Dfk's Transient Guru", gx, gy, 0, mx-(gx/2), my-(gy/2))
		
		collect_data() 
		main()
	end 
else 
	reaper.MB( "Script cancelled.", "[script message]", 0 ) 
end


