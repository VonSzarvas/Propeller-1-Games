'' Spintris
'' JT Cook - http://www.avalondreams.com
'' Other drivers used:
'' Andrew Arsenault's HSS sound driver - http://www.andrewarsenault.com/hss/
'' PS/2 Keyboard Driver v2.0  by Parallax and Mike Green
'' TV driver that supports either NTSC or PAL by Parallax and Jim Bagley
''
'' NOTE: Under the CON section, uncomment the section of code that is your Proppeller Hardware setup or
''   create your own settings
''
'' Use left and right, up and down to move through menu and Start or B button to start a game
'' 2 Player Elimination - 1st player to clear 25 lines wins
'' 2 Player Battle - 2 players play until one loses. When a player clears two or more lines then
''  those lines minus one will be added to the other player's table
''
'' NOTE: To change the keyboard keys used in the game, look in gamepad.spin
'' Keboard keys -
''  Player 1: Arrow keys, Right Ctrl and Alt to rotate pieces, and enter to start a game
''  Player 2: F & H to move piece left and right, G to drop piece, Left Ctrl and Alt to rotate pieces
''
'' -- future things to work on
'' Change controls to allow holding keys to move pieces left and right (done)
'' Change controls to stop the down arrow from dropping after a peice has been dropped (done)
'' when a line erases have the blocks desinegrate
'' Use map maker to redraw the screens
'' Music
''------------------
'' Releases
'' 10-02-19 - Improved controls, added scoring.
'' 12-15-07 - Added keyboard driver, new TV driver(that supports PAL), configuration for Demo/Proto boards,
''          Level and Height options, started peices higher up, 1 player levels up after 25 lines
''          Also added function to read Hybrid flash rom to check for NTSC/PAL
'' 11-07-07 - release 2a(Hybrid only) fixed program so you could start game using
''            a one button atari style joystick
'' 11-03-07 - 2nd release, fixed joy issue with player 2
'' 11-02-07 - 1st public release
CON
  PAL=%0001
  NTSC=%0000
  Hydra = 0
  Hybrid = 1
 ' joypad bit encodings
  JOY0_RIGHT  = %00000000_00000001
  JOY0_LEFT   = %00000000_00000010
  JOY0_DOWN   = %00000000_00000100
  JOY0_UP     = %00000000_00001000
  JOY0_START  = %00000000_00010000
  JOY0_SELECT = %00000000_00100000
  JOY0_B      = %00000000_01000000
  JOY0_A      = %00000000_10000000
  JOY1_RIGHT  = %00000001_00000000
  JOY1_LEFT   = %00000010_00000000
  JOY1_DOWN   = %00000100_00000000
  JOY1_UP     = %00001000_00000000
  JOY1_START  = %00010000_00000000
  JOY1_SELECT = %00100000_00000000
  JOY1_B      = %01000000_00000000
  JOY1_A      = %10000000_00000000

  JOY_SELECT_CLR = %00100000_00100000
  JOY_RIGHT_CLR  = %00000001_00000001
  JOY_LEFT_CLR   = %00000010_00000010

{ Hydra setup
  _clkmode = xtal1 + pll8x     ''Hydra
  _xinfreq = 10_000_000        ''Stock Hydra
'  _xinfreq = 10_000_000 + 5000 ''My Hydra
  _memstart = $10      ' memory starts $10 in!!! (this took 2 headaches to figure out)  
  Key_Pins    = 13   ''pin location for keyboard
  Video_Pins  = %011_0000   ''pin location for video out
  V_NP = NTSC ''video type - NTSC
  ''setup pin groupings for audio
  Audio_Pins = %00000000_00000000_00000000_10000000
               '- CTR   PLL -------- BPIN   --- APIN  
  Audio_Ctra = %0_00110_000_00000000_000000_000_000111
  Console = Hydra 
 }
 
 { Hybrid setup
  _clkmode = xtal1 + pll16x   
  _xinfreq = 6_000_000        
  _memstart = $10      ' memory starts $10 in!!! (this took 2 headaches to figure out)     
  Key_Pins    = 12   ''pin location for keyboard
  Video_Pins  = %011_0000   ''pin location for video out
  V_NP = NTSC ''video type  - NTSC
  Console = Hybrid
  ''setup pin groupings for audio
  Audio_Pins = %00000000_00000000_00000000_10000000
               '- CTR   PLL -------- BPIN   --- APIN  
  Audio_Ctra = %0_00110_000_00000000_000000_000_000111  
}

'{ Demo/Proto board stup
  _clkmode = xtal1 + pll16x 
  _xinfreq = 5_000_000     
  _memstart = $10      ' memory starts $10 in!!! (this took 2 headaches to figure out)
  Key_Pins = 8   ''pin location for keyboard     
  Video_Pins = %001_0101   ''pin location for video out
  V_NP = NTSC ''video type - NTSC
  Console = 0
  Audio_Pins = %00000000_00000000_00001100_00000000
               '- CTR   PLL -------- BPIN   --- APIN
  Audio_Ctra = %0_00110_000_00000000_000000_000_001010
  Audio_Ctrb = %0_00110_000_00000000_000000_000_001011     
'}

 ' constants
 Empty_Tile = 0 ''value for empty background in game field
 Arrow_Tile = 106 ''tile for arrow in menu selection
 Door_Tile = 2  ''tile that closes door on game field, game over
 Block_offset = 1 ''where block tiles start
 Font_offset = 107 ''where font starts
 Lines_to_clear = 25 '' number of lines to clear in 2p mode
 Level_UP = 25 ''how many lines needed to get the next level
 Screen_Shot = 0 ''1 - enable screenshot by hitting select, 0 - disable
 ''used for video driver
 SCANLINE_BUFFER = $7F00           
 request_scanline       = SCANLINE_BUFFER-4  'address of scanline buffer for TV driver
 tilemap_adr            = SCANLINE_BUFFER-8  'address of tile map
 tile_adr               = SCANLINE_BUFFER-12 'address of tiles
 border_color           = SCANLINE_BUFFER-16 'address of border color
 _FREE = ($8000-border_color)/4
 _STACK = 128
 
  down_drop = 25 ''how much to deduct from drop clock when pushing down - NTSC
  ''50 ''how much to deduct from drop clock when pushing down - NTSC
  ''42 ''how much to deduct from drop clock when pushing down - PAL
  repeat_rate = 20

OBJ
  tv_game_gfx : "JTC_Tile_Drv.spin"  'JTC's Tile Driver
  joy : "gamepad.spin" 'controller objecet
  'i2c           : "Basic_I2C_Driver"
  sound : "yma_hss_v1.2_hydra.spin" 'Andrew Arsenault's HSS sound driver
  uart : "dummy_uart.spin" 'serial replacement for use with sound driver
  bag[2] : "bag_random.spin" ' new piece randomizer
'  sound : "dummy_sound.spin" 'sound replacemnt for use with serial driver
'  uart  : "FullDuplex.spin"           ' serial driver (for screen capture)  
VAR
   long Tile_Map_Adr ''address to tilemap for graphics driver
   long joypad'grab value from controller
   long joypadold 'original joypad value
   byte Game_Field[20*10*2] '' piece play field
    ''x/y position for dropping blocks 10 because ther are 4 blocks in a shape
    ''   and one set is to hold old movement (5th one holds general location)
   long block_x[10*2] 
   long block_y[10*2]
   long next_x[2], next_y[2] ''location of next box
   long playfield_x[2], playfield_y[2] ''offset for drawing play field 
   long block_angle[2] '' for rotation
   long drop_clock[2] '' timer until block drops
   long next_peice[2] ''peice in next box
   long current_peice[2] '' current peice we are using
   long lines[2]   '' how many lines that have been cleared
   long level_lines[2] ''how many lines, if over 25 move to next level
   long block_adr[2]  '' offset for current block
   long block_color[2] '' color of block in play
   long block_tile[4*2] '' tile map for blocks, 2 for 2 players
   long calc_adr   '' address for peice
   long Game_State '' which mode game is in (select, game play, etc)
   long Game_Play_State ''handles end of game or not
   long menu_var ''used to select number of players
   long height_var ''used to select difficulty level by placing random pieces on board
   long level_var ''used to select speed that pieces drop
   long rand  ''seed for randomizer
   long pending_blocks[2] ''number of blocks to push up(2p battle)
   long score '' 1 player score
   word softdrop_lines ''amount of softdropped lines (used only for scoring, so player 1 only)
   byte no_softdrop[2]
   'long next_peice_2p[2] '' position on list for next block
   'byte block_list[75] '' for multiplayer store a list of random blocks so both
                       '' players have the same blocks
   long battle ''toggle battle game
   long player '' number of players 0=1, 1=2
   long TV_Type  ''NTSC or PAL
   long new_clock '' what to reset drop clock to
   ''debug
  ' long Tile_Ad
   long Game_Delay

   byte j0left_repeat,j0right_repeat,j1left_repeat,j1right_repeat
              
