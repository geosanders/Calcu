MS_001con

  _clkmode = xtal1 + pll4x                                      ' run @ 20MHz in XTAL mode
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000

  ' generic indexes for various keys
  KEY_0         = 0
  KEY_1         = 1
  KEY_2         = 2
  KEY_3         = 3
  KEY_4         = 4
  KEY_5         = 5
  KEY_6         = 6
  KEY_7         = 7
  KEY_8         = 8
  KEY_9         = 9
  KEY_ON        = 10
  KEY_OFF       = 11
  KEY_EQUALS    = 12
  KEY_PLUS      = 13
  KEY_MINUS     = 14
  KEY_TIMES     = 15
  KEY_DIVIDE    = 16
  KEY_POINT     = 17
  KEY_PERCENT   = 18
  KEY_SQRT      = 19
  KEY_MPLUS     = 20
  KEY_MMINUS    = 21
  KEY_MR        = 22
  KEY_MC        = 23
  KEY_CE        = 24
  ' number of keys
  KEY_COUNT     = 25

  ' the bucket value added when a key is on
  BUCKET_ON_VAL = 40
  ' the bucket value added when a key is off
  BUCKET_OFF_VAL = -1
  ' max bucket value
  BUCKET_MAX    = 500
  ' min bucket value
  BUCKET_MIN    = 0
  ' how full does it have to be to be considered "pressed"
  BUCKET_THRESHOLD = 60

  ' how many samples to run when we do debug sampling (measured in words)
  SAMPLE_WORD_SIZE = 500

obj
  leds  : "jm_pwm8"
  term : "PC_Interface"
  F : "Float32Full"
  FStr : "FloatString"
  CE : "calceng"

dat

HEX_ALPHABET  byte      "0123456789ABCDEF"

