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
  LCD_PIN_RS = 9
  LCD_PIN_RW = 10
  LCD_PIN_E  = 11

  ' data bus pin range
  LCD_PIN_DBLow  = 0 
  LCD_PIN_DBHigh = 3

  ' how many characters wide is the LCD
  LCD_CHAR_WIDTH = 16

  ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
  ' keypad constants
  KEYPAD_COLS          = %00000000_00011000
  KEYPAD_ROWS          = %00001101_00000000


obj

  SER : "ParallaxSerialTerminal"        ' serial interface
  STR : "ASCII0_STREngine_1"            ' string manipulation
  TIM : "Timing"                        ' timing/pauses
  CALC: "calceng"                       ' calculator engine
  LCD : "LCD_16x1_SxS"                  ' LCD driver
  KEY : "ARCKEY"                        ' keypad scanner

dat

' map of keycodes to calculator "command" characters
keytbl
        word %00001000_00000001, "0"
        word %00000100_00000001, "1"
'        word $012b,"1"
'        word $010b,"2"
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

  'run
  runDebug


pub runDebug | ch, cmd, ptr, len, tmp

  ch := 0

  repeat

    cmd := 0

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

      ' write debug output to serial
      writeJson(string("{'c':'lcdtxt','d':'"))
      writeJson(@lcdtxt)
      writeJsonLn(string("'}"))

  repeat
    ch := KEY.scankeys
    'serial.str(KEY.getdebugstr)
    'serial.str(ltoa16(ch, 2))
    'serial.str(string(13,10))
    if ch+1
      'serial.str(string(13,10,"Scancode = "))
      'serial.bin(ch,4)
      'serial.str(string(" : Keycode = "))
      ch := KEY.translate(ch)
      'serial.bin(ch,4)
      'serial.str(string(13,10))
    TIM.pause1s(1)


pub run


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
  TIM.pause1ms(10)
  LCD.PrintStr( string("Warming up...") )
  TIM.pause1ms(10)

  writeJsonLn(string("{'c':'init_status','d':'starting keypad scanner'}"))

  KEY.pins(KEYPAD_ROWS,KEYPAD_COLS)
  KEY.table(@keytbl)

  TIM.pause1ms(500)

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

