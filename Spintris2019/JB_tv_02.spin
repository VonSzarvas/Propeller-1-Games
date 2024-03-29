''*****************************
''*  TV Driver v1.0           *
''*  (C) 2004 Parallax, Inc.  *
''*****************************

CON

  fntsc         = 3_579_545     'NTSC color frequency
  lntsc         = 3640          'NTSC color cycles per line * 16
  sntsc         = 624           'NTSC color cycles per sync * 16

  fpal          = 4_433_618     'PAL color frequency
  lpal          = 4540          'PAL color cycles per line * 16
  spal          = 848           'PAL color cycles per sync * 16

  paramcount    = 16

VAR

  long  cogon, cog


PUB start(tvptr) : okay

'' Start TV driver - starts a cog
'' returns false if no cog available
''
''   tvptr = pointer to TV parameters

  stop
  okay := cogon := (cog := cognew(@entry,tvptr)) > 0


PUB stop

'' Stop TV driver - frees a cog

  if cogon~
    cogstop(cog)


DAT

'*******************************
'* Assembly language TV driver *
'*******************************

                        org
'
'
' Entry
'
entry
                        mov     t1,par                  'load parameters
                        movd    :par1,#_enable           '(skip _status)
                        mov     t2,#paramcount - 1
:load1                  add     t1,#4
:par1                   rdlong  0,t1
                        add     :par1,d0
                        djnz    t2,#:load1               '+119
                        mov     isinterlacedmode,_mode
                        and     isinterlacedmode,#%0010

                        mov     VSyncFeedBack,par
                        add     VSyncFeedBack,#16*4

                        mov     taskptr,#tasks          'reset tasks

                        mov     x,#10                   'perform task sections initially
:init                   jmpret  taskret,taskptr
                        djnz    x,#:init
'
'
' Superfield
'
superfield              mov     taskptr,#tasks          'reset tasks

                        test    _mode,#%0001    wc      'if ntsc, set phaseflip
        if_nc           mov     phaseflip,phasemask

                        test    _mode,#%0010    wz      'get interlace into z
'
'
' Field
'
field                   mov     x,vinv                  'do invisible back porch lines
:black                  call    #hsync                  'do hsync
                        waitvid burst,sync_high2        'do black
                        jmpret  taskret,taskptr         'call task section (z undisturbed)
                        djnz    x,#:black               'another black line?

                        wrlong  invisible,VSyncFeedBack '1

                        mov     current_line,#0
                        test    interlace,#1     wc
        if_z_and_c      mov     current_line,#1
                        wrlong  current_line,_nextline

                        mov     x,vb                    'do visible back porch lines
                        call    #blank_lines

                        mov     y,_vt                   'set vertical tiles
:line                   mov     vx,_vx                  'set vertical expand
:vert   if_z            xor     interlace,#1            'interlace skip?
        if_z            tjz     interlace,#:skip

                        call    #hsync                  'do hsync

                        mov     vscl,hb                 'do visible back porch pixels
                        mov     ptr,_bordercolour
                        rdlong  bordercolour,ptr
                        xor     tile,bordercolour
                        waitvid tile,#0

                        mov     vscl,hx                 'set horizontal expand
                        mov     x,_ht                   'set horizontal tiles
                        shl     x,#2
                        mov     ptr,_scanline
:xloop                  rdlong  pixels,ptr
                        xor     pixels,phaseflip
                        add     ptr,#4
                        waitvid pixels,#%%3210
                        djnz    x,#:xloop

                        mov     vscl,hf                 'do visible front porch pixels
                        mov     tile,phaseflip
'                        mov     ptr,_bordercolour
'                        rdlong  bordercolour,ptr
                        xor     tile,bordercolour
                        waitvid tile,#0

                        add     current_line,#1
                        cmp     isinterlacedmode,#2    wc      'get interlace into z
        if_nc           add     current_line,#1
                        wrlong  current_line,_nextline

:skip                   djnz    vx,#:vert               'vertical expand?
                        add     line,lineinc    wc      'set next line
        if_nc           jmp     #:line
                        djnz    y,#:line                'another tile line?

        if_z            xor     interlace,#1    wz      'get interlace and field1 into z

                        test    _mode,#%0001    wc      'do visible front porch lines
                        mov     x,vf
        if_nz_and_c     add     x,#1
                        call    #blank_lines

                        mov     t1,par
                        add     t1,#1
                        wrbyte  interlace,t1             'set status to visible

                        wrlong  visible,VSyncFeedBack   '2

