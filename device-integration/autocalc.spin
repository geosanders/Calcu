' a simple program that simulates key presses from the calculator

con

  _clkmode = xtal1 + pll4x                                      ' run @ 20MHz in XTAL mode
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000

obj
  rand  : "jm_prng"
  leds  : "jm_pwm8"
  term : "PC_Interface"

dat

KEY_DATA      ' these are all exactly 4 bytes, so we can index into it easily
        byte "0", 0, 0, 0
        byte "00", 0, 0
        byte "1", 0, 0, 0
        byte "2", 0, 0, 0
        byte "3", 0, 0, 0
        byte "4", 0, 0, 0
        byte "5", 0, 0, 0
        byte "6", 0, 0, 0
        byte "7", 0, 0, 0
        byte "8", 0, 0, 0
        byte "9", 0, 0, 0
        byte ".", 0, 0, 0
        byte "-", 0, 0, 0
        byte "+", 0, 0, 0
        byte "%", 0, 0, 0
        byte "div", 0
        byte "mul", 0
        byte "+-", 0, 0

KEY_DATA_END


pub main | wait_time, qnum, qcount, qptr

  leds.start(8, 16)                                                             ' start led drivers
  term.start(31,30)                                                             ' start terminal
  rand.start                                                                    ' start random number generator

  qcount := (@KEY_DATA_END - @KEY_DATA) / 4

  repeat

    qnum := (||rand.random) // qcount
    qptr := @KEY_DATA.long[qnum]

    leds.digital(128, %11111111) ' FIXME, why does this only flash one LED?

    term.str(string(34))
    term.str(qptr)
    term.str(string(34, 10))

    pause(50)
    leds.digital(0, %11111111)

    wait_time := ((||rand.random) // 5000) + 2000
    pause(wait_time)

  return


pub pause(ms) | t

'' Delay program in milliseconds
'' -- use only in full-speed mode

  if (ms < 1)                                                                   ' delay must be > 0
    return
  else
    t := cnt - 1792                                                             ' sync with system counter
    repeat ms                                                                   ' run delay
      waitcnt(t += MS_001)