PUB start | n
  tv_game_gfx.Set_Border_Color($02) 'set border color
  joy.start(Key_Pins,Console) 'start gamepad/keyboard driver
  sound.start(Audio_Pins, Audio_Ctra, Audio_Ctrb) 'Start HSS sound driver

  ''NTSC or PAL
  if Console==Hybrid ''Hybrid stores NTSC/PAL val on flash rom
      'i2c.ReadPage(28, $a0, $7fff, @TV_Type, 1)
  else
     TV_Type:=V_NP
  tv_game_gfx.start(Video_Pins,TV_Type) 'start graphics driver
  Long[Tile_Adr]:=@TileFile 'grab address of tile graphics
  Tile_Map_Adr:=LONG[CONSTANT($7F00-8)] 'grab address of tile map

  uart.start(31, 30, 115200) 'start serial driver for screen capture
  repeat n from 32 to 95
     tv_game_gfx.Convert_Tile(@Char_data, n + Font_offset-2,n, $02, $07)

  Game_State:=0 ''start at menu
  rand := cnt
  repeat  
      if(Game_State==0)
         GameMenu
      if(Game_State==1)
         GameLoop   

PUB Wait_Vsync ''wait until frame is done drawing
    repeat while long[$7F00-4] <> 191
   
PUB Check_Tap_Key(key_hit)
  ''check joy pad 1
  if(key_hit<$0100)
   if(((joypad & key_hit & $00FF) & ((joypadold & key_hit & $00FF)^ key_hit)) <> 0)
    return 1
  ''check joy pad 2
  if(key_hit>$00FF)
   if(((joypad & key_hit & $FF00) & ((joypadold & key_hit & $FF00)^ key_hit)) <> 0)
    return 1
  else
    return 0

PUB Do_Pause | i
  repeat i from 0 to player
    Pause_GameField(i)
  Pause_Loop
  repeat i from 0 to player
    Draw_GameField(i)
    Draw_Block(i)

PUB Pause_Loop | n
  n:=0
  joypadold:=joypad ''grab last hit key
  repeat while n==0
      joypad := joy.Read_Gamepad
      if(Check_Tap_Key(JOY0_Start) <> 0 OR Check_Tap_Key(JOY1_Start))
         n:=1
      joypadold:=joypad             

PUB Clr_Screen(tile) | n
    ''fill screen with selected char
    'repeat n from 0 to CONSTANT(32*24-1)
      'BYTE[Tile_Map_Adr+n]:=tile
    bytefill(Tile_Map_Adr,tile,CONSTANT(32*24))
    
PUB GameMenu | n, menu_var_old, h_toggle, var_old, menu_select
      menu_select:=0
      menu_var:=0
      height_var:=0
      level_var:=0
      Clr_Screen(Empty_Tile)
      Print_String(12,1,@TitleText)
      Print_String(6,22,@DemoText)
      Print_String(0,23,@DateText)            
      Print_String(6,6,@Text1p)
      Print_String(6,7,@Text2p)
      Print_String(6,8,@Text2psu)            
      tv_game_gfx.Place_Tile_XY(4,6,Arrow_Tile)
      Print_String(3,10,@Height0)
      Print_String(3,11,@Height1)
      Print_String(3,12,@Height2)            
      Print_String(3,13,@Height3)
      Print_String(3,14,@Height4)
      Print_String(3,15,@Height5)            
      tv_game_gfx.Place_Tile_XY(1,10,Arrow_Tile)
      Print_String(17,10,@Level0)
      Print_String(17,11,@Level1)
      Print_String(17,12,@Level2)            
      Print_String(17,13,@Level3)
      Print_String(17,14,@Level4)
      Print_String(17,15,@Level5)            
      Print_String(17,16,@Level6)
      Print_String(17,17,@Level7)
      Print_String(17,18,@Level8)            
      Print_String(17,19,@Level9)
      tv_game_gfx.Place_Tile_XY(15,10,Arrow_Tile)                       
      n:=0
      h_toggle:=0
      repeat while n == 0
        ''sync to vsync
        Wait_Vsync      
        'Print_Joy '' debug info
          
        joypadold:=joypad ''grab last hit key      
        joypad := joy.Read_Gamepad
        h_toggle ^= 1

        ''level select
        if menu_select==2
          if(h_toggle==1)
              tv_game_gfx.Place_Tile_XY(15, level_var+10,Arrow_Tile)
          else
              tv_game_gfx.Place_Tile_XY(15, level_var+10,Empty_Tile)         
        
          if(Check_Tap_Key(JOY0_Down) <> 0 OR Check_Tap_Key(JOY1_Down) <> 0 )
            var_old:=level_var
            level_var++
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)            
            if level_var>9
              level_var:=0
            tv_game_gfx.Place_Tile_XY(15,var_old+10,Empty_Tile) ''erase cursor
          if(Check_Tap_Key(JOY0_Up) <> 0 OR Check_Tap_Key(JOY1_Up) <> 0 )
            var_old:=level_var
            level_var--
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)            
            if level_var<0
              level_var:=9
            tv_game_gfx.Place_Tile_XY(15,var_old+10,Empty_Tile) ''erase cursor
                        
          if(Check_Tap_Key(JOY0_Start) <> 0 OR Check_Tap_Key(JOY1_Start) <> 0 OR Check_Tap_Key(JOY0_B) <> 0 OR Check_Tap_Key(JOY1_B) <> 0 )
            n:=1
            Game_State:=1 ''start game
            
          ''move to next menu item
          if(Check_Tap_Key(JOY0_Select) <> 0 OR Check_Tap_Key(JOY1_Select) <> 0 OR (Check_Tap_Key(JOY0_LEFT) <> 0 OR Check_Tap_Key(JOY1_LEFT) <> 0))
            menu_select:=0
            joypadold|=JOY_Select_CLR | JOY_Left_CLR
            tv_game_gfx.Place_Tile_XY(15,level_var+10,Arrow_Tile)
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)
          if (Check_Tap_Key(JOY0_Right) <> 0 OR Check_Tap_Key(JOY1_Right) <> 0)            
            menu_select:=1
            joypadold|=JOY_Right_CLR
            tv_game_gfx.Place_Tile_XY(15,level_var+10,Arrow_Tile)
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)
                    
        ''height select
        if menu_select==1
          if(h_toggle==1)
              tv_game_gfx.Place_Tile_XY(1, height_var+10,Arrow_Tile)
          else
              tv_game_gfx.Place_Tile_XY(1,height_var+10,Empty_Tile)         
        
          if(Check_Tap_Key(JOY0_Down) <> 0 OR Check_Tap_Key(JOY1_Down) <> 0 )
            var_old:=height_var
            height_var++
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)            
            if height_var>5
              height_var:=0
            tv_game_gfx.Place_Tile_XY(1,var_old+10,Empty_Tile) ''erase cursor
          if(Check_Tap_Key(JOY0_Up) <> 0 OR Check_Tap_Key(JOY1_Up) <> 0 )
            var_old:=height_var
            height_var--
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)            
            if height_var<0
              height_var:=5
            tv_game_gfx.Place_Tile_XY(1,var_old+10,Empty_Tile) ''erase cursor
                        
          if(Check_Tap_Key(JOY0_Start) <> 0 OR Check_Tap_Key(JOY1_Start) <> 0 OR Check_Tap_Key(JOY0_B) <> 0 OR Check_Tap_Key(JOY1_B) <> 0 )
            n:=1
            Game_State:=1 ''start game
            
          ''move to next menu item
          if(Check_Tap_Key(JOY0_Select) <> 0 OR Check_Tap_Key(JOY1_Select) <> 0 OR Check_Tap_Key(JOY0_Left) <> 0 OR Check_Tap_Key(JOY1_Left) <> 0)
            menu_select:=2
            joypadold|=JOY_Select_CLR | JOY_Left_CLR
            tv_game_gfx.Place_Tile_XY(1,height_var+10,Arrow_Tile)
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)
          if (Check_Tap_Key(JOY0_Right) <> 0 OR Check_Tap_Key(JOY1_Right) <> 0)            
            menu_select:=0
            joypadold|=JOY_Right_CLR
            tv_game_gfx.Place_Tile_XY(1,height_var+10,Arrow_Tile)
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)
            
        ''menu for number of players
        if menu_select==0
          ''make the cursor we are selecting active
          if(h_toggle==1)
              tv_game_gfx.Place_Tile_XY(4,menu_var+6,Arrow_Tile)
          else
              tv_game_gfx.Place_Tile_XY(4,menu_var+6,Empty_Tile)         

          if(Check_Tap_Key(JOY0_Down) <> 0 OR Check_Tap_Key(JOY1_Down) <> 0 )
            menu_var_old:=menu_var
            menu_var++
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)            
            if menu_var>2
              menu_var:=0
            tv_game_gfx.Place_Tile_XY(4,menu_var_old+6,Empty_Tile) ''erase cursor
          if(Check_Tap_Key(JOY0_Up) <> 0 OR Check_Tap_Key(JOY1_Up) <> 0 )
            menu_var_old:=menu_var
            menu_var--
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)            
            if menu_var<0
              menu_var:=2
            tv_game_gfx.Place_Tile_XY(4,menu_var_old+6,Empty_Tile) ''erase cursor
                        
          if(Check_Tap_Key(JOY0_Start) <> 0 OR Check_Tap_Key(JOY1_Start) <> 0 OR Check_Tap_Key(JOY0_B) <> 0 OR Check_Tap_Key(JOY1_B) <> 0 )
            n:=1
            Game_State:=1 ''start game
          ''move to next menu item
          if(Check_Tap_Key(JOY0_Select) <> 0 OR Check_Tap_Key(JOY1_Select) <> 0 OR Check_Tap_Key(JOY0_Left) <> 0 OR Check_Tap_Key(JOY1_Left) <> 0)
            menu_select:=1
            joypadold|=JOY_Select_CLR | JOY_Left_CLR
            tv_game_gfx.Place_Tile_XY(4,menu_var+6,Arrow_Tile)
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)            
          if (Check_Tap_Key(JOY0_Right) <> 0 OR Check_Tap_Key(JOY1_Right) <> 0)            
            menu_select:=2
            joypadold|=JOY_Right_CLR
            tv_game_gfx.Place_Tile_XY(4,menu_var+6,Arrow_Tile)
            sound.sfx_play(1, @SoundFX1) 'Play a sound effect on FX channel (1)            
        
        rand++ ''change randomizer
            
