--[[
 * ReaScript Name: Dfk Regress Loop Segment
 * About: Script advances the project loop by the length of the loop itself.
 * Author: Dfk
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.00
--]]
 
--[[
 * Changelog:
 * v1.00 (2020-04-03)
  + script release
--]]

function Msg(param)
 reaper.ShowConsoleMsg(param.."\n")
end

lstart, lend = reaper.GetSet_LoopTimeRange( false, true, 0, 0, false )

llength = lend - lstart
lnewstart = lstart - llength


if llength >= 0 then
reaper.GetSet_LoopTimeRange( true, true, lnewstart, lstart, false )

llength = llength / 2
lnewstart = lstart - llength
restore_pos = reaper.GetCursorPosition()
reaper.SetEditCurPos( lnewstart, false, false )

reaper.Main_OnCommand(reaper.NamedCommandLookup("_SWS_HSCROLL50"), 0)

play_pos = reaper.GetPlayPosition()
if play_pos >= lstart then
llength = lend - lstart
lnewstart = lstart - llength
reaper.SetEditCurPos( lnewstart, false, true )
end

reaper.SetEditCurPos( restore_pos, false, false )

end