'        if_nz           wrlong  invisible,par           'unless interlace and field1, set status to invisible

        if_z_eq_c       call    #hsync                  'if required, do short line
        if_z_eq_c       mov     vscl,hrest
        if_z_eq_c       waitvid burst,sync_high2
        if_z_eq_c       xor     phaseflip,phasemask

                        call    #vsync_high             'do high vsync pulses

                        movs    vsync1,#sync_low1       'do low vsync pulses
                        movs    vsync2,#sync_low2
                        call    #vsync_low

                        call    #vsync_high             'do high vsync pulses

        if_nz           mov     vscl,hhalf              'if odd frame, do half line
        if_nz           waitvid burst,sync_high2

        if_z            jmp     #field                  'if interlace and field1, display field2
                        jmp     #superfield             'else, new superfield
'
'
' Blank lines
'
blank_lines             call    #hsync                  'do hsync

                        mov     ptr,_bordercolour
                        rdlong  bordercolour,ptr
                        xor     tile,bordercolour
                        waitvid tile,#0

                        djnz    x,#blank_lines
blank_lines_ret         ret
'
'
' Horizontal sync
'
hsync                   test    _mode,#%0001    wc      'if pal, toggle phaseflip
        if_c            xor     phaseflip,phasemask

                        mov     vscl,sync_scale1        'do hsync       
                        mov     tile,phaseflip
                        xor     tile,burst
                        waitvid tile,sync_normal

                        mov     vscl,hvis               'setup in case blank line
                        mov     tile,phaseflip

hsync_ret               ret
'
'
' Vertical sync
'
vsync_high              movs    vsync1,#sync_high1      'vertical sync
                        movs    vsync2,#sync_high2

vsync_low               mov     x,vrep

vsyncx                  mov     vscl,sync_scale1
vsync1                  waitvid burst,sync_high1

                        mov     vscl,sync_scale2
vsync2                  waitvid burst,sync_high2

                        djnz    x,#vsyncx
vsync_low_ret
vsync_high_ret          ret
'
'
' Tasks - performed in sections during invisible back porch lines
'
tasks                   mov     t1,par                  'load parameters
                        movd    :par,#_enable           '(skip _status)
                        mov     t2,#paramcount - 1
:load                   add     t1,#4
:par                    rdlong  0,t1
                        add     :par,d0
                        djnz    t2,#:load               '+119

                        mov     t1,_pins                'set video pins and directions
                        test    t1,#$08         wc
        if_nc           mov     t2,pins0
        if_c            mov     t2,pins1
                        test    t1,#$40         wc
                        shr     t1,#1
                        shl     t1,#3
                        shr     t2,t1
                        movs    vcfg,t2
                        shr     t1,#6
                        movd    vcfg,t1
                        shl     t1,#3
                        and     t2,#$FF
                        shl     t2,t1
        if_nc           mov     dira,t2
        if_nc           mov     dirb,#0
        if_c            mov     dira,#0
        if_c            mov     dirb,t2                 '+18

                        tjz     _enable,#disabled       '+2, disabled?

                        jmpret  taskptr,taskret         '+1=140, break and return later

                        movs    :rd,#wtab               'load ntsc/pal metrics from word table
                        movd    :wr,#hvis
                        mov     t1,#wtabx - wtab
                        test    _mode,#%0001    wc
:rd                     mov     t2,0
                        add     :rd,#1
        if_nc           shl     t2,#16
                        shr     t2,#16
:wr                     mov     0,t2
                        add     :wr,d0
                        djnz    t1,#:rd                 '+54

        if_nc           movs    :ltab,#ltab             'load ntsc/pal metrics from long table
        if_c            movs    :ltab,#ltab+1
                        movd    :ltab,#fcolor
                        mov     t1,#(ltabx - ltab) >> 1
:ltab                   mov     0,0
                        add     :ltab,d0s1
                        djnz    t1,#:ltab               '+17

                        rdlong  t1,#0                   'get CLKFREQ
                        shr     t1,#1                   'if CLKFREQ < 16MHz, cancel _broadcast
                        cmp     t1,m8           wc
        if_c            mov     _broadcast,#0
                        shr     t1,#1                   'if CLKFREQ < color frequency * 4, disable
                        cmp     t1,fcolor       wc
        if_c            jmp     #disabled               '+11

                        jmpret  taskptr,taskret         '+1=83, break and return later

                        mov     t1,fcolor               'set ctra pll to fcolor * 16
                        call    #divide                 'if ntsc, set vco to fcolor * 32 (114.5454 MHz)
                        test    _mode,#%0001    wc      'if pal, set vco to fcolor * 16 (70.9379 MHz)
        if_c            movi    ctra,#%00001_111        'select fcolor * 16 output (ntsc=/2, pal=/1)
        if_nc           movi    ctra,#%00001_110
        if_nc           shl     t2,#1
                        mov     frqa,t2                 '+147

                        jmpret  taskptr,taskret         '+1=148, break and return later

                        mov     t1,_broadcast           'set ctrb pll to _broadcast
                        mov     t2,#0                   'if 0, turn off ctrb
                        tjz     t1,:off
                        min     t1,m8                   'limit from 8MHz to 128MHz
                        max     t1,m128
                        mov     t2,#%00001_100          'adjust _broadcast to be within 4MHz-8MHz