PUB GameLoop | i, ii
     player:=menu_var
     battle:=0 ''reset battle game variable
     if(player>1) ''debug
      player:=1
     if(menu_var==2) ''battle game
      battle:=1
     Reset_Game_Var(player) ' reset variables in game
     joypadold:=joypad ''grab last hit key
     repeat while Game_Play_State==0
      ''sync to vsync
      Wait_Vsync
      ''Debug:slow down game, look for different way to do this
      Game_Delay++
      ''if(Game_Delay>15)
       Game_Delay:=0      
       joypad := joy.Read_Gamepad
       
       ''check for screen grab
       if(Check_Tap_Key(JOY0_SELECT) <> 0 AND Screen_Shot)
          Screen_Grab '' send screenshot over serial
       ''player 1 -----------------
       if(Check_Tap_Key(JOY0_A) <> 0)
        Erase_Block(0)
        New_Rot(0,1) ''place new peice in memory
       if(Check_Tap_Key(JOY0_B) <> 0)
        Erase_Block(0)
        New_Rot(0,2) ''place new peice in memory                
       'if((joypad & JOY0_LEFT) <> 0)
       if(joypad & JOY0_LEFT)
         j0left_repeat++
       else
         j0left_repeat~
       if(joypad & JOY0_RIGHT)
         j0right_repeat++
       else
         j0right_repeat~
       if(Check_Tap_Key(JOY0_LEFT) OR j0left_repeat=>repeat_rate)
        j0left_repeat~
        Move_Block(1,0) 'move block left
       'if((joypad & JOY0_RIGHT) <> 0) 
       if(Check_Tap_Key(JOY0_RIGHT) OR j0right_repeat=>repeat_rate)
        j0right_repeat~
        Move_Block(2,0) 'move block right
       if((joypad & JOY0_DOWN) <> 0)
        ''Move_Block(3,0) 'move block down - removed from code
        if no_softdrop[0]
         drop_clock[0]-=1
        else
         drop_clock[0]-=down_drop
       else
        drop_clock[0]-=1
        no_softdrop[0]~
       if(drop_clock[0]<1)
        drop_clock[0]:=new_clock
        drop_peice(0) 'drop a peice
       if(Check_Tap_Key(JOY0_Start) <> 0)         
         Do_Pause ' Pauses game
       ''player 2 ---------------
       if(player>0)
        if(Check_Tap_Key(JOY1_Start) <> 0)         
         Do_Pause ' Pauses game
             
        if(Check_Tap_Key(JOY1_A) <> 0)
         Erase_Block(1)
         New_Rot(1,1) ''place new peice in memory
        if(Check_Tap_Key(JOY1_B) <> 0)
         Erase_Block(1)
         New_Rot(1,2) ''place new peice in memory
        if(joypad & JOY1_LEFT)
         j1left_repeat++
        else
         j1left_repeat~
        if(joypad & JOY1_RIGHT)
         j1right_repeat++
        else
         j1right_repeat~
        if(Check_Tap_Key(JOY1_LEFT) OR j1left_repeat=>repeat_rate)
         j1left_repeat~
         Move_Block(1,1) 'move block left 
        if(Check_Tap_Key(JOY1_RIGHT) OR j1right_repeat=>repeat_rate)
         j1right_repeat~
         Move_Block(2,1) 'move block right
        if((joypad & JOY1_DOWN) <> 0) 
         ''Move_Block(3,1) 'move block down - removed from code
         if no_softdrop[0]
          drop_clock[1]-=down_drop
         else
          drop_clock[1]-=1
        else
         drop_clock[1]-=1
         no_softdrop[1]~
        if(drop_clock[1]<1)
         drop_clock[1]:=new_clock
         drop_peice(1) 'drop a peice
        if(Check_Tap_Key(JOY1_Start) <> 0)         
          Do_Pause ' Pauses game       
       joypadold:=joypad
       rand++ ''change randomizer
   ''exit the loop, game over, go to menu
    Game_State:=0                
PUB Print_Joy | x, joy_test, n
''test joy pad
  x:=20
  joy_test := joy.Read_Gamepad
  repeat n from 0 to 15
   tv_game_gfx.Place_Tile_XY(x,0,joy_test&1) ''erase cursor
   joy_test>>=1
   x-=1
PUB Move_Block(dir,pl) | x, n, calc, offset
'' move a block around the playfield
'' 1 - left, 2 - right
  offset:=pl*10 ''offset for player blocks
  Erase_Block(pl)
   ''copy old block position
  repeat n from 0 to 4
     block_x[n+5+offset]:=block_x[n+offset]
     block_y[n+5+offset]:=block_y[n+offset]
  ''set movement
  x:=0
  if(dir==1)
     x:=-1
  elseif(dir==2)
     x:=1
  repeat n from 0 to 4
     block_x[n+offset]+=x
  ''check the colision detection
  calc:=Check_Hit(pl)
  ''if the blocks hit something, return it back to old state
  if(calc==1)
    repeat n from 0 to 4
     block_x[n+offset]:=block_x[n+5+offset]
     block_y[n+offset]:=block_y[n+5+offset]
  else
    sound.sfx_play(2, @SoundFX2) 'Play a sound effect
  Draw_Block(pl) '' draw block in play  
