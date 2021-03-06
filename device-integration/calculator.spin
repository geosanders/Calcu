{{
─────────────────────────────────────────────────
File: calculator.spin
Version: 0.1

Copyright (C) 2013, Licensed under the APL
(If someone else actually ever uses this code for something,
feel free to contact me.  Odds are that day will never come.)
Author: Brad Peabody
─────────────────────────────────────────────────
}}

{

Functional calculator with keypad scanning, LCD output, calculation logic, and serial output to PC
(for display on large screen).


TODO:
* WONTFIX, not needed - Re-init LCD on C key, so if power issues or something, we reset the screen.
* FIXED - Make tape data output from calceng
* FIXED Implement backspace
* Tape row adds even when no calc is done (plus, plus, plus, etc.)
* Implement sign toggle
* Make period not be just "." but "0." if press when zero is in display
*

}

con

  '_clkmode = xtal1 + pll4x                                      ' run @ 20MHz in XTAL mode
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000

  ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  ' LCD constants

  ' control pins
  LCD_PIN_RS = 4
  LCD_PIN_RW = 5
  LCD_PIN_E  = 6

  ' data bus pin range
  LCD_PIN_DBLow  = 0 
  LCD_PIN_DBHigh = 3

  ' how many characters wide is the LCD
  LCD_CHAR_WIDTH = 16

  ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  ' keypad constants (columns drive, rows sense)
  KEYPAD_COLS          = %1_00111100_10000000
  KEYPAD_ROWS          = %0_11000011_00000000


obj

  SER : "ParallaxSerialTerminal"        ' serial interface
  STR : "ASCII0_STREngine_1"            ' string manipulation
  TIM : "Timing"                        ' timing/pauses
  CALC: "calceng"                       ' calculator engine
  LCD : "LCD_16x1_SxS"                  ' LCD driver
  KEY : "ARCKEY"                        ' keypad scanner

dat

' map of keypad keycodes to calculator "command" characters
keytbl
        word $00e8,"C"
        word $0149,"X"
        word $0148,"/"
        word $00e9,"="
        word $01a9,"0"
        word $01af,"."
        word $01ae,"Z"
        word $0168,"1"
        word $0169,"2"
        word $016e,"3"
        word $016f,"4"
        word $0189,"5"
        word $0188,"6"
        word $018e,"7"
        word $018f,"8"
        word $01a8,"9"
        word $014e,"-"
        word $014f,"+"
        word $0209,"|"  ' sign toggle
        word $020f,"B"  ' backspace
        word  0

debug_console_keys                      ' this is a bit odd, but the serial terminal
                                        ' sends strange codes for each key.  i just map
                                        ' them for now since i only need to emulate
                                        ' the calculator keys and i don't have time
                                        ' to debug this particular bit of strangeness
        byte 48, "0"
        byte 49, "1"
        byte 50, "2"
        byte 51, "3"
        byte 52, "4"
        byte 53, "5"
        byte 54, "6"
        byte 55, "7"
        byte 56, "8"
        byte 57, "9"
        byte 45, "-"
        byte 43, "+"
        byte 61, "="
        byte 47, "/"
        byte 88, "X"
        byte 42, "X"
        byte 27, "C"
        byte 46, "."
        byte 0, 0                       ' end


var

  byte outbuf[256]                      ' output buffer for strings
  byte lcdtxt[32]                       ' LCD text temp buffer

pub main

  _init

  run
  'runDebugKeyMapper


pub runDebugKeyMapper : ch ' used during dev to figure out keypad

  repeat
    ch := KEY.scankeys
    'SER.str(KEY.getdebugstr)
    'SER.hex(ch,4)
    'SER.str(string(13,10))
    if ch+1
      SER.str(string(13,10,"Scancode = "))
      SER.hex(ch,4)
      SER.str(string(" : Keycode = "))
      ch := KEY.translate(ch)
      SER.hex(ch,4)
      SER.str(string(13,10))
    'TIM.pause1s(1)
    TIM.pause1ms(10)