:scale                  shr     t1,#1                   '(vco will be within 64MHz-128MHz)
                        cmp     m8,t1           wc
        if_c            add     t2,#%00000_001
        if_c            jmp     #:scale
:off                    movi    ctrb,t2
                        call    #divide
                        mov     frqb,t2                 '+165

                        jmpret  taskptr,taskret         '+1=166, break and return later

                        mov     t1,#%10100_000          'set video configuration
                        test    _pins,#$01      wc      '(swap broadcast/baseband output bits?)
        if_c            or      t1,#%01000_000
                        test    _mode,#%1000    wc      '(strip chroma from broadcast?)
        if_nc           or      t1,#%00010_000
                        test    _mode,#%0100    wc      '(strip chroma from baseband?)
        if_nc           or      t1,#%00001_000
                        and     _auralcog,#%111         '(set aural cog)
                        or      t1,_auralcog
                        movi    vcfg,t1                 '+10

                        mov     hx,_hx                  'compute horizontal metrics
                        shl     hx,#10
                        or      hx,_hx
                        shl     hx,#2

'                        mov     hc2x,_ht
'                        shl     hc2x,#1

                        mov     t1,_ht
                        mov     t2,_hx
                        call    #multiply
                        mov     hf,hvis
                        sub     hf,t1
                        shr     hf,#1           wc
                        mov     hb,_ho
                        addx    hb,hf
                        sub     hf,_ho                  '+52

                        mov     t1,_vt                  'compute vertical metrics
                        mov     t2,_vx
                        call    #multiply
                        test    _mode,#%0010    wc      '(if interlace, halve lines)
        if_c            shr     t1,#1
                        mov     vf,vvis
                        sub     vf,t1
                        shr     vf,#1           wc
                        neg     vb,_vo
                        addx    vb,vf
                        add     vf,_vo                  '+48

                        xor     _mode,#%0010            '+1, flip interlace bit for display

:colors                 jmpret  taskptr,taskret         '+1=112/160, break and return later

                        jmp     #:colors                '+1, keep loading colors
'
' Divide t1/CLKFREQ to get frqa or frqb value into t2
'
divide                  rdlong  m1,#0                   'get CLKFREQ

                        mov     m2,#32+1
:loop                   cmpsub  t1,m1           wc
                        rcl     t2,#1
                        shl     t1,#1
                        djnz    m2,#:loop

divide_ret              ret                             '+140
'
'
' Multiply t1 * t2 * 16 (t1, t2 = bytes)
'
multiply                shl     t2,#8+4-1

                        mov     m1,#8
:loop                   shr     t1,#1           wc
        if_c            add     t1,t2
                        djnz    m1,#:loop

multiply_ret            ret                             '+37
'
'
' Disabled - reset status, nap ~4ms, try again
'
disabled                mov     ctra,#0                 'reset ctra
                        mov     ctrb,#0                 'reset ctrb
                        mov     vcfg,#0                 'reset video

                        wrlong  outa,par                'set status to disabled

                        rdlong  t1,#0                   'get CLKFREQ
                        shr     t1,#8                   'nap for ~4ms
                        min     t1,#3
                        add     t1,cnt
                        waitcnt t1,#0

                        jmp     #entry                  'reload parameters
'
'
' Initialized data
'

bordercolour            long    $02

m8                      long    8_000_000
m128                    long    128_000_000
d0                      long    1 << 9 << 0
d6                      long    1 << 9 << 6
d0s1                    long    1 << 9 << 0 + 1 << 1
interlace               long    0
invisible               long    1
visible                 long    2
phaseflip               long    $00000000
phasemask               long    $F0F0F0F0
line                    long    $00060000
lineinc                 long    $10000000
pins0                   long    %11110000_01110000_00001111_00000111
pins1                   long    %11111111_11110111_01111111_01110111
sync_high1              long    %0101010101010101010101_101010_0101
sync_high2              long    %01010101010101010101010101010101       'used for black
sync_low1               long    %1010101010101010101010101010_0101
sync_low2               long    %01_101010101010101010101010101010

