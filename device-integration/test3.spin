con

  _clkmode = xtal1 + pll4x                                      ' run @ 20MHz in XTAL mode
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000


obj
  leds  : "jm_pwm8"
  term : "PC_Interface"
       
pub main | pin_state, cycle_count, i

  leds.start(8, 16)                                         ' start led drivers

  pause(5)

  leds.digital(0, %11111111)

  term.start(31,30)                                     ' fire up the terminal

  pause(5)
  
  term.str(string(13, 13, 13))

  term.str(string(34, "INITIALIZING", 34, 13))

  ' clear all output
  outa[0] := 0
  outa[1] := 0
  outa[2] := 0
  outa[3] := 0
  outa[4] := 0
  outa[5] := 0
  outa[6] := 0
  outa[7] := 0

  ' set pin directions
  dira[0] := 0
  dira[1] := 0
  dira[2] := 0
  dira[3] := 0
  dira[4] := 0
  dira[5] := 0
  dira[6] := 0
  dira[7] := 0


  term.str(string(34, "LED LIGHT SHOW", 34, 13))

  ' start up LED display - give the user some time to prepare...
  repeat 128
    leds.inc_all
    pause(20)
    'waitcnt(1)
                          
  repeat 128
    leds.dec_all
    pause(20)

  term.str(string(34, "ACTIVATED", 34, 13))


{
  term.str(string("test"))
  term.str(ltoa(50))
  term.str(string(13))
  term.str(string("test"))
  term.str(ltoa(128))
  term.str(string(13))
  term.str(string("test"))
  term.str(ltoa(1234))
  term.str(string(13))
  term.str(string("test"))
  term.str(ltoa(0))
  term.str(string(13))
  term.str(string("test"))
  term.str(ltoa(55551))
  term.str(string(13))
}

  test_buf[0] := 0
  test_buf[1] := 0
  test_buf[2] := 0

  cycle_count := 5000

  pin_state := 0

  i := 0

  repeat cycle_count
    ' read pin states in one shot
    data_buf[i++] := ina[0..7]

  test_buf[0] := 0
  test_buf[1] := 0
  i := 0
  repeat cycle_count
    'test_buf[0] := data_buf[i++] '((data_buf[i++] & %01000000) >> 6) + "0"
    test_buf[0] := ((data_buf[i++] & %11000000) >> 6) + "0"
    term.str(@test_buf)
    if i // 64 == 0
      test_buf[0] := 13
      term.str(@test_buf)

  return

  repeat cycle_count
    ' read pin states in one shot
    pin_state := ina[0..7]
    data_buf[i] := pin_state
    test_buf[0] := test_buf[0] + ((pin_state & %10000000) >> 7)
    test_buf[1] := test_buf[1] + ((pin_state & %01000000) >> 6)
    if pin_state & %11000000 == %11000000
      test_buf[2] := test_buf[2] + 1
    'pause(1)
    i++

  term.str(string("After "))
  term.str(ltoa(cycle_count))
  term.str(string(" cycles:", 13))

  term.str(string("pin 0 was on "))
  term.str(ltoa(test_buf[0]))
  term.str(string(" times", 13))

  term.str(string("pin 1 was on "))
  term.str(ltoa(test_buf[1]))
  term.str(string(" times", 13))

  term.str(string("pin 0 and 1 were both on "))
  term.str(ltoa(test_buf[2]))
  term.str(string(" times", 13))

  return

  repeat 5000
'    term.str(string("Pin Test:",13))

    test_buf[0] := ina[0] + "0"
    test_buf[1] := ina[1] + "0"
    test_buf[2] := ina[2] + "0"
    test_buf[3] := ina[3] + "0"
    test_buf[4] := ina[4] + "0"
    test_buf[5] := ina[5] + "0"
    test_buf[6] := ina[6] + "0"
    test_buf[7] := ina[7] + "0"
    test_buf[8] := 0

    term.str(string("{",34,"type",34,":",34,"pindata",34,",",34,"data",34,":",34))
    term.str(@test_buf)
    term.str(string(34,"}",13))

    pause(50)

 '   term.str(string("End",13))

  
    
   
   
pub pause(ms) | t

'' Delay program in milliseconds
'' -- use only in full-speed mode 

  if (ms < 1)                                                                   ' delay must be > 0
    return
  else
    t := cnt - 1792                                                             ' sync with system counter
    repeat ms                                                                   ' run delay
      waitcnt(t += MS_001)

dat

HEX_ALPHABET  byte      "0123456789ABCDEF"

var
  byte  test_buf[33]
  byte  ltoa_buf[20]                                                            ' buffer for ltoa output
  byte  data_buf[5000]                                                          ' temp buffer for strobe data

pub ltoa(num): r | value, i, j, len, tmp                                        ' convert integer to string

  value := num
  i := 0

  ' TODO: negative numbers will produce serious funk...

  ' special handling for zero
  if value == 0
    ltoa_buf[0] := "0"
    ltoa_buf[1] := 0
  else ' for other numbers we go through and get the remainder and divide - pretty simple actually
    repeat while value > 0
      ltoa_buf[i] := (value // 10) + "0"
      value := value / 10
      i := i + 1

    ' cap the string with a zero
    len := i
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

pub ltoa16(num): r | value, i, j, len, tmp                                       ' convert integer to string (hex)

  value := num
  i := 0

  ' TODO: negative numbers will produce serious funk...

  ' special handling for zero
  if value == 0
    ltoa_buf[0] := "0"
    ltoa_buf[1] := 0
  else ' for other numbers we go through and get the remainder and divide - pretty simple actually
    repeat while value > 0
      ltoa_buf[i] := HEX_ALPHABET[value // 16]
      value := value / 16
      i := i + 1

    ' cap the string with a zero
    len := i
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

pub ltoa2(num): r | value, i, j, len, tmp                                       ' convert integer to string (binary)

  value := num
  i := 0

  ' TODO: negative numbers will produce serious funk...

  ' special handling for zero
  if value == 0
    ltoa_buf[0] := "0"
    ltoa_buf[1] := 0
  else ' for other numbers we go through and get the remainder and divide - pretty simple actually
    repeat while value > 0
      ltoa_buf[i] := (value // 2) + "0"
      value := value / 2
      i := i + 1

    ' cap the string with a zero
    len := i
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