PUB Erase_Block(pl) | n, offset
''erase old block location
  offset:=pl*10 ''offset for player blocks
  repeat n from 0 to 3
    ''if(block_y[n+offset]>1)
       tv_game_gfx.Place_Tile_XY(block_x[n+offset]+playfield_x[pl],block_y[n+offset]+playfield_y[pl]-2,Empty_tile) ''draw 1 of 4 block peices
 
PUB Draw_Block(pl) | n, offset, b_tile
'' draws the block in play
  offset:=pl*10 ''offset for player blocks
  b_tile:=pl*4
  repeat n from 0 to 3
   ''if(block_y[n+offset]>1)
       tv_game_gfx.Place_Tile_XY(block_x[n+offset]+playfield_x[pl],block_y[n+offset]+playfield_y[pl]-2,block_tile[b_tile+n])
PUB Drop_Peice(pl) | x,y,n, calc, offset, screen_offset
  screen_offset:=pl* CONSTANT(20*10)
  offset:=pl*10 ''offset for player blocks
  ''erases old peice
  Erase_Block(pl)
   ''copy old block position
  repeat n from 0 to 4
     block_x[n+5+offset]:=block_x[n+offset]
     block_y[n+5+offset]:=block_y[n+offset]
  ''drop peice
  repeat n from 0 to 4
     block_y[n+offset]+=1
  ''check the colision detection
  calc:=Check_Hit(pl)
  ''if the blocks hit something, reset peice position, places blocks on bg
  if(calc==1)
     sound.sfx_play(1, @SoundFX3) 'Play a sound effect  
     n:=4 ''grab general location
     block_x[n+offset]:=block_x[n+5+offset]
     block_y[n+offset]:=block_y[n+5+offset]  
    repeat n from 0 to 3
     block_x[n+offset]:=block_x[n+5+offset]
     block_y[n+offset]:=block_y[n+5+offset]
     calc:=(block_y[n+offset]*10)+block_x[n+offset]
     game_field[calc+screen_offset]:=block_tile[(pl*4)+n]
    Draw_Block(pl) '' draw the block in it's final resting place
    ''check for a line
    Check_Tris(pl)
    if(battle) ''are we in a battle game?
      Check_Battle(pl) ''add pending blocks if in a battle game
    New_Peice(pl) ''grab new piece
    no_softdrop[pl]~~
    if (player==0 AND softdrop_lines)
      score += softdrop_lines~
      Draw_Score

  ''we didn't hit anything
  else
    Draw_Block(pl) '' draw block
    if (joypad & JOY0_DOWN)
      softdrop_lines++
PUB Check_Battle(pl) | n, x, n2, temp_row, screen_offset
   if(pending_blocks[pl]>0)
    screen_offset:=pl* CONSTANT(20*10)
    repeat n from 0 to pending_blocks[pl]-1
     temp_row:=screen_offset
      ''check top most row to see if there are any blocks
      repeat x from 0 to 9
          if(game_field[temp_row+x] <> Empty_Tile)
            Do_Gameover(pl) ''if there are blocks on the top row, game over
      ''shift all the blocks up
      repeat n2 from 0 to CONSTANT(19-1)
         repeat x from 0 to 9
          game_field[temp_row+x]:=game_field[temp_row+x+10]
       temp_row+=10          

      ''add other player's row of blocks
      repeat x from 0 to 9
        game_field[CONSTANT(10*19)+x+screen_offset]:=14+Block_offset
      ''place a hole in that row so it can be cleared
      game_field[CONSTANT(10*19)+7+screen_offset]:=Empty_Tile
    pending_blocks[pl]:=0
    Draw_GameField(pl)
    'Draw_Block(pl) 
PUB Check_Tris(pl) | n, row, counter, row_offset, temp_row, kill, screen_offset,line_cnt
   screen_offset:=pl* CONSTANT(20*10)
   row_offset:=0 ''offset for player blocks
   line_cnt:=0   ''line counter
   repeat row from 0 to 19
     counter:=0  
     repeat n from 0 to 9
       ''count number of blocks
       if(game_field[row_offset+n + screen_offset] <>Empty_Tile)
         counter++

    ''we have a full line to clear
    if(counter==10)
      line_cnt++
      sound.sfx_play(1, @SoundFX4) 'Play a sound effect
      ''shift all the blocks down
      temp_row:=row_offset
      repeat kill from 0 to row-1
        repeat n from 0 to 9
          game_field[temp_row+n+ screen_offset]:=game_field[temp_row+n-10+ screen_offset]
       temp_row-=10   
     Draw_GameField(pl) '' redraw playfield
   ''ready next row     
    row_offset+=10
    
   ''check to see if player levels up
   if(player==0 AND line_cnt>0)
      level_lines[0]+=line_cnt
      if(level_lines[0] =>Level_UP)
        level_lines[0]-=Level_UP
        if(level_lines[1]<9)
           level_lines[1]++           
           Draw_Level ''draw new level number on screen
           New_Speed(level_lines[1]) ''set new speed
           sound.sfx_play(1, @SoundFX5) 'Play a sound
      '' Handle scoring
      score += lookup(line_cnt: 40,100,300,1200)*(level_lines[1]+1)
      Draw_Score
      
   ''handle lines cleared
   if(line_cnt>0)
     ''check to see if we are in elimination mode
     if(player == 1 AND battle == 0)
       if(line_cnt => lines[pl]) '' have all the lines been cleared?
        lines[pl]:=0
        Draw_Lines(pl) '' draw number of lines
        Do_Gameover(pl^1) ''game over for other player
       else
        lines[pl]-=line_cnt
     else
       lines[pl]+=line_cnt ''add line count
     Draw_Lines(pl) '' draw number of lines     
     if(battle) ''check if we are in a battle game
       pending_blocks[pl^1]+=line_cnt-1 ''add lines to be added to other player's table

PUB Draw_GameField(pl) | ycounter,y,x, screen_offset, screen_value
     ''draw gamefield
     screen_offset:=pl* CONSTANT(20*10)     
     ycounter:=20
     repeat y from 0 to 17
       repeat x from 0 to 9
        screen_value:=game_field[ycounter+x+screen_offset]
          tv_game_gfx.Place_Tile_XY(x+playfield_x[pl],y+playfield_y[pl],screen_value)          
       ycounter+=10                            

PUB Pause_GameField(pl) |y,x
  '' Clear gamefield and put PAUSE text in it
  repeat y from 0 to 17
    repeat x from 0 to 9
      tv_game_gfx.Place_Tile_XY(x+playfield_x[pl],y+playfield_y[pl],Empty_Tile)
  Print_String(playfield_x[pl],8+playfield_y[pl],@PauseText)
               
PUB Check_Hit(pl) | x,y, n, calc, offset, screen_offset    
  ''check screen limits
  offset:= pl*10 ''offset for player blocks
  screen_offset:=pl*CONSTANT(20*10)
  repeat n from 0 to 3
    if(block_x[n+offset]>9)
      return 1
    if(block_x[n+offset]<0)
      return 1
    if(block_y[n+offset]>19)
      return 1
  ''check blocks to see if they hit anything
  repeat n from 0 to 3
     calc:=(block_y[n+offset]*10)+block_x[n+offset] '' grab block position
''     if (game_field[calc+screen_offset]>0)
     if (game_field[calc+screen_offset]<>Empty_Tile)     
       return 1
  return 0 '' no collision
