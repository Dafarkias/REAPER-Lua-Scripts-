--[[
 * ReaScript Name: Dfk Item Reader
 * About: Project workflow utility for reading media item information.
 * Author: Dfk
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: SWS/S&M 2.10.0, js_ReaScriptAPI .987
 * Version: 2.21
--]]
 
--[[
 * Changelog:
 * v1.01 (2020-04-03) 
    +Removed bug when selecting MIDI items
    +Buffed documentation
 * v2.0 (2020-04-03)
    +Added menus system
	+Added display hierachy capabilities
	+Feature: 'search' function (req. by lachinhan)
	+Feature: item replacement, item naming, and item quantization capabilities (req. by lachinhan)
	+Overhauled GUI
 * v2.01 (2020-04-03)
	+Added replacement capabilities for groups (limited)
	+Added undo points for non-colorization actions (use 'reset color/selection' to undo any colorization actions)
	+Buffed documentation
	+minor bug removal
 * v2.10 (2020-04-03)
	+Added proper reset for item colors when changing selection and exiting script
	+Added color gradient to hierarchy display
	+Feature: 'select/deselect all items' action button
	+Improved color contrasting of colorization actions and removed previous 'mode' limitations
	+Removed bugs from 'search' function and increased utilitarian intelligence
	+Removed empty-item bug selection bug
	+Simplified copy/replace menu options (same functionality, removed redundancy)
 * v2.2 (2020-04-03)
	+Added center-formatting to text
	+Added column-width customization and memory (req. by musicbynumbers)
	+Added: Highlight items listed in GUI when mouse is hovering over selected items in arrange
	+Added: Hold left-click on +/- font button for continuing adjustment
	+Feature: colorize action to colorize selected (GUI selection) items
	+Feature: right-click to edit selected item(s) data field (track, take name, src, pos, len, group)
	+Feature: rename item and include track name
	+Improved color contrast of colorization features (again)
	+Redesigned and reconstructed GUI
 * v2.21 (2020-04-03)
	+Added font-style options (req. by JamesPeters)
	+Fixed item colorization bug
--]]

local VERSION = "2.21"

--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA
--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA
local M_W_S = .1 -- Mouse Wheel Sensitivity... multiplaction based, so .1 is less sensitive than .9
--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA
--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA--USER AREA

function Msg(param) reaper.ShowConsoleMsg(tostring(param).."\n") end function Up() reaper.UpdateTimeline() end

local string1, string2 = {}, {}

--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON
string1[0] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[1] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[2] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[3] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[4] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[5] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,0,0,0,0,0,0,0,0,0}
string1[6] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,1.,1.,1.,1.,1.,1.,1.,1.,1.,1.,1.,1.,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,0,0,0}
string1[7] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,1.,1.,1.,1.,1.,1.,.64,.45,.13,.64,.45,.13,1.,1.,1.,1.,1.,1.,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31}
string1[8] = {0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,1.,1.,1.,1.,1.,1.,1.,1.,1.,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31}
string1[9] = {0,0,0,0,0,0,0,0,0,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,1.,1.,1.,1.,1.,1.,1.,1.,1.,1.,1.,1.,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,0,0,0}
string1[10] = {0,0,0,0,0,0,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,1.,1.,1.,1.,1.,1.,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,0,0,0}
string1[11] = {0,0,0,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31}
string1[12] = {.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,1.,1.,1.,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,.31,.31,.31,1.,1.,1.,.31,.31,.31}
string1[13] = {.31,.31,.31,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,1.,1.,1.,1.,1.,1.,1.,1.,1.,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,.31,.31,.31,1.,1.,1.,.31,.31,.31,0,0,0}
string1[14] = {.31,.31,.31,1.,1.,1.,.31,.31,.31,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,1.,1.,1.,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,.31,.31,.31,1.,1.,1.,.31,.31,.31,0,0,0,0,0,0}
string1[15] = {.31,.31,.31,1.,1.,1.,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,.31,.31,.31,1.,1.,1.,.31,.31,.31,0,0,0,0,0,0,0,0,0}
string1[16] = {0,0,0,.31,.31,.31,1.,1.,1.,1.,1.,1.,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,.31,.31,.31,1.,1.,1.,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0}
string1[17] = {0,0,0,0,0,0,.31,.31,.31,.31,.31,.31,1.,1.,1.,1.,1.,1.,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.64,.45,.13,.64,.45,.13,.64,.45,.13,.64,.45,.13,.31,.31,.31,.31,.31,.31,.31,.31,.31,1.,1.,1.,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[18] = {0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.31,.31,.31,1.,1.,1.,1.,1.,1.,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.64,.45,.13,.31,.31,.31,.31,.31,.31,.31,.31,.31,1.,1.,1.,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[19] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.31,.31,.31,1.,1.,1.,1.,1.,1.,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,.31,1.,1.,1.,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[20] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.31,.31,.31,1.,1.,1.,1.,1.,1.,.31,.31,.31,.31,.31,.31,1.,1.,1.,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[21] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.31,.31,.31,1.,1.,1.,1.,1.,1.,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[22] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,.31,.31,.31,.31,.31,.31,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
string1[23] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON--HELP_ICON

if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "Font"  ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "Font", 24,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W_W"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W_W",  w,   true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W_H"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W_H",  100, true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W_X"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W_X",  0,   true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W_Y"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W_Y",  0,   true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W_D"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W_D",  0,   true ) end
if type( tostring( reaper.GetExtState( "Dfk Item Reader", "F_S"   ) ) ) ~= 'string' then reaper.SetExtState( "Dfk Item Reader", "F_S",  "times new roman",   true ) end


--reaper.DeleteExtState( "Dfk Item Reader", "W1", true )reaper.DeleteExtState( "Dfk Item Reader", "W2", true ) reaper.DeleteExtState( "Dfk Item Reader", "W3", true ) reaper.DeleteExtState( "Dfk Item Reader", "W4", true ) reaper.DeleteExtState( "Dfk Item Reader", "W5", true ) reaper.DeleteExtState( "Dfk Item Reader", "W6", true ) reaper.DeleteExtState( "Dfk Item Reader", "W7", true ) reaper.DeleteExtState( "Dfk Item Reader", "X2", true ) reaper.DeleteExtState( "Dfk Item Reader", "X3", true ) reaper.DeleteExtState( "Dfk Item Reader", "X4", true ) reaper.DeleteExtState( "Dfk Item Reader", "X5", true ) reaper.DeleteExtState( "Dfk Item Reader", "X6", true ) reaper.DeleteExtState( "Dfk Item Reader", "X7", true )

if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W1"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W1",  100,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W2"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W2",  200,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W3"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W3",  200,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W4"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W4",  200,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W5"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W5",  200,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W6"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W6",  200,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "W7"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "W7",  200,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "X2"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "X2",  100,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "X3"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "X3",  300,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "X4"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "X4",  500,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "X5"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "X5",  700,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "X6"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "X6",  900,  true ) end
if type( tonumber( reaper.GetExtState( "Dfk Item Reader", "X7"   ) ) ) ~= 'number' then reaper.SetExtState( "Dfk Item Reader", "X7",  1100, true ) end

local i_nums = 0
local source = {}
local source_check = {}
local list = {}
local sort = {}
local button_folder = 1
local copy = {} 
local colord = {} local colordO = {}
local font_roll = 0 

local color_table = {}
color_table[1]  = {r = 255, g = 0,   b = 0} 
color_table[2]  = {r = 255, g = 128, b = 0} 
color_table[3]  = {r = 255, g = 255, b = 0} 
color_table[4]  = {r = 128, g = 255, b = 0} 
color_table[5]  = {r = 0,   g = 255, b = 0} 
color_table[6]  = {r = 0,   g = 255, b = 128} 
color_table[7]  = {r = 0,   g = 255, b = 255} 
color_table[8]  = {r = 0,   g = 128, b = 255} 
color_table[9]  = {r = 0,   g = 0,   b = 255} 
color_table[10] = {r = 127, g = 0,   b = 255} 
color_table[11] = {r = 255, g = 0,   b = 255} 
color_table[12] = {r = 255, g = 0,   b = 127} 

local font = tonumber( reaper.GetExtState( "Dfk Item Reader", "Font" ) ) local font_style = reaper.GetExtState( "Dfk Item Reader", "F_S" )
function get_font() return font end

local mouse_x, mouse_y = reaper.GetMousePosition() 
local caret = {} caret[0] = reaper.time_precise() caret[1] = 0 caret[2] = .3

