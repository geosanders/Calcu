{{
┌────────────────────────────────┐
│ Parallel Low-level LCD Driver  │
├────────────────────────────────┴────────────────────┐
│  Version : 1.2                                      │
│  By      : Tom Dinger                               │   
│            propeller@tomdinger.net                  │
│  Date    : 2010-10-23                               │
│  (c) Copyright 2010 Tom Dinger.                     │
│  See end of file for terms of use.                  │
├─────────────────────────────────────────────────────┤
│  Width      : 8 - 80 Characters                     │
│  Height     : 1 -  4 Lines                          │
│  Interface  :  4 Bit                                │
│  Controller :  HD44780-based                        │
│                (KS0066 and similar)                 │
├─────────────────────────────────────────────────────┤
│  Including comments adapted from an ObEx            │
│  object (object 106) written by:                    │ 
│            Simon Ampleman                           │
│            sa@infodev.ca                            │
└─────────────────────────────────────────────────────┘
}}
{
  Version History:
  1.0 -- 2010-09-16 -- Initial release.

  1.1 -- 2010-09-23 -- Added ResendFunctionSetCmd method, to support
                       brightness control on a 20x4 VFD

  1.2 -- 2010-10-23 -- Added a delay in the WaitForIdle routine if used
                       right after a Clear operation, because sometimes
                       for some displays, a display shift right after a clear
                       would not be executed correctly. 
}
{{

This is a low-level, basic interface to a class of LCD display boards
that use display controllers compatible with the Hitachi HD44780 Dot Matrix
Liquid Crystal Display Controller/Driver chip, with or without extension
drivers. This driver handles all signal-level communication with the
display controller: timing requirements, 4-bit/8-bit data bus width,
and initialization.

By itself, the HD44780 (and compatible chips) typically can address up to
16 individual characters in the dislpay, and with extension driver chips on
the display board, can address up to 80 characters.

This layered design permits isolation of the details of communication from
the higher-level logic that may handle details of the display layout
(1, 2 or 4 line; 8, 16, 20 or 40 characters per line; etc.).

This particular version of the driver implements:
- 4-bit data interface: transfer of 8-bit commands and data requires two
  transfers;
- Direct connection of the display pins to the Propeller; the pin assignments
  are passed into the Init() routine as arguments.
- 5x7 pixel character set use, which is typical for most displays.

Other versions may use 8-bit data transfers, or connect the dislpay to the
Propeller indirectly, such as through an I/O expander chip.

The signal pin assignments, and the 1-line or 2-line operating mode selection
are controlled with arguments to the Init() routine. The selection of the
"font" (5x7) is fixed in this version.

For the most part, this object is "stateless", which is to say that very
little of the state of the display is stored within this object. Most operations
use the RAM address returned by the Read Busy Flag/Address operation to
determine the location of the cursor. The only exception is that the "mode"
for data writes is tracked (data writes go either to the display RAM or to the
Character Generator RAM, depending on the last Set RAM Address cmomand issued)
so that unneeded address set commands can be skipped. This permits the clients
of this object to be less careful about avoiding unnecessary cursor positioning
commands.

This object makes no assumptions about the mapping between display RAM
address and the position of the corresponding character on the actual
display. Management of that is up to the higher-level clients of this object
that would have the information about how the display is connected, and
the other properties of the actual display.

Resources:
---------
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
   DB4  [In/Out] Data Bus Pin 4 -- bidirectional, tristate 
   DB5  [In/Out] Data Bus Pin 5 -- bidirectional, tristate
   DB6  [In/Out] Data Bus Pin 6 -- bidirectional, tristate
   DB7  [In/Out] Data Bus Pin 7 -- bidirectional, tristate


LCD Controller Instruction Set:
------------------------------
   ┌──────────────────────┬───┬───┬─────┬───┬───┬───┬───┬───┬───┬───┬───┬─────┬─────────────────────────────────────────────────────────────────────┐
   │  INSTRUCTION         │R/S│R/W│     │DB7│DB6│DB5│DB4│DB3│DB2│DB1│DB0│     │ Description                                                         │
   ├──────────────────────┼───┼───┼─────┼───┼───┼───┼───┼───┼───┼───┼───┼─────┼─────────────────────────────────────────────────────────────────────┤
   │ Clear Display        │ 0 │ 0 │     │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │     │ Clears display and returns cursor to the home position (address 0). │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │ Returns display to unshifted state; resets to increment.            │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ Return Home          │ 0 │ 0 │     │ 0 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │ * │     │ Returns cursor to home position (address 0). Also returns display   │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │ to unshifted state.                                                 │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ Entry Mode Set       │ 0 │ 0 │     │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │I/D│ S │     │ Sets cursor/address autoincrement/autodecrement (I/D); specifies    │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │ whether the display shifts at the same time (S)                     │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │ These operations are performed during data read/write.              │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ Display On/Off       │ 0 │ 0 │     │ 0 │ 0 │ 0 │ 0 │ 1 │ D │ C │ B │     │ Sets On/Off of all display (D), cursor On/Off (C) and blink of      │
   │ Control              │   │   │     │   │   │   │   │   │   │   │   │     │ cursor position character                                           │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ Cursor/Display       │ 0 │ 0 │     │ 0 │ 0 │ 0 │ 1 │S/C│R/L│ * │ * │     │ Selects cursor-move or display-shift (S/C), shift direction (R/L).  │
   │ Shift                │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ Function Set         │ 0 │ 0 │     │ 0 │ 0 │ 1 │ DL│ N │ F │ * │ * │     │ Sets interface data length (DL), number of display lines (N) and    │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │ character font (F).                                                 │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ Set CGRAM Address    │ 0 │ 0 │     │ 0 │ 1 │      CGRAM ADDRESS    │     │ Sets the CGRAM address. CGRAM data is sent and received after       │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │ this setting.                                                       │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ Set DDRAM Address    │ 0 │ 0 │     │ 1 │       DDRAM ADDRESS       │     │ Sets the DDRAM address. DDRAM data is sent and received after       │                                                             
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │ this setting.                                                       │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ Read Busy Flag and   │ 0 │ 1 │     │ BF│    CGRAM/DDRAM ADDRESS    │     │ Reads Busy-flag (BF) indicating internal operation is being         │
   │ Address              │   │   │     │   │   │   │   │   │   │   │   │     │ performed and reads CGRAM or DDRAM address counter contents.        │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ Write to CGRAM or    │ 1 │ 0 │     │         WRITE DATA            │     │ Writes data to CGRAM or DDRAM.                                      │
   │ DDRAM                │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │ Read from CGRAM or   │ 1 │ 1 │     │          READ DATA            │     │ Reads data from CGRAM or DDRAM.                                     │
   │ DDRAM                │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   │                      │   │   │     │   │   │   │   │   │   │   │   │     │                                                                     │
   └──────────────────────┴───┴───┴─────┴───┴───┴───┴───┴───┴───┴───┴───┴─────┴─────────────────────────────────────────────────────────────────────┘
   Remarks :
            * = 0 OR 1 (don't care)
        DDRAM = Display Data RAM
                Corresponds to cursor position                  
        CGRAM = Character Generator RAM        

   ┌──────────┬──────────────────────────────────────────────────────────────────────┐
   │ BIT NAME │                          SETTING STATUS                              │                                                              
   ├──────────┼─────────────────────────────────┬────────────────────────────────────┤
   │  I/D     │ 0 = Decrement address           │ 1 = Increment address              │
   │  S       │ 0 = No display shift            │ 1 = Display shift                  │
   │  D       │ 0 = Display off                 │ 1 = Display on                     │
   │  C       │ 0 = Cursor off                  │ 1 = Cursor on                      │
   │  B       │ 0 = Cursor blink off            │ 1 = Cursor blink on                │
   │  S/C     │ 0 = Move cursor                 │ 1 = Shift display                  │
   │  R/L     │ 0 = Shift left                  │ 1 = Shift right                    │
   │  DL      │ 0 = 4-bit interface             │ 1 = 8-bit interface                │
   │  N       │ 0 = 1/8 or 1/11 Duty (1 line)   │ 1 = 1/16 Duty (2 lines)            │
   │  F       │ 0 = 5x7 dots                    │ 1 = 5x10 dots                      │
   │  BF      │ 0 = Can accept instruction      │ 1 = Internal operation in progress │
   └──────────┴─────────────────────────────────┴────────────────────────────────────┘

   DDRAM ADDRESS USAGE FOR A 1-LINE DISPLAY, 16x1, split memory for the line
   So the display is actually using the 2-line mode of the controller.
   
    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15   <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│40│41│42│43│44│45│46│47│  <- DDRAM ADDRESS (unshifted)
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘

   DDRAM ADDRESS USAGE FOR A 1-LINE DISPLAY (may be up to 80 columns)
   When using the 1-line mode of the controller.
   
    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39   <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│08│09│0A│0B│0C│0D│0E│0F│10│11│12│13│14│15│16│17│18│19│1A│1B│1C│1D│1E│1F│20│21│22│23│24│25│26│27│  <- DDRAM ADDRESS
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘

   DDRAM ADDRESS USAGE FOR A 2-LINE DISPLAY (up to 40 columns)

    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39   <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│08│09│0A│0B│0C│0D│0E│0F│10│11│12│13│14│15│16│17│18│19│1A│1B│1C│1D│1E│1F│20│21│22│23│24│25│26│27│  <- ROW0 DDRAM ADDRESS
   │40│41│42│43│44│45│46│47│48│49│4A│4B│4C│4D│4E│4F│50│51│52│53│54│55│56│57│58│59│5A│5B│5C│5D│5E│5F│60│61│62│63│64│65│66│67│  <- ROW1 DDRAM ADDRESS
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘

   DDRAM ADDRESS USAGE FOR A 4-LINE DISPLAY (up to 20 columns)
   Note that the first and third lines of the display are really part
   of the first "line" in the controller, and the second and fourth
   display lines are part of the second "line" in the controller.

    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19   <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│08│09│0A│0B│0C│0D│0E│0F│10│11│12│13│  <- ROW0 DDRAM ADDRESS
   │40│41│42│43│44│45│46│47│48│49│4A│4B│4C│4D│4E│4F│50│51│52│53│  <- ROW1 DDRAM ADDRESS
   │14│15│16│17│18│19│1A│1B│1C│1D│1E│1F│20│21│22│23│24│25│26│27│  <- ROW2 DDRAM ADDRESS
   │54│55│56│57│58│59│5A│5B│5C│5D│5E│5F│60│61│62│63│64│65│66│67│  <- ROW3 DDRAM ADDRESS
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
  
}}      
        
        
        
CON

  ' Command constants:
  ClearDisplayCmd = $01

  CursorHomeCmd   = $02

  ' modifiers for EntryModeSetCmd
  EntryModeSet_Incr        = $02
  EntryModeSet_Decr        = $00
  EntryModeSet_DispShift   = $01
  EntryModeSet_NoDispShift = $00
  
  EntryModeSetCmd = $04
  EntryModeSetCmd_Incr_Shift   = EntryModeSetCmd | EntryModeSet_Incr | EntryModeSet_DispShift
  EntryModeSetCmd_Incr_NoShift = EntryModeSetCmd | EntryModeSet_Incr | EntryModeSet_NoDispShift
  EntryModeSetCmd_Decr_Shift   = EntryModeSetCmd | EntryModeSet_Decr | EntryModeSet_DispShift
  EntryModeSetCmd_Decr_NoShift = EntryModeSetCmd | EntryModeSet_Decr | EntryModeSet_NoDispShift
  
  ' Modifiers for DisplayControlCmd
  DispCtl_DisplayOn        = $04
  DispCtl_DisplayOff       = $00
  DispCtl_CursorOn         = $02
  DispCtl_CursorOff        = $00
  DispCtl_Blinking         = $01
  DispCtl_NoBlinking       = $00

  ' Yes, I ran into the 30-character identifier limit...

  DispCtlCmd = $08
  DispCtlCmd_On_CrsrOn_Blink     = DispCtlCmd | DispCtl_DisplayOn  | DispCtl_CursorOn  | DispCtl_Blinking
  DispCtlCmd_On_CrsrOn_NoBlink   = DispCtlCmd | DispCtl_DisplayOn  | DispCtl_CursorOn  | DispCtl_NoBlinking
  DispCtlCmd_On_CrsrOff_Blink    = DispCtlCmd | DispCtl_DisplayOn  | DispCtl_CursorOff | DispCtl_Blinking
  DispCtlCmd_On_CrsrOff_NoBlink  = DispCtlCmd | DispCtl_DisplayOn  | DispCtl_CursorOff | DispCtl_NoBlinking
  DispCtlCmd_Off_CrsrOn_Blink    = DispCtlCmd | DispCtl_DisplayOff | DispCtl_CursorOn  | DispCtl_Blinking
  DispCtlCmd_Off_CrsrOn_NoBlink  = DispCtlCmd | DispCtl_DisplayOff | DispCtl_CursorOn  | DispCtl_NoBlinking
  DispCtlCmd_Off_CrsrOff_Blink   = DispCtlCmd | DispCtl_DisplayOff | DispCtl_CursorOff | DispCtl_Blinking
  DispCtlCmd_Off_CrsrOff_NoBlink = DispCtlCmd | DispCtl_DisplayOff | DispCtl_CursorOff | DispCtl_NoBlinking

  ' Modifiers for CursorShiftCmd
  CursorShift_Right    = $04
  CursorShift_Left     = $00

  CursorShiftCmd       = $10
  CursorShiftCmd_Right = CursorShiftCmd | CursorShift_Right
  CursorShiftCmd_Left  = CursorShiftCmd | CursorShift_Left

  ' Modifiers for DisplayShiftCmd  
  DisplayShift_Right    = $04
  DisplayShift_Left     = $00
  
  DisplayShiftCmd       = $18
  DisplayShiftCmd_Right = DisplayShiftCmd | DisplayShift_Right
  DisplayShiftCmd_Left  = DisplayShiftCmd | DisplayShift_Left

  ' Modifiers for FunctionSetCmd
  FunctionSet_8BitMode = $10
  FunctionSet_4BitMode = $00
  FunctionSet_1Line    = $00
  FunctionSet_2Lines   = $08
  FunctionSet_5x7Font  = $00
  'FunctionSet_5x7Font  = $04
  FunctionSet_5x10Font = $04

  FunctionSetCmd       = $20
  FunctionSetCmd_8Bit_1Line_5x7  = FunctionSetCmd | FunctionSet_8BitMode | FunctionSet_1Line  | FunctionSet_5x7Font
  FunctionSetCmd_8Bit_1Line_5x10 = FunctionSetCmd | FunctionSet_8BitMode | FunctionSet_1Line  | FunctionSet_5x10Font
  FunctionSetCmd_8Bit_2Line_5x7  = FunctionSetCmd | FunctionSet_8BitMode | FunctionSet_2Lines | FunctionSet_5x7Font
  FunctionSetCmd_8Bit_2Line_5x10 = FunctionSetCmd | FunctionSet_8BitMode | FunctionSet_2Lines | FunctionSet_5x10Font
  FunctionSetCmd_4Bit_1Line_5x7  = FunctionSetCmd | FunctionSet_4BitMode | FunctionSet_1Line  | FunctionSet_5x7Font
  FunctionSetCmd_4Bit_1Line_5x10 = FunctionSetCmd | FunctionSet_4BitMode | FunctionSet_1Line  | FunctionSet_5x10Font
  FunctionSetCmd_4Bit_2Line_5x7  = FunctionSetCmd | FunctionSet_4BitMode | FunctionSet_2Lines | FunctionSet_5x7Font
  FunctionSetCmd_84it_2Line_5x10 = FunctionSetCmd | FunctionSet_4BitMode | FunctionSet_2Lines | FunctionSet_5x10Font

  SetCgRamAddrCmd      = $40

  SetDisplayRamAddrCmd = $80

  ' Masks for commands or reading status
  BusyFlag             = $80
  DisplayRamAddrMask   = $7F
  CgRamAddrMask        = $3F

 
VAR

  ' Storage for the pin numbers of the LCD display interface
  byte E
  byte RW            
  byte RS
  byte DB4    ' These should span exactly 4 consecutive pins
  byte DB7

  ' InDDRAMMode is a flag that tracks in which data "mode" the display
  ' controller was last placed, using the Set CGRAM Address and
  ' Set DDRAM Address.
  ' This is used to optimize the WriteCommand() routine: if the command is
  ' setting the address, and the address from the display is already the
  ' same, we don't need to send the command. 
  byte InDDRAMMode

  ' CurrentFunctionSetCmd is the function set value used during initialization.
  ' It is recorded so that it can be re-sent in the ResendFunctionSetCmd
  ' method, which is used for some VFDs as the command sent before the
  ' brightness level is set.
  byte CurrentFunctionSetCmd

  byte LastCmdWasClear


PUB Init( Use2LineMode, Epin, RSpin, RWpin, DB7Pin, DB4pin )
'' Record the I/O pin numbers, and initialize the display
'' controller for 4-bit mode; the display is turned on and
'' cleared, and the cursor is turned off.

  ' Record the pin numbers
  E   := Epin   & $1F  ' limit to 0..31
  RW  := RWpin  & $1F
  RS  := RSpin  & $1F
  DB7 := DB7pin & $1F  ' NOTE: not checked for 4 consecutive pins
  DB4 := DB4pin & $1F

  ' preset the bit state for the output bits
  outa[E ]~       ' preset to zero
  outa[RS]~       ' preset initially to zero because we first transfer lots
                  ' of commands.  Once Init is done, we change to 1, for
                  ' mostly data transfers after that.
  outa[RW]~       ' preset to zero (we will be writing commands)
  outa[DB7..DB4]~ ' preset data bits to zero

  ' Set all those I/O pins to output
  ' When we want to read the status, we will change DB4..DB7 to input
  ' and change RW so that both the Propeller and the display controller
  ' do not drive those signals at the same time.
  dira[DB7..DB4]~~
  dira[RS]~~
  dira[RW]~~
  dira[E ]~~

  ' The various data sheets recommend a delay of up to 30 ms from the time
  ' the power is stable to the display, before initializing the display.
  ' Apparently that is the time needed to complete the power-up initialization
  ' steps. But normally, the startup time for the Propeller from power-on
  ' takes much longer than that, so we might not need the delay. The only
  ' reason we might need a delay here is if the power to the LCD display
  ' is controlled separately, under program control.
  ' KS0066U -- 30 ms delay
  ' HC44780 -- 15 ms delay

  'usDelay( 30_000 ) ' 30 ms delay -- probably not needed here.

  { Our first goal is to put the display into 4-bit mode.
    Now, most display controllers will be initialized at power-up
    to 8-bit mode, but if we also want to be able to use this to
    re-initialize a display, then the operation also has to work when
    the display is already in 4-bit mode. But there is no way to tell
    what mode the display is in by checking any I/O pins.
   
    So, we send a FunctionSet command to the display, to put it into
    a known state. Since the display might be in 4-bit mode, we have to
    pulse the E line twice to transfer both halves of the command, but
    if the display is in 8-bit mode, that will send the command twice,
    so we need a delay between the two pulses.
   
    If we were to send a FunctionSet command for 4-bit mode initially,
    that won't work, if the display is in 8-bit mode:
    - we send the first "part" of the command, with a pulse on E
    - Since the display is in 8-bit mode, right after sending the
      first E pulse, the display will now be in 4-bit mode
    - We pulse E a second time, and that is accepted as the first
      half of a transfer in 4-bit mode, so the controller is expecting
      the second half.
    But we cannot send it a third time, because that won't work if the
    display is already in 4-bit mode.
   
    The result of this is that we need to use a FunctionSet command for
    8-bit mode initially, in order to put the display controller into
    a known state.

    According to the H47780 datasheet, the proper way to initialize to 4-bit mode
    (Initialize by Instruction) is:
    - Wait for > 15ms after VXX rises to 4.5V
   
    - Send command: FunctionSetCmd_8Bit_1Line_5x7 as one transfer
      (cannot check BusyFlag before this)
      If the controller is in 4-bit mode already, this will be seen as
      only the first half of the command. If the controller is in 8-bit
      mode, then this leaves it in 8-bit mode.
   
    - Wait for > 4.1ms
   
    - Send command: FunctionSetCmd_8Bit_1Line_5x7 as one transfer
      (cannot check BusyFlag before this)
      If the controller was in 4-bit mode, this will be seen as the second
      half of the command, and this cmomand will put the controller into
      8-bit mode. If the controller was already in 8-bit mode, this command
      leaves it in 8-bit mode.
   
    - Wait > 100us
   
    - Send command: FunctionSetCmd_8Bit_1Line_5x7 as one transfer
      (cannot check BusyFlag before this)
      Not sure why this is needed...
   
    - Wait > 37 us
   
    - Send Command: FunctionSetCmd_4Bit_1Line_5x7
      (cannot check BusyFlag before this)
      This command should put the controller into 4-bit mode, and
      we can start using the Busy Flag.
   
    - wait for not busy (or > 37us)
    - Send Command: FunctionSetCmd_4Bit_<lines>_<font>
   
    - wait for not busy (or > 37us)
    - Send Command: DisplayControlCmd_<Display>_<Cursor>_<Blink>
   
    - wait for not busy (or > 37us)
    - Send Command: ClearDisplayCmd
   
    - wait for not busy (or > 1.53ms)
    - Send Command: EntryModeSetCmd_<incrdecr>_<blink>
  } 
  

  outa[DB7..DB4] := constant( FunctionSetCmd_8Bit_1Line_5x7 >> 4 )
  pulseE            ' send the command
  usDelay( 4_100 )  ' => 4.1 ms for HD44780U
           
  pulseE            ' send the same command again
  usDelay( 100 )    ' => 100 us for HD44780U
  pulseE            ' send the same command again
  usDelay( 37 )     ' command time (37 us at 270KHz), since we still cannot
                    ' check the Busy flag
    
  outa[DB7..DB4] := constant( FunctionSetCmd_4Bit_1Line_5x7 >> 4 )
  pulseE            ' send a single data pulse since we are in 8-bit mode

  ' Now we can use normal 4-bit transfers, and we can use the
  ' Busy flag to delay writing commands and data until ready
  
  LastCmdWasClear := 0
 
  ' Adjust for 1Line or 2Lines depending on geometry
  ' and assume 5x7 characters.
  if Use2LineMode
    CurrentFunctionSetCmd := FunctionSetCmd_4Bit_2Line_5x7
  else
    CurrentFunctionSetCmd := FunctionSetCmd_4Bit_1Line_5x7
  WriteCommand( CurrentFunctionSetCmd )

  WriteCommand( ClearDisplayCmd )
  WriteCommand( DispCtlCmd_On_CrsrOff_NoBlink )
  WriteCommand( EntryModeSetCmd_Incr_NoShift )
  InDDRAMMode~~


PUB ReadBusy : Busy
'' Read the Busy Flag and the address register from the display
'' controller. The Busy Flag is $80 in the returned value -- if
'' 1, the display controller is processing a command, if 0, the
'' controller is idle.

  ' To read the busy bit (and current Ram ptr):
  ' set DB7..DB4 to input -- Do this first, before telling the controller
  '                          chip that we will be reading, so that
  '                          there is no risk of both chips driving the
  '                          data lines at the same time.
  ' set RS to 0  -- We are reading the IR (not the DR) 
  ' set RW to 1  -- 1 means Reading.
  ' set E to 1   -- Start the transfer, this tells the controller to
  '                 put the high bits on the data lines
  ' read DB7..DB4 to get high order bits
  ' set E to 0
  ' set E to 1 -- the controller now puts the low bits onto the data lines
  ' read DB7..DB4 to get low order bits
  ' set E to 0
  ' set RW to 0
  ' set DB7..DB4 to output
  ' set RS to 1 (DR)
  '
  dira[DB7..DB4]~          ' make the data bits input
  outa[RS]~                ' reading IR not DR
  outa[RW]~~               ' reading not writing
  outa[E]~~                ' assert E
  Busy := ina[DB7..DB4] << 4   ' get the high 4 bits
  outa[E]~                 ' Deassert E
  outa[E]~~                ' cycle E again
  Busy |= ina[DB7..DB4]        ' get the low-order bits
  outa[E]~
  outa[RW]~                ' now we will be writing
  outa[RS]~~               ' we will be writing data
  dira[DB7..DB4]~~         ' now output bits again
  ' return Busy

PUB ReadData : data
  WaitUntilReady
  LastCmdWasClear := 0

  dira[DB7..DB4]~          ' make the data bits input
  'outa[RS]~~              ' stay reading DR not IR
  outa[RW]~~               ' reading not writing
  outa[E]~~                ' assert E
  data := ina[DB7..DB4] << 4   ' get the high 4 bits
  outa[E]~                 ' Deassert E
  outa[E]~~                ' cycle E again
  data |= ina[DB7..DB4]        ' get the low-order bits
  outa[E]~
  outa[RW]~                ' now we will be writing
  'outa[RS]~~              ' we are still writing data
  dira[DB7..DB4]~~         ' set pins to output again
  ' return data

Pub IsBusy
'' Returns true (-1) if the display controller is processing
'' the previous command, and returns false (0) if the display
'' controller is ready to accept commands/data.
  return ((ReadBusy & BusyFlag) <> 0)

Pub WaitUntilReady : CurAddr | i
'' Check the Busy Flag repeatedly until it is not set, so that
'' the display controller is ready for the next operation.
'' Returns the current address for DDRAM or CGRAM.

  ' Instead of calling ReadBusy() repeatedly, we put the
  ' read code directly into our loop, so that we don't
  ' have to change the direction of the data pins repeatedly,
  ' and toggle the other bits while waiting.

  ' Work-around for a problem with some displays:
  ' In my testing, I found that doing a display shift command right after
  ' a clear operation, using the Busy flag to maximize speed, that the
  ' first display shift would often not done. I am not sure if any other
  ' operations also might need delay, so I added a delay to this Wait
  ' routine if the most recent operation was a Clear. We repeat the
  ' test for no-longer-Busy multiple times to create the delay.  
  
  i := 1
  if ( LastCmdWasClear )
    i := 3 ' take longer after a Clear command
    LastCmdWasClear := 0

  repeat i
    dira[DB7..DB4]~          ' make the data bits input
    outa[RS]~                ' reading IR not DR
    outa[RW]~~               ' reading not writing
    CurAddr := BusyFlag      ' assume busy first time in
    repeat while ( (CurAddr & BusyFlag) <> 0 )
      outa[E]~~                        ' assert E
      CurAddr := ina[DB7..DB4] << 4    ' get the high 4 bits        
      outa[E]~                         ' deassert E
      outa[E]~~
      CurAddr |= ina[DB7..DB4]         ' get the low-order bits
      outa[E]~
    outa[RW]~                ' now we will be writing
    outa[RS]~~               ' we will be writing data, not commands
    dira[DB7..DB4]~~         ' set pins to output

  ' return CurAddr ' the current DDRAM/CGRAM address.


PUB WriteCommand( cmd ) : CurAddr
'' Sends a command to the display controller.
'' Will wait for the Busy Flag to be clear before sending the
'' command. Contains some optimizations to eliminate redundant
'' cursor positioning commands.
'' Returns the current RAM address returned from the controller
'' just before sending the command. So, if the command changes
'' the RAM address (DDRAM or CGRAM) the returned value will be
'' the address _before_ the command changes it.

  CurAddr := WaitUntilReady

  ' If we are setting the DDRAM or CGRAM address, we see if we can
  ' skip sending the command because the address is already correct.
  ' This allows our "customers" to be a little less efficient
  ' about avoiding cursor positioning calls.
  
  if ( ( cmd & SetDisplayRamAddrCmd ) <> 0 )
  
    ' See if we can skip sending this command:
    ' - if we are in DDRAM mode, and CurAddr matches
    '   the address in the command, we don't have to issue
    '   the command 
    if ( InDDRAMMode AND (cmd == (CurAddr | SetDisplayRamAddrCmd)) )
      return CurAddr ' no need to issue this command.
    ' Otherwise, we will be in DDRAM mode
    InDDRAMMode~~
    
  elseif( ( cmd & SetCgRamAddrCmd ) <> 0 )
    ' See if we can ship sending this command:
    ' - If we are in CGRAM mode, and CurAddr matches
    '   the address in the command, we don't have to issue
    '   the command 
    if ( (NOT InDDRAMMode) AND (cmd == (CurAddr | SetCgRamAddrCmd)) )
      return CurAddr ' no need to issue this command.
    ' Otherwise, we will be in CGRAM mode
    InDDRAMMode~
  
  outa[RS]~        ' writing IR (Instruction Register)
  writeByteNoWait( cmd )
  outa[RS]~~       ' back to writing DR (Data Register)

  LastCmdWasClear := ( cmd == ClearDisplayCmd )
  ' return CurAddr

PUB WriteByte( d ) : CurAddr
'' Write the data byte to the display controller
'' Can be used to write display data, or Character Generator data
'' Returns the Display RAM address (or CGRAM address) at which the
'' data was written.

  CurAddr := WaitUntilReady
  LastCmdWasClear := 0
  writeByteNoWait( d )
  ' return CurAddr

PUB WriteData( adr, len ) : CurAddr
'' Writes a series of data bytes to the display controller starting
'' at the current RAM address.
'' Returns the display RAM Address (or CGRAM address) into which
'' the first character of the list of bytes was written.
'' 'len' may be zero, in which case it simply returns the
'' current RAM address.

  CurAddr := WaitUntilReady   ' wait for idle, collect the starting address
  LastCmdWasClear := 0
  if ( len > 0 )
    writeByteNoWait( byte[adr++] )
    repeat len-1
      WaitUntilReady
      writeByteNoWait( byte[adr++] )
  ' return CurAddr

PUB ResendFunctionSetCmd
'' Resend the Function Set command that was sent during initialization.
'' This is used by some VFDs to signal that the next data byte will set
'' the display brightness.

  WriteCommand( CurrentFunctionSetCmd )


PUB usDelay( Delay )
'' Delay at least the specified number of microseconds
'' The smallest time interval we can use here is about 4.5 us for
'' an 80MHz clock, due to Spin overhead.
  waitcnt( (((clkfreq / 1_000_000) * Delay) #> 382 )+ cnt)

PRI writeByteNoWait( d )
  ' Send data or a command to the display controller
  ' the 4 high bits first, then the 4 low bits.
  
  outa[DB7..DB4] := (d >> 4) ' high 4 bits
  pulseE                     ' assert, then deassert E, to trigger the
                             ' write of the data
  outa[DB7..DB4] := d        ' low 4 bits
  pulseE

PRI pulseE
  ' Assert, then deassert the E signal pin
  outa[E]~~
  outa[E]~

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
