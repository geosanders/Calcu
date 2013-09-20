MS_001con

  _clkmode = xtal1 + pll4x                                      ' run @ 20MHz in XTAL mode
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000


obj
  term : "PC_Interface"
  num : "Numbers"
  'leds : "jm_pwm8"

pub main | r, testpin

  term.start(31,30)                                     ' fire up the terminal

  'leds.start(8, 16)                                         ' start drivers

  pause(5)

  'leds.digital(0, %11111111)

  num.Init

  term.str(string("TESTING", 13))


  dira[7] := 1
  dira[8] := 0

  outa[7] := 1

  repeat
    term.hex(ina[8],1)
    term.str(string(13,10))
    pause(500)


  'dira[0..11] := 1
  'dira[24..27] := 1

  'RS = 9
  'RW = 10
  'E  = 11
  testpin := 7

  'outa[0..11] := 1
  'outa[24..27] := 1

  dira[testpin] := 1

  repeat
    pause(2000)
    term.str(string("OFF", 13))
    outa[testpin] := 0
    'outa[0..11] := 0
    'outa[24..27] := 0
    pause(2000)
    term.str(string("ON", 13))
    outa[testpin] := 1
    'outa[0..11] := 1
    'outa[24..27] := 1

  ''''''

  repeat
    term.str(string("OFF", 13))
    outa[25] := 0
    pause(2500)
    r := ina[24]
    term.str(string("read says: "))
    term.str(num.ToStr(r, %000_000_000_0_0_000000_01010))
    term.str(string(13,10))
    pause(2500)

    term.str(string("ON", 13))
    outa[25] := 1
    pause(2500)
    r := ina[24]
    term.str(string("read says: "))
    term.str(num.ToStr(r, %000_000_000_0_0_000000_01010))
    term.str(string(13,10))
    pause(2500)


  return

  dira[27] := 1
  dira[26] := 1
  dira[25] := 1
  dira[24] := 1

  outa[24..27] := 0


  repeat
    term.str(string("OFF", 13))
    outa[25] := 0
    pause(2500)
    r := ina[24]
    term.str(string("read says: "))
    term.str(num.ToStr(r, %000_000_000_0_0_000000_01010))
    term.str(string(13,10))
    pause(2500)

    term.str(string("ON", 13))
    outa[25] := 1
    pause(2500)
    r := ina[24]
    term.str(string("read says: "))
    term.str(num.ToStr(r, %000_000_000_0_0_000000_01010))
    term.str(string(13,10))
    pause(2500)

pub pause(ms) | t

'' Delay program in milliseconds
'' -- use only in full-speed mode

  if (ms < 1)                                                                   ' delay must be > 0
    return
  else
    t := cnt - 1792                                                             ' sync with system counter
    repeat ms                                                                   ' run delay
      waitcnt(t += MS_001)


