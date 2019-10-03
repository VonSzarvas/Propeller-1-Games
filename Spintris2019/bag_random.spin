'' somewhat TGM3-ish piece bag randomizer
'' Written by Ada Gottensträter in 2019

  #0,Op,Ip,Tp,Jp,Lp,Sp,Zp

VAR

long seed

byte lastpiece,bag[35],drought[7]

PUB init(initseed) |tmp,i,j,i5
  seed:=initseed
  lastpiece:=Ip
  
  'fill bag with 5 of each piece
  repeat i from 0 to 6
    i5:=i*5
    repeat j from i5 to (i5+4)
      bag[j] := i
  
  'shuffle bag
  repeat 69
   i := randomwrap(35)
   j := randomwrap(35)
   tmp := bag[i]
   bag[i] := bag[j]
   bag[j] := tmp

  bytefill(@drought,0,7)
   
PUB getpiece : piece | i
  i := randomwrap(36)
  if i => 35 '' Occasionally deal a random piece
    'drawdebug(-1,i)
    return update_drought(randomwrap(7))
  piece := bag[i]
  if lastpiece==piece AND (seed&negx) '' Maybe reroll once if repeated piece
    i := randomwrap(35)
    piece := bag[i]
  update_drought(piece)
  bag[i] := refill_piece

  'drawdebug(piece,i)

PRI randomwrap(mod)
  return ((?seed)&posx)//mod

PRI update_drought(piece) | i
  result := lastpiece:= piece
  repeat i from 0 to 6
    if i == piece
      drought[i]~
    else
      drought[i]++
                   
PRI refill_piece | highest,i ' Find piece with highest drought value
  highest~~
  repeat i from 0 to 6
    if drought[i] => highest
      highest := drought[i]
      result := i

PRI drawdebug(piece,select) | i,screen
  screen:= LONG[CONSTANT($7F00-8)]
  byte[screen] := byte[@piecenames][piece]
   
  repeat i from 0 to 34
    byte[screen][33+(i&3)+((i>>2)<<5)] := byte[@piecenames][bag[i]]
  byte[screen][constant(5+32*10)]:= byte[@piecenames][refill_piece]
  i:= select
  byte[screen][constant(1+32*23)]:= constant("0"+107)+(i//10)
  byte[screen][constant(0+32*23)]:= constant("0"+107)+(i/10)

  repeat i from 0 to 6
    byte[screen][constant(0+32*11)+(i<<5)] := byte[@piecenames][i]
    byte[screen][constant(1+32*11)+(i<<5)] := constant("0"+107)+(drought[i]/100)
    byte[screen][constant(2+32*11)+(i<<5)] := constant("0"+107)+((drought[i]/10)//10)
    byte[screen][constant(3+32*11)+(i<<5)] := constant("0"+107)+(drought[i]//10)

DAT
' Debug guff
byte "r"+107
piecenames
byte "O"+107
byte "I"+107
byte "T"+107
byte "J"+107
byte "L"+107
byte "S"+107
byte "Z"+107