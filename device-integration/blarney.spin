' a simple program that periodically and continually blabs out various text, so we can test reading from the serial port

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

QUOTE1  byte  "If the freedom of speech is taken away then dumb and silent we may be led, like sheep to the slaughter. -George Washington",0
QUOTE2  byte  "A kiss is a lovely trick designed by nature to stop speech when words become superfluous. -Ingrid Bergman",0
QUOTE3  byte  "The trouble with her is that she lacks the power of conversation but not the power of speech. -George Bernard Shaw",0
QUOTE4  byte  "I have a dream that my four little children will one day live in a nation where they will not be judged by the color of their skin but by the content of their character. - MLK",0
QUOTE5  byte  "And so, my fellow Americans, ask not what your country can do for you; ask what you can do for your country.  My fellow citizens of the world, ask not what America will do for you, but what together we can do for the freedom of man. - JFK",0
QUOTE6  byte  "My most brilliant achievement was my ability to be able to persuade my wife to marry me. -Winston Churchill",0
QUOTE7  byte  "You can always count on Americans to do the right thing - after they've tried everything else. -Winston Churchill",0
QUOTE8  byte  "I may be drunk, Miss, but in the morning I will be sober and you will still be ugly. -Winston Churchill",0
QUOTE9  byte  "I am fond of pigs. Dogs look up to us. Cats look down on us. Pigs treat us as equals. -Winston Churchill",0
QUOTE10 byte  "This report, by its very length, defends itself against the risk of being read. -Winston Churchill",0

pub main | wait_time, qnum, qptr

  leds.start(8, 16)                                                             ' start led drivers
  term.start(31,30)                                                             ' start terminal
  rand.start                                                                    ' start random number generator

  wait_time := 0

  repeat

    qptr := @QUOTE1

    qnum := ((||rand.random) // 10) + 1
    if qnum == 1
      qptr := @QUOTE1
    elseif qnum == 2
      qptr := @QUOTE2
    elseif qnum == 3
      qptr := @QUOTE3
    elseif qnum == 4
      qptr := @QUOTE4
    elseif qnum == 5
      qptr := @QUOTE5
    elseif qnum == 6
      qptr := @QUOTE6
    elseif qnum == 7
      qptr := @QUOTE7
    elseif qnum == 8
      qptr := @QUOTE8
    elseif qnum == 9
      qptr := @QUOTE9
    elseif qnum == 10
      qptr := @QUOTE10

    leds.digital(128, %11111111) ' FIXME, why does this only flash one LED?
    term.str(qptr)
    term.str(string(13))
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