PUB Do_Gameover(pl) | go_counter,x, y, counter 
''Handle game over sequence
     go_counter:=0 ''counter to keep looping through game over sequence
     counter:=100 ''delay counter
     Game_Play_State:=1 ''go back to menu after this
     y:=0
     repeat until go_counter <> 0
      ''sync to vsync
      Wait_Vsync
      counter++
       if(counter>6)
        counter:=0
        sound.sfx_play(1, @SoundFX3) 'Play a sound effect on FX channel (1)
        ''draw one row of wall
        repeat x from 0 to 9
         tv_game_gfx.Place_Tile_XY(x+playfield_x[pl],y+playfield_y[pl],Door_Tile)
        y++
        if(y>17)
         go_counter:=1
    ''delay it a little bit after wall comes down
    go_counter:=0
    y:=0
    {repeat until go_counter <> 0
     repeat while long[$7F00-4] <> 192
     counter++
       if(counter>500)
        counter:=0
        y++
        if(y>3)
          go_counter:=1}
     Pause_loop

PUB New_Rot(pl,direction) | n, calc, offset, old_angle
     old_angle:=block_angle[pl]
     ''change angle
     if(direction==1)
       block_angle[pl]++
     if(direction==2)
       block_angle[pl]--
     block_angle[pl]&=3 ''mask off everything else to have 0-3
     ''grabs new angle and places peice in memory
     calc_adr:= block_adr[pl] +  (4*block_angle[pl])
     offset:= pl*10 ''offset for player blocks
     ''copy current location/shape
     repeat n from 0 to 4
          block_x[n+5+offset]:=block_x[n+offset]
          block_y[n+5+offset]:=block_y[n+offset]        
     
     repeat n from 0 to 3
        block_x[n+offset]:=((byte[calc_adr+n]) >>4) + block_x[4+offset]
        block_y[n+offset]:=(byte[calc_adr+n] & $F) + block_y[4+offset] 

     ''if the blocks hit something, return it back to old state
     calc:=Check_Hit(pl)
     if(calc==1)
        block_angle[pl]:=old_angle ''restore angle since we can't rotate
        repeat n from 0 to 4
          block_x[n+offset]:=block_x[n+5+offset]
          block_y[n+offset]:=block_y[n+5+offset]
     else
     ''block doesn't hit anything store new value in old pos
       if(direction<>0)     
        sound.sfx_play(1, @SoundFX1) 'Play a sound effect
       repeat n from 0 to 4
          block_x[n+5+offset]:=block_x[n+offset]
          block_y[n+5+offset]:=block_y[n+offset]
       ''get block peice tile map
       Grab_P_Layout(pl)
                        
     Draw_Block(pl)
     return(calc)''return hit

PUB Draw_Screen(pl) |n,x,y
     ''draw wall
     repeat n from 1 to 18                                           
       tv_game_gfx.Place_Tile_XY(playfield_x[pl]-1,n+playfield_y[pl],5)  ''draw wall
       tv_game_gfx.Place_Tile_XY(playfield_x[pl]-1+11,n+playfield_y[pl],5)  ''draw wall
     repeat n from 0 to 9
       tv_game_gfx.Place_Tile_XY(playfield_x[pl]+n,18+playfield_y[pl],2)  ''draw wall
     ''corners
     tv_game_gfx.Place_Tile_XY(playfield_x[pl]-1,18+playfield_y[pl],13)  
     tv_game_gfx.Place_Tile_XY(playfield_x[pl]+10,18+playfield_y[pl],12)
     tv_game_gfx.Place_Tile_XY(playfield_x[pl]-1,playfield_y[pl],4)  
     tv_game_gfx.Place_Tile_XY(playfield_x[pl]+10,playfield_y[pl],4)
     
     ''clear playfield 
     repeat y from 0 to 17
       repeat x from 0 to 9
        tv_game_gfx.Place_Tile_XY(x+playfield_x[pl],y+playfield_y[pl],Empty_tile)

     ''next box
     repeat n from 0 to 5
        tv_game_gfx.Place_Tile_XY(next_x[pl],next_y[pl]+n,5)  
        tv_game_gfx.Place_Tile_XY(next_x[pl]+5,next_y[pl]+n,5)
        tv_game_gfx.Place_Tile_XY(next_x[pl]+n,next_y[pl],2)  
        tv_game_gfx.Place_Tile_XY(next_x[pl]+n,next_y[pl]+6,2)                       
     repeat y from 0 to 4
       repeat x from 0 to 3
        tv_game_gfx.Place_Tile_XY(x+next_x[pl]+1,y+next_y[pl]+1,Empty_tile) 
     Print_String(next_x[pl]+1,next_y[pl]+1,@NextText)
     ''lines box
     repeat n from 0 to 5
       tv_game_gfx.Place_Tile_XY(next_x[pl]+n,next_y[pl],2)
       tv_game_gfx.Place_Tile_XY(next_x[pl]+n,next_y[pl]-3,2)
     repeat n from 0 to 3
       tv_game_gfx.Place_Tile_XY(next_x[pl],next_y[pl]-3+n,5)
       tv_game_gfx.Place_Tile_XY(next_x[pl]+5,next_y[pl]-3+n,5)
     ''corners
       tv_game_gfx.Place_Tile_XY(next_x[pl],next_y[pl]-3,11)
       tv_game_gfx.Place_Tile_XY(next_x[pl]+5,next_y[pl]-3,14)
       tv_game_gfx.Place_Tile_XY(next_x[pl],next_y[pl]+6,13)
       tv_game_gfx.Place_Tile_XY(next_x[pl]+5,next_y[pl]+6,12)
       tv_game_gfx.Place_Tile_XY(next_x[pl],next_y[pl],8)
       tv_game_gfx.Place_Tile_XY(next_x[pl]+5,next_y[pl],10)

     repeat y from 0 to 1
       repeat x from 0 to 3
         tv_game_gfx.Place_Tile_XY(x+next_x[pl]+1,y+next_y[pl]-2,Empty_tile)
     Print_String(next_x[pl]+1,next_y[pl]-2,@LineText)
     Draw_Lines(pl) '' draw number of lines

     ''Draw current Level and score (1 player only)
     if(player==0)
      repeat n from 0 to 7
       tv_game_gfx.Place_Tile_XY(22+n,17-3,2)
       tv_game_gfx.Place_Tile_XY(22+n,19-3,2)
       tv_game_gfx.Place_Tile_XY(22+n,22-3,2)
      tv_game_gfx.Place_Tile_XY(21,18-3,5)
      tv_game_gfx.Place_Tile_XY(30,18-3,5)
      tv_game_gfx.Place_Tile_XY(21,19-3,8)
      tv_game_gfx.Place_Tile_XY(30,19-3,10)
      tv_game_gfx.Place_Tile_XY(21,20-3,5)
      tv_game_gfx.Place_Tile_XY(30,20-3,5)
      tv_game_gfx.Place_Tile_XY(21,21-3,5)
      tv_game_gfx.Place_Tile_XY(30,21-3,5)
      tv_game_gfx.Place_Tile_XY(21,17-3,11)
      tv_game_gfx.Place_Tile_XY(21,22-3,13)
      tv_game_gfx.Place_Tile_XY(30,17-3,14)
      tv_game_gfx.Place_Tile_XY(30,22-3,12)            
      tv_game_gfx.Place_Tile_XY(22,17-3,7)
      tv_game_gfx.Place_Tile_XY(27,17-3,7)                  
      Print_String(22,18-3,@LevelText)
      Print_String(22,20-3,@ScoreText)
      Draw_Level '' draw current level number
      Draw_Score
                            
