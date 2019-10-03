'' Gamepad driver - interfaces joypads and keyboard into one interface
'' Hybrid key conversion could use some optimizing 
OBJ   keyboard  : "comboKeyboard.spin"
CON
  ''keyboard key codes assigned to joypad keys
  ''To find the key codes for the keyboard, look at the bottom of the source code in comboKeyboard.spin
  ''player 1
  Key0_Up = $C2    ''Up arrow
  Key0_Down = $C3  ''Down arrow
  Key0_Left = $C0  ''Left arrow
  Key0_Right = $C1 ''Right arrow
  Key0_B = $F5     ''Right Alt
  Key0_A = $F3     ''Right Ctrl
  Key0_Start = $0D ''Enter
  Key0_Select = $09 ''Tab  
  ''player 2 (use upper case when mapping keys)
  Key1_Up = $74    ''T
  Key1_Down = $67  ''G
  Key1_Left = $66  ''F
  Key1_Right = $68 ''H
  Key1_B = $F2     ''Left Ctrl
  Key1_A = $F4     ''Left Alt
  
  Hydra = 0
  Hybrid = 1

  '' joypad serial shifter settings
  JOY_CLK = 16
  JOY_LCH = 17
  JOY_DATA0 = 19
  JOY_DATA1 = 18

  ''Hydra Joy settings 
  JOY_RIGHT  = %00000001
  JOY_LEFT   = %00000010
  JOY_DOWN   = %00000100
  JOY_UP     = %00001000
  JOY_START  = %00010000
  JOY_SELECT = %00100000
  JOY_B      = %01000000
  JOY_A      = %10000000

  ''Hybrid Joy settings
  JOYH_RIGHT  = %00001000
  JOYH_LEFT   = %00000100
  JOYH_DOWN   = %00000010
  JOYH_UP     = %00000001
  JOYH_START  = %00000000
  JOYH_SELECT = %00000000
  JOYH_B      = %00100000
  JOYH_A      = %10000000

VAR
  LONG Console_Type

PUB Read_Gamepad : nes_bits   |  i, joy0, joy1, joy0_fix, joy1_fix 
  DIRA [JOY_CLK] := 1 ' output
  DIRA [JOY_LCH] := 1 ' output
  DIRA [JOY_DATA0] := 0 ' input
  DIRA [JOY_DATA1] := 0 ' input

  OUTA [JOY_CLK] := 0 ' JOY_CLK = 0
  NES_Delay
  OUTA [JOY_LCH] := 0 ' JOY_SH/LDn = 0
  NES_Delay
  OUTA [JOY_LCH] := 1 ' JOY_SH/LDn = 1
  NES_Delay
  OUTA [JOY_LCH] := 0 ' JOY_SH/LDn = 0
  joy0:=INA[JOY_DATA0]
  joy1:=INA[JOY_DATA1]
  repeat i from 0 to 6
    NES_Delay
    OUTA [JOY_CLK] := 1 ' JOY_CLK = 1
    NES_Delay
    OUTA [JOY_CLK] := 0 ' JOY_CLK = 0
    joy0:=joy0<<1
    joy0:=joy0 | INA[JOY_DATA0]
    joy1:=joy1<<1
    joy1:=joy1 | INA[JOY_DATA1]

  ''Setup controller for Hybrid
  if Console_Type==Hybrid
     joy0_fix:=$FF
     joy1_fix:=$FF
     joy0:=!joy0 & $FF
     joy1:=!joy1 & $FF
     ''joy 0
     if((joy0 & JOYH_LEFT) <> 0)
      joy0_fix&=!JOY_LEFT
     if((joy0 & JOYH_RIGHT) <> 0)
      joy0_fix&=!JOY_RIGHT
     if((joy0 & JOYH_UP) <> 0)
      joy0_fix&=!JOY_UP
     if((joy0 & JOYH_DOWN) <> 0)
      joy0_fix&=!JOY_DOWN
     if((joy0 & JOYH_B) <> 0)
      joy0_fix&=!JOY_B
     if((joy0 & JOYH_A) <> 0)
      joy0_fix&=!JOY_A
     joy0:=joy0_fix     
      ''joy 1
     if((joy1 & JOYH_LEFT) <> 0)
      joy1_fix&=!JOY_LEFT
     if((joy1 & JOYH_RIGHT) <> 0)
      joy1_fix&=!JOY_RIGHT
     if((joy1 & JOYH_UP) <> 0)
      joy1_fix&=!JOY_UP
     if((joy1 & JOYH_DOWN) <> 0)
      joy1_fix&=!JOY_DOWN
     if((joy1 & JOYH_B) <> 0)
      joy1_fix&=!JOY_B
     if((joy1 & JOYH_A) <> 0)
      joy1_fix&=!JOY_A
     joy1:=joy1_fix
     
  ''button check, if all buttons are showing low(registered as all pushed down)
  '' then release all buttons because it means the controller is not plugged in
  if(joy0==0)
   joy0:=$FF
  if(joy1==0)
   joy1:=$FF

  ''handle keyboard
  if keyboard.present 
    if keyboard.keystate(Key0_Right)
     joy0&=!JOY_RIGHT
    if keyboard.keystate(Key0_Left)
     joy0&=!JOY_LEFT
    if keyboard.keystate(Key0_Down)
     joy0&=!JOY_DOWN
    if keyboard.keystate(Key0_Up) 
     joy0&=!JOY_UP
    if keyboard.keystate(Key0_Start)
     joy0&=!JOY_Start
    if keyboard.keystate(Key0_Select)
     joy0&=!JOY_Select
    if keyboard.keystate(Key0_B)
     joy0&=!JOY_B
    if keyboard.keystate(Key0_A)
     joy0&=!JOY_A
    if keyboard.keystate(Key1_Right)
     joy1&=!JOY_RIGHT
    if keyboard.keystate(Key1_Left)
     joy1&=!JOY_LEFT
    if keyboard.keystate(Key1_Down)
     joy1&=!JOY_DOWN
    if keyboard.keystate(Key1_Up) 
     joy1&=!JOY_UP
    if keyboard.keystate(Key1_B)
     joy1&=!JOY_B
    if keyboard.keystate(Key1_A)
     joy1&=!JOY_A
  ''combine the two controllers 
  nes_bits :=!(joy0 | (joy1<<8)) & $FFFF
PUB NES_Delay  | ii, iii
''    repeat ii from 0 to 5000
      iii:= 5*675

PUB Start(pingroup,console)
'' Used to start keyboard driver, console is to figure out if it is hydra or hybrid, or none
keyboard.start(pingroup)
Console_Type:=console      