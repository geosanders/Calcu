{{
┌────────────────────────────────┐
│ 16x1 LCD Driver                │
├────────────────────────────────┴────────────────────┐
│  Version : 1.3                                      │
│  By      : Tom Dinger                               │   
│            propeller@tomdinger.net                  │
│  Date    : 2010-11-14                               │
│  (c) Copyright 2010 Tom Dinger                      │
│  See end of file for terms of use.                  │
├─────────────────────────────────────────────────────┤
│  Width      : 16 Characters (columns)               │
│  Height     : 1 Line (row)                          │
│  Controller :  HD44780-based                        │
│                (KS0066 and similar)                 │
└─────────────────────────────────────────────────────┘
}}
{
  Version History:
  1.0 -- 2010-09-16 -- Initial release.

  1.2 -- 2010-10-23 -- Added ColsInOneHalf constant, to make it easier
                       to adapt for 24x1 displays (12 cols in each half)

  1.3 -- 2010-11-14 -- changed the pin variable names to allow for
                       use of either the 4-bit or the 8-bit lowest-
                       level driver; added an alternate OBJ
                       statement for 4-bit or 8-bit interfaces
}
{{

This is a driver for a 16 character, 1 line LCD display.

The display is part number AC-161B, manufactured by Ampire Co., Ltd.
Documentation for the display is available in the Parallax Forums, at:
    http://forums.parallax.com/showthread.php?t=124913
Other 16x1 displays using HD44780-compatible commands will probably
work with this drive as well.

This driver provides direct access to the functions of the display:
- writing text
- positioning the cursor
- setting the cursor mode: invisible, underline, blinking block
- shifting the display left and right
- shifting the cursor left and right.

This driver uses a lower-level driver object that manages initialization
of the display and data and command I/O, so that this object (and other
objects at this level) can focus on management of displayed data for
a particular geometry of display. 

Resources:
---------
Ampire Co. Ltd. display AC-161B datasheet, in the Parallax Forums:
    http://pdf1.alldatasheet.com/datasheet-pdf/view/277445/ZETTLER/AC161B.html
    
Hitachi HC44780U datasheet:
  http://www.sparkfun.com/datasheets/LCD/HD44780.pdf
Samsung KS0066U datasheet:
  http://www.datasheetcatalog.org/datasheet/SamsungElectronic/mXuuzvr.pdf
Samsung S6A0069 datasheet (successor to KS0066U):
  http://www.datasheetcatalog.org/datasheet/SamsungElectronic/mXruzuq.pdf
  

Interface Pins to the Display Module:
------------------------------------
Note that the actual assignments of functions to pins is done by
the code that uses this object -- the pin numbers are passed into
the Init() method.

   R/S  [Output] Indicates if the operation is a command or data:
                   0 - Command (write) or Busy Flag + Address (read)
                   1 - Data
   R/W  [Output] I/O Direction:
                   0 - Write to Module
                   1 - Read From Module
   E    [Output] Enable -- triggers the I/O operation 
   DB0  [In/Out] Data Bus Pin 0 -- bidirectional, tristate 
   DB1  [In/Out] Data Bus Pin 1 -- bidirectional, tristate
   DB2  [In/Out] Data Bus Pin 2 -- bidirectional, tristate
   DB3  [In/Out] Data Bus Pin 3 -- bidirectional, tristate
   DB4  [In/Out] Data Bus Pin 4 -- bidirectional, tristate 
   DB5  [In/Out] Data Bus Pin 5 -- bidirectional, tristate
   DB6  [In/Out] Data Bus Pin 6 -- bidirectional, tristate
   DB7  [In/Out] Data Bus Pin 7 -- bidirectional, tristate


DDRAM Address Map:
------------------   
    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15   <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│40│41│42│43│44│45│46│47│  <- DDRAM ADDRESS (unshifted)
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘

}}      