PUB Reset_Game_Var(pl) |n, calc, p_loop, offset, peice
     ''one player
     if(pl==0)
       repeat n from 0 to 1
        ''location of next/lins boxes
        next_x[n]:=22
        next_y[n]:=8
        ''offset for play field
        playfield_x[n]:=10
        playfield_y[n]:=4
        Lines[n]:=0 ''reset number of lines cleared
        level_lines[0]:=0 ''reset counter to see if we advance to new level
        level_lines[1]:=level_var ''current level player starts out on        
     ''two player
     if(pl==1) 
     ''2 player values
        next_x[0]:=13
        next_y[0]:=7
        next_x[1]:=13
        next_y[1]:=17
        
        ''offset for play field
        playfield_x[0]:=1
        playfield_y[0]:=5      
        playfield_x[1]:=21 
        playfield_y[1]:=5
        '' position on list for next block
        'next_peice_2p[0]:=0 '' position on list for next block
        'next_peice_2p[1]:=0 '' position on list for next block       
        Lines[0]:=0 ''reset number of lines cleared
        Lines[1]:=0 ''reset number of lines cleared
        
        '' if we are not in battle mode, then we want to clear 25 lines
        if(battle==0) 
         Lines[0]:=Lines_to_clear
         Lines[1]:=Lines_to_clear        
        '' generate random block list for 2 player
        {
        repeat n from 0 to 50
          peice:=7
          repeat while peice == 7
            peice:=(?rand & $7)
          ''general peice location
          ''peice:=0''debug
          byte[@block_list+n]:=peice
          }
        
     ''reset number of blocks to push game field up(used for 2p battle)
     pending_blocks[0]:=0
     pending_blocks[1]:=0
     Game_Play_State:=0 'reset in game loop
     ''clear screen
     Clr_Screen(Empty_Tile) 'clear the screen, set the colors
     Print_String(12,1,@TitleText)
     ''reset game table
     repeat n from 0 to CONSTANT(20*10) *2
        Game_Field[n]:=Empty_Tile
       ''check to see if we need to place random blocks in play field
     New_Height

    score~
    softdrop_lines~

    ''clear all player value    
    repeat p_loop from 0 to pl
     'p_loop:=pl ''debug 
     offset:= p_loop * CONSTANT(20*10)
     block_color[p_loop]:=Empty_Tile ''reset next block color
     ''redraw screen
     Draw_Screen(p_loop)
     no_softdrop[p_loop]~~
     drop_clock[p_loop]:=new_clock 'reset peice drop clock
     next_peice[p_loop]:=0
     ''start a new peice(do this twice so first peice is random
     bag[p_loop].init(rand)
     New_Peice(p_loop)
     New_Peice(p_loop)
     Draw_GameField(p_loop) '' draw game field
     Draw_Block(p_loop)     ''draw game peice
     New_Speed(level_var) ''set how fast pieces drop
     

PUB New_Height | n, offset, block_num, location, area, ran_color
'' randomly place blocks in playfield
 if(height_var>0)
  
   offset:=10*(20-byte[@height_rows+height_var-1]) ''where blocks will go
   block_num:=byte[@height_blocks+height_var-1]-1 '' number blocks to place in field
   area:=byte[@height_rows+height_var-1]*10  ''total area the blocks will cover

    repeat n from 0 to block_num
      location := area
      repeat while location > area-1
       location:=(?rand & 127)
       if(location+offset < CONSTANT(20*10))
        if game_field[location+offset]==Empty_Tile
         ''select a random color
         ran_color:=7
         repeat while ran_color == 7
            ran_color:=(?rand & $7)
         game_field[location+offset]:=(ran_color+1)*$F
        else
          location:=area

  ''check to make sure we don't have a full line of random blocks
   offset:=0
   repeat n from 0 to 19
     area:=0
     repeat block_num from 0 to 9
      if game_field[offset] > Empty_Tile
        area++
      offset++
     if area==10
      game_field[offset-3]:= Empty_Tile 

   ''copy over to player 2 field   
   offset:=CONSTANT(20*10)
   repeat n from 0 to CONSTANT(20*10)
     game_field[offset+n]:=game_field[n]

             
PUB New_Speed(speed_lvl) 
''select speed that pieces drop
 if TV_Type== NTSC
   new_clock:=byte[@drop_speed_NTSC+speed_lvl]
 else
   new_clock:=byte[@drop_speed_PAL+speed_lvl]          
PUB Draw_Lines (pl)
     ''update number of lines diplayed   
     Print_Int(next_x[pl]+1,next_y[pl]-1,Lines[pl],4)        

PUB Draw_Level
     ''update number of lines diplayed
    Print_Int(28,15,level_lines[1],2)   
PUB Draw_Score
     ''update diplayed score
    Print_Int(22,18,score,8)            
    
PUB Draw_Next(pl) | n, temp_x, temp_y, b_adr, offset_tile,offset 
'' draw next peice in next box
     repeat temp_y from 0 to 2
       repeat temp_x from 0 to 3
         tv_game_gfx.Place_Tile_XY(temp_x+next_x[pl]+1,temp_y+next_y[pl]+2,Empty_tile) ''clear next box

     ''grabs new angle and places peice in memory
     b_adr:= @blocks + (16 * next_peice[pl]) 

''     ''match color with peice
''     offset_tile:=(next_peice[pl]*15)+Block_offset

     block_adr[pl]:= @blocks + (16 * next_peice[pl])
     block_color[pl]:=next_peice[pl]+1
     ''match color with peice
     offset_tile:=(next_peice[pl]*15)+Block_offset
     ''get block peice tile map
     offset:=(next_peice[pl]*8)+@Block_Tile_Map
     block_tile[(pl*4)]:=(Byte[offset] & $F)  + offset_tile
     block_tile[1+(pl*4)]:=((Byte[offset] >> 4)& $F) + offset_tile
     block_tile[2+(pl*4)]:=(Byte[offset+1] & $F) + offset_tile
     block_tile[3+(pl*4)]:=((Byte[offset+1] >> 4)& $F) + offset_tile
     
     repeat n from 0 to 3
        temp_x:=((byte[b_adr+n]) >>4)
        temp_y:=(byte[b_adr+n] & $F)         
        tv_game_gfx.Place_Tile_XY(1+temp_x + next_x[pl],2+temp_y + next_y[pl]-1,block_tile[n+(pl*4)])

Grab_P_Layout(pl) ''reset layout for piece in play        
PUB New_Peice (pl) | n, peice, rot_check, offset
''reset game peices     
     drop_clock[pl]:=new_clock ''reset drop timer
     block_angle[pl]:=0 ''reset peice angle
     current_peice[pl]:=next_peice[pl] ''grab peice from next box
     Grab_P_Layout(pl) ''grab tile layout
  ''grab a random peice
     {'' 1 player
     if(player==0)
       peice:=7
       repeat while peice == 7
           peice:=(?rand & $7)
       ''general peice location
       ''peice:=0''debug
       next_peice[pl]:=peice
      '' 2 player
     else
       next_peice_2p[pl]+=1
       if(next_peice_2p[pl]>49)
         next_peice_2p[pl]:=0
       ''next_peice[pl]:=block_list[next_peice_2p[pl]]
       next_peice[pl]:=byte[@block_list+next_peice_2p[pl]]}
     next_peice[pl] := bag[pl].getpiece
       
     offset:=10*pl ''calculate memory offset for each player
     block_x[4+offset]:=4
     block_y[4+offset]:=0     
     block_angle[pl]:=0 'reset angle
     rot_check:=New_Rot(pl,0) 'grab peice, place it in memory
     ''if board is full, start new game
     if rot_check==1
       ''Game_Play_State:=1 ''end game, game over
       Do_Gameover(pl) ''end game, game over
     Draw_Next(pl)

PUB Grab_P_Layout(pl) | offset, offset_tile
'' grab the tile layout for current peice      
     ''grab peice from next peice       
     block_adr[pl]:= @blocks + (16 * current_peice[pl])
     block_color[pl]:=current_peice[pl]+1
     ''match color with peice
     offset_tile:=(current_peice[pl]*15)+Block_offset
     ''get block peice tile map
     offset:=(current_peice[pl]*8)+@Block_Tile_Map + (block_angle[pl]*2)
     block_tile[(pl*4)]:=(Byte[offset] & $F)  + offset_tile
     block_tile[1+(pl*4)]:=((Byte[offset] >> 4)& $F) + offset_tile
     block_tile[2+(pl*4)]:=(Byte[offset+1] & $F) + offset_tile
     block_tile[3+(pl*4)]:=((Byte[offset+1] >> 4)& $F) + offset_tile

PUB Print_String(x,y,adr) | n, text_adr
'' prints a string
  n:=0
  text_adr:=adr
  repeat until byte[text_adr+n] == 0
    tv_game_gfx.Place_Tile_XY(x+n,y,byte[text_adr+n]+Font_offset) ''write characer
    n++
PUB Print_Int(x,y,int,digits) : sp | chr
  x+=digits
  repeat digits
   ifnot sp
     chr := int//10+constant("0"+Font_offset)
   else
     chr := constant(" "+Font_offset)
   tv_game_gfx.Place_Tile_XY(--x,y,chr)
   sp := NOT (int /= 10)
PUB Screen_Grab | current_line, pixel_adr, cur_pixel, pixel_4,packet
  '' Stop the TV driver, send 16 bits of X pixel width, send 16 bits of Y pixel
  ''    height, send the screen data, then when all is finished send $FF to tell
  ''    client no more pixel data is coming. After that is done start up the TV
  ''    driver.
  tv_game_gfx.tv_stop

  ''send X screen width - 16 bits big endian
  uart.tx($01) ''256
  uart.tx($00)
  ''send Y screen length - 16 bits big endian
  uart.tx($00) ''192
  uart.tx($C0)
  
  ''send screen data   
  current_line:=0
  repeat 192
    long[request_scanline]:= current_line
    pixel_adr:=SCANLINE_BUFFER
    ''pixel_adr+=(255-32)
    ''read scanline and send scanline
    repeat 256
    ''+2 added because TV driver adds this when it renders the signal
     cur_pixel:=byte[pixel_adr]''+2 
     pixel_adr+=1
     uart.tx(cur_pixel) ' - send byte
     {
     '' this will loop until we receive a valid byte
     repeat
       packet:=uart.rxcheck
     while packet==-1  'wait until valid byte is received
      }
   current_line+=1
  uart.tx($FF) ' - all done
  ''start tv driver up again
'  longmove(@tv_status, @tvparams, paramcount)
'  tv_colors := @colors
  tv_game_gfx.tv_start
            

DAT
 ''tile graphics
TileFile file "tile.dat"
''sound effects
byte 0 ''debug, help allign memory
''flip sound                   'Wav 'Len 'Fre 'Vol 'LFO 'LFW 'FMa 'AMa
SoundFX1                byte    $01, $03, $D0, $0F, $01, $00, $04, $05  
                                'Att 'Dec 'Sus 'Rel
                        byte    $D0, $24, $40, $FF
''selet/move sound              'Wav 'Len 'Fre 'Vol 'LFO 'LFW 'FMa 'AMa
SoundFX2                byte    $01, $03, $80, $0F, $00, $00, $30, $F0  
                                'Att 'Dec 'Sus 'Rel
                        byte    $30, $E0, $FF, $A0
''drop sound                   'Wav 'Len 'Fre 'Vol 'LFO 'LFW 'FMa 'AMa
SoundFX3                byte    $06, $02, $10, $0F, $F0, $00, $F0, $30  
                                'Att 'Dec 'Sus 'Rel
                        byte    $30, $30, $FF, $F0
'' clear line sound
SoundFX4                byte    $06, $FF, $5F, $0F, $01, $03, $01, $00  
                                'Att 'Dec 'Sus 'Rel
                        byte    $FF, $14, $00, $FF

''level up sound
SoundFX5                byte    $00, $FF, $06, $0F, $09, $FF, $04, $05
                                'Att 'Dec 'Sus 'Rel
                        byte    $F1, $F4, $F0, $0F
                        byte    $F1, $78, $3C, $00, $00, $00, $F1, $78, $3C, $00, $00, $00, $00, $00, $00, $00
                        

Text1p
byte "1 PLAYER",0
Text2p
byte "2 PLAYER - ELIMINATION",0
Text2psu
byte "2 PLAYER - BATTLE",0
TitleText
byte "SPINTRIS",0
DateText
byte "02 OCT 2019 - JT COOK & ADA G.",0
DemoText
byte "WWW.AVALONDREAMS.COM",0
PauseText
byte "- PAUSED -",0
LevelText
byte "LEVEL: ",0
ScoreText
byte "SCORE: ",0
NextText
byte "NEXT",0
LineText
byte "LINE",0
Height0
byte "HEIGHT 0",0
Height1
byte "HEIGHT 1",0
Height2
byte "HEIGHT 2",0
Height3
byte "HEIGHT 3",0
Height4
byte "HEIGHT 4",0
Height5
byte "HEIGHT 5",0
Level0
byte "LEVEL 0",0
Level1
byte "LEVEL 1",0
Level2
byte "LEVEL 2",0
Level3
byte "LEVEL 3",0
Level4
byte "LEVEL 4",0
Level5
byte "LEVEL 5",0
Level6
byte "LEVEL 6",0
Level7
byte "LEVEL 7",0
Level8
byte "LEVEL 8",0
Level9
byte "LEVEL 9",0
''setup height tables
height_rows
byte 3,5,8,10,12
height_blocks
byte 14,24,36,47,55
''the speed the blocks drop
drop_speed_NTSC
''slowest is 50, fastest is 7 - 4.8 difference between step
byte 50,45,40,36,31,26,21,16,12,7
drop_speed_PAL
'' slowest 41.66, fastest is 5.83 - 3.981 bewteen each step
byte 42,38,34,30,26,22,18,14,10,6

''peices
'' each peice is made up of 4 bytes, one nibble for x offset, other for y offset
'' there are 4 different rotation angles per peice
'' each peice set is made up of 16 bytes (4x4)
'' each peice rotates next set right
blocks
''sqaure block 
byte $12, $22, $13, $23   '' [][]
byte $12, $22, $13, $23   '' [][]
byte $12, $22, $13, $23  
byte $12, $22, $13, $23

''line peice 
byte $02, $12, $22, $32   '' start  [][][][]
byte $20, $21, $22, $23
byte $02, $12, $22, $32
byte $20, $21, $22, $23

''t peice              
byte $02, $12, $22, $13   '' start  [][][]
byte $11, $12, $13, $02   ''          []
byte $02, $12, $22, $11   
byte $11, $12, $13, $22

'' J peice   
byte $02, $12, $22, $23
byte $11, $12, $13, $03
byte $02, $12, $22, $01  '' start  [][][]
byte $11, $12, $13, $21  ''            []

'' L peice
byte $02, $12, $22, $03  
byte $11, $12, $13, $01  
byte $02, $12, $22, $21  '' start [][][]
byte $11, $12, $13, $23  ''       []


'' s peice  
byte $12, $22, $03, $13  '' start   [][]
byte $11, $12, $22, $23  ''       [][]
byte $12, $22, $03, $13  
byte $11, $12, $22, $23

'' backward s peice   
byte $02, $12, $13, $23  ''start   [][]
byte $12, $13, $21, $22  ''          [][]
byte $02, $12, $13, $23
byte $12, $13, $21, $22
'''' Piece maps, tile numbers that go with each peice
'' each tile is a nibble
Block_Tile_Map
'' square block
byte $DA, $BC
byte $DA, $BC
byte $DA, $BC
byte $DA, $BC

''line peice
byte $10, $21
byte $43, $54
byte $10, $21
byte $43, $54

''t peice
byte $80, $52
byte $93, $05 
byte $60, $32
byte $73, $25

''J peice
byte $10, $5D
byte $43, $0B
byte $1C, $32 
byte $4A, $25

''L peice    -x
byte $1A, $52
byte $4D, $05  
byte $10, $3B 
byte $43, $2C

''S peice
byte $2A, $B0 
byte $C3, $5D
byte $2A, $B0 
byte $C3, $5D

''backwards s peice
'byte $D0, $2C
byte $D0, $2C
byte $5A, $B3
byte $D0, $2C
byte $5A, $B3

Char_Data
'misc characters
byte 255,255,255,255,255,255,255,255 'solid block - 0
byte 170,85,170,85,170,85,170,85 ' checker board - 1
byte 128,64,32,16,8,4,2,1 ' slash char - 2
byte 56,84,214,254,130,68,56,0 ' smiley face - 3
byte 126,129,165,129,189,153,129,126 ' - 4
byte 1,127,127,127,127,127,127,255 ' block - 5                                 
byte 102,255,12,48,60,12,48,24 ' screw - 6
byte 0,0,0,0,0,0,0,0 ' nothing - 5                                 
byte 0,0,0,0,0,0,0,0 ' nothing - 6
byte 0,0,0,0,0,0,0,0 ' nothing - 7
byte 0,0,0,0,0,0,0,0 ' nothing - 8
byte 0,0,0,0,0,0,0,0 ' nothing - 9
byte 0,0,0,0,0,0,0,0 ' nothing - 10
byte 0,0,0,0,0,0,0,0 ' nothing - 11              
byte 0,0,0,0,0,0,0,0 ' nothing - 12
byte 0,0,0,0,0,0,0,0 ' nothing - 13
byte 0,0,0,0,0,0,0,0 ' nothing - 14
byte 0,0,0,0,0,0,0,0 ' nothing - 15
byte 0,0,0,0,0,0,0,0 ' nothing - 16
byte 0,0,0,0,0,0,0,0 ' nothing - 17
byte 0,0,0,0,0,0,0,0 ' nothing - 18              
byte 0,0,0,0,0,0,0,0 ' nothing - 19
byte 0,0,0,0,0,0,0,0 ' nothing - 20
byte 0,0,0,0,0,0,0,0 ' nothing - 21
byte 0,0,0,0,0,0,0,0 ' nothing - 22
byte 0,0,0,0,0,0,0,0 ' nothing - 23
byte 0,0,0,0,0,0,0,0 ' nothing - 24
byte 0,0,0,0,0,0,0,0 ' nothing - 25              
byte 0,0,0,0,0,0,0,0 ' nothing - 26
byte 0,0,0,0,0,0,0,0 ' nothing - 27
byte 0,0,0,0,0,0,0,0 ' nothing - 28
byte 0,0,0,0,0,0,0,0 ' nothing - 29
byte 0,0,0,0,0,0,0,0 ' nothing - 30
byte 0,0,0,0,0,0,0,0 ' nothing - 31
'enter, special characters
byte 0,0,0,0,0,0,0,0 ' Enter/Clear - 32              
byte 24,24,24,24,0,0,24,0 ' ! - 33
byte 102,102,102,0,0,0,0,0 ' " - 34
byte 102,102,255,102,255,102,102,0 ' # - 35
byte 24,62,96,60,6,124,24,0 '$ - 36
byte 98,102,12,24,48,102,70,0' % - 37
byte 60,102,60,56,103,102,63,0 ' & - 38
byte 6,12,24,0,0,0,0,0 ' ' - 39              
byte 12,24,48,48,48,24,12,0 ' ( - 40
byte 48,24,12,12,12,24,48,0 ' ) - 41
byte 0,102,60,255,60,102,0,0 ' * - 42
byte 0, 24,24,126,24,24,0,0 ' +  - 43
byte 0,0,0,0,0,24,24,48 ' ,  44
byte 0,0,0,126,0,0,0,0 ' - - 45
byte 0,0,0,0,0,24,24,0 ' . - 46              
byte 0,3,6,12,24,48,96,0 ' / - 47
'Numbers 0-9
byte 60,102,110,118,102,102,60,0 ' 0 - 48
byte 24,24,56,24,24,24,126,0 ' 1 - 49
byte 60,102,6,12,48,96,126,0 ' 2 - 50
byte 60,102,6,28,6,102,60,0 ' 3 - 51
byte 6,14,22,102,127,6,6,0 ' 4 - 52
byte 126,96,124,6,6,102,60,0 ' 5 - 53              
byte 60,102,96,124,102,102,60,0 ' 6 - 54
byte 126,102,12,12,12,12,12,0 ' 7 - 55
byte 60,102,102,60,102,102,60,0 ' 8 - 56
byte 60,102,102,62,6,102,60,0 ' 9 - 57
'special characters
byte 0,0,24,0,0,24,0,0 ' : - 58
byte 0,0,24,0,0,24,24,48 ' ; - 59
byte 14,24,48,96,48,24,14,0 ' < - 60
byte 0,0,126,0,126,0,0,0 ' = - 61
byte 112,24,12,6,12,24,112,0 ' > - 62
byte 60,102,6,12,24,0,24,0 ' ? - 63
byte 60,102,110,110,96,98,60,0 ' @ - 64
'A-Z upper case
byte 24,60,102,126,102,102,102,0 ' A - 65
byte 124,102,102,124,102,102,124,0 ' B - 66
byte 60,102,96,96,96,102,60,0 ' C - 67
byte 120,108,102,102,102,108,120,0 ' D - 68
byte 126,96,96,120,96,96,126,0 ' E - 69
byte 126,96,96,120,96,96,96,0 ' F - 70
byte 60,102,96,110,102,102,60,0 ' G - 71
byte 102,102,102,126,102,102,102,0 ' H - 72
byte 60,24,24,24,24,24,60,0 'I - 73
byte 30,12,12,12,12,108,56,0 ' J - 74
byte 102,108,120,112,120,108,102,0 ' K - 75
byte 96,96,96,96,96,96,126,0 ' L - 76
byte 99,119,127,107,99,99,99,0 ' M - 77
byte 102,118,126,110,102,102,102,0 ' N - 78
byte 60,102,102,102,102,102,60,0 ' O - 79
byte 124,102,102,124,96,96,96,0 ' P - 80
byte 60,102,102,102,102,102,60,14 ' Q - 81
byte 124,102,102,124,120,108,102,0 ' R - 82
byte 60,102,96,60,6,102,60,0 ' S - 83
byte 126,24,24,24,24,24,24,0 ' T - 84
byte 102,102,102,102,102,102,60,0 ' U - 85
byte 102,102,102,102,102,60,24,0 ' V - 86
byte 99,99,99,107,127,119,99,0 ' W - 87
byte 102,102,60,24,60,102,102,0 ' X - 88
byte 102,102,102,60,24,24,24,0 ' Y - 89
byte 126,6,12,24,48,112,126,0 ' Z - 90
'special characters
byte 60,48,48,48,48,48,60,0 ' [ - 91
byte 0,96,48,24,12,6,3,0 ' \ - 92
byte 60,12,12,12,12,12,60,0 ' ] - 93
byte 24,60,102,0,0,0,0,0 ' ^ - 94
byte 0,0,0,0,0,0,255,0 ' _ - 95
byte 96,48,24,0,0,0,0,0 ' ` - 96
'a-z lower case
byte 0,0,60,6,62,102,62,0 'a - 97
byte 0,96,96,124,102,102,124,0 ' b - 98
byte 0,0,60,96,96,96,60,0 ' c - 99
byte 0,6,6,62,102,102,62,0 ' d - 100
byte 0,0,60,102,126,96,60,0 ' e - 101
byte 0,14,24,62,24,24,24,0 ' f - 102
byte 0,0,62,102,102,62,6,124 ' g - 103
byte 0,96,96,124,102,102,102,0 ' h - 104
byte 0,24,0,56,24,24,60,0 ' i -105
byte 0,6,0,6,6,6,6,60 ' j -106
byte 0,96,96,108,120,108,102,0 ' k - 107
byte 0,56,24,24,24,24,60,0 ' l - 108
byte 0,0,102,127,127,107,99,0 ' m - 109
byte 0,0,124,102,102,102,102,0 ' n - 110
byte 0,0,60,102,102,102,60,0 ' o - 111
byte 0,0,124,102,102,124,96,96 ' p - 112
byte 0,0,62,102,102,62,6,6 ' q - 113
byte 0,0,124,102,96,96,96,0 ' r - 114
byte 0,0,62,96,60,6,124,0 ' s - 115
byte 0,24,126,24,24,24,14,0 ' t - 116
byte 0,0,102,102,102,102,62,0 ' u - 117
byte 0,0,102,102,102,60,24,0 ' v - 118
byte 0,0,99,107,127,62,54,0 ' w - 119
byte 0,0,102,60,24,60,102,0 ' x - 120
byte 0,0,102,102,102,62,12,120' y - 121
byte 0,0,126,12,24,48,126,0 ' z - 122
'special characters
byte 28,48,48,224,48,48,28,0 ' { - 123
byte 24,24,24,24,24,24,24,24 ' | - 124
byte 56,12,12,7,12,12,56,0 ' } - 125
byte 54,108,0,0,0,0,0,0 ' ~ - 126

                         