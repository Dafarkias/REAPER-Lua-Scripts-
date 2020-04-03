function Msg(param)
reaper.ShowConsoleMsg(param.."\n")
end
i = 0
-- USER AREA: Change "_S&M_CYCLACTION_2" & "_S&M_CYCLACTION_3" to whatever appropriate SWS cycle you want
cmdID = reaper.NamedCommandLookup( "_S&M_CYCLACTION_2" )  -- SWS Cycle for this script, Dfk Place SM on Left Click
cmdIDcheck = reaper.NamedCommandLookup( "_S&M_CYCLACTION_3" )  -- SWS Cycle for this script, Dfk Remove SM on Left Click
------------------------------------------------------------------------------------------

if reaper.GetToggleCommandState( cmdIDcheck ) == 1 then -- Disable Auto-Project Crossfade 
reaper.Main_OnCommand(cmdIDcheck, 0)
end


function main()

take, checkmouse_pos = reaper.BR_TakeAtMouseCursor()

    if i == 0 then
        if reaper.JS_Mouse_GetState(1) == 1 and take ~= nil then
        item = reaper.GetMediaItemTake_Item( take )
        item_pos = reaper.GetMediaItemInfo_Value( item, "D_POSITION" )
        item_group = reaper.GetMediaItemInfo_Value( item, "I_GROUPID" )
        
        pos = reaper.BR_PositionAtMouseCursor( false )
        pos = pos - item_pos
        i = 30
        reaper.SetTakeStretchMarker( take, -1, pos)
            --Set group SM's
            if item_group ~= 0 then
            item_num = reaper.CountMediaItems( 0 )
            b = 0
                while b < item_num do
                check_item = reaper.GetMediaItem( 0, b )
                check_group = reaper.GetMediaItemInfo_Value( check_item, "I_GROUPID" )
                    if check_group == item_group then
                    check_take = reaper.GetActiveTake( check_item )
                    reaper.SetTakeStretchMarker( check_take, -1, pos)
                    end -- if check_group == item_group then
                b = b + 1
                end -- while b < item_num do
            end -- if item_group ~= 0 then
        
        end -- if reaper.JS_Mouse_GetState(1) == 1 and take ~= nil then
    end -- if i == 0 then
    
    if i > 0 then i = i - 1 end
    
    if reaper.GetToggleCommandState( cmdID ) == 1 then
    reaper.Undo_OnStateChange( "Place SM" )
    reaper.defer(main)
    end -- if reaper.GetToggleCommandState( cmdID ) == 1 then

end -- function main()



main()