--[[TOOLBARS (25) ]] local toolbar = {}
--HELP ICON
toolbar[1] = {name = "HELP", x = gfx.w-24, y = 3,  w = 24, h = 24, state = 0, bf = 1 }
--[[BUTTONS]] local button = {} 
--COLORIZE
button[1] = {name = "color^",                 x = 0,   y = gfx.h-font,     w = 120, h = font,   r = .2,  g = .6,  b = .8, bf = 1 }
--CLEAR
button[2] = {name = "clear",                  x = 0,   y = gfx.h-font,     w = 240, h = font,   r = .6,  g = .6,  b = .6, bf = 2  }
--COLORIZE
button[23] = {name = "colorize",              x = 0,   y = gfx.h-font,     w = 240, h = font,   r = .1,  g = .5,  b = .7, bf = 2 }
--SOURCES
button[3] = {name = "sources",                x = 0,   y = gfx.h-font,     w = 240, h = font,   r = .1,  g = .5,  b = .7, bf = 2  }
--IDENTICALS 
button[4] = {name = "identicals",             x = 0,   y = gfx.h-font,     w = 240, h = font,   r = .1,  g = .5,  b = .7, bf = 2  }
--DOCK
button[5] = {name = "dock",                   x = 480, y = gfx.h-font,     w = 120, h = font,   r = .8,  g = .5,  b = .3, bf = 1  } 
--FONT MINUS 
button[6] = {name = "(-)",                    x = 600, y = gfx.h-font,     w = 60,  h = font,   r = .2,  g = .2,  b = .2, bf = 1 }
--FONT 
button[24] = {name = "font",                  x = 660, y = gfx.h-font,     w = 120, h = font,   r = .5,  g = .5,  b = .5, bf = 1 }
--FONT PLUS
button[7] = {name = "(+)",                    x = 780, y = gfx.h-font,     w = 60,  h = font,   r = .8,  g = .8,  b = .8, bf = 1 }
--SEARCH
button[8] = {name = "search",                 x = 840, y = gfx.h-font,     w = 180, h = font,   r = .6,  g = .2,  b = .8, bf = 1 }
--REPLACE
button[9] = {name = "replace^",   					  x = 120, y = gfx.h-font,     w = 120, h = font,   r = .7,  g = .2,  b = .3, bf = 1 }
--RENAME
button[10] = {name = "name^",                 x = 240, y = gfx.h-font,     w = 120, h = font,   r = .3,  g = .6,  b = .2, bf = 1 }
--RENAME (WITH TRACK NAME)
button[11] = {name = "rename (w/t-name)",     x = 240, y = gfx.h-(font*5), w = 240, h = font,   r = .2,  g = .5,  b = .1, bf = 4 }
--RENAME WITH ITEM #
button[12] = {name = "rename (w/ item#)",     x = 240, y = gfx.h-(font*4), w = 240, h = font,   r = .2,  g = .5,  b = .1, bf = 4 }
--RENAME WITH TRACK #
button[13] = {name = "rename (w/ track#)",    x = 240, y = gfx.h-(font*3), w = 240, h = font,   r = .2,  g = .5,  b = .1, bf = 4 }
--RENAME WITH ITEM AND TRACK #
button[14] = {name = "rename (w/ i#&t#)",     x = 240, y = gfx.h-(font*2), w = 240, h = font,   r = .2,  g = .5,  b = .1, bf = 4 }
--RESET NAME
button[15] = {name = "reset to default",      x = 240, y = gfx.h-(font*6), w = 240, h = font,   r = .6,  g = .6,  b = .6, bf = 4 }
--COPY
button[16] = {name = "items selected)",       x = 1020, y = gfx.h-(font*5), w = 240, h = font,   r = .6,  g = .6,  b = .6, bf = 1 }
--REPLACE
button[17] = {name = "replace",               x = 120, y = gfx.h-(font*4), w = 240, h = font,   r = .6,  g = .1,  b = .2, bf = 3 }
--COPY
button[18] = {name = "copy",                  x = 120, y = gfx.h-(font*3), w = 240, h = font,   r = .4,  g = .3,  b = .8, bf = 3 }
--REPLACE GROUPS
button[19] = {name = "replace + group",    x = 120, y = gfx.h-(font*2), w = 240, h = font,   r = .6,  g = .1,  b = .2, bf = 3 }
--QUANTIZE
button[20] = {name = "quant.^",               x = 360, y = gfx.h-font,     w = 120, h = font,   r = .6,  g = .7,  b = .2, bf = 1 }
--QUANTIZE ENDS
button[21] = {name = "quant. ends",           x = 360, y = gfx.h-(font*3), w = 240, h = font,   r = .5,  g = .6,  b = .1, bf = 5 }
--QUANTIZE POSITION
button[22] = {name = "quant. position",       x = 360, y = gfx.h-(font*2), w = 240, h = font,   r = .5,  g = .6,  b = .1, bf = 5 }
--INPUT FONT
button[25] = {name = "input font",            x = 660, y = gfx.h-(font*2), w = 240, h = font,   r = .7,  g = .7,  b = .7, bf = 6 }
--TIMES NEW ROMAN
button[26] = {name = "times new roman",       x = 660, y = gfx.h-(font*2), w = 240, h = font,   r = .5,  g = .5,  b = .5, bf = 6 }
--ARIAL
button[27] = {name = "arial",                 x = 660, y = gfx.h-(font*2), w = 240, h = font,   r = .5,  g = .5,  b = .5, bf = 6 }
--CALIBRI
button[28] = {name = "calibri",             x = 660, y = gfx.h-(font*2), w = 240, h = font,   r = .5,  g = .5,  b = .5, bf = 6 }


if tonumber( reaper.GetExtState( "Dfk Item Reader", "W_D"   ) ) == 1 then button[5].name = "undock" end
--[[TITLES]] local title = {} local link = 0  
--ITEM NUMBER
title[1] = {mname =  "(T.I#)", name = "(T.I#)",      x=0,   y = 0,  w=tonumber( reaper.GetExtState( "Dfk Item Reader", "W1"   ) ), h = font, state = 0, bf = 1, min = 100 }
--TRACK NAME 
title[2] = {mname = "TRACK", name = "TRACK",     x=tonumber( reaper.GetExtState( "Dfk Item Reader", "X2"   ) ),  y = 0,  w=tonumber( reaper.GetExtState( "Dfk Item Reader", "W2"   ) ), h = font, state = 0, bf = 1, min = 200 }
--ITEM NAME
title[3] = {mname = "TAKE NAME", name = "TAKE NAME", x=tonumber( reaper.GetExtState( "Dfk Item Reader", "X3"   ) ),  y = 0,  w=tonumber( reaper.GetExtState( "Dfk Item Reader", "W3"   ) ), h = font, state = 0, bf = 1, min = 200 }
--SOURCE 
title[4] = {mname = "SRC. P.", name = "SRC. POS.", x=tonumber( reaper.GetExtState( "Dfk Item Reader", "X4"   ) ),  y = 0,  w=tonumber( reaper.GetExtState( "Dfk Item Reader", "W4"   ) ), h = font, state = 0, bf = 1, min = 100 }
--POSITION
title[5] = {mname = "POS.", name = "POSITION",  x=tonumber( reaper.GetExtState( "Dfk Item Reader", "X5"   ) ),  y = 0,  w=tonumber( reaper.GetExtState( "Dfk Item Reader", "W5"   ) ), h = font, state = 0, bf = 1, min = 100 }
--LENGTH 
title[6] = {mname = "LEN.", name = "LENGTH",    x=tonumber( reaper.GetExtState( "Dfk Item Reader", "X6"   ) ),  y = 0,  w=tonumber( reaper.GetExtState( "Dfk Item Reader", "W6"   ) ), h = font, state = 0, bf = 1, min = 100 }
--GROUP 
title[7] = {mname = "GR.", name = "GROUP",     x=tonumber( reaper.GetExtState( "Dfk Item Reader", "X7"   ) ),  y = 0,  w=tonumber( reaper.GetExtState( "Dfk Item Reader", "W7"   ) ), h = font, state = 0, bf = 1, min = 100 }

local click = 0
local search_input = false

function update_vars() gfx.setfont(1, font_style, font, 98 )
	button[1].y =  gfx.h-font button[1].h = font--COLORIZE
	button[2].y =  gfx.h-(font*5) button[2].h = font--CLEAR
	button[23].y = gfx.h-(font*4) button[23].h = font--COLORIZE
	button[3].y =  gfx.h-(font*3) button[3].h = font--SOURCES
	button[4].y =  gfx.h-(font*2) button[4].h = font--IDENTICALS
	button[5].y =  gfx.h-font button[5].h  = font--DOCK
	button[6].y =  gfx.h-font button[6].h  = font--FONT-
	button[24].y = gfx.h-font button[24].h  = font--FONT
	button[7].y =  gfx.h-font button[7].h  = font--FONT+
	button[8].y =  gfx.h-font button[8].h  = font--SEARCH
	button[9].y =  gfx.h-font button[9].h  = font--REPLACE
	button[10].y = gfx.h-font button[10].h = font--RENAME
	button[12].y = gfx.h-(font*5) button[12].h = font--RENAME WITH ITEM #
	button[13].y = gfx.h-(font*4) button[13].h = font--RENAME WITH TRACK #
	button[14].y = gfx.h-(font*3) button[14].h = font--RENAME WITH ITEM AND TRACK #
	button[11].y = gfx.h-(font*2) button[11].h = font--RENAME WITH TRACK NAME
	button[15].y = gfx.h-(font*6) button[15].h = font--RESET NAME
	button[16].y = gfx.h-font     button[16].h = font button[16].w = gfx.w-(button[8].x+button[8].w) --QUICK SELECT
	local sloct = false for a = 1, #list do if list[sort[a].orig].sel ~= nil then sloct = true end end if sloct == true then button[16].name = "deselect all ("..#sort..") items listed" --QUICK SELECT 
	else button[16].name = "select all ("..#sort..") items listed" end --QUICK SELECT
	button[17].y = gfx.h-(font*3) button[17].h = font--REPLACE
	button[18].y = gfx.h-(font*4) button[18].h = font--COPY
	button[19].y = gfx.h-(font*2) button[19].h = font--REPLACE WITH GROUP
	button[20].y = gfx.h-font     button[20].h = font--QUANTIZE
	button[21].y = gfx.h-(font*3)     button[21].h = font--QUANTIZE ENDS
	button[22].y = gfx.h-(font*2)     button[22].h = font--QUANTIZE POSITION
	button[25].y = gfx.h-(font*5)     button[25].h = font--INPUT FONT
	button[26].y = gfx.h-(font*4)     button[26].h = font--TIMES NEW ROMAN
	button[27].y = gfx.h-(font*3)     button[27].h = font--ARIAL
	button[28].y = gfx.h-(font*2)     button[28].h = font--CALIBRI


	title[1].h = font
	title[2].h = font
	title[3].h = font
	title[4].h = font
	title[5].h = font
	title[6].h = font
	title[7].h = font
	
	toolbar[1].x = gfx.w-24
	
	get_list()
	
end