'
'
' NTSC/PAL metrics tables
'                               ntsc                    pal
'                               ----------------------------------------------
wtab                    word    lntsc - sntsc,          lpal - spal     'hvis
                        word    lntsc / 2 - sntsc,      lpal / 2 - spal 'hrest
                        word    lntsc / 2,              lpal / 2        'hhalf
                        word    243,                    286             'vvis
                        word    10,                     18              'vinv
                        word    6,                      5               'vrep
                        word    $02_8A,                 $02_AA          'burst
wtabx
ltab                    long    fntsc                                   'fcolor
                        long    fpal
                        long    sntsc >> 4 << 12 + sntsc                'sync_scale1
                        long    spal >> 4 << 12 + spal
                        long    67 << 12 + lntsc / 2 - sntsc            'sync_scale2
                        long    79 << 12 + lpal / 2 - spal
                        long    %0101_00000000_01_10101010101010_0101   'sync_normal
                        long    %010101_00000000_01_101010101010_0101
ltabx
'
'
' Uninitialized data
'
taskptr                 res     1                       'tasks
taskret                 res     1
t1                      res     1
t2                      res     1
m1                      res     1
m2                      res     1

x                       res     1                       'display
y                       res     1
hf                      res     1
hb                      res     1
vf                      res     1
vb                      res     1
hx                      res     1
vx                      res     1
tile                    res     1
pixels                  res     1

hvis                    res     1                       'loaded from word table
hrest                   res     1
hhalf                   res     1
vvis                    res     1
vinv                    res     1
vrep                    res     1
burst                   res     1

fcolor                  res     1                       'loaded from long table
sync_scale1             res     1
sync_scale2             res     1
sync_normal             res     1
'
'
' Parameter buffer
'
_enable                 res     1       '0/non-0        read-only
_pins                   res     1       '%pppmmmm       read-only
_mode                   res     1       '%ccip          read-only
_ht                     res     1       '1+             read-only
_vt                     res     1       '1+             read-only
_hx                     res     1       '4+             read-only
_vx                     res     1       '1+             read-only
_ho                     res     1       '0+-            read-only
_vo                     res     1       '0+-            read-only
_broadcast              res     1       '0+             read-only
_auralcog               res     1       '0-7            read-only
_scanline               res     1       'buffer address read-only
_bordercolour           res     1       'long @border
_nextline               res     1       'line to fetch
_tvdisplist             res     1
_tvsync                 res     1


ptr                     res     1

current_line            res     1
isinterlacedmode        res     1

VSyncFeedBack           res     1

                        fit 
