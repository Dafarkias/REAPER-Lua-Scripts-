function Msg(param)
 reaper.ShowConsoleMsg(param.."\n")
end

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