' bit masks which "mean" different keys, note that all 1's essentially means "disabled" (i.e. we don't read that key)
KEY_MASKS
        ' pins ACYGZFBEX
        word  %1001000000000000 '  KEY_0         = 0
        word  %1000100000000000 '  KEY_1         = 1
        word  %1010000000000000 '  KEY_2         = 2
        word  %1000001000000000 '  KEY_3         = 3
        word  %1100000000000000 '  KEY_4         = 4
        word  %1111111111111111 '  KEY_5         = 5 ' this one is odd, duplicate of key 1???
        word  %0010010000000000 '  KEY_6         = 6
        word  %0000101000000000 '  KEY_7         = 7
        word  %0011000000000000 '  KEY_8         = 8
        word  %0010100000000000 '  KEY_9         = 9
        word  %1111111111111111 '  KEY_ON        = 10
        word  %1111111111111111 '  KEY_OFF       = 11
        word  %0010100000000000 '  KEY_EQUALS    = 12 ' dup of 9???
        word  %1111111111111111 '  KEY_PLUS      = 13
        word  %1111111111111111 '  KEY_MINUS     = 14
        word  %1111111111111111 '  KEY_TIMES     = 15
        word  %1111111111111111 '  KEY_DIVIDE    = 16
        word  %1111111111111111 '  KEY_POINT     = 17
        word  %1111111111111111 '  KEY_PERCENT   = 18
        word  %1111111111111111 '  KEY_SQRT      = 19
        word  %1111111111111111 '  KEY_MPLUS     = 20
        word  %1111111111111111 '  KEY_MMINUS    = 21
        word  %1111111111111111 '  KEY_MR        = 22
        word  %1111111111111111 '  KEY_MC        = 23
        word  %1111111111111111 '  KEY_CE        = 24


var
  byte  test_buf[33]
  byte  ltoa_buf[20]                                                            ' buffer for ltoa output

  ' key "bucket" data
  long  key_buckets[KEY_COUNT]

  long run_io_stack[16]

  word  sample_buffer[SAMPLE_WORD_SIZE]                                         ' sample data storage

pub main | pin_state, cycle_count, i, tmp

  io_setup

  term.str(string("TESTING", 13))

  CE.init

  return

  term.str(string(13, 13, 13))

  term.str(string(34, "INITIALIZING", 34, 13))

  'term.str(string(13, "TEST", 13))
  'term.str(ltoa16(word[@KEY_MASKS][0], 4))
  'term.str(string(13, "TEST", 13))

  bucket_reset

  'term.str(string(34, "LED LIGHT SHOW", 34, 13))
  'light_show

  term.str(string(34, "STARTING IO COG", 34, 13))

  cognew(run_io, @run_io_stack)

  pause(1000)

  term.str(string(34, "ACTIVATED", 34, 13))

  'pin_state := (ina[0..8] << 7) & %1111111110000000
  'pin_state := (ina[0..8] << 7) & %1111111110000000
  'term.str(ltoa16(pin_state, 4))


  test_buf[0] := 0
  test_buf[1] := 0
  test_buf[2] := 0

  cycle_count := 500


  term.str(string(13, "Sampling...", 13))

  pause(1000)

  ' for debugging - dump out the raw key data
  'run_and_output_sample
  'return

  i := 0

  'repeat cycle_count
  '  ' do bucket sampling
  '  bucket_io_update

  term.str(string(13, "Done Sampling.", 13))

  i := 0
  repeat KEY_COUNT
    term.str(string("KEY "))
    term.str(ltoa(i))
    term.str(string(" BUCKET VALUE: "))
    term.str(ltoa(key_buckets[i]))
    term.str(string(13))
    i++

'  return
'
'  test_buf[0] := 0
'  test_buf[1] := 0
'  i := 0
'  repeat cycle_count
'    tmp := 0
'    if data_buf[i++] & KEY_MASKS[KEY_1] == KEY_MASKS[KEY_1]
'      tmp := 1
'    term.str(ltoa16(tmp, 2))
'    term.str(string(" "))
'    if i // 64 == 0
'      test_buf[0] := 13
'      term.str(@test_buf)

pub run_io                                              ' runs in a separate cog to do the pin monitoring

  repeat
    bucket_io_update

pub bucket_io_update | pin_state, i, key_mask           ' do one cycle of reading the pins and updating the buckets

  ' read pins
  pin_state := (ina[0..8] << 7) & %1111111110000000

  ' for each key, check if it's pattern matches the current pin state
  i := 0
  repeat KEY_COUNT

    key_mask := KEY_MASKS.word[i]
    if pin_state & key_mask == key_mask                 ' is this key pressed
      key_buckets[i] += BUCKET_ON_VAL                   ' yes, add to bucket
    else
      key_buckets[i] += BUCKET_OFF_VAL                  ' nope, subtract from bucket

    ' bounds check, make sure the bucket doesn't get too full or too empty
    if key_buckets[i] > BUCKET_MAX
      key_buckets[i] := BUCKET_MAX
    if key_buckets[i] < BUCKET_MIN
      key_buckets[i] := BUCKET_MIN

    i++

pub bucket_reset | i                                    ' set buckets to initial state

  i := 0
  repeat KEY_COUNT
    key_buckets[i++] := BUCKET_MIN

pub run_and_output_sample | pin_state, i
  ' sample the pins and output what we saw (for debugging)

  i := 0

  repeat SAMPLE_WORD_SIZE
    ' read pins
    pin_state := (ina[0..8] << 7) & %1111111110000000
    'pin_state := (ina[0..8] << 7) ' & %1111111110000000
    'pin_state := ina[0..8]
    sample_buffer[i++] := pin_state
    'pause(1)

  i := 0
  repeat SAMPLE_WORD_SIZE
    term.str(ltoa16(sample_buffer[i++], 4))
    term.str(string(13))

pub io_setup                                          ' set up our basic I/O

  leds.start(8, 16)                                         ' start led drivers

  pause(5)

  leds.digital(0, %11111111)

  term.start(31,30)                                     ' fire up the terminal

  pause(5)

  ' clear all output
  outa[0..9] := 0

  ' set pin directions
  dira[0..8] := 0


pub light_show

  ' start up LED display - give the user some time to prepare...
  repeat 128
    leds.inc_all
    pause(20)
    'waitcnt(1)

  repeat 128
    leds.dec_all
    pause(20)

pub pause(ms) | t

'' Delay program in milliseconds
'' -- use only in full-speed mode 

  if (ms < 1)                                                                   ' delay must be > 0
    return
  else
    t := cnt - 1792                                                             ' sync with system counter
    repeat ms                                                                   ' run delay
      waitcnt(t += MS_001)


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

