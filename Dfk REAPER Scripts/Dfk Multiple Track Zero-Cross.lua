--[[
 * ReaScript Name: Dfk Multiple Track Zero-Cross
 * About: Project workflow utility for finding zero-cross points in parallel media items.
 * Author: Dfk
 * Licence: GPL v3
 * REAPER: 5.979
 * Extensions: SWS/S&M 2.10.0, js_ReaScriptAPI .987
 * Version: 1.00
--]]
 
--[[
 * Changelog:
 * v1.00 (2020-04-03)
    +Recoded script for greater efficiency and speed
    +Removed inability to process stereo items
	+Changed envelope placement to length of one grid-division unit (i.e., 1/8, 1/16, 1/32, etc.)
	+Altered script 'undo' handling
--]]

function Msg(param) reaper.ShowConsoleMsg(tostring(param).."\n") end function Up() reaper.UpdateTimeline() end    

--GLOBAL VARIABLES
local ts_start, ts_end = reaper.GetSet_LoopTimeRange( 0, 0, 0, 0, 0 ) 
local item_num = reaper.CountSelectedMediaItems( 0 )
local action = 0

local item = 0
local item_start = 0
local take = 0
local source = 0
local aa = 0
local s_rate = 0
local samples = 0

local check = {}
local chans = {}
local two_check = {}
local zero_cross = {} zero_cross[0] = 500

function set_vol_points(pos, val, clear_envelope) 

  track_restoreselection(42) Up() -- restore track selection
  
  for i = 0, reaper.CountSelectedTracks( 0 )-1 do
    
    reaper.SetOnlyTrackSelected( reaper.GetSelectedTrack( 0, i ) ) Up()
    reaper.Main_OnCommand(41865,  1) -- selects/activates pre-FX volume envelope
    
    if clear_envelope then
      reaper.Main_OnCommand(40089,  1) -- clears pre_FX volume points in time selection
    end
  
    reaper.InsertEnvelopePoint( reaper.GetSelectedEnvelope( 0 ), pos, val, 0, 0, false )
    
    track_restoreselection(42) Up() Up() -- restore track selection 
    
  end -- for i = 0, reaper.CountSelectedTracks(0) do

end -- function select_envelopes() local tr


function track_storeselection (number, boolean)
  
  for a = 0, reaper.CountSelectedTracks( 0 ) - 1 do
  
    local track = reaper.GetSelectedTrack( 0, a )
    
    local GUID = reaper.GetTrackGUID( track )
    
    reaper.SetExtState("Dfk", "track_selection"..number..a, GUID, boolean )
    
  end -- for a = 0, reaper.CountSelectedTracks( 0 ) do
  
  reaper.SetExtState("Dfk", "track_selection_count"..number, reaper.CountSelectedTracks( 0 ), boolean )
  Up()
end -- function track_selection_store()


function track_restoreselection(number)

  if reaper.HasExtState("Dfk", "track_selection_count"..number) == false then return end
  if reaper.GetExtState("Dfk", "track_selection_count"..number) == 0 then return end
  
  for a = 0, reaper.GetExtState("Dfk", "track_selection_count"..number) - 1 do
  
    if a == 0 then
    
      reaper.SetOnlyTrackSelected( reaper.BR_GetMediaTrackByGUID( 0, reaper.GetExtState( "Dfk", "track_selection"..number..a) ) )
      
    end -- if a == 0 then
    
    reaper.SetTrackSelected( reaper.BR_GetMediaTrackByGUID( 0, reaper.GetExtState( "Dfk", "track_selection"..number..a) ) , true )
    
  end -- for a = 0, #track_selection_tracks+1 do
  Up()
end -- function track_selection_restore()

