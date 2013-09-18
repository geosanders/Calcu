{{
Calculator Engine
}}
{
  
  TODO:
  * FIXED multiple operations in a row without equals don't cumulatively add up properly right now
  * Make it restrict to two decimal places if fractical component
  * (also restrict while typing? maybe not necessary)
  * If you try to enter more than max digits it should cut off
  * Verify that C key does reset ALL of the state, so if breaks it's easy to reset without power cycling
  * Make it output what should be added to the tape roll
}

con

  _clkmode = xtal1 + pll4x                                      ' run @ 20MHz in XTAL mode
  _xinfreq = 5_000_000                                          ' use 5MHz crystal

  CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
  MS_001   = CLK_FREQ / 1_000
  US_001   = CLK_FREQ / 1_000_000

  FZERO = 0.0


obj
  DBG : "PC_Interface"
  'F : "Float32Full"
  FStr : "FloatString"
  F: "FME"
  str : "ASCII0_STREngine_1"

dat

HEX_ALPHABET  byte      "0123456789ABCDEF"

var

  long mdblResult           ' float - corresponds to the last number on the display, but only updated when needed for calc
  long mdblSavedNumber      ' float - the prior number being saved for the next calculation
  byte mstrDot[32]          ' string - not used
  byte mstrOp               ' char - current operator, remains set after calculation, so = can do it again
  byte mstrDisplay[32]      ' string - display text
  byte mblnDecEntered       ' bool - not used
  byte mblnOpPending        ' bool - true immediately after an operator is set
  byte mblnNewEquals        ' bool - oddly enough, this means we have an op and are expecting an equals button press
  byte mblnEqualsPressed    ' bool - true immediately after the equals button was pressed
  long mintCurrKeyIndex     ' int - unused

  byte lblDisplay[32]       ' string

  byte DEBUG_DATA[32]

