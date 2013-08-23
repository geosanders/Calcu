con

  _clkmode = xtal1 + pll4x                                      ' run @ 20MHz in XTAL mode
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000


obj
  leds  : "jm_pwm8"
  term : "PC_Interface"
       
pub main | test1

  leds.start(8, 16)                                         ' start drivers

  pause(5)

  leds.digital(0, %11111111)

'  repeat 255                          
'    leds.inc_all

  term.start(31,30)

  pause(5)
  
  term.str(string("Hello World",13))  

  dira[0] := 0
  dira[1] := 0
  dira[2] := 0
  dira[3] := 0
  dira[4] := 0
  dira[5] := 0
  dira[6] := 0
  dira[7] := 0

                      
  repeat 64                          
    leds.inc_all
    pause(20)
    'waitcnt(1)
                          
  repeat 64                          
    leds.dec_all
    pause(20)


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

  if (ms < 1)                                                   ' delay must be > 0
    return
  else
    t := cnt - 1792                                             ' sync with system counter
    repeat ms                                                   ' run delay
      waitcnt(t += MS_001)

var
  byte  test_buf[33]


pub ltoa(n)                      ' convert integer to string
    