CON

  ' Display dimensions
  NumLines =  1   ' never used
  NumCols  = 16   ' never used
  
  'Line0Col0Addr       = $00
  'Line0Col8Addr       = $f8
  'Line0Col8Addr       = $08
  Line0Col0Addr       = $00
  Line0Col8Addr       = $40

  ColsInOneHalf       = 8 ' could be 12
  
  Line0Col8Addr_Less8 = Line0Col8Addr - ColsInOneHalf

  ' CharsInOneLine is the number of character positions in display RAM
  ' for one line. It does not necessarily correspond to the number
  ' of visible characters in one row of the display. This is used to
  ' determine when the cursor has moved off the end of a "line" in
  ' display memory.
  CharsInOneLine      = $28 ' == 40  

OBJ
  ' The LCDBase object provides access to the actual display device,
  ' and manages the details of the data interface (4 or 8 bit) and
  ' the other signals to the controller.
  '
  ' Pick only one of thexe lines, and make sure that the top-level
  ' program passes in the proper values for the data pins:
  ' 4 consecutive pins for the 4-bit interface, or 8 consecutive
  ' pins for the 8-bit interface.
  
  LCDBase : "LCDBase_4bit_direct_HD44780"
  'LCDBase : "LCDBase_8bit_direct_HD44780"

VAR
  ' CurDisplayCmd contains the most recent settings for the
  ' Display: display on/off, and cursor mode. It is used when changing
  ' only some of the display properties in methods of this obejct.
  byte CurDisplayCmd

  ' CurDisplayShift is the amount the display has been shifted,
  ' relative to the position after a Clear.
  ' Another way to interpret this value is that it is the display RAM
  ' address shown in the leftmost character position on the display.
  ' So, a left-shift of the display will increment this value.
  byte CurDisplayShift
  

PUB Init( Epin, RSpin, RWpin, DBHighPin, DBLowPin )
'' Initialize the display: assign I/O pins to functions, initialize the
'' communication, clear it, turn the display on, turn the
'' cursor off.

  ' We will be using both "lines" of the display controller for the
  ' two halves of the display.
  LCDBase.Init( true, Epin, RSpin, RWpin, DBHighPin, DBLowPin )
  'LCDBase.Init( false, Epin, RSpin, RWpin, DBHighPin, DBLowPin )

  ' The following is how LCDBase initialized the display.
  ' If we wanted something different, we could issue the command
  ' ourselves at this point.
  CurDisplayCmd   := LCDBase#DispCtlCmd_On_CrsrOff_NoBlink
  CurDisplayShift := 0
  

PUB RawSetPos(addr)
'' Setthe next display RAM address that will be written, without
'' doing any adjustments for the geometry of the display.
'' This method is intended for special uses, and will not be used
'' by typical applications.

  LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + addr )


PUB RawWriteChr( chr )
'' Write a character to the display, without adjustments for cursor
'' positioning on the display. Primarily used for "special effects".
'' Generally, PrintChr() will be more useful.

  return LCDBase.WriteByte( chr )
  ' no other adjustments
  

PUB RawWriteStr( str )
'' Write a series of characters (a string) to the display, without
'' adjusting for cursor positioning on the display. Primarily used for
'' "special effects". Generally, PrintStr() will be more useful.

  LCDBase.WriteData( str, strsize(str) )

PUB RawReadData : chr
'' read the data at the current position
'' NOTE: this does not always work as expected -- see the
'' relevant data sheets. It should always work right
'' after a cursor shift or cursor address operation.

  chr := LCDBase.ReadData
  'return chr


