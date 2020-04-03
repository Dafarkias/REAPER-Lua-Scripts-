--[[
 * ReaScript Name: Advance Loop Segment
 * About: Script advances the project loop by the length of the loop itself.
 * Author: Dfk
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-04-03)
  + script release
--]]

lstart, lend = reaper.GetSet_LoopTimeRange( false, true, 0, 0, false )

llength = lend - lstart
lnewend = llength + lend

reaper.GetSet_LoopTimeRange( true, true, lend, lnewend, false )

llength = llength / 2
lnewend = llength + lend
restore_pos = reaper.GetCursorPosition()
reaper.SetEditCurPos( lnewend, false, false )

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HSCROLL50"), 0)

reaper.SetEditCurPos( restore_pos, false, false )