''
''___
''VAR                   'TV parameters - 13 contiguous longs
''
'' 0  long  tv_status     '0/1/2 = off/invisible/visible           read-only
'' 1  long  tv_enable     '0/non-0 = off/on                        write-only
'' 2  long  tv_pins       '%pppmmmm = pin group, pin group mode    write-only
'' 3  long  tv_mode       '%ccip = chroma, interlace, ntsc/pal     write-only
'' 4  long  tv_hc         'horizontal count tiles                  write-only
'' 5  long  tv_vc         'vertical count tiles                    write-only
'' 6  long  tv_hx         'horizontal tile expansion               write-only
'' 7  long  tv_vx         'vertical tile expansion                 write-only
'' 8  long  tv_ho         'horizontal offset                       write-only
'' 9  long  tv_vo         'vertical offset                         write-only
''10  long  tv_broadcast  'broadcast frequency (Hz)                write-only
''11  long  tv_auralcog   'aural fm cog                            write-only
''12  long  tv_scanline   '256 bytes (64 longs) for display buffer write-only
''13  long  tv_bordercolour
''14  long  tv_nextline
''15  long  tv_DisplayList_ptr
''16  long  tv_vsync
''
''The preceding VAR section may be copied into your code.
''After setting variables, do start(@tv_status) to start driver.
''
''All parameters are reloaded each superframe, allowing you to make live
''changes. To minimize flicker, correlate changes with tv_status.
''
''Experimentation may be required to optimize some parameters.
''
''Parameter descriptions:
''  _________
''  tv_status
''
''    driver sets this to indicate status:
''      0: driver disabled (tv_enable = 0 or CLKFREQ < requirement)
''      1: currently outputting invisible sync data
''      2: currently outputting visible screen data
''  _________
''  tv_enable
''
''        0: disable (pins will be driven low, reduces power)
''    non-0: enable
''  _______
''  tv_pins
''
''    bits 6..4 select pin group:
''      %000: pins 7..0
''      %001: pins 15..8
''      %010: pins 23..16
''      %011: pins 31..24
''      %100: pins 39..32
''      %101: pins 47..40
''      %110: pins 55..48
''      %111: pins 63..56
''
''    bits 3..0 select pin group mode:
''      %0000: %0000_0111    -                    baseband
''      %0001: %0000_0111    -                    broadcast
''      %0010: %0000_1111    -                    baseband + chroma
''      %0011: %0000_1111    -                    broadcast + aural
''      %0100: %0111_0000    baseband             -
''      %0101: %0111_0000    broadcast            -
''      %0110: %1111_0000    baseband + chroma    -
''      %0111: %1111_0000    broadcast + aural    -
''      %1000: %0111_0111    broadcast            baseband
''      %1001: %0111_0111    baseband             broadcast
''      %1010: %0111_1111    broadcast            baseband + chroma
''      %1011: %0111_1111    baseband             broadcast + aural
''      %1100: %1111_0111    broadcast + aural    baseband
''      %1101: %1111_0111    baseband + chroma    broadcast
''      %1110: %1111_1111    broadcast + aural    baseband + chroma
''      %1111: %1111_1111    baseband + chroma    broadcast + aural
''      -----------------------------------------------------------
''            active pins    top nibble           bottom nibble
''
''      the baseband signal nibble is arranged as:
''        bit 3: chroma signal for s-video (attach via 560-ohm resistor)
''        bits 2..0: baseband video (sum 270/560/1100-ohm resistors to form 75-ohm 1V signal)
''
''      the broadcast signal nibble is arranged as:
''        bit 3: aural subcarrier (sum 560-ohm resistor into network below)
''        bits 2..0: visual carrier (sum 270/560/1100-ohm resistors to form 75-ohm 1V signal)
''  _______
''  tv_mode
''
''    bit 3 controls chroma mixing into broadcast:
''      0: mix chroma into broadcast (color)
''      1: strip chroma from broadcast (black/white)
''
''    bit 2 controls chroma mixing into baseband:
''      0: mix chroma into baseband (composite color)
''      1: strip chroma from baseband (black/white or s-video)
''
''    bit 1 controls interlace:
''      0: progressive scan (243 display lines for NTSC, 286 for PAL)
''           less flicker, good for motion
''      1: interlaced scan (486 display lines for NTSC, 572 for PAL)
''           doubles the vertical display lines, good for text
''
''    bit 0 selects NTSC or PAL format
''      0: NTSC
''           3016 horizontal display ticks
''           243 or 486 (interlaced) vertical display lines
''           CLKFREQ must be at least 14_318_180 (4 * 3_579_545 Hz)*
''      1: PAL
''           3692 horizontal display ticks
''           286 or 572 (interlaced) vertical display lines
''           CLKFREQ must be at least 17_734_472 (4 * 4_433_618 Hz)*
''
''      * driver will disable itself while CLKFREQ is below requirement
''  _____
''  tv_ht
''
''    horizontal number of 16 * 16 pixel tiles - must be at least 1
''    practical limit is 40 for NTSC, 50 for PAL
''  _____
''  tv_vt
''
''    vertical number of 16 * 16 pixel tiles - must be at least 1
''    practical limit is 13 for NTSC, 15 for PAL (26/30 max for interlaced NTSC/PAL)
''  _____
''  tv_hx
''
''    horizontal tile expansion factor - must be at least 3 for NTSC, 4 for PAL
''
''    make sure 16 * tv_ht * tv_hx + ||tv_ho + 32 is less than the horizontal display ticks
''  _____
''  tv_vx
''
''    vertical tile expansion factor - must be at least 1
''
''    make sure 16 * tv_vt * tv_vx + ||tv_vo + 1 is less than the display lines
''  _____
''  tv_ho
''
''    horizontal offset in ticks - pos/neg value (0 for centered image)
''    shifts the display right/left
''  _____
''  tv_vo
''
''    vertical offset in lines - pos/neg value (0 for centered image)
''    shifts the display up/down
''  ____________
''  tv_broadcast
''
''    broadcast frequency expressed in Hz (ie channel 2 is 55_250_000)
''    if 0, modulator is turned off - saves power
''
''    broadcasting requires CLKFREQ to be at least 16_000_000
''    while CLKFREQ is below 16_000_000, modulator will be turned off
''  ___________
''  tv_auralcog
''
''    selects cog to supply aural fm signal - 0..7
''    uses ctra pll output from selected cog
''
''    in NTSC, the offset frequency must be 4.5MHz and the max bandwidth +-25KHz
''    in PAL, the offset frequency is and max bandwidth vary by PAL type