PUB Clear
'' Clear the display: write all spaces to the Display RAM, set the
'' display back to unshifted, cursor back to first character (leftmost)
'' on the display.

  LCDBase.WriteCommand( LCDBase#ClearDisplayCmd )
  CurDisplayShift := 0
  
  ' For some reason, for this display, we need to add a short
  ' delay here, or else the next couple of operations (the second
  ' data write done by PrintChr, to be precise) are not reliable.
  ' My best guess as to why: the current cursor address is
  ' not correct until a short while after the clear instruction
  ' reaches the "not busy" state, so the second address written to
  ' by PrintChr() will be calculated wrong.
  'usDelay( 20 ) ' 16 was enough in the test program, with more
  '              ' call/ret layers.s
  usDelay( 5 ) ' 16 was enough in the test program, with more
                ' call/ret layers.s

PUB GetPos : RowAndCol
'' Retrieve the cursor position, as an encoded row and column number:
''   (row << 8) | col
'' For this display, row will always be 0, so this will be just
'' the column number

  return MapAdrToCol( LCDBase.WaitUntilReady & LCDBase#DisplayRamAddrMask )

  
PUB SetPos(pos)
'' Sets the cursor position, to the row and column encoded into the
'' position value:
'' pos -- row and column, encoded as (row << 8) | col
''        For this display, row == 0 always, so it is just the column

  return LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + MapColToAdr( pos ) )


PUB SetRowCol(line,col) | addr
'' Position the cursor to a specific line and character position (column)
'' within that line.
'' line -- 0-based line number; For this display this is ignored, and
''         presumed to be 0.
'' col  -- 0-based column number, or character position, in the line.
''         This will be the next position written, and the position at
''         which the cursor is shown. For this display, this may take
''         values 0..39.

  ' We want these positions to correspond to what is showing on the
  ' display, so we adjust the location to write to, based on the
  ' amount the display has been shifted.
  ' We also need to make the cursor appear in the correct character
  ' cell of the display, so if c > 7 we put the address in the
  ' second line, otherwise into the first line

  return LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + MapColToAdr( col ) )


PUB PrintChr( chr ) : nextadr | highadr, lowadr  ', t
'' Displays the character passed in at the current cursor position, and
'' advances the cursor position.
'' Returns the display RAM address of the cursor after writing the char,
'' i.e. the next display position that will be written.
'' As of now, there is no spcial interpretation for "carriage control"
'' characters such as CR and LF.

  ' The strategy here is to write each character in two places, so that
  ' dislpay scrolling works. So we treat the display as 1x40.

  ' First, write the character to one line, and get the position that
  ' we wrote it to.
  
  highadr := LCDBase.WriteByte( chr )

  ' It might not have been a high address after all
  ' so we have to adjust for that.
  
  if ( highadr < Line0Col8Addr )
    ' It is in fact the low addr
    lowadr  := highadr
    highadr := MapLowToHigh( lowadr )
    nextadr := LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + highadr )

    ' nextadr is also in the low address line range, since we just wrote
    ' to lowadr.
    LCDBase.WriteByte( chr )

    ' We need to adjust nextadr, because the controller moves
    ' between the two regions
    if ( nextadr == Line0Col8Addr )
      nextadr := Line0Col0Addr
    elseif ( nextadr == constant(Line0Col8Addr + CharsInOneLine - 1) )
      nextadr := constant(Line0Col0Addr + CharsInOneLine - 1)

  else ' (highadr => Line0Col8Addr )
    lowadr  := MapHighToLow( highadr )
    nextadr := LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + lowadr )
    ' nextadr is in the high address range, because we just wrote to
    ' highadr.

    LCDBase.WriteByte( chr )

    ' We need to adjust nextadr, because the controller moves
    ' between the two regions
    if ( nextadr == Line0Col0Addr )
      nextadr := Line0Col8Addr
    elseif ( nextadr == constant(Line0Col0Addr + CharsInOneLine - 1) )
      nextadr := constant(Line0Col8Addr + CharsInOneLine - 1)

  ' Now, just reposition the cursor, adjusting for display shift
  ' and for first half/second half of display
  SetPos( MapAdrToCol( nextadr ) )
  ' return nextadr


PUB PrintStr( str )
'' Prints out each characters of the string by calling PrintChr().

  ' For each character of the string
  '   printchr(c)
  repeat strsize(str)
    PrintChr( byte[str++] )

    ' The above is the easiest to write, but is not necessarily
    ' the fastest. We could us an implementation similar to PrintChr()
    ' except that we use dataOut on a string instead of a char.
    ' With this approach we will execute many fewer cursor
    ' positioning commands (but it takes more program memory).
    ' It also has issues dealing with the two halves of the display:
    ' we have to limit writing each string to that half, which
    ' requires checking after each character written for wrapping back
    ' to the start of the memory for that half.
    ' TODO: Someday...

PUB Newline
'' Advance to the start of the next line of the display.
'' For this display, all it does it return the cursor to the first
'' character position. On a mutliline display, perhaps it should also
'' clear to the end of the line?

  SetPos( 0 )

