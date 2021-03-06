{{
**************************************************************************
*
*   ARCKEY.spin
*   ARC KEYBOARD SCANNER EMNCODER V1.0
*   October 2011 Peter Jakacki
*
**************************************************************************
}}
' See ARCKEY.spin for more information

' Demo setup - attach keypad to P0..P7 and set rows and columns accordingly

con
  '_CLKMODE = XTAL1 + PLL16X
  '_XINFREQ = 8_000_000
  'clockfreq = ((_CLKMODE - XTAL1) >> 6) * _XINFREQ

  _CLKMODE      = XTAL1 + PLL16X
  _XINFREQ      = 5_000_000


  ' note - drive from columns, sense with rows

  'columns       = %00001111     ' assume columns are on P0..P3
  'rows          = %11110000     ' assume columns are on P4..P7
  columns       = %00000000_00011000
  rows          = %00001101_00000000
  'columns       = %10000000
  'rows          = %01000000
  txd           = 30
  rxd           = 31

obj
  'serial :      "FullDuplexSerial"
  serial :      "PC_Interface"
  'DBG :      "SimpleDebug"
  keypad :      "ARCKEY"
  time : "Timing"

pub start                    ' insert startup method demo or demo2
  demo

' Demo will display the scancode and try to translate this code as well

pub demo | ch

  'DBG.start(9600)
  'DBG.str(string("TEST!", 13, 10))

    'serial.start(rxd,txd,0,9600)
    serial.start(rxd,txd)
    serial.str(@SPLASH)


'    outa[0] := 1
'    dira[0] := 1
'    ch := ina[1]


'    repeat ' freez
'      ch := ina[1]
'      serial.str(ltoa16(ch, 2))
'      serial.str(string(13,10))
'      time.pause1ms(250)


    'serial.str(string(13,10,"TEST", 13, 10))
    'keypad.pins(%110000000101,%1101010000) '(rows,columns)
    keypad.pins(rows,columns) '(rows,columns)
    keypad.table(@keytbl)
    repeat
      ch := keypad.scankeys
      serial.str(keypad.getdebugstr)
      'serial.str(ltoa16(ch, 2))
      serial.str(string(13,10))
      if ch+1
        serial.str(string(13,10,"Scancode = "))
        serial.bin(ch,4)
        serial.str(string(" : Keycode = "))
        ch := keypad.translate(ch)
        serial.bin(ch,4)
        serial.str(string(13,10))
      time.pause1s(1)

' This method demonstrate how the application would normally access the keypad
'
pub demo2 | ch
    keypad.pins(rows,columns)
    keypad.table(@keytbl)
    'serial.start(rxd,txd,0,9600)
    serial.start(rxd,txd)
    serial.str(@SPLASH)
    repeat
      ch := keypad.key                                  ' read a key, translate if possible
      if ch+1                                           ' quick way of saying if ch <> -1
        serial.str(string(13,10,"Keycode = "))
        serial.hex(ch,4)

pub ltoa16(num, pad_len): r | value, i, j, len, tmp                                       ' convert integer to string (hex)

  value := num
  i := 0

  ' TODO: negative numbers will produce serious funk...

  ' special handling for zero
  if value == 0
    ltoa_buf[0] := "0"
    ltoa_buf[1] := 0
    i := 1
  else ' for other numbers we go through and get the remainder and divide - pretty simple actually
    repeat while value > 0
      ltoa_buf[i] := HEX_ALPHABET[value // 16]
      value := value / 16
      i := i + 1

  ' cap the string with a zero
  len := i
  ltoa_buf[len] := 0
  repeat while len < pad_len
    ltoa_buf[len++] := "0"
    ltoa_buf[len] := 0

  ' now reverse it
  i := 0
  j := len - 1
  repeat while i < j
    tmp := ltoa_buf[j]
    ltoa_buf[j] := ltoa_buf[i]
    ltoa_buf[i] := tmp
    i++
    j--

  ' we're done
  r := @ltoa_buf

var

  byte  ltoa_buf[20]                                                            ' buffer for ltoa output

dat

HEX_ALPHABET  byte      "0123456789ABCDEF"
'
' Sample scancode translation table.
' Find the scancodes by running the Demo and then include this scancode
' in the table along with the desired keycode
'
keytbl
        word %00001000_00000001, "A"
        word %00000100_00000001, "B"
'        word $012b,"1"
'        word $010b,"2"
'        word $00cb,"3"
'        word $012a,"4"
'        word $010a,"5"
'        word $00ca,"6"
'        word $0120,"7"
'        word $0100,"8"
'        word $00c0,"9"
'        word $0122,"*"
'        word $0102,"0"
'        word $00c2,"#"
'        word $0003,"O"
        word  0

SPLASH
        byte  13,10,"ARCKEY DEMO - arbitrary row and column keyboard encoding",13,10,0


DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}
