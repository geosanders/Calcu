' a "blank" program that just runs forever blinking one of the LEDs, useful while testing/deving

con

  _clkmode = xtal1 + pll4x                                      ' run @ 20MHz in XTAL mode
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000

obj
  leds  : "jm_pwm8"

pub main

  leds.start(8, 16)                                         ' start led drivers

  repeat
    leds.digital(0, %11111111)
    pause(1000)
    leds.digital(128, %11111111)
    pause(1000)


pub pause(ms) | t

'' Delay program in milliseconds
'' -- use only in full-speed mode

  if (ms < 1)                                                                   ' delay must be > 0
    return
  else
    t := cnt - 1792                                                             ' sync with system counter
    repeat ms                                                                   ' run delay
      waitcnt(t += MS_001)