function check_mousewheel()
		if click == 2 
	then local scale_a = font+12 local scale_z = gfx.h-font-12 local mousey = gfx.mouse_y if mousey > scale_z then mousey = scale_z elseif mousey < scale_a then mousey = scale_a end
		local ratio = (mousey-scale_a)/(scale_z-scale_a)
		gfx.mouse_wheel = ( ( ( ( #list+3 )*font )-gfx.h )/M_W_S )*ratio
	end
		if click == 3 or click == 4 
	then
		if gfx.mouse_y < font then gfx.mouse_wheel=gfx.mouse_wheel-45 end
		if gfx.mouse_y > gfx.h-font then gfx.mouse_wheel=gfx.mouse_wheel+45 end
	end
		if (gfx.mouse_wheel*M_W_S) > ((#list+3)*font )-gfx.h 
  then
    gfx.mouse_wheel = ( ( ( #list+3 )*font )-gfx.h )/M_W_S 
  end
   if gfx.mouse_wheel < 0 or ( #list+3 )*font < gfx.h
  then
    gfx.mouse_wheel = 0 
  end
	
	click_action()
	
end

function click_action() if #sort == 0 then end  

	--[[SET/CHECK WINDOW FOCUS]] 
		if gfx.mouse_x > 0 and gfx.mouse_x < gfx.w and gfx.mouse_y > 0 and gfx.mouse_y < gfx.h and reaper.JS_Window_FromPoint( mouse_x, mouse_y ) == reaper.JS_Window_Find( "Dfk Item Reader", 1 )
  then
    reaper.JS_Window_SetFocus( reaper.JS_Window_Find( "Dfk Item Reader", 1 ) ) 
  else
    if click == 0 then return draw() end
  end

	--[[SCROLLBAR]] local scroll_pos = (font+((gfx.h-(font*2)-24)*(gfx.mouse_wheel/((((#list+3)*font)-gfx.h)/M_W_S ))))
		if gfx.mouse_x > gfx.w-24 and gfx.mouse_x < gfx.w and gfx.mouse_y > font and gfx.mouse_y < gfx.h-font and reaper.JS_Mouse_GetState(1) == 1 and button_folder == 1
	then 
		click = 2
	end
	
	--[[RIGHT-CLICK-EDIT]]
	local how_many = 0
	for b = 1, #sort do if list[sort[b].orig].sel then how_many = how_many + 1 end end 
		if how_many > 0
	then
			for a = 2, #title
		do 
				if click == 0 and reaper.JS_Mouse_GetState(2) == 2 and gfx.mouse_x > title[a].x and gfx.mouse_x < title[a].x+title[a].w and gfx.mouse_y > font and gfx.mouse_y < gfx.h-font
			then click = 1000
					if a == 2 -- EDIT TRACK
				then reaper.Undo_BeginBlock() local track_it = ""
					for h = 1, #sort do if list[sort[h].orig].sel then  track_it = list[sort[h].orig].tname end end 
					local retval, retvals_csv = reaper.GetUserInputs("("..how_many..") item(s) selected", 1, "Input track name(s):", track_it ) 
						for h = 1, #sort 
					do if retval == false then break end 
						if list[sort[h].orig].sel then reaper.GetSetMediaTrackInfo_String(  reaper.GetMediaItem_Track( list[sort[h].orig].item ), "P_NAME", retvals_csv, true ) end 
					end  
					Up() reaper.Undo_EndBlock( "Dfk Item Reader: Track Rename", 1 ) Up()
				end
					if a == 3 -- EDIT TAKE NAME
				then reaper.Undo_BeginBlock() local track_it = ""
						for h = 1, #sort do if list[sort[h].orig].sel then track_it = list[sort[h].orig].iname end end 
					local retval, retvals_csv = reaper.GetUserInputs("("..how_many..") item(s) selected", 1, "Input item name(s):", track_it ) 
						for h = 1, #sort 
					do if retval == false then break end 
						if list[sort[h].orig].sel then reaper.GetSetMediaItemTakeInfo_String( reaper.GetActiveTake( list[sort[h].orig].item ), "P_NAME", retvals_csv, true ) end 
					end  
					Up() reaper.Undo_EndBlock( "Dfk Item Reader: Item Rename", 4 ) Up() 
				end
					if a == 4 -- EDIT SRC
				then reaper.Undo_BeginBlock() local track_it = ""
						for h = 1, #sort do if list[sort[h].orig].sel then track_it = list[sort[h].orig].src end end 
					local retval, retvals_csv = reaper.GetUserInputs("("..how_many..") item(s) selected", 1, "Input item(s') SRC:", track_it ) 
						for h = 1, #sort 
					do if retval == false then break end 
						if list[sort[h].orig].sel and type( tonumber( retvals_csv ) ) == 'number' then reaper.SetMediaItemTakeInfo_Value( reaper.GetActiveTake(list[sort[h].orig].item), "D_STARTOFFS", tonumber( retvals_csv ) ) end 
					end  
					Up() reaper.Undo_EndBlock( "Dfk Item Reader: Change Item Source Position", 4 ) Up() 
				end
					if a == 5 -- EDIT POS
				then reaper.Undo_BeginBlock() local track_it = ""
						for h = 1, #sort do if list[sort[h].orig].sel then track_it = list[sort[h].orig].pos end end 
					local retval, retvals_csv = reaper.GetUserInputs("("..how_many..") item(s) selected", 1, "Input item(s') POS:", track_it ) 
						for h = 1, #sort 
					do if retval == false then break end 
						if list[sort[h].orig].sel and type( tonumber( retvals_csv ) ) == 'number' then  reaper.SetMediaItemInfo_Value( list[sort[h].orig].item, "D_POSITION", tonumber( retvals_csv ) ) end 
					end  
					Up() reaper.Undo_EndBlock( "Dfk Item Reader: Change Item Position", 4 ) Up() 
				end
					if a == 6 -- EDIT LEN
				then reaper.Undo_BeginBlock() local track_it = ""
						for h = 1, #sort do if list[sort[h].orig].sel then track_it = list[sort[h].orig].len end end 
					local retval, retvals_csv = reaper.GetUserInputs("("..how_many..") item(s) selected", 1, "Input item(s') LEN:", track_it ) 
						for h = 1, #sort 
					do if retval == false then break end 
						if list[sort[h].orig].sel and type( tonumber( retvals_csv ) ) == 'number' then  reaper.SetMediaItemInfo_Value( list[sort[h].orig].item, "D_LENGTH", tonumber( retvals_csv ) ) end 
					end  
					Up() reaper.Undo_EndBlock( "Dfk Item Reader: Change Item Length", 4 ) Up() 
				end
					if a == 7 -- EDIT GROUP
				then reaper.Undo_BeginBlock() local track_it = ""
						for h = 1, #sort do if list[sort[h].orig].sel then track_it = list[sort[h].orig].group end end if track_it == "" then break end
					local retval, retvals_csv = reaper.GetUserInputs("("..how_many..") item(s) selected", 1, "Input item(s') GROUP:", track_it ) 
						for h = 1, #sort 
					do if retval == false then break end  
						if list[sort[h].orig].sel and type( tonumber( retvals_csv ) ) == 'number' then  reaper.SetMediaItemInfo_Value( list[sort[h].orig].item, "I_GROUPID", tonumber( retvals_csv ) ) end 
					end  
					Up() reaper.Undo_EndBlock( "Dfk Item Reader: Change Item Group", 4 ) Up() 
				end
			end
		end
	end -- end of right-click-edit
	
	--[[BUTTON]]
		for a = 1, #button
	do 
		
			if gfx.mouse_x > button[a].x and gfx.mouse_x < button[a].x+button[a].w and gfx.mouse_y > button[a].y and gfx.mouse_y < button[a].y+button[a].h 
		then 
			--FONT MINUS
			if a == 6 and font > 16 and click == 55 and reaper.time_precise() > font_roll then font = font - 1 reaper.SetExtState( "Dfk Item Reader", "Font", font, true ) gfx.mouse_wheel = 0 font_roll = reaper.time_precise()+.07 end
			--FONT PLUS
			if a == 7 and font < 34 and click == 56 and reaper.time_precise() > font_roll then font = font + 1 reaper.SetExtState( "Dfk Item Reader", "Font", font, true ) gfx.mouse_wheel = 0 font_roll = reaper.time_precise()+.07 end
	
				if search_input == false and reaper.JS_Mouse_GetState(1) == 1 
			then
				--COLOURIZE
				if a == 1 then button_folder = 2 end
				--REPLACE
				if a == 9 then button_folder = 3 end
				--RENAME
				if a == 10 then button_folder = 4 end
				--RENAME
				if a == 20 then button_folder = 5 end
				--FONT
				if a == 24 then button_folder = 6 end
			end
			--CLICK
				if reaper.JS_Mouse_GetState(1) == 1 and click == 0 and button_folder == button[a].bf
			then click = 1 if a ~= 8 then search_input = false end
				--DOCK
					if a == 5
				then
					if tonumber( reaper.GetExtState( "Dfk Item Reader", "W_D" ) ) == 0 then reaper.SetExtState( "Dfk Item Reader", "W_D", 1, 1 ) button[5].name = "undock" else reaper.SetExtState( "Dfk Item Reader", "W_D", 0, 1 ) button[5].name = "dock" end
					gfx.dock(tonumber( reaper.GetExtState( "Dfk Item Reader", "W_D"   ) ), tonumber( reaper.GetExtState( "Dfk Item Reader", "W_X"   ) ), tonumber( reaper.GetExtState( "Dfk Item Reader", "W_Y" ) ), tonumber( reaper.GetExtState( "Dfk Item Reader", "W_W" ) ), tonumber( reaper.GetExtState( "Dfk Item Reader", "W_H" ) ) )
				end
				--FONT MINUS
				if a == 6 and font > 16 then font = font - 1 reaper.SetExtState( "Dfk Item Reader", "Font", font, true ) gfx.mouse_wheel = 0 click = 55 font_roll = reaper.time_precise()+.45 end
				--FONT PLUS
				if a == 7 and font < 34 then font = font + 1 reaper.SetExtState( "Dfk Item Reader", "Font", font, true ) gfx.mouse_wheel = 0 click = 56 font_roll = reaper.time_precise()+.45 end
				--SEARCH
				if a == 8 
				then 
						if link == 0 
					then  
						reaper.MB( "In order to search your item list, choose a search method by clicking on a title header, like 'TRACK,' 'TAKE NAME,' or 'GROUP.'", "[error]", 0 ) 
					end
						if search_input == false and link ~= 0 
					then 
						search_input = true 
					else 
						search_input = false 
					end 
				end 
				--QUICK SELECT
					if a == 16
				then local slecter = false
					for q = 1, #list do if list[sort[q].orig].sel ~= nil then slecter = true end end
						for q = 1, #list 
					do 
							if slecter == true 
						then 
							list[sort[q].orig].sel = nil 
						else 
							list[sort[q].orig].sel = 1 
						end 
					end
				end 

			end --END OF CLICK
			--UNCLICK
				if reaper.JS_Mouse_GetState(1) == 0 and click == 1 and button_folder == button[a].bf and button_folder ~= 1
			then click = 0 button_folder = 1 
				local sel_count = 0 for h = 1, #list do if list[h].sel == 1 then sel_count = 1 break end end 
				if sel_count == 0 and a ~= 2 and a ~= 25 and a ~= 26 and a ~= 27 and a ~= 28 then reaper.MB( "Please select an item inside the Item Reader GUI.", "[error]", 0 ) goto end_unclick end
				
				--RESET
					if a == 2 
				then 
					colord = nil colord = {} colordO = nil colordO = {} 
				end 
				--COLORIZE
					if a == 23 
				then local retvaler, colorer = reaper.GR_SelectColor( reaper.GetMainHwnd() )
						if retvaler ~= 0 and retvaler ~= nil 
					then reaper.Undo_BeginBlock() colord = nil colord = {} colordO = nil colordO = {} 
							for h = 1, #sort 
						do if retval == false then break end 
							if list[sort[h].orig].sel then reaper.SetMediaItemInfo_Value( list[sort[h].orig].item , "I_CUSTOMCOLOR", colorer ) list[sort[h].orig].color = colorer sort[h].color = colorer list[h].sel = nil end 
						end 
						reaper.Undo_OnStateChange2( 0, "Dfk Item Reader: Colorize" ) reaper.Undo_EndBlock( "Dfk Item Reader: Colorize", 8 ) Up()
					end
				end 
				--SOURCES
					if a == 3 
				then colord = nil colord = {} colordO = nil colordO = {} local data = {} local good = {}
					for k = 1, #sort
				do
					list[k].sel = nil colord[k] = reaper.ColorToNative( 0, 0, 0 ) colordO[k] = reaper.ColorToNative( 0, 0, 0 ) 
				end
						for e = 1, #sort
					do 
						data[e] = {iname = sort[e].iname, orig = -1}
					end
						for e = 1, #sort
					 do
							for f = 1, #sort
						do
							if e~=f and data[e].iname == data[f].iname 
							then local goahead = true 
									for g = 1, #good
								do
										if good[g].iname == data[e].iname
									then
										data[f].orig = g goahead = false
									end
								end
									if goahead == true 
								then
									good[#good+1] = data[f] data[f].orig = #good
								end
							end
						end
					 end
					 
					 --Msg(#good)
						for p = 1, #data
					 do 
						if data[p].orig ~= -1
						then local color_level = 0 local IDD = data[p].orig while IDD > 12 do IDD = IDD - 12 color_level = color_level + 1 end
						
							local rr, gg, bb = color_table[IDD].r,color_table[IDD].g,color_table[IDD].b
							for z = 1, color_level do rr, gg, bb = rr*1.25, gg*1.25, bb*1.25 end 
							
							local colour = reaper.ColorToNative( math.floor(rr), math.floor(gg), math.floor(bb) ) 

							colord[p] = colour
							colordO[p] = colour
						  --Msg(p..": data ("..data[p].orig..")")
						end
					end
					Up() 
					
				end
				--IDENTICALS
					if a == 4 
				then colord = nil colord = {} colordO = nil colordO = {} local data = {} local good = {}
					for k = 1, #sort
				do
					list[k].sel = nil colord[k] = reaper.ColorToNative( 0, 0, 0 ) colordO[k] = reaper.ColorToNative( 0, 0, 0 ) 
				end
						for e = 1, #sort
					do 
						data[e] = {iname = sort[e].iname, src = sort[e].src, orig = -1}
					end
						for e = 1, #sort
					 do
							for f = 1, #sort
						do
							if e~=f and data[e].iname == data[f].iname and data[e].src == data[f].src
							then local goahead = true 
									for g = 1, #good
								do
										if good[g].iname == data[e].iname and good[g].src == data[e].src
									then
										data[f].orig = g goahead = false
									end
								end
									if goahead == true 
								then
									good[#good+1] = data[f] data[f].orig = #good
								end
							end
						end
					 end
					 
						for p = 1, #data
					 do 
						if data[p].orig ~= -1
						then local color_level = 0 local IDD = data[p].orig while IDD > 12 do IDD = IDD - 12 color_level = color_level + 1 end
						
							local rr, gg, bb = color_table[IDD].r,color_table[IDD].g,color_table[IDD].b
							for z = 1, color_level do rr, gg, bb = rr*1.25, gg*1.25, bb*1.25 end 
							
							local colour = reaper.ColorToNative( math.floor(rr), math.floor(gg), math.floor(bb) ) 

							colord[p] = colour
							colordO[p] = colour
						  --Msg(p..": data ("..data[p].orig..")")
						end
					end
					Up() 
					
				end
				--RENAME WITH TRACK NAME
					if a == 11 
				then local retval, retvals_csv = reaper.GetUserInputs( "[user input]", 1, "Input name/title:", "" ) if retval ~= false then reaper.Undo_BeginBlock() end
						for h = 1, #sort 
					do if retval == false then break end 
						local _, boof = reaper.GetTrackName( reaper.GetMediaItemTrack( list[sort[h].orig].item ) )
						if list[sort[h].orig].sel then reaper.GetSetMediaItemTakeInfo_String( reaper.GetActiveTake( list[sort[h].orig].item ), "P_NAME", boof..", "..retvals_csv, 1 ) end 
					end  
					reaper.Undo_OnStateChange2( 0, "Dfk Item Reader: Rename" ) reaper.Undo_EndBlock( "Dfk Item Reader: Rename", 8 ) Up()
				end 
				--RENAME WITH ITEM #
					if a == 12
				then local retval, retvals_csv = reaper.GetUserInputs( "[user input]", 1, "Input name/title:", "" ) if retval ~= false then reaper.Undo_BeginBlock() end
						for h = 1, #sort 
					do if retval == false then break end 
						if list[sort[h].orig].sel then reaper.GetSetMediaItemTakeInfo_String( reaper.GetActiveTake( list[sort[h].orig].item ), "P_NAME", retvals_csv.."("..tostring(math.floor(reaper.GetMediaItemInfo_Value( list[sort[h].orig].item, "IP_ITEMNUMBER" )+1))..")", 1 ) end 
					end 
					reaper.Undo_OnStateChange2( 0, "Dfk Item Reader: Rename w/ item#" ) reaper.Undo_EndBlock( "Dfk Item Reader: Rename w/ item#", 8 ) Up()
				end 
				--RENAME WITH TRACK #
					if a == 13   
				then local retval, retvals_csv = reaper.GetUserInputs( "[user input]", 1, "Input name/title:", "" ) if retval ~= false then reaper.Undo_BeginBlock() end
						for h = 1, #sort 
					do if retval == false then break end 
						if list[sort[h].orig].sel then reaper.GetSetMediaItemTakeInfo_String( reaper.GetActiveTake( list[sort[h].orig].item ), "P_NAME", retvals_csv.."("..tostring( math.floor ( reaper.GetMediaTrackInfo_Value(  reaper.GetMediaItem_Track( list[sort[h].orig].item ), "IP_TRACKNUMBER" ) ) )..")", 1 ) end
					end 
					reaper.Undo_OnStateChange2( 0, "Dfk Item Reader: Rename w/ track#" ) reaper.Undo_EndBlock( "Dfk Item Reader: Rename w/ track#", 8 ) Up()
				end 
				--RENAME WITH ITEM & TRACK #
					if a == 14
				then local retval, retvals_csv = reaper.GetUserInputs( "[user input]", 1, "Input name/title:", "" ) if retval ~= false then reaper.Undo_BeginBlock() end
						for h = 1, #sort 
					do if retval == false then break end 
						if list[sort[h].orig].sel then reaper.GetSetMediaItemTakeInfo_String( reaper.GetActiveTake( list[sort[h].orig].item ), "P_NAME", retvals_csv.."("..tostring( math.floor( reaper.GetMediaTrackInfo_Value(  reaper.GetMediaItem_Track( list[sort[h].orig].item ), "IP_TRACKNUMBER" ) ) )..")".."("..tostring(math.floor(reaper.GetMediaItemInfo_Value( list[sort[h].orig].item, "IP_ITEMNUMBER" )+1))..")", 1 ) end
					end 
					reaper.Undo_OnStateChange2( 0, "Dfk Item Reader: Rename w/ item & track#" ) reaper.Undo_EndBlock( "Dfk Item Reader: Rename w/ item & track#", 8 ) Up()
				end 
				--RESET NAME
					if a == 15
				then reaper.Undo_BeginBlock()
						for h = 1, #sort 
					do 
							if list[sort[h].orig].sel
						then --reaper.GetSetMediaItemTakeInfo_String( reaper.GetActiveTake( sel[h] ), "P_NAME", retvals_csv, 1 ) 
							local filenamebuf = reaper.GetMediaSourceFileName(  reaper.GetMediaItemTake_Source( reaper.GetActiveTake( list[sort[h].orig].item ) ), "" ) filenamebuf = string.reverse(filenamebuf)
							local it = string.find(filenamebuf, "\\") local dot = string.find(filenamebuf, "%.") filenamebuf = string.reverse( string.sub(filenamebuf, dot+1, it-1) ) 
							reaper.GetSetMediaItemTakeInfo_String( reaper.GetActiveTake( list[sort[h].orig].item ), "P_NAME", filenamebuf, 1 )
						end
					end 
					reaper.Undo_OnStateChange2( 0, "Dfk Item Reader: Reset item(s) name" ) reaper.Undo_EndBlock( "Dfk Item Reader: Reset item(s) name", 8 ) Up()
				end 
				--REPLACE SELECTED
					if a == 17
				then 
						if copy[1] == nil 
					then
						reaper.MB( "Please copy an item before attempting to paste.", "[error]", 0 )
					else reaper.Undo_BeginBlock()
							for h = 1, #sort 
						do 
								if list[sort[h].orig].sel
							then 
								 reaper.SetMediaItemTake_Source( reaper.GetActiveTake( list[sort[h].orig].item ), copy[1].source )
								 reaper.SetMediaItemInfo_Value( list[sort[h].orig].item, "D_LENGTH", reaper.GetMediaItemInfo_Value( copy[1].item, "D_LENGTH" ) )
								 reaper.SetMediaItemInfo_Value( list[sort[h].orig].item, "I_GROUPID", reaper.GetMediaItemInfo_Value( copy[1].item, "I_GROUPID" ) )
								 reaper.SetMediaItemInfo_Value( list[sort[h].orig].item, "I_CUSTOMCOLOR", reaper.GetTrackColor( reaper.GetMediaItem_Track( list[sort[h].orig].item ) ) )    
								 reaper.SetMediaItemTakeInfo_Value( reaper.GetActiveTake( list[sort[h].orig].item ), "D_STARTOFFS", reaper.GetMediaItemTakeInfo_Value( reaper.GetActiveTake( copy[1].item ), "D_STARTOFFS" ) )
							end 
						end 
						reaper.Undo_OnStateChange2( 0, "Dfk Item Reader: Paste item(s)" ) reaper.Undo_EndBlock( "Dfk Item Reader: Paste item(s)", 8 )
					end
					Up()
				end 
				--COPY
					if a == 18
				then local sel_count = 0 
						for h = 1, #sort 
					do 
							if list[sort[h].orig].sel 
						then sel_count = sel_count + 1
							copy[1] = {source = reaper.GetMediaItemTake_Source( reaper.GetActiveTake( list[sort[h].orig].item ) ), item = list[sort[h].orig].item }
						end 
					end 
						if sel_count > 1
					then
						copy = nil copy = {} reaper.MB( "Copy only one item at a time. Multiple item selection is not currently supported.", "[error]", 0 )
					elseif sel_count == 1 then
							for h = 1,  reaper.CountMediaItems( 0 )
						do
								if reaper.GetMediaItemInfo_Value( copy[1].item, "I_GROUPID" ) ==  reaper.GetMediaItemInfo_Value( reaper.GetMediaItem( 0, h-1 ), "I_GROUPID" ) and reaper.GetActiveTake( reaper.GetMediaItem( 0, h-1 ) ) and copy[1].item ~= reaper.GetMediaItem( 0, h-1 ) and reaper.GetMediaItemInfo_Value( copy[1].item, "I_GROUPID" ) ~= 0
							then
								copy[#copy+1] = { item = reaper.GetMediaItem( 0, h-1 ), source = reaper.GetMediaItemTake_Source( reaper.GetActiveTake( reaper.GetMediaItem( 0, h-1 ) ) ) }
							end
						end
						reaper.MB( "Copied "..#copy.." item(s) successfully!", "[message]", 0 )
					end
					Up()
				end 
				--REPLACE AND GROUP
					if a == 19
				then 
						if copy[1] == nil 
					then
						reaper.MB( "Please copy an item before attempting to paste.", "[error]", 0 )
					else reaper.Undo_BeginBlock()
							for h = 1, #sort 
						do 
								if list[sort[h].orig].sel 
							then local x_counter = 1
									for i = 1,  reaper.CountMediaItems( 0 )
								do 
										if reaper.GetMediaItemInfo_Value( list[sort[h].orig].item, "I_GROUPID" ) == reaper.GetMediaItemInfo_Value( reaper.GetMediaItem( 0, i-1 ), "I_GROUPID" )
									then 
										reaper.SetMediaItemTake_Source( reaper.GetActiveTake( reaper.GetMediaItem( 0, i-1 ) ), copy[x_counter].source )
										reaper.SetMediaItemInfo_Value( reaper.GetMediaItem( 0, i-1 ), "D_LENGTH", reaper.GetMediaItemInfo_Value( copy[x_counter].item, "D_LENGTH" ) )
										--reaper.SetMediaItemInfo_Value( sel[h], "I_GROUPID", reaper.GetMediaItemInfo_Value( copy[x_counter].item, "I_GROUPID" ) )
										reaper.SetMediaItemInfo_Value( reaper.GetMediaItem( 0, i-1 ), "I_CUSTOMCOLOR", reaper.GetTrackColor( reaper.GetMediaItem_Track( reaper.GetMediaItem( 0, i-1 ) ) ) )    
										reaper.SetMediaItemTakeInfo_Value( reaper.GetActiveTake( reaper.GetMediaItem( 0, i-1 ) ), "D_STARTOFFS", reaper.GetMediaItemTakeInfo_Value( reaper.GetActiveTake( copy[x_counter].item ), "D_STARTOFFS" ) )
										x_counter = x_counter + 1
									end if x_counter > #copy then break end
								end
							end 
						end 
						reaper.Undo_OnStateChange2( 0, "Dfk Item Reader: Paste item(s) + group" ) reaper.Undo_EndBlock( "Dfk Item Reader: Paste item(s) + group", 8 )
					end
					Up()
				end 
				--QUANTIZE ENDS
					if a == 21
				then reaper.Undo_BeginBlock()
						for h = 1, #sort 
					do   
							if list[sort[h].orig].sel 
						then
							reaper.BR_SetItemEdges( list[sort[h].orig].item, reaper.BR_GetClosestGridDivision( reaper.GetMediaItemInfo_Value( list[sort[h].orig].item, "D_POSITION" ) ), reaper.BR_GetClosestGridDivision( ( reaper.GetMediaItemInfo_Value( list[sort[h].orig].item, "D_POSITION" )+reaper.GetMediaItemInfo_Value( list[sort[h].orig].item, "D_LENGTH" ) ) ) )
						end
					end reaper.Undo_OnStateChange2( 0, "Dfk Item Reader: Quantize item(s) ends" ) reaper.Undo_EndBlock( "Dfk Item Reader: Quantize item(s) ends", 8 )
					Up()
				end
				--QUANTIZE POSITION
					if a == 22
				then reaper.Undo_BeginBlock()   
						for h = 1, #sort 
					do   
							if list[sort[h].orig].sel
						then 
							reaper.SetMediaItemPosition( list[sort[h].orig].item, reaper.BR_GetClosestGridDivision( reaper.GetMediaItemInfo_Value( list[sort[h].orig].item, "D_POSITION" ) ), false )
						end
					end reaper.Undo_OnStateChange2( 0, "Dfk Item Reader: Quantize item(s) position" ) reaper.Undo_EndBlock( "Dfk Item Reader: Quantize item(s) position", 8 )
					Up()
				end
				--INPUT FONT
					if a == 25
				then local retval, retvals_csv = reaper.GetUserInputs( "[user input]", 1, "Input font name:", "" )
						if pcall(function ()gfx.setfont(1, retvals_csv, font, 98 ) end ) == true
					then
						font_style = retvals_csv
					end
				end 
				--TIMES NEW ROMAN
					if a == 26 and pcall(function ()gfx.setfont(1, "times new roman", font, 98 ) end ) == true
				then
					font_style = "times new roman"
				end 
				--ARIAL
					if a == 27 and pcall(function ()gfx.setfont(1, "arial", font, 98 ) end ) == true
				then
					font_style = "arial"
				end 
				--CALIBRI
					if a == 28 and pcall(function ()gfx.setfont(1, "calibri", font, 98 ) end ) == true
				then
					font_style = "calibri"
				end 
				
				::end_unclick::
				
			end--END OF UNCLICK
	
		end
	end
	--[[TITLE]] local cursor_change = false
		if button_folder == 1
	then
			for a = 1, #title
		do 
				if gfx.mouse_x > title[a].x+title[a].w-7 and gfx.mouse_x < title[a].x+title[a].w+7 and gfx.mouse_y > 0 and gfx.mouse_y < gfx.h-font --and reaper.JS_Mouse_GetState(1) == 1 and click == 0 
			then
				gfx.setcursor( 1, "arrange_dualedge" ) cursor_change = true
			end
			if gfx.mouse_x > title[a].x+title[a].w-7 and gfx.mouse_x < title[a].x+title[a].w+7 and gfx.mouse_y > 0 and gfx.mouse_y < gfx.h-font and reaper.JS_Mouse_GetState(1) == 1 and click == 0 then click = a+100 end
				if click-100 == a 
			then local origger = 0 
					if gfx.mouse_x-title[a].x > title[a].min
				then
					origger = title[a].w
					title[a].w = gfx.mouse_x-title[a].x
				else 
					origger = title[a].w
					title[a].w = title[a].min
				end
					for l = 2, #title
				do
						if l > a
					then
						title[l].x = title[l].x + title[a].w-origger
					end
				end
			end
				if gfx.mouse_x > title[a].x and gfx.mouse_x < title[a].x+title[a].w and gfx.mouse_y > title[a].y and gfx.mouse_y < title[a].y+font and reaper.JS_Mouse_GetState(1) == 1 and click == 0 
			then click = 1 search_input = false link = a
				for b = 1, #title do if b ~= a then title[b].state = 0 end end -- CLEAR STATES
				if title[a].state == 0 then title[a].state = 2 elseif title[a].state == 2 then title[a].state = 1 elseif title[a].state == 1 then title[a].state = 0 link = 0 end --SET STATE
				gfx.mouse_wheel = 0 --RESET SCROLL
			end
		end
		if cursor_change == false then gfx.setcursor( 0 ) end
	end
	--[[TOOLBAR]]
		for a = 1, #toolbar
	do 
			if gfx.mouse_x > toolbar[a].x and gfx.mouse_x < toolbar[a].x+toolbar[a].w and gfx.mouse_y > toolbar[a].y and gfx.mouse_y < toolbar[a].y+toolbar[a].h and reaper.JS_Mouse_GetState(1) == 1 and click == 0 and button_folder == 1
		then click = 1 search_input = false
				if a == 1 
			then 
				reaper.MB("This script is designed to assist in the editing and processing of REAPER's items. This script includes a GUI that shows a layout of information regarding your current selection of media items.\n\n"..

				"In order to perform any of the script-actions--'group,' 'replace,' 'rename,' or 'quantize,'--you must first select items within the GUI list by clicking on them.\n\nItems may be unselected at any time by clicking on them again, and you can also select/deselect all items in the GUI list by pressing Ctrl+a while the script GUI has mouse-cursor focus. If you click and hold on a listed item, you can mass select/deselect by dragging mouse cursor either up or down.\n\nNOTE:\n\nIn order for the colorize features in this script to operate properly, 'Tint media item background to item color' setting under Appearance>Peaks/Waveforms must be enabled.\n\nFIELD EDITING:\n\nWith any number of items selected in your GUI list, right-click while hovering the mouse in the section of the desired value you would like to edit (e.g., track, take name, src. pos., pos., len., group ). All items selected will receive the input of a successful data entry."
				
				, "[Dfk's Item Reader v"..VERSION.."]", 0) 

			end
		end
	end

	--[[LIST SELECTION]] local selected = false 
		for a = 1, #list
	do 
		--[[if gfx.mouse_x > 0 and gfx.mouse_x < w and gfx.mouse_y > (a*font)-(gfx.mouse_wheel*M_W_S) and gfx.mouse_y < (a*font)+font-(gfx.mouse_wheel*M_W_S) and gfx.mouse_y > font
		then
			Msg(list[sort[a].orig].sel)
		end]]
			if gfx.mouse_x > 0 and gfx.mouse_x < gfx.w and gfx.mouse_y > (a*font)-(gfx.mouse_wheel*M_W_S) and gfx.mouse_y < (a*font)+font-(gfx.mouse_wheel*M_W_S) and gfx.mouse_y > font and click == 0 and reaper.JS_Mouse_GetState(1) == 1 and button_folder == 1
		then click = 1
			if list[sort[a].orig].sel ~= 1 then list[sort[a].orig].sel = 1 click = 3 else list[sort[a].orig].sel = nil click = 4 end
		end
		if list[sort[a].orig].sel ~= nil then selected = true end
			if gfx.mouse_x > 0 and gfx.mouse_x < gfx.w and gfx.mouse_y > (a*font)-(gfx.mouse_wheel*M_W_S) and gfx.mouse_y < (a*font)+font-(gfx.mouse_wheel*M_W_S) and click == 3 and reaper.JS_Mouse_GetState(1) == 1
		then
			list[sort[a].orig].sel = 1
		end
			if gfx.mouse_x > 0 and gfx.mouse_x < gfx.w and gfx.mouse_y > (a*font)-(gfx.mouse_wheel*M_W_S) and gfx.mouse_y < (a*font)+font-(gfx.mouse_wheel*M_W_S) and click == 4 and reaper.JS_Mouse_GetState(1) == 1
		then
			list[sort[a].orig].sel = nil
		end
	end
	if search_input == false then if gfx.getchar() == 1 and reaper.JS_Mouse_GetState(1) == 0 then for a = 1, #list do if selected == true then list[sort[a].orig].sel = nil else list[sort[a].orig].sel = 1 end end end end
	
	--[[SEARCH INPUT]]
	if search_input == true
	then if button[8].name == "search" then button[8].name = "" end
		local char = gfx.getchar()
			if char >= 31 and char <= 125 and gfx.measurestr( button[8].name.."H" ) < button[8].w 
		then
			button[8].name = button[8].name..string.format("%c", char ) 
			gfx.mouse_wheel = 0 
		end
		if char == 8 then if string.len(button[8].name) == 0 then search_input = false end button[8].name = string.sub(button[8].name, 1, string.len(button[8].name)-1 ) end
	else
			if button[8].name ~= "search"
		then local erase = true
				for r = 1, string.len( button[8].name )
			do
				if string.sub(button[8].name, r, r ) ~= " " then erase = false end 
			end
			if button[8].name == "" or erase == true then button[8].name = "search" end
		end
	end
	
	--[[UNCLICK]] 
	if reaper.JS_Mouse_GetState(1) == 0 then click = 0 button_folder = 1 end 
	--[[SEARCH UNCLICK]]
	if reaper.JS_Mouse_GetState(1) == 1 and click == 0 then search_input = false end 
	
	draw()
	
end -- END OF CLICK ACTION

function sort_list() local orig = {} local orig2 = {} local temp = {} local temp2 = {} 

	while #sort > #list do sort[#sort] = nil end
	
		if button[8].name ~= "search" and button[8].name ~= "" and link ~= 0 
	then 
	
		--[[SEARCH]] local counter = 1 local breakdown = {} breakdown[counter] = "" local hits = {}

		--SPLIT STRING AT SPACES
			if link == 2 or link ==3 --STRING SEARCH
		then
				for z = 1, tonumber( string.len(button[8].name) ) 
			do 
					if z ~= 1 and string.sub( button[8].name, z, z ) == " " or type( tonumber ( string.sub( button[8].name, z, z ) ) ) ~= type( tonumber ( string.sub( button[8].name, z-1, z-1 ) ) )
				then 
					counter = #breakdown+1
				else
					if breakdown[counter] == nil then breakdown[counter] = "" end breakdown[counter] = breakdown[counter]..string.sub( button[8].name, z, z )
				end
			end 
		end
		
			for a = 1, #list
		do hits[a] = 0 orig2[a] = a 
			
			local search_by = 0 
			if     link == 1 then search_by = list[a].iid
			elseif link == 2 then search_by = list[a].tname
			elseif link == 3 then search_by = list[a].iname
			elseif link == 4 then search_by = list[a].src
			elseif link == 5 then search_by = list[a].pos
			elseif link == 6 then search_by = list[a].len
			elseif link == 7 then search_by = list[a].group end
			
				if link == 2 or link ==3 --STRING SEARCH
			then
					for y = 1, #breakdown
				do 
						if string.find( string.upper( search_by ), string.upper(breakdown[y]), 1, true )
					then 
						hits[a] = hits[a] + 1/y 
					end
				end
			else
				hits[a] = search_by
			end
		
			temp2[a] = hits[a]

		end

		table.sort(orig2,function(p,q)
				if type(tonumber(temp2[p])) == 'number' and type(tonumber(temp2[q])) == 'number' 
			then
				if link == 2 or link ==3 then return tonumber(temp2[p]) < tonumber(temp2[q]) else return tonumber(temp2[p]) > tonumber(temp2[q]) end
			else
				return temp2[p] < temp2[q]
			end
		end)

			for u = 1, #list
		do 
			if sort[#list+1-u] == list[orig2[u]] then local getit = sort[#list+1-u].color end
			sort[#list+1-u] = list[orig2[u]]
			sort[#list+1-u].orig = orig2[u]
			if colordO[#list+1-u] then colord[#list+1-u] = colordO[orig2[u]] end --[[COLORIZE]]
			if getit then sort[#list+1-u].color = getit end
		end 
	end
		
	--LIST HIERARCHY
		if link ~= 0 and button[8].name == "search" 
	then 
		for a = 1, #list do orig[a] = a end

				if link == 1 then for a = 1, #list do temp[a] = list[a].iid   end end
				if link == 2 then for a = 1, #list do temp[a] = string.upper( list[a].tname ) end end
				if link == 3 then for a = 1, #list do temp[a] = string.upper( list[a].iname ) end end
				if link == 4 then for a = 1, #list do temp[a] = list[a].src   end end
				if link == 5 then for a = 1, #list do temp[a] = list[a].pos   end end
				if link == 6 then for a = 1, #list do temp[a] = list[a].len   end end
				if link == 7 then for a = 1, #list do temp[a] = list[a].group end end
			
			table.sort(orig,function(a,b)
					if type(tonumber(temp[a])) == 'number' and type(tonumber(temp[b])) == 'number' 
				then
					return tonumber(temp[a]) < tonumber(temp[b])
				else
					return temp[a] < temp[b]
				end
			end)
		
			--FLIP LIST
				if link ~= 0
			then
					if title[link].state == 2 
				then 
						for a = 1, #list
					do
						if sort[a] == list[orig[#list+1-a]] then local getit = sort[a].color end
						sort[a] = list[orig[#list+1-a]] 
						sort[a].orig = orig[#list+1-a]
						if colordO[a] then colord[a] = colordO[orig[#list+1-a]] end --[[COLORIZE]]
						if getit then sort[a].color = getit end
					end
				else
						for a = 1, #list 
					do 
						if sort[a] == list[orig[a]] then local getit = sort[a].color end
						sort[a] = list[orig[a]] 
						sort[a].orig = orig[a]
						if colordO[a] then colord[a] = colordO[orig[a]] end --[[COLORIZE]]
						if getit then sort[a].color = getit end
					end
				end
			end
	end

	--ORDINARY VIEW
		if link == 0
	then 
	
			for a = 1, #list 
		do 
			if sort[a] == list[a] then local getit = sort[a].color end
			sort[a] = list[a] sort[a].orig = a
			if colordO[a] then colord[a] = colordO[a] end --[[COLORIZE]] 
			if getit then sort[a].color = getit end
		end
	
	end 
	
	check_mousewheel()

end -- end sort list

function get_list() 
	
	--FILTER 'EMPTY' ITEMS
	local keep_count = 0
		while keep_count <= reaper.CountSelectedMediaItems( 0 ) 
	do
			if reaper.GetSelectedMediaItem( 0, keep_count )
		then 
				if reaper.GetActiveTake( reaper.GetSelectedMediaItem( 0, keep_count ) ) == nil 
			then 
				reaper.SetMediaItemSelected( reaper.GetSelectedMediaItem( 0, keep_count ), false ) keep_count = keep_count - 1 
			end 
		end
		keep_count = keep_count + 1
	end Up()
	
	local runner = #list 
	if runner < reaper.CountSelectedMediaItems( 0 ) then runner = reaper.CountSelectedMediaItems( 0 ) end
	--GET LIST
    for a = 0, runner-1
  do 
		--INVALID ITEM
			if pcall(function ()reaper.GetMediaItemTrack( reaper.GetSelectedMediaItem( 0, a ) ) end ) == false 
		then  --Msg("invalid item")
				for n = 1, #list
			do
				reaper.SetMediaItemInfo_Value( list[n].item, "I_CUSTOMCOLOR", list[n].color|0x1000000 )
			end
			list = nil list = {} sort = nil sort = {} colord = nil colord = {} colordO = nil colordO = {} gfx.mouse_wheel = 0 
			break
		end 
		--ITEM NOT IDENTICAL?
			if list[a+1] 
		then  
				if list[a+1].item ~= reaper.GetSelectedMediaItem( 0,a ) 
			then --Msg("not identical")
					for n = 1, #list
				do 
					reaper.SetMediaItemInfo_Value( list[n].item, "I_CUSTOMCOLOR", list[n].color|0x1000000 )
				end
				list = nil list = {} sort = nil sort = {} colord = nil colord = {} colordO = nil colordO = {} gfx.mouse_wheel = 0 
				break
			end 
		end 
	end -- end of for a loop(1)
		for a = 0, reaper.CountSelectedMediaItems( 0 )-1
	do local color_save, sel_save = -1, -1
		if list[a+1] then if list[a+1].item == reaper.GetSelectedMediaItem( 0,a ) then color_save, sel_save = list[a+1].color, list[a+1].sel end end 
		
		local _, buf = reaper.GetTrackName( reaper.GetMediaItem_Track( reaper.GetSelectedMediaItem( 0,a) ) ) 
		--SET LIST		
		list[a+1] = {iid = tostring(math.floor(reaper.GetMediaItemInfo_Value( reaper.GetSelectedMediaItem( 0,a), "IP_ITEMNUMBER" )+1)), tname = buf, iname = reaper.GetTakeName( reaper.GetActiveTake( reaper.GetSelectedMediaItem( 0, a ) ) ), src = tostring(reaper.GetMediaItemTakeInfo_Value( reaper.GetActiveTake( reaper.GetSelectedMediaItem( 0, a ) ), "D_STARTOFFS" ) ), pos = tostring(reaper.GetMediaItemInfo_Value( reaper.GetSelectedMediaItem( 0,a), "D_POSITION" ) ), len = tostring(reaper.GetMediaItemInfo_Value( reaper.GetSelectedMediaItem( 0,a), "D_LENGTH" ) ), group = tostring( math.floor( tonumber( reaper.GetMediaItemInfo_Value( reaper.GetSelectedMediaItem( 0,a), "I_GROUPID" ) ) ) ), item = reaper.GetSelectedMediaItem( 0,a), color = reaper.GetDisplayedMediaItemColor( reaper.GetSelectedMediaItem( 0,a) ), sel = nil}

		if color_save ~= -1 then list[a+1].color = color_save list[a+1].sel = sel_save end 

  end --  end of for a loop(2)
	
	sort_list()

end

function fontflags(str) 
	
	local v = 0
	
	for a = 1, str:len() do 
		v = v * 256 + string.byte(str, a) 
	end 
	
	return v 

end


function draw() gfx.a = 1 local big_type = 0 local digits = {} local all_digits = {}

		for a = 1, #title 
	do
		digits[a] = 0
		all_digits[a] = {}
			for b = 1, #sort
		do
			if a == 1 then big_type = tostring(sort[b].iid) end
			if a == 2 then big_type = tostring(sort[b].tname) end
			if a == 3 then big_type = tostring(sort[b].iname) end
			if a == 4 then big_type = tostring(sort[b].src) end
			if a == 5 then big_type = tostring(sort[b].pos) end
			if a == 6 then big_type = tostring(sort[b].len) end
			if a == 7 then big_type = tostring(sort[b].group) end
				if tonumber(big_type) ~= nil 
			then
				if string.len( tostring( math.floor( tonumber(big_type) ) ) ) > digits[a] then digits[a] = string.len( tostring( math.floor( tonumber( big_type ) ) ) ) end 
				all_digits[a][b] = string.len( tostring( math.floor( tonumber( big_type ) ) ) )
			end
		end
	end

		for a = 1, #sort 
	do gfx.a = 1 
	
		--CALCULATE 'Y'
		gfx.y = a*font-(gfx.mouse_wheel*M_W_S)
		--COLORIZE LIST
		gfx.r, gfx.g, gfx.b = .8-((.8/#sort)*(a-1)), .07+((.7/#sort)*(a-1)), .3+((.6/#sort)*(a-1)) 
	
		--ILLUMINATE
		local color = 0 local light = -1 local r8, g8, b8 = -1, -1, -1 local bold = 200 local mild = 50
		
		if colord[a] then color = colord[a] else color = sort[a].color end
		
			if list[sort[a].orig].sel == 1 
		then 
			r8, g8, b8 = reaper.ColorFromNative( color ) light = bold if r8+g8+b8 > 127 then light = 0-bold end
			r8, g8, b8 = r8+light, g8+light, b8+light if r8>255then r8=255 end if g8>255then g8=255 end if b8>255 then b8=255 end if r8<0 then r8=0 end if g8<0 then g8=0 end if b8<0 then b8=0 end color = reaper.ColorToNative( r8, g8, b8) 
			gfx.gradrect(0,a*font-(gfx.mouse_wheel*M_W_S),gfx.w,font,0,1,0,0, 0, 0, 0, 0, 0, 0, 0, ((1/font)*.25) )
		else
			r8, g8, b8 = reaper.ColorFromNative( color ) 
		end

		--HIGHLIGHT
		local item_checker = nil
		if gfx.mouse_y < 0 then local pox, poy = reaper.GetMousePosition() item_checker, _ = reaper.GetItemFromPoint( pox, poy, true ) end 
			if gfx.mouse_x > 0 and gfx.mouse_x < gfx.w and gfx.mouse_y > (a*font)-(gfx.mouse_wheel*M_W_S) and gfx.mouse_y < (a*font)+font-(gfx.mouse_wheel*M_W_S) and gfx.mouse_y > font and button_folder == 1 or item_checker == list[sort[a].orig].item
		then
				if gfx.mouse_y < gfx.h-font
			then 
			
				light = mild if r8+g8+b8 < 127 then light = light *-1 end if list[sort[a].orig].sel == 1 then else light = light * -1 end
				r8, g8, b8 = r8+light, g8+light, b8+light if r8>255then r8=255 end if g8>255then g8=255 end if b8>255 then b8=255 end if r8<0 then r8=0 end if g8<0 then g8=0 end if b8<0 then b8=0 end color = reaper.ColorToNative( r8, g8, b8) 

				--RECTANGLE HIGHLIGHT
				gfx.gradrect(0,a*font-(gfx.mouse_wheel*M_W_S),gfx.w,font,1,1,1,.17, 0, 0, 0, 0, 0, 0, 0, -(.3/font) )
			
			end
		end
	
		--[[DRAW ITEM#]] local buffet = tostring( tonumber(sort[a].iid) ) gfx.a = 1 
		if gfx.measurestr( buffet )+(digits[1]+1-all_digits[1][a])*gfx.measurestr("0") > title[1].w-10 then while gfx.measurestr( buffet..".." ) +(digits[1]+1-all_digits[1][a])*gfx.measurestr("0") > title[1].w-10 do buffet = string.sub(buffet, 0, string.len(buffet)-1) end buffet = buffet..".." end
		gfx.x = title[1].x+(digits[1]+1-all_digits[1][a])*gfx.measurestr("0") gfx.drawstr(buffet) 
		--[[DRAW TRACKNAME]] buffet = sort[a].tname 
		if gfx.measurestr( buffet ) > title[2].w-10 then while gfx.measurestr( buffet..".." ) > title[2].w-10 do buffet = string.sub(buffet, 0, string.len(buffet)-1) end buffet = buffet..".." end
		gfx.x = title[2].x+5
		gfx.drawstr(buffet) 
		--[[DRAW ITEMNAME]] buffet = sort[a].iname 
		if gfx.measurestr( buffet ) > title[3].w-10 then while gfx.measurestr( buffet..".." ) > title[3].w-10 do buffet = string.sub(buffet, 0, string.len(buffet)-1) end buffet = buffet..".." end
		gfx.x = title[3].x+5 gfx.drawstr(buffet) 
		--[[DRAW SRC. POS.]] buffet = tostring( tonumber(sort[a].src) )
		if gfx.measurestr( buffet )+(digits[4]+1-all_digits[4][a])*gfx.measurestr("0") > title[4].w-10 then while gfx.measurestr( buffet..".." ) +(digits[4]+1-all_digits[4][a])*gfx.measurestr("0") > title[4].w-10 do buffet = string.sub(buffet, 0, string.len(buffet)-1) end buffet = buffet..".." end
		gfx.x = title[4].x+(digits[4]+1-all_digits[4][a])*gfx.measurestr("0") gfx.drawstr(buffet) 	
		--[[DRAW POSITION]] buffet = tostring( tonumber(sort[a].pos) )
		if gfx.measurestr( buffet )+(digits[5]+1-all_digits[5][a])*gfx.measurestr("0") > title[5].w-10 then while gfx.measurestr( buffet..".." ) +(digits[5]+1-all_digits[5][a])*gfx.measurestr("0") > title[5].w-10 do buffet = string.sub(buffet, 0, string.len(buffet)-1) end buffet = buffet..".." end
		gfx.x = title[5].x+(digits[5]+1-all_digits[5][a])*gfx.measurestr("0") gfx.drawstr(buffet) 	
		--[[DRAW LENGTH]] buffet = sort[a].len
		if gfx.measurestr( buffet )+(digits[6]+1-all_digits[6][a])*gfx.measurestr("0") > title[6].w-10 then while gfx.measurestr( buffet..".." ) +(digits[6]+1-all_digits[6][a])*gfx.measurestr("0") > title[6].w-10 do buffet = string.sub(buffet, 0, string.len(buffet)-1) end buffet = buffet..".." end
		gfx.x = title[6].x+(digits[6]+1-all_digits[6][a])*gfx.measurestr("0") gfx.drawstr(buffet) 		
		--[[DRAW GROUP]] buffet = sort[a].group 
		if gfx.measurestr( buffet )+(digits[7]+1-all_digits[7][a])*gfx.measurestr("0") > title[7].w-10 then while gfx.measurestr( buffet..".." ) +(digits[7]+1-all_digits[7][a])*gfx.measurestr("0") > title[7].w-10 do buffet = string.sub(buffet, 0, string.len(buffet)-1) end buffet = buffet..".." end
		gfx.x = title[7].x+(digits[7]+1-all_digits[7][a])*gfx.measurestr("0") gfx.drawstr(buffet) 	
		
		reaper.SetMediaItemInfo_Value( sort[a].item, "I_CUSTOMCOLOR", math.floor(color)|0x1000000 )
		
	end -- END OF FOR LIST

	
	--[[TITLE]] gfx.r, gfx.g, gfx.b, gfx.a = 0, 0, 0, .6 gfx.rect(0,0,gfx.w,title[1].h, 1) 
	--ITEM# 
		for a = 1, #title
	do 
		--ILLUMINATE
			if a == link 
		then
				if button[8].name ~= "search" and button[8].name ~= "" and link ~= 0 
			then
				gfx.gradrect(title[a].x,font,title[a].w,gfx.h-(font*2),.6,.2,.8,.24, 0, 0, 0, 0, 0, -1/(gfx.h-(font*2)), 0, 0)
				elseif title[a].state == 1
			then 
				gfx.gradrect(title[a].x,font,title[a].w,gfx.h-(font*2),0,0,0,.24, 0, 0, 0, 0, 0, 1/(gfx.h-(font*2)), 0, 0 )
				elseif title[a].state == 2
			then
				gfx.gradrect(title[a].x,font,title[a].w,gfx.h-(font*2),0,1,0,.24, 0, 0, 0, 0, 0, -1/(gfx.h-(font*2)), 0, 0)
			end
		end
		--TEXT
		gfx.r, gfx.g, gfx.b, gfx.y, gfx.a = .84, .18, .27, 0, 1 if gfx.measurestr(title[a].name) > title[a].w then gfx.x = title[a].x+(title[a].w/2)-(gfx.measurestr(title[a].mname)/2) gfx.drawstr(title[a].mname) else gfx.x = title[a].x+(title[a].w/2)-(gfx.measurestr(title[a].name)/2) gfx.drawstr(title[a].name)	end
		--SHADOW TEXT
		gfx.r, gfx.g, gfx.b, gfx.y, gfx.a = 0, .87, 1, 1, .1 if gfx.measurestr(title[a].name) > title[a].w then gfx.x = title[a].x+(title[a].w/2)-(gfx.measurestr(title[a].mname)/2) gfx.x = gfx.x +1 gfx.drawstr(title[a].mname) else gfx.x = title[a].x+(title[a].w/2)-(gfx.measurestr(title[a].name)/2) gfx.x = gfx.x +1 gfx.drawstr(title[a].name)	end
		--HIGHLIGHT
			gfx.a = 1 gfx.y = 0 if gfx.mouse_x > title[a].x and gfx.mouse_x < title[a].x+title[a].w and gfx.mouse_y > title[a].y and gfx.mouse_y < title[a].y+title[a].h and title[a].bf == button_folder
		then
			--gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, .23 if click == 1 then gfx.a = gfx.a * 3 end gfx.rect(title[a].x,title[a].y,title[a].w,title[a].h, 1)
			gfx.gradrect(title[a].x,title[a].y,title[a].w,title[a].h,1,1,1,.2, 0, 0, 0, 0, -(1/font), -(1/font), -(1/font), 0 )
		end
	end
	
	--[[SCROLLBAR]]
	gfx.r, gfx.g, gfx.b, gfx.a = .2, .2, .2, 1 gfx.rect(gfx.w-30,font,30,gfx.h-(font*2), 1)
	gfx.gradrect(gfx.w-29,font+1,28,gfx.h-font, .05,.05,.05,1, .01, .01, .01, 0, 0, 0, 0, 0 )
		for ze = 0, 10 
	do
		gfx.r, gfx.g, gfx.b = .05+(.07*ze), .07+(.07*ze), .05+(.07*ze) gfx.circle(gfx.w-15+(ze*.4),font+((gfx.h-(font*2)-24)*(gfx.mouse_wheel/((((#list+3)*font)-gfx.h)/M_W_S )))+12-(ze*.3),12-(ze*1),1,1 )
	end

	--gfx.r, gfx.g, gfx.b = .35, .35, .35 gfx.rect(gfx.w-24,font+((gfx.h-(font*2)-24)*(gfx.mouse_wheel/((((#list+3)*font)-gfx.h)/M_W_S ))),24,24, 1) 
	
		--[[TOOLBAR]] gfx.a = 1 local helplight = 1
	--HIGHLIGHT
		for a = 1, #toolbar
	do 
			if gfx.mouse_x > toolbar[a].x and gfx.mouse_x < toolbar[a].x+toolbar[a].w and gfx.mouse_y > toolbar[a].y and gfx.mouse_y < toolbar[a].y+toolbar[a].h and toolbar[a].bf == button_folder
		then
			helplight = 1.25
		end

	end
	local x_counter = 0 for a = 0, 23 do for b = 0, 71, 3 do 
	local aaa, bbb, ccc = string1[a][b+2], string1[a][b], string1[a][b+1] if aaa ~= 0 and aaa ~= nil then aaa = aaa * helplight end if bbb ~= 0 and bbb ~= nil then bbb = bbb * helplight end if ccc ~= 0 and ccc ~= nil then ccc = ccc * helplight end
	gfx.x = toolbar[1].x + x_counter gfx.y = toolbar[1].y + a gfx.setpixel(aaa, bbb, ccc) x_counter = x_counter + 1
	end x_counter = 0 end
	
	--[[LINES]]
	--TITLE BUTTON LINES
		gfx.a = 1 for a = 1, #title
	do
		gfx.r, gfx.g, gfx.b = 0, .5, .5 gfx.rect( title[a].x-1,0,1,font, 1)
		gfx.r, gfx.g, gfx.b = 0, .7, .7 gfx.rect( title[a].x,0,1,font, 1)
		gfx.r, gfx.g, gfx.b = 0, .5, .5 gfx.rect( title[a].x+1,0,1,font, 1)
	end 
	--LIST LINES
	for a = 1, #title
	do
		gfx.r, gfx.g, gfx.b = .7, .7, .7 gfx.rect( title[a].x-1,font,1,gfx.h-font-font, 1)
		gfx.r, gfx.g, gfx.b =  1,  1,  1 gfx.rect( title[a].x  ,font,1,gfx.h-font-font, 1)
		gfx.r, gfx.g, gfx.b = .7, .7, .7 gfx.rect( title[a].x+1,font,1,gfx.h-font-font, 1)
	end
	gfx.r, gfx.g, gfx.b = .7, .7, .7 gfx.rect( title[7].x+title[7].w-1,font,1,gfx.h-font-font, 1) gfx.rect( gfx.w-33,font,1,gfx.h-font-font, 1)
	gfx.r, gfx.g, gfx.b =  1,  1,  1 gfx.rect( title[7].x+title[7].w  ,font,1,gfx.h-font-font, 1) gfx.rect( gfx.w-32,font,1,gfx.h-font-font, 1)
	gfx.r, gfx.g, gfx.b = .7, .7, .7 gfx.rect( title[7].x+title[7].w+1,font,1,gfx.h-font-font, 1) gfx.rect( gfx.w-31,font,1,gfx.h-font-font, 1)
	gfx.r, gfx.g, gfx.b = 0, .5, .5 gfx.rect( 0,font-1,gfx.w,1, 1) gfx.rect( title[7].x+title[7].w-1,0,1,font, 1)
	gfx.r, gfx.g, gfx.b = 0, .7, .7 gfx.rect( 0,0,gfx.w,1, 1) gfx.rect( 0,font,gfx.w,1, 1) gfx.rect( title[7].x+title[7].w,0,1,font, 1)
	gfx.r, gfx.g, gfx.b = 0, .5, .5 gfx.rect( 0,1,gfx.w,1, 1) gfx.rect( 0,font+1,gfx.w,1, 1) gfx.rect( title[7].x+title[7].w+1,0,1,font, 1)
	
	--[[BUTTON]] 
			for a = 1, #button
		do if button[a].bf ~= button_folder and button[a].bf ~= 1 then goto draw_skip end gfx.y = button[a].y- math.floor(font/15)
			gfx.a = 1 
			--BOX
			gfx.gradrect(button[a].x,button[a].y,button[a].w,button[a].h/2,button[a].r,button[a].g,button[a].b,1, 0, 0, 0, 0, 0, 0, 0, -(1/(font/2)) )
			gfx.gradrect(button[a].x,button[a].y+button[a].h/2,button[a].w,button[a].h/2,button[a].r,button[a].g,button[a].b,1, 0, 0, 0, 0, 0, 0, 0, -(1/(font)) )
			gfx.gradrect(button[a].x,button[a].y,button[a].w,button[a].h/2,button[a].r,button[a].g,button[a].b,0, 0, 0, 0, 0, 0, 0, 0, (1/(font/2)) )
			gfx.gradrect(button[a].x,button[a].y+button[a].h/2,button[a].w,button[a].h/2,button[a].r,button[a].g,button[a].b,1, 0, 0, 0, 0, 0, 0, 0, -(1/(font)) )

			
			--gfx.r, gfx.g, gfx.b = button[a].r, button[a].g, button[a].b gfx.rect(button[a].x,button[a].y,button[a].w,button[a].h, 1)
			gfx.r, gfx.g, gfx.b, gfx.a = 0, 0, 0, .1 gfx.rect(button[a].x+1,button[a].y+1,button[a].w-2,button[a].h-2, 0)
			gfx.r, gfx.g, gfx.b, gfx.a = 0, 0, 0, .3 gfx.rect(button[a].x,button[a].y,button[a].w,button[a].h, 0)
			--TEXT
				gfx.r, gfx.g, gfx.b = .9, .9, .9 if a ~= 8 and a ~= 5
			then
					if a == 16 
				then 
					while gfx.measurestr( button[16].name ) > button[16].w-10 do button[16].name = string.sub(button[16].name, 0, string.len(button[16].name)-1) end 
					gfx.a = .9 gfx.x = button[a].x+5 if button[a].bf == 1 then gfx.x = button[a].x+(button[a].w-gfx.measurestr(button[a].name))/2 end gfx.drawstr(button[a].name) 
				else
					if button_folder == 6 and a == 26 then gfx.setfont(1, "times new roman", font, 98 ) end
					if button_folder == 6 and a == 27 then gfx.setfont(1, "arial", font, 98 ) end
					if button_folder == 6 and a == 28 then gfx.setfont(1, "calibri", font, 98 ) end
					gfx.y = gfx.y +3 gfx.r, gfx.g, gfx.b = .1, .1, .1 gfx.x = button[a].x+5 gfx.a = 1 if button[a].bf == 1 then gfx.x = button[a].x-3+(button[a].w-gfx.measurestr(button[a].name))/2 end gfx.drawstr(button[a].name) gfx.y = gfx.y - 2
					gfx.r, gfx.g, gfx.b = .4, .4, .4 gfx.x = button[a].x+5 gfx.a = 1 if button[a].bf == 1 then gfx.x = button[a].x-1+(button[a].w-gfx.measurestr(button[a].name))/2 end gfx.drawstr(button[a].name) gfx.y = gfx.y - 1
					gfx.r, gfx.g, gfx.b = 1, 1, 1 gfx.a = .9  gfx.x = button[a].x+5 if button[a].bf == 1 then gfx.x = button[a].x+(button[a].w-gfx.measurestr(button[a].name))/2 end 
					if a == 1 and button_folder == 2 then gfx.r, gfx.g, gfx.b = .5, .5, .5 end if a == 9 and button_folder == 3 then gfx.r, gfx.g, gfx.b = .5, .5, .5 end if a == 10 and button_folder == 4 then gfx.r, gfx.g, gfx.b = .5, .5, .5 end if a == 20 and button_folder == 5 then gfx.r, gfx.g, gfx.b = .5, .5, .5 end
					gfx.drawstr(button[a].name) 
					if button_folder == 6 then gfx.setfont(1, font_style, font, 98 ) end 
				end
			else
					if a == 5
				then
					gfx.a = .9gfx.x = button[a].x+(button[a].w-gfx.measurestr(button[a].name))/2 gfx.drawstr(button[a].name) 
				end
					if a == 8
				then
						if search_input == true
					then
						gfx.a = .1 gfx.x = button[a].x gfx.drawstr(button[a].name) 
						gfx.a = .9 gfx.x = button[a].x+gfx.measurestr("|") gfx.drawstr(button[a].name) 
					else
						gfx.a = .1 gfx.x = button[a].x+(button[a].w-gfx.measurestr(button[a].name))/2 gfx.drawstr(button[a].name) 
						gfx.a = .9  gfx.x = button[a].x+(button[a].w-gfx.measurestr(button[a].name))/2 gfx.drawstr(button[a].name) 
					end
				end
			end
			--HIGHLIGHT
				if gfx.mouse_x > button[a].x and gfx.mouse_x < button[a].x+button[a].w and gfx.mouse_y > button[a].y and gfx.mouse_y < button[a].h+button[a].y and button[a].bf == button_folder
			then
				gfx.r, gfx.g, gfx.b, gfx.a = 1, 1, 1, .16 if click == 1 and button[a].bf == 1 then gfx.a = gfx.a * 3 end gfx.rect(button[a].x,button[a].y,button[a].w,font, 1)
			end
			::draw_skip::
		end

	
	--[[BLINKING CARET]]
		if search_input == true
	then
		if reaper.time_precise() > caret[0]+1 then caret[0] = reaper.time_precise() caret[1] = caret[2] end
		if reaper.time_precise() < caret[0] + caret[1] then gfx.r, gfx.g, gfx.b, gfx.a = .9, .9, .9, 1 gfx.rect(button[8].x+gfx.measurestr(button[8].name)+gfx.measurestr("|"),button[8].y,2,font, 0) else caret[1] = 0 end
	end
	
	
end --END OF DRAW

function exit()
	for z = 1, #list do if list[z].item then reaper.SetMediaItemInfo_Value( list[z].item, "I_CUSTOMCOLOR", list[z].color|0x1000000 ) end end
	local a4, b4, c4, d4, e4 = gfx.dock( -1, 0, 0, 0, 0 )
	
	reaper.SetExtState( "Dfk Item Reader", "Font",font, true )
	reaper.SetExtState( "Dfk Item Reader", "F_S", font_style, true )
	reaper.SetExtState( "Dfk Item Reader", "W1",  title[1].w, true )
	reaper.SetExtState( "Dfk Item Reader", "W2",  title[2].w, true ) 
	reaper.SetExtState( "Dfk Item Reader", "W3",  title[3].w, true ) 
	reaper.SetExtState( "Dfk Item Reader", "W4",  title[4].w, true ) 
	reaper.SetExtState( "Dfk Item Reader", "W5",  title[5].w, true ) 
	reaper.SetExtState( "Dfk Item Reader", "W6",  title[6].w, true ) 
	reaper.SetExtState( "Dfk Item Reader", "W7",  title[7].w, true ) 
	reaper.SetExtState( "Dfk Item Reader", "X2",  title[2].x, true ) 
	reaper.SetExtState( "Dfk Item Reader", "X3",  title[3].x, true ) 
	reaper.SetExtState( "Dfk Item Reader", "X4",  title[4].x, true ) 
	reaper.SetExtState( "Dfk Item Reader", "X5",  title[5].x, true ) 
	reaper.SetExtState( "Dfk Item Reader", "X6",  title[6].x, true ) 
	reaper.SetExtState( "Dfk Item Reader", "X7",  title[7].x, true ) 
	
	reaper.SetExtState( "Dfk Item Reader", "W_W",  d4,   true ) 
	reaper.SetExtState( "Dfk Item Reader", "W_H",  e4,   true ) 
	reaper.SetExtState( "Dfk Item Reader", "W_X",  b4,   true ) 
	reaper.SetExtState( "Dfk Item Reader", "W_Y",  c4,   true ) 
	reaper.SetExtState( "Dfk Item Reader", "W_D",  a4,   true ) Up()
end

reaper.atexit(exit)

function main() 
  mouse_x, mouse_y = reaper.GetMousePosition() 
	
	update_vars() 
 
  gfx.update() Up()
  
  if gfx.getchar() ~= -1 and gfx.getchar(27) ~= 1 then reaper.defer(main) end 

end

gfx.init("Dfk Item Reader", tonumber( reaper.GetExtState( "Dfk Item Reader", "W_W" ) ), tonumber( reaper.GetExtState( "Dfk Item Reader", "W_H" ) ), tonumber( reaper.GetExtState( "Dfk Item Reader", "W_D" ) ), tonumber( reaper.GetExtState( "Dfk Item Reader", "W_X" ) ), tonumber( reaper.GetExtState( "Dfk Item Reader", "W_Y" ) ) )
main()