pub demo | tmp

  DBG.start(31,30)
  DBG.str(string("calceng.demo called", 13))

  init

  processKey("4")
  processKey(".")
  processKey("5")
  processKey("X")
  processKey("5")
  processKey("=")

  DBG.str(string("4.5 X 5 = "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

  processKey("4")
  processKey("/")
  processKey("5")
  processKey("=")

  DBG.str(string("4 / 5 = "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

  processKey("2")
  processKey("5")
  processKey("0")
  processKey("0")
  processKey("0")
  processKey("0")
  processKey("0")
  processKey("/")
  processKey("1")
  processKey("0")
  processKey("3")
  processKey("=")

  DBG.str(string("2500000 / 103 = "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

  processKey("X")
  processKey("2")
  processKey("=")

  DBG.str(string(" X 2 = "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

  processKey("/")
  processKey("3")
  processKey("=")

  DBG.str(string(" / 3 = "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

  processKey("2")
  processKey("+")
  processKey("3")
  processKey("=")

  DBG.str(string("2 + 3 = "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

  processKey("2")
  processKey("-")
  processKey("3")
  processKey("=")

  DBG.str(string("2 - 3 = "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

  processKey("X")
  processKey("6")
  processKey("=")

  DBG.str(string(" X 6 = "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

  processKey("X")
  processKey("/")
  processKey("2")
  processKey("=")

  DBG.str(string(" X (changed my mind) / 2 = "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

  processKey("2")
  processKey("X")
  processKey("2")
  processKey("X")
  processKey("2")
  processKey("X")
  processKey("2")
  processKey("=")

  DBG.str(string("2 X 2 X 2 X 2 = "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

  processKey("2")
  processKey("X")
  processKey("2")
  processKey("X")

  DBG.str(string("2 X 2 X ... "))
  DBG.str(@mstrDisplay)
  DBG.str(string(13,10))

pub init | ok



  'ok := F.start

  'DBG.str(string("Float library init returned: "))
  'DBG.str(str.integerToDecimal(ok, 1))
  'DBG.str(string(13, 10))

  mstrDisplay[0] := 0
  mblnOpPending := 0

pub isOpPending : r
  r := mblnOpPending

pub getPendingOp : r
  r := mstrOp

pub wasEqualsPressed : r
  r := mblnEqualsPressed

pub isInNewEquals : r
  r := mblnNewEquals

pub runOp(op, v1, v2) : r ' execute an operation and return the result (all numbers are float)
  if op == "+"
    r := F.FAdd(v1, v2)
  if op == "-"
    r := F.FSub(v1, v2)
  if op == "X"
    r := F.FMul(v1, v2)
  if op == "/"
    if v2 == FZERO
        r := FZERO
    else
        r := F.FDiv(v1, v2)


pub processKey(keycode) : retDisplayPtr | len, tmpstr, foundop

  if keycode => "0" and keycode =< "9"

    if mblnOpPending
      mstrDisplay[0] := 0
      mblnOpPending := 0
    if mblnEqualsPressed
      mstrDisplay[0] := 0
      mblnEqualsPressed := 0
    len := strsize(@mstrDisplay)
    mstrDisplay[len] := keycode
    mstrDisplay[len+1] := 0

  if keycode == "."
    if mblnOpPending
      mstrDisplay[0] := 0
      mblnOpPending := 0
    if mblnEqualsPressed
      mstrDisplay[0] := 0
      mblnEqualsPressed := 0
    if str.findCharacter(@mstrDisplay, ".") =< 0
      len := strsize(@mstrDisplay)
      mstrDisplay[len] := keycode
      mstrDisplay[len+1] := 0

  if keycode == "+" or keycode == "-" or keycode == "X" or keycode == "/"

    ' if we got an operator but it's not pending right now (more digits entered into new number)
    if mblnNewEquals AND NOT mblnOpPending
      ' we need to calculate the result, just like equals, and keep rolling
      mdblSavedNumber := FStr.StringToFloat(@mstrDisplay)
      mdblResult := runOp(mstrOp, mdblResult, mdblSavedNumber)
      tmpstr := FStr.FloatToString(mdblResult)
      str.stringCopy(@mstrDisplay, tmpstr)
      'mdblSavedNumber := mdblResult
      'mdblResult := runOp(mstrOp, mdblResult, FStr.StringToFloat(@mstrDisplay))

    mdblResult := FStr.StringToFloat(@mstrDisplay)
    'mdblSavedNumber := FStr.StringToFloat(@mstrDisplay)
    mstrOp := keycode
    mblnOpPending := 1
    mblnDecEntered := 0
    mblnNewEquals := 1

  'if keycode == "%"
  '  mdblSavedNumber = (Val(mstrDisplay) / 100) * mdblResult
  '  mstrDisplay = Format$(mdblSavedNumber)

  if keycode == "="

    if mblnNewEquals
      'DBG.str(string("mblnNewEquals=1"))
      mdblSavedNumber := FStr.StringToFloat(@mstrDisplay)
      mblnNewEquals := 0
    else
      mdblResult := FStr.StringToFloat(@mstrDisplay)

    foundop := 0

    if mstrOp == "+"
      mdblResult := runOp(mstrOp, mdblResult, mdblSavedNumber)
      foundop := 1
    if mstrOp == "-"
      mdblResult := runOp(mstrOp, mdblResult, mdblSavedNumber)
      foundop := 1
    if mstrOp == "X"
      mdblResult := runOp(mstrOp, mdblResult, mdblSavedNumber)
      foundop := 1
    if mstrOp == "/"
      foundop := 1
      if mdblSavedNumber == FZERO
          str.stringCopy(@mstrDisplay, string("ERROR"))
      else
          mdblResult := runOp(mstrOp, mdblResult, mdblSavedNumber)

    if not foundop
      mdblResult := FStr.StringToFloat(@mstrDisplay)

    '' FIXME: if mstrDisplay[0] <> "E" ' was "ERROR"
    tmpstr := FStr.FloatToString(mdblResult)
    str.stringCopy(@mstrDisplay, tmpstr)
    mblnEqualsPressed := 1

  'Case "+/-"
  ''    if mstrDisplay <> "" Then
  ''        if Left$(mstrDisplay, 1) = "-" Then
  ''            mstrDisplay = Right$(mstrDisplay, 2)
  ''        Else
  ''            mstrDisplay = "-" & mstrDisplay
  ''        Case "Backspace"
  ''    if Val(mstrDisplay) <> 0 Then
  ''        mstrDisplay = Left$(mstrDisplay, Len(mstrDisplay) - 1)
  ''        mdblResult = Val(mstrDisplay)

  'Case "CE"
  ''    mstrDisplay = ""
  if keycode == "C"
    mstrDisplay[0] := 0
    mdblResult := FZERO
    mdblSavedNumber := FZERO
    ' more reset
    mblnOpPending := 0
    mblnEqualsPressed := 0
    mblnNewEquals := 0
    mstrOp := 0
    mblnDecEntered := 0


  'Case "1/x"
  ''    if Val(mstrDisplay) = 0 Then
  ''        mstrDisplay = "ERROR"
  ''    Else
  ''        mdblResult = Val(mstrDisplay)
  ''        mdblResult = 1 / mdblResult
  ''        mstrDisplay = Format$(mdblResult)
  ''  Case "sqrt"
  ''    if Val(mstrDisplay) < 0 Then
  ''        mstrDisplay = "ERROR"
  ''    Else
  ''        mdblResult = Val(mstrDisplay)
  ''        mdblResult = Sqr(mdblResult)
  ''        mstrDisplay = Format$(mdblResult)
    
  if mstrDisplay[0] == 0
    str.stringCopy(@lblDisplay, string("0"))
  else
    str.stringCopy(@lblDisplay, @mstrDisplay)
    'if str.findCharacter(@mstrDisplay, ".") =< 0
    ''  len := 
    ''  mstrDot := 0
    'else
    ''  mstrDot := "."
    'lblDisplay = mstrDisplay & mstrDot
    'if Left$(lblDisplay, 1) = "0"
    ''    lblDisplay = Mid$(lblDisplay, 2)

  'if lblDisplay = "."
  ''  lblDisplay = "0."

  retDisplayPtr := @lblDisplay

  return