pub run | ch, cmd, ptr, len, tmp

  ch := 0

  ' first command is clear
  cmd := "C"

  repeat

    ' cmd is reset at bottom...

    ' check for serial terminal input
    if SER.RxCount
      ch := SER.CharIn

      ' to debug character input
      'SER.Str(STR.integerToDecimal(ch, 2))

      ptr := @debug_console_keys
      repeat while byte[ptr+1] AND cmd == 0
        if byte[ptr] == ch
          cmd := byte[ptr+1]
        ptr += 2

    ' check for keypad input
    if cmd == 0
      'SER.Str(string("GOT HERE",13,10))
      ch := KEY.scankeys
      if ch+1
        ch := KEY.translate(ch)
        cmd := ch
        'SER.Str(string("GOT KEY: "))
        'SER.hex(ch, 4)
        'SER.Str(string(13,10))
      ' run at max rate...
      'TIM.pause1ms(2)

    ' if command was found by either means
    if cmd

      ' tell PC about the command
      writeJson(string("{'c':'key','d':'"))
      writeJson(@cmd)           ' works because it's a long an higher bytes are zero so it's a valid stringz
      writeJsonLn(string("'}"))

      ' tell calc engine about it
      ptr := CALC.processKey(cmd)

      ' pad LCD display with spaces
      len := strsize(ptr)
      tmp := LCD_CHAR_WIDTH - len
      repeat while tmp
        lcdtxt[--tmp] := " "

      ' copy LCD text, right aligned
      tmp := LCD_CHAR_WIDTH - len
      STR.stringCopy(@lcdtxt + tmp, ptr)

      ' add in the operator
      if CALC.getPendingOp AND (CALC.isInNewEquals OR NOT CALC.wasEqualsPressed)
        lcdtxt[0] := CALC.getPendingOp

      ' update LCD display
      LCD.Clear
      LCD.PrintStr(@lcdtxt)

      ' write debug output to serial
      writeJson(string("{'c':'lcdtxt','d':'"))
      writeJson(@lcdtxt)
      writeJsonLn(string("'}"))

      ' get tape line and if any write that out
      tmp := CALC.popTapeLine
      if tmp
        writeJsonLn(tmp)
        'SER.hex(tmp[0],4)
        'SER.hex(tmp,8)
        'SER.str(string(13,10))
        'SER.dec(strsize(tmp))
        'SER.str(string(13,10))

    ' clear out command and start over again..
    cmd := 0



pub _init

  ' start up serial interface
  SER.Start(115200)   ' (uses pins 31,30 by default)

  writeJsonLn(string("{'c':'init','d':'calculator initializing'}"))

  CALC.init

  writeJsonLn(string("{'c':'init_status','d':'starting LCD display'}"))

  ' not sure if all of these pauses are needed, but couldn't really hurt
  TIM.pause1ms(100)
  LCD.Init(LCD_PIN_E, LCD_PIN_RS, LCD_PIN_RW, LCD_PIN_DBHigh, LCD_PIN_DBLow)
  TIM.pause1ms(10)
  LCD.Clear
  LCD.PrintStr( string("Warming up...") )
  TIM.pause1ms(10)

  writeJsonLn(string("{'c':'init_status','d':'starting keypad scanner'}"))

  KEY.pins(KEYPAD_ROWS,KEYPAD_COLS)
  KEY.table(@keytbl)

  TIM.pause1ms(500)

  LCD.Clear
  LCD.PrintStr( string("Starting...") )

  TIM.pause1ms(250)

  writeJsonLn(string("{'c':'ready','d':'ready to roll'}"))


pub writeJson(strptr)                 ' helper to write JSON data to serial, replaces single quotes with double
                                      ' so the SPIN string literals can be way simpler
  STR.stringCopy(@outbuf, strptr)
  STR.replaceAllCharacters(@outbuf, "'", 34)
  SER.str(@outbuf)

pub writeJsonLn(strptr)               ' line writeJson but adds a newline also
  writeJson(strptr)
  SER.Char(10)

