function Msg(param)
 reaper.ShowConsoleMsg(param.."\n")
end
-- USER AREA: Change "_S&M_CYCLACTION_2" & "_S&M_CYCLACTION_3" to whatever appropriate SWS cycle you want
cmdID = reaper.NamedCommandLookup( "_S&M_CYCLACTION_3" ) -- SWS Cycle for this script, Dfk Remove SM on Left Click
cmdIDcheck = reaper.NamedCommandLookup( "_S&M_CYCLACTION_2" )  -- SWS Cycle for the other script, Dfk Place SM on Left Click
------------------------------------------------------------------------------------------

if reaper.GetToggleCommandState( cmdIDcheck ) == 1 then -- Disable Auto-Project Crossfade 
reaper.Main_OnCommand(cmdIDcheck, 0)
end


function main()

window, segment, details = reaper.BR_GetMouseCursorContext()
if details == "item_stretch_marker" then
take, checkmouse_pos = reaper.BR_TakeAtMouseCursor()
item = reaper.GetMediaItemTake_Item( take )
item_group = reaper.GetMediaItemInfo_Value( item, "I_GROUPID" )
    if take ~= nil then
    smhoverID = reaper.BR_GetMouseCursorContext_StretchMarker()
        if reaper.JS_Mouse_GetState(1) == 1 and take ~= nil then
           reaper.DeleteTakeStretchMarkers( take, smhoverID)
           
             --Set group SM's
             if item_group ~= 0 then
             item_num = reaper.CountMediaItems( 0 )
             b = 0
                 while b < item_num do
                 check_item = reaper.GetMediaItem( 0, b )
                 check_group = reaper.GetMediaItemInfo_Value( check_item, "I_GROUPID" )
                     if check_group == item_group then
                     check_take = reaper.GetActiveTake( check_item )
                     reaper.DeleteTakeStretchMarkers( check_take, smhoverID)
                     end -- if check_group == item_group then
                 b = b + 1
                 end -- while b < item_num do
             end -- if item_group ~= 0 then
           
        end
    end
end



if reaper.GetToggleCommandState( cmdID ) == 1 then
reaper.Undo_OnStateChange( "Delete SM" )
reaper.defer(main)
end

end



main()