function errors()

  if item_num == 0 then  reaper.MB( "Please select an item.", "[error]", 0 ) return end
  if ts_end-ts_start <= 0 then reaper.MB( "Please set a time selection.", "[error]", 0 ) return end
  if ts_end-ts_start > 5 then reaper.MB( "Please ensure time selection is less than 5 seconds in length.", "[error]", 0 ) return end
  reaper.SetOnlyTrackSelected( reaper.GetMediaItemTrack( reaper.GetSelectedMediaItem( 0, 0 ) ) )
  reaper.SetTrackSelected( reaper.GetMediaItemTrack( reaper.GetSelectedMediaItem( 0, 0 ) ), 0 )
    for a = 1, item_num
  do reaper.SetTrackSelected( reaper.GetMediaItemTrack( reaper.GetSelectedMediaItem( 0, a-1 ) ), 1 )
    if reaper.GetMediaItemInfo_Value( reaper.GetSelectedMediaItem( 0, a-1 ), "D_POSITION" ) > ts_start then 
    reaper.MB( "Please ensure all selected items are encapsulated within your time selection.", "[error]", 0 ) return end 
    if reaper.GetMediaItemInfo_Value( reaper.GetSelectedMediaItem( 0, a-1 ), "D_POSITION" )+reaper.GetMediaItemInfo_Value( reaper.GetSelectedMediaItem( 0, a-1 ), "D_LENGTH" )< ts_end then 
    reaper.MB( "Please ensure all selected items are encapsulated within your time selection.", "[error]", 0 ) return end 
    if reaper.GetMediaSourceNumChannels( reaper.GetMediaItemTake_Source( reaper.GetActiveTake( reaper.GetSelectedMediaItem( 0, a-1 ) ) ) ) > 2 then
    reaper.MB( "Please ensure all selected items are either mono or stereo.", "[error]", 0 ) return end 
  end
  
  reaper.MB( "Enter \"0\" to place your Edit Cursor at zero-cross, and \"1\" to place pre-volume envelope points.", "[message]", 0 )
  ::incorrect::
   _, action = reaper.GetUserInputs( "", 1, "0: EC 1: ENV", "0-1") 
   if action ~= "0-1" then action = tonumber(action)
     if type(action) ~= 'number' then reaper.MB( "Ensure that your entry is either 0 or 1", "[error]", 0 ) goto incorrect end
     if action ~= 0 and action ~= 1 then goto incorrect end 
   else
    return
   end
 
  track_storeselection(42, false)
 
  get_bits()

end

function calculate_bits()

    for a = 1, samples
  do
    zero_cross[a] = 0
    --Msg("chans: "..chans[a])

        for b = 1, item_num
      do 
      
          if chans[b] == 2 
        then
      
        zero_cross[a] = zero_cross[a] + math.abs(check[b][a+(a-1)]) 
        zero_cross[a] = zero_cross[a] + math.abs(check[b][a+a]) --Msg(a..": "..zero_cross[a])
        
        else
        
          for b = 1, item_num
        do
          zero_cross[a] = zero_cross[a] + math.abs(check[b][a]) --Msg(a..": "..zero_cross[a])
        end
        
        end
        
      end  
    
    if a ~= 1 then if zero_cross[a] <= zero_cross[0] then zero_cross[0] = zero_cross[a] zero_cross[-1] = a  end end 

  end
  
    if action == 0 
  then 
    reaper.SetEditCurPos( ts_start+(zero_cross[-1]/s_rate), 0, 0 ) Up()
  else
    reaper.Undo_BeginBlock()
    set_vol_points((ts_start+(zero_cross[-1]/s_rate)), 0, 1) 
    set_vol_points(((ts_start+(zero_cross[-1]/s_rate))+(reaper.BR_GetNextGridDivision( 0 )/2)), 1 ) 
    set_vol_points(((ts_start+(zero_cross[-1]/s_rate))-(reaper.BR_GetNextGridDivision( 0 )/2)), 1 ) 
    reaper.Undo_EndBlock( "Multiple-Item Zero-Cross: Insert Envelope Points", 8 )
    --INSERT ENVELOPES
  end

end

function get_bits()

    for a = 1, item_num
  do
    item = reaper.GetSelectedMediaItem( 0, a-1 )
    item_start = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
    take = reaper.GetActiveTake( item )
    source = reaper.GetMediaItemTake_Source( take )
    aa = reaper.CreateTakeAudioAccessor( take )
    s_rate = reaper.GetMediaSourceSampleRate( source )
    chans[a] = reaper.GetMediaSourceNumChannels( source )
    samples = math.floor(((ts_end-ts_start)*s_rate)) if samples > s_rate then samples = s_rate end
    check[a] = reaper.new_array(samples*chans[a])
    
    reaper.GetAudioAccessorSamples( aa, s_rate, chans[a], ts_start-item_start, samples, check[a] )
    
    reaper.DestroyAudioAccessor( aa )      
  end                                                             

  calculate_bits()
  
end

errors()






