PUB Home
'' Move the cursor (and the next write address) to the first character
'' position on the display.

  SetPos( 0 )

PUB GetDisplayAddr : adr
'' Returns the next RAM address (the current cursor position).
  return LCDBase.WaitUntilReady '  & LCDBase#DisplayRamAddrMask

PUB usDelay(us)
'' Delay the specified number of microseconds, but not less than 382 us.

  LCDBase.usDelay(us)

PUB CursorOff
'' Turns the cursor off

  CurDisplayCmd &= !(LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking)
  'CurDisplayCmd |= LCDBase#DispCtl_CursorOff  ' = $00
  LCDBase.WriteCommand( CurDisplayCmd )

PUB CursorBlink
'' Turn the cursor on -- for the tested display, it appears as a steady
'' underline, and the character cell alternates between the character
'' shown at that position, and all piels on (all black).

  'CurDisplayCmd &= !(LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking)
  CurDisplayCmd |= LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking
  LCDBase.WriteCommand( CurDisplayCmd )

PUB CursorSteady
'' Turns the cursor on -- for the tested display, it appears as a
'' steady underline.

  CurDisplayCmd &= !(LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking)
  CurDisplayCmd |= LCDBase#DispCtl_CursorOn ' | LCDBase#DispCtl_NoBlinking
  LCDBase.WriteCommand( CurDisplayCmd )
 
PUB DisplayOff
'' Turns the dislpay off.

  CurDisplayCmd &= !LCDBase#DispCtl_DisplayOn
  LCDBase.WriteCommand( CurDisplayCmd )

PUB DisplayOn
'' Turns the display on -- makes no change to the contents of display RAM,
'' it just enabled the display of what is already in RAM.

  CurDisplayCmd |= LCDBase#DispCtl_DisplayOn
  LCDBase.WriteCommand( CurDisplayCmd )

