''8-Bit Game Graphics tile driver
'' JT Cook
''

CON
  X_Length = 32 ''number of tiles that run horizontally across screen
  Y_Length = 24 ''number of tiles that run vertically across screen

' constants
SCANLINE_BUFFER = $7F00            
request_scanline       = SCANLINE_BUFFER-4  'address of scanline buffer for TV driver
tilemap_adr            = SCANLINE_BUFFER-8  'address of tile map
tile_adr               = SCANLINE_BUFFER-12 'address of tiles
border_color           = SCANLINE_BUFFER-16 'address of border color
{
  PAL=%0001
  NTSC=%0000

  HYBRIDPINS=%011_0000
  PROTOBOARDPINS=%001_0101
  HYDRAPINS=%011_0000

  INTERLACED=%0010
  modepins = HYBRIDPINS 'PROTOBOARDPINS
  mode = NTSC 'PAL'NTSC 'PAL          'don't forget to half y_tiles, if you add interlaced
  
}
  x_tiles = 16 '*16=240
  y_tiles = 12 '*16=160


OBJ
  tv    : "JB_tv_02.spin"             ' tv driver 256 pixel scanline
  gfx   : "JTC_Tile_Renderer.spin"    ' graphics engine

VAR
   byte Tile_Map[X_Length*Y_Length] ''tile map
   'byte Tiles[(64)*Num_Of_Tiles] ''number of tiles (8x8 pixels = 64)

   long cog_number ''used for rendering engine
   long cog_total  ''used for rendering engine  
   'long border_color ''used for borders
''used for TV driver
   long tv_status      '0/1/2 = off/visible/invisible           read-only
   long tv_enable      '0/? = off/on                            write-only
   long tv_pins        '%ppmmm = pins                           write-only
   long tv_mode        '%ccinp = chroma,interlace,ntsc/pal,swap write-only
   long tv_screen      'pointer to screen (words)               write-only
   long tv_colors      'pointer to colors (longs)               write-only               
   long tv_hc          'horizontal cells                        write-only
   long tv_vc          'vertical cells                          write-only
   long tv_hx          'horizontal cell expansion               write-only
   long tv_vx          'vertical cell expansion                 write-only
   long tv_ho          'horizontal offset                       write-only
   long tv_vo          'vertical offset                         write-only
   long tv_broadcast   'broadcast frequency (Hz)                write-only
   long tv_auralcog    'aural fm cog                            write-only
''used to stop and start tv driver

PUB tv_start
  tv.start(@tvparams)

PUB tv_stop
'  tv.stop(@tv_status)
   tv.stop
   
PUB start(video_pins,NorP)      | i
  DIRA[0] := 1
  outa[0] := 0

  long[tilemap_adr] := @Tile_Map  'address of tile map
  long[@tvparams+8]:=video_pins ''map pins for video out
  long[@tvparams+12]:=NorP ''NTSC or PAL  
  ' Boot requested number of rendering cogs:
  ' this must be at least 2, anything less will not be enough cogs  
  cog_total := 2
  cog_number := 0
  repeat
    gfx.start(@cog_number)
    repeat 10000 ' Allow some time for previous cog to boot up before setting 'cog_number' again
    cog_number++
  until cog_number == cog_total  
  long[border_color]:=$02 ''default border color
  'start tv driver
  tv.start(@tvparams)

PUB Place_Tile_XY(x_location, y_location, tile)
'' Place a tile in the tilemap
 ''x_location - select x position of tile
 ''y_location - select y position of tile
 ''tile - which tile will occupy location
   y_location<<=5 '' multiply by 32 since there are 32 tiles per row
   x_location+=y_location ''get final address
   Tile_Map[x_location]:=tile
          
PUB Convert_Tile(char_adr,bit_8_tile,bit_1_tile, bg_color, fg_color) | x,y,n, bit1, bit8_adr,bit1_adr, til_adr
'' Convert a 1 bit tile to an 8 bit tile
'' Convert_Tile(address of 1 bit character table, 8 bit tile location to be decoded to,1 bit tile to decode, background color, foreground color)
   bit8_adr:=bit_8_tile*64 ''grab tile address
   bit1_adr:=bit_1_tile*8 ''grab tile address
   til_adr:=long[tile_adr] ''address of tile graphics      
   repeat y from 0 to 7
    bit1:=Byte[char_adr + y + bit1_adr] ''grab bit row for 1 bit tile
    bit1<-=24 ''working with longs
    repeat x from 0 to 7
     bit1<-=1  ''shift to ready current bit/pixel
     n:=bit1&1 ''grab bit
     if(n==1)
       Byte[til_adr+bit8_adr]:=fg_color
     else
       Byte[til_adr+bit8_adr]:=bg_color
     bit8_adr++ 
  
PUB Set_Border_Color(bcolor) | i
''set the color for border around screen
'    i:= $02020200 + bcolor + 2 
'    longfill(@colors, i, 1) 'set the border in rightmost two hex digits       
'    long[@bordercolor]:=bcolor+2
    'border_color:=(bcolor+2)&$FF
    long[border_color]:=bcolor
     
DAT
tvparams                long    0               'status
                        long    1               'enable
                        long    %011_0000       'pins ' PROTO/DEMO BOARD = %001_0101 ' HYDRA = %011_0000
                        long    0               'mode - default to NTSC
                        long    x_tiles         'hc
                        long    y_tiles         'vc
                        long    10              'hx
                        long    1               'vx
                        long    0               'ho
                        long    0               'vo
                        long    50_000_000'_xinfreq<<4  'broadcast
                        long    0               'auralcog
                        long    SCANLINE_BUFFER
                        long    border_color 'pointer to border colour
                        long    request_scanline
disp_ptr                long    0
VSync                   long    0
                        

nextline                long    0                        