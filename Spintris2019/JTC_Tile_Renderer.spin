'' Renderer for 8 Bit tile driver
'' JT Cook
''

CON
  SCANLINE_BUFFER = $7F00
PUB start(param)
'' Start Rendering Engine
  cognew(@Entry, param)

DAT
        org
Entry    
        mov Temp_Adr, Par  ''read parameter
        rdlong cognumber, Temp_Adr ''grab which COG number it is
        add Temp_Adr, #4   '' add 4 to address for total # of cogs
        rdlong cogtotal, Temp_Adr ''grab total number of rendering COGs
        
        rdlong Tile_Map_Adr, tilemap_adr ''read address of tile map
'        rdlong Tiles_Adr, tile_adr ''read address of where tiles are at

''Main loop for renderer
Main_Loop
''wait until we hit scanline 0 so we can start with a fresh frame
        mov currentscanline, cognumber ''reset current scanline for COG
        rdlong Tiles_Adr, tile_adr ''read address of where tile graphics are stored
          ''read this each frame incase address changes 
:waitloop
        rdlong currentrequest, request_scanline wz
if_nz   jmp #:waitloop
Render_Tiles
        movd :write_scanline, #scanbuffer   'location of destination of local scanline buffer
        mov Buffer_Number, #0 ''reset scanline buffer location
        ''set character rendering attributes
        mov Temp_Toggle, #0 ''this is used to toggle left or right tile grab
        mov Temp_Row, currentscanline ''grab current scanline(for character row)
        and Temp_Row, #7   ''mask off all but 7 bits to get current tile row
        shl Temp_Row, #3   ''multiply by 8 (each row is 8 bytes)
        ''mov Temp_Col, #0   ''current column we are going to render
        ''grab start position for tile map
        mov Temp_Adr2, currentscanline ''grab current scanline(for character map)

        shr Temp_Adr2, #3    ''divide by 8(each row is 8 pixels)
        shl Temp_Adr2, #5    ''then multiply by 32 (32 tiles per row)        
        add Temp_Adr2, Tile_Map_Adr ''grab tilemap address
:Render_Four
        rdbyte Temp_Adr, Temp_Adr2 ''grab character number
        shl Temp_Adr, #6 ''multiply by 64(each char is 64 bytes)
        add Temp_Adr, Temp_Row   ''grab exact tile row address
        add Temp_Adr, Tiles_Adr  '' add address for current tile

        
        cmp Temp_Toggle, #1 wz ''check to see if we need new address or not
        if_e add Temp_Adr, #4   ''add four to the address
        if_e add Temp_Adr2, #1   ''ready next character to grab
''        if_e add Temp_Col, #1   ''ready next character to grab
        xor Temp_Toggle, #1 ''toggle switch
        rdlong Four_Pixels, Temp_Adr ''copy tile pixels over to background
{                        
        rdlong Load_Four_Pixels, Temp_Adr ''grab four tile pixels

        mov Four_Pixels, #0   ''clear 4 pixel buffer to render to scanline
        ''loops are unrolled (may need to change this for scrolling)
        ''start first pixel
        rol Load_Four_Pixels, #8 ''rotate tile pixles so left most pixel is on left side
        mov Single_Pixel, Load_Four_Pixels ''grab pixel
        and Single_Pixel, #$FF  ''mask off all but current pixel
               
        or Four_Pixels,Single_Pixel ''write pixels to the four pixel buffer
        rol Four_Pixels, #8 ''move all pixels left
        ''second pixel
        rol Load_Four_Pixels, #8 
        mov Single_Pixel, Load_Four_Pixels 
        and Single_Pixel, #$FF        
        or Four_Pixels,Single_Pixel
        rol Four_Pixels, #8
        ''third pixel
        rol Load_Four_Pixels, #8 
        mov Single_Pixel, Load_Four_Pixels 
        and Single_Pixel, #$FF        
        or Four_Pixels,Single_Pixel
        rol Four_Pixels, #8
        ''fourth pixel                
        rol Load_Four_Pixels, #8 
        mov Single_Pixel, Load_Four_Pixels 
        and Single_Pixel, #$FF        
        or Four_Pixels,Single_Pixel
} 
'write pixels to internal scanline buffer
:write_scanline
        mov scanbuffer, Four_Pixels ''write Four Pixel buffer to scanline buffer  
        add :write_scanline, destination_increment  ''move to next index in scanline buffer
        add Buffer_Number, #1            ''add location to scanline buffer
        cmp Buffer_Number, #64 wz,wc     ''if below 64, keep looping
        if_b jmp #:Render_Four           ''keep drawing pixels
        jmp #scanline_finished            ''finish scanline, copy to TV
                                 
scanline_finished                
'' wait until TV requests the scanline we rendered
:wait
        rdlong currentrequest, request_scanline
        cmps currentrequest, currentscanline wz, wc
if_b    jmp #:wait

'' copy scanline
start_tv_copy
        movs :nextcopy, #scanbuffer
        mov Temp_Adr, display_base
        mov Buffer_Number, #64

:nextcopy
        mov Temp_Var,scanbuffer
        add :nextcopy, #1
        wrlong Temp_Var, Temp_Adr
        add Temp_Adr, #4
        djnz Buffer_Number, #:nextcopy                      
scanlinedone
        ' Line is done, increment to the next one this cog will handle                        
        add currentscanline, cogtotal
        cmp currentscanline, #191 wc, wz
if_be   jmp #Render_Tiles
        ' The screen is completed, jump back to main loop a wait for next frame                        
        jmp #Main_Loop


           


display_base            long SCANLINE_BUFFER    ''scanline address
request_scanline        long SCANLINE_BUFFER-4  ''next scanline to render
tilemap_adr             long SCANLINE_BUFFER-8  ''address of tile map
tile_adr                long SCANLINE_BUFFER-12 ''address of tiles

destination_increment long 512 
Buffer_Number long       $0  ''location in scanline buffer
Single_Pixel long       $0  ''single pixel value
Four_Pixels long        $0  ''value stored for 4 pixels
Load_Four_Pixels long   $0  ''loading four pixels from tiles
Temp_Toggle long        $0  ''used to toggle left or right side of tile
Temp_Adr long           $0  ''temp address holder
Temp_Adr2 long           $0  ''temp address holder
Temp_Row long           $0  ''current tile row
Temp_Col long           $0  ''current tile column
Temp_Var long           $0  ''temp value holder
Temp_Var_1 long         $0  ''temp value holder
Tile_Map_Adr long       $0  ''address of tile map
Tiles_Adr long          $0  ''address for tiles
cognumber long          $0  ''which COG this rendering COG is
cogtotal  long          $0  ''total number of rendering COGs
currentscanline long    $0  ''current scanline that TV driver is rendering
currentrequest long     $0  ''next scanline to render
scanbuffer res          65 ''Scanline buffer + 1 extra