PUB ShiftCursorLeft | curadr, col
'' Shift the cursor position to the left one character.
'' This is done in the "virtual" 40-character line, so that the cursor
'' can be shifted off the left end of the display, and it will
'' eventually reappear on the right end.

  curadr := LCDBase.WriteCommand( LCDBase#CursorShiftCmd_Left )
  ' If we shift fom Col 16 to Col 15, make sure the resulting
  ' next address is in the high area
  ' But if we shift from col 8 to col 7, make sure the resulting
  ' next address is in the low area.
  col := MapAdrToCol( curadr )
  if ( (col == ColsInOneHalf) OR (col == constant(ColsInOneHalf * 2)) )
    ' Force the cursor into the desired region.
    SetPos( col-1 )

PUB ShiftCursorRight | curadr, col
'' Shift the cursor position to the right one character.
'' This is done in the "virtual" 40-character line, so that the cursor
'' can be shifted off the right end of the display, and it will
'' eventually reappear on the left end.

  curadr := LCDBase.WriteCommand( LCDBase#CursorShiftCmd_Right )
  ' If we shift fom Col 7 to Col 8, make sure the resulting
  ' next address is in the high area
  ' But if we shift from col 39 to col 0, make sure the resulting
  ' next address is in the low area.
  col := MapAdrToCol( curadr )
  if ( col == 7 )
    SetPos( ColsInOneHalf ) ' force into the high region
  elseif ( col == constant( CharsInOneLine - 1 ) )
    SetPos( 0 ) ' force into the low region.

PUB ShiftDisplayLeft
'' This shifts the entire display contents to the left one character.
'' The cursor will seem not to move, so it effectively moves to the
'' right one character in display RAM (but not on the display itself).

  LCDBase.WriteCommand( LCDBase#DisplayShiftCmd_Left )
  CurDisplayShift += 1
  if ( CurDisplayShift => CharsInOneLine )
    CurDisplayShift -= CharsInOneLine ' limit to $00..$27

PUB ShiftDisplayRight
'' This shifts the entire display contents to the right one character.
'' The cursor will seem not to move, so it effectively moves to the
'' leftt one character in display RAM (but not on the display itself).

  LCDBase.WriteCommand( LCDBase#DisplayShiftCmd_Right )
  if ( CurDisplayShift == 0 )
    CurDisplayShift := constant(CharsInOneLine-1) ' limit to $00..$27
  else
    CurDisplayShift -= 1


PUB WriteCharGen( index, pRows ) | c, curadr
'' Write the supplied pattern to the character generator RAM.
'' index -- The character index to write, from 0..7
''          The value is masked to that range
'' pRows -- a pointer to the character cell row data; only the low
''          order 5 bits are used for the character.
''          Any byte outside the range $00..$1F will end the range
''          written to the Char Gen RAM

  ' We save the current cursor position so we can restore it later...
  curadr := LCDBase.WriteCommand( LCDBase#SetCgRamAddrCmd + ((index & $07) << 3) )
  
  c := byte[ pRows++ ]   ' get the first character  
  repeat while ( (c & $E0) == 0 )
    ' The high bits are not set
    ' NOTE: This assumes addresses auto-increment 
    LCDBase.WriteByte( c )
    c := byte[ pRows++ ]

  ' Now that we have written all the CG data, restore the
  ' current cursor position
  LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + curadr )


PUB WriteCharGenCnt( index, line, pRows, len ) | curadr
'' Write the supplied pattern to the character generator RAM.
'' index -- The character index to write, from 0..7
''          The value is masked to that range
'' line -- Scan line to start within the character, from 0..7
''         The value is masked to that range.
'' pRows -- A pointer to the character cell row data; only the low
''          order 5 bits are used for the character.
''          Any byte outside the range $00..$1F will end the range
''          written to the Char Gen RAM
'' len -- Number of character scan lines to write -- one character
''        contains 8 scan lines. NOTE: Not range-limited!

  ' We save the current cursor position so we can restore it later...
  curadr := LCDBase.WriteCommand( LCDBase#SetCgRamAddrCmd + ((index & $07) << 3) + (line & $07) )
  
  repeat len
    ' The high bits are not set
    ' NOTE: This assumes addresses auto-increment 
    LCDBase.WriteByte( byte[ pRows++ ] )

  ' Now that we have written all the CG data, restore the
  ' current cursor position
  LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + curadr )

    
' ---------------------------------------------------------------
' We define some helper functions: map from a low-area address to
' a high-area, and vice-versa, and cnovert between an address and a
' column position

PRI MapHighToLow( hiadr ) : loadr
  ' convert a high address to the corresponding low address
  loadr := hiadr - Line0Col8Addr_Less8 ' map $40..$5F to $08..$27
                        ' but this also maps $60..$67 to $28..@2F
                        ' which we have to move to $00..$07
  if ( loadr => constant(Line0Col0Addr + CharsInOneLine) )
    loadr -= CharsInOneLine

  ' Perhaps we could use one line:
  ' loadr := hiadr - constant(Line0Col8Addr - 8) - ((hiadr => constant(Line0Col8Adr + CharsInOneLine - 8)) & CharsInOneLine)

PRI MapLowToHigh( loadr ) : hiadr
  ' convert a high address to the corresponding low address
  hiadr := loadr + Line0Col8Addr_Less8 ' map $08..$27 to $40..$5F
                        ' but this maps $00..$07 to $38..$3F, which
                        ' we want to go to $60..$6f
  if ( hiadr < Line0Col8Addr )
    hiadr += CharsInOneLine
    
  ' Perhaps we could use one line:
  ' hiadr := loadr + $38 + ( (loadr < 8) & $28 )

PRI MapAdrToCol( adr ) : col
  ' Convert from an address to the display column from the start of
  ' the display, adjusting for display shift.
  if ( adr => Line0Col8Addr )
    ' adr is in the second line, so we "adjust" the address
    ' to look like the first line
    adr -= Line0Col8Addr_Less8 ' not $40, since the second line starts in column 8

  ' Now, we have adr in the range $00..$2F
  ' Note that $28..$2F will map to $00..$07 later..
  ' We have to adjust based on the display shift.
    
  if ( adr < CurDisplayShift )
    ' adr is in the first, line, so we can directly calculate the column
    col := adr + CharsInOneLine - CurDisplayShift
  else
    col := adr - CurDisplayShift

  ' Now, col might still be too big, so we have to adjust for that
  if ( col => constant(Line0Col0Addr + CharsInOneLine) )
    col -= CharsInOneLine

PRI MapColToAdr( col ) : adr
  ' Convert the column number to an address such that the
  ' cursor will be displayed correctly.
  repeat while ( col => CharsInOneLine )
    col -= CharsInOneLine
    
  if ( col < 8 )
    ' In the low area
    adr := CurDisplayShift + col
    if ( adr => constant(Line0Col0Addr + CharsInOneLine) )
      adr -= CharsInOneLine   ' wrap around
  else ' ( col => 8 )
    ' In the high area
    adr := CurDisplayShift + col + Line0Col8Addr_Less8
    if ( adr => constant(Line0Col8Addr + CharsInOneLine) )
      adr -= CharsInOneLine   ' wrap around
  ' return adr

' TODO:
' - Clear to EOL method?
'
' Open questions:
' - Do we need, for the FunctionSet command:
'   - IncrementingAddresses
'   - DecrementingAddresses
'   - Enable/Disable display shift on write

{{
Detailed Display Information:
----------------------------

The display seems to use the Samsung KS0066 LCD display controller,
which accepts the same command set as the HD44780 controller, and has
a parallel interface either 4 bits or 8 bits wide.

It seems that it was designed as low-cost as possible, which leads to
a quirk that makes it more difficult to use than other, larger LCD
character displays. The 16 characters of the display are not mapped to
consecutive memory addresses; the display internally is organized like
a 2 line by 8 character display, but with the to "lines" side-by-side
instead of above and below.

In a larger, 2 line by 16 character display, the display is actually
a 2x16 window into display memory organized as 2 lines by 40 characters,
and the display can be treated as a sliding window over that display memory.

This 1x16 display is very similar: each 8-character half of the display
is a sliding window into the 40 character line in display memory. But that
means that there is a discontinuity in memory addressing across the
characters of the display, as seen in the following table:

DDRAM Address Map:
------------------   
    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15   <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│40│41│42│43│44│45│46│47│  <- DDRAM ADDRESS (unshifted)
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘

Furthermore, if the display controller commands to shift the dislpay
left or right are used, the two halves do not act like they are
connected: the left 8 characters only display portions of the memory
region from $00 to $27, while the right 8 characters display the region
from $40 to $67. Similarly, the commands to shift the cursor left and
right do not cause the cursor to move across the two halves, and writing
a series of characters does not cross the halves either.

The goal of this driver is to make the display appear to be a single-line
display of 16 conesutive characters within a 40 character display memory.

The approach taken is to mirror the contents of each "line" of the display
memory (addresses $00..$27 and $40..$67) into the other half at the proper
offsets so that the display seems to shift correctly when those shift
commands are used. Furthermore, writing to the display should appear to
cross from one half of the display to the other, without requiring the
caller to take any special action.

This means:
- When writing characters to the display, they need to be written twice:
  once in the low addresses ($00..$27) and once in the matching high
  addresses ($40..$67)
- When writing characters, make sure the cursor (next RAM address) ends
  up in the "right" place for cursor display on the screen.
- Remember the amount of shift of the display, so that we can correctly
  map from display position to display RAM address.
- When shifting the cursor using the cursor shift commands for the
  controller, we have to deal with the discontinuity between the two
  halves of the display.
}}

{{

  (c) Copyright 2010 Tom Dinger

┌────────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                           │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a     │
│copy of this software and associated documentation files (the               │
│"Software"), to deal in the Software without restriction, including         │
│without limitation the rights to use, copy, modify, merge, publish,         │
│distribute, sublicense, and/or sell copies of the Software, and to          │
│permit persons to whom the Software is furnished to do so, subject to       │
│the following conditions:                                                   │
│                                                                            │
│The above copyright notice and this permission notice shall be included     │
│in all copies or substantial portions of the Software.                      │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS     │
│OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                  │
│MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.      │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, │
│DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR       │
│OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE   │
│USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└────────────────────────────────────────────────────────────────────────────┘
}}
  
