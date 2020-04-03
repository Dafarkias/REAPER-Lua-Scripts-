--[[
 * ReaScript Name: Dfk Quantize Project Markers
 * About: Script quantizes project markers.
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

mark_tot, num_markers, num_regions = reaper.CountProjectMarkers( 0 )

reaper.Main_OnCommand(40755, 0) -- Save snap state

reaper.Main_OnCommand(40754, 0) -- Enable snap

i = 1
while i <= mark_tot do

retval, isrgn, pos, rgnend, name, markrgnindexnumber = reaper.EnumProjectMarkers( i )

new_pos = reaper.SnapToGrid( 0, pos )

reaper.SetProjectMarker( markrgnindexnumber, false, new_pos, rgnend, name )

i = i + 1
end

reaper.UpdateTimeline()

reaper.Main_OnCommand(40756, 0) -- Restore snap state

