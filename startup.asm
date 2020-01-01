///////////////////////////////////////////////////////////
//
//  Kattrattan - A game by Hermanos
//
//  Design+GFX: Paulina Hermansson
//  Code+SFX: Daniel Rejment
//
//
#import "zeropage.asm"
BasicUpstart2(entrypoint)


*=* "Code"
entrypoint:

    sei

    // disable interrupts
    lda #$7f
    sta $dc0d
    sta $dd0d

    // enable raster interrupts
    lda #$01
    sta $d01a

    // set irq vector
    lda #<IRQ
    ldx #>IRQ
    sta $fffe
    stx $ffff

    // set raster line for irq
    lda $d011
    and #$7f
    sta $d011
    lda #$01
    sta $d012

    // bank out stuff
    lda #$35
    sta $01

    // init music
    lda #$01
    jsr $1000

    // enable interrupts
    cli

    // black border
    lda #0
    sta $d020
    sta $d021
    sta $d022
    sta $d023

    // set multicolor
    lda #%11011000
    sta $d016

    // screen=$400 font=$2000
    lda #%00011000
    sta $d018

    // clear zeropage
    lda #$00
zl: sta $02
    inc zl+1
    bne zl

    jsr intro


    lda #0
    sta current_level
    jsr show_level


    // show player sprite
    lda #sprite_data/64
    sta $07F8   // sprite data #1
    sta $07F9   // sprite data #2
    lda #%011
    sta $d015   // sprite enable
    lda #BLACK
    sta $d027   // sprite color #1
    lda #RED
    sta $d028   // sprite color #2

    lda #$01
    jsr start_animation
    lda #0
    sta player_score
    sta player_score+1

mainloop:
    // black bg during hud
    lda #$e2-8
    cmp $d012
    bne *-3
    lda #0
    sta $d021

    // gray after hud
    lda #$ff
    cmp $d012
    bne *-3
    lda #12
    sta $d021

    // count time
    inc frame_counter
    lda frame_counter
    cmp #50
    bne !+
    lda #0
    sta frame_counter
    dec player_time
!:

    lda #$50
    cmp $d012
    bne *-3


    // animate characters
    // inc $d020
    jsr char_animation
    // dec $d020
    jsr update_hud

    // update player sprite position
    jsr move_animation
    lda player_x
    sta $d000   // sprite x #1
    sta $d002   // sprite x #2
    lda player_x+1
    and #$01
    beq no
    lda #$03
no: sta $d010
    lda player_y
    sta $d001   // sprite y #1
    sta $d003   // sprite y #2

    jsr statemachine
    jmp mainloop


IRQ:
    sta ra+1
    stx rx+1
    sty ry+1
    lda $d020
    sta b0+1
    lda #4
    // sta $d020
    jsr $1003
    asl $d019
b0: lda #0 
    // sta $d020
ra: lda #$0
rx: ldx #$0
ry: ldy #$0
    rti

#import "intro.asm"
#import "portals.asm"
#import "collisions.asm"
#import "animations.asm"
#import "charanims.asm"
#import "utils.asm"
#import "statemachine.asm"


.var ctmTemplate = "Junk=0,Font=20,Color=2068,Map=2324"
.var map1 = LoadBinary("ten.ctm", ctmTemplate)

/////////////////////////////////////////////
// IMPORT SOUND FROM GOATTRACKER
*=$1000 "Sound"
    .import binary "kattratt.bin"
sfx1:
    .byte $00,$FA,$08,$B8,$81,$A4,$41,$A0,$B4,$81,$98,$92,$9C,$90,$95,$9E
    .byte $92,$80,$94,$8F,$8E,$8D,$8C,$8B,$8A,$89,$88,$87,$86,$84,$00
pling:
    .byte $00,$F9,$00,$C0,$11,$C0,$10,$C0,$C0,$C8,$11,$C8,$10,$C8,$C8,$C8
    .byte $C8,$C8,$C8,$C8,$C8,$C8,$C8,$C8,$00

*=* "Font Colors"
map_colors: .fill map1.getColorSize(), map1.getColor(i)

#import "hud.asm"
#import "levels.asm"


/////////////////////////////////////////////
// LOAD MAP FROM CHARPAD FILE
*=$2000 "Font"
map_font:   .fill map1.getFontSize(),  map1.getFont(i)


/////////////////////////////////////////////
// LOAD SPRITES FROM SPRITEPAD FILE
*=* "Sprites"
.var spdTemplate = "Junk=0,SpriteCount=4,AnimationCount=5,SpriteData=9"
.var spritefile1 = LoadBinary("Kattrattan.spd", spdTemplate)
.align 64
sprite_data:        .fill 64*(spritefile1.getSpriteCount(0)+1), spritefile1.getSpriteData(i)
spr_anims_from:     .fill spritefile1.getAnimationCount(0)+1, spritefile1.getSpriteData(64*(spritefile1.getSpriteCount(0)+1) + i)
spr_anims_to:       .fill spritefile1.getAnimationCount(0)+1, spritefile1.getSpriteData(64*(spritefile1.getSpriteCount(0)+1) + (spritefile1.getAnimationCount(0)+1) + i)
spr_anims_reload:   .fill spritefile1.getAnimationCount(0)+1, spritefile1.getSpriteData(64*(spritefile1.getSpriteCount(0)+1) + (spritefile1.getAnimationCount(0)+1)*2 + i)
spr_anims_attrib:   .fill spritefile1.getAnimationCount(0)+1, spritefile1.getSpriteData(64*(spritefile1.getSpriteCount(0)+1) + (spritefile1.getAnimationCount(0)+1)*3 + i)


*=* "Map Data"
map_data:   .fill map1.getMapSize()/2, map1.getMap(i*2)


/////////////////////////////////////////////
// LOAD HUD FROM CHARPAD FILE
// *=$7000 "Hud"
// .var hudTemplate = "Junk=0,Font=20,Color=188,Map=209"
// .var hud = LoadBinary("hud.ctm", hudTemplate)
// hud_font:   .fill hud.getFontSize(),  hud.getFont(i)
// hud_data:   .fill hud.getMapSize()/2, hud.getMap(i*2)
// hud_colors: .fill hud.getColorSize(), hud.getColor(i)


*=* "Generated tables"

level_pos_hi:
    .for (var l=0; l<20; l++) {
        .byte (map_data + ((l+2)*40*21)) >> 8
    }
level_pos_lo:
    .for (var l=0; l<20; l++) {
        .byte (map_data + ((l+2)*40*21)) & $ff
    }


line_pos_hi:
    .for (var y=0; y<25; y++) {
        .byte ($0400 + (y*40)) >> 8
    }
line_pos_lo:
    .for (var y=0; y<25; y++) {
        .byte ($0400 + (y*40)) & $ff
    }