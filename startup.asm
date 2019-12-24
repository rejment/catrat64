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

    // stop interrupts
    lda #$7f
    sta $dc0d
    sta $dd0d

    // bank out stuff
    lda #$35
    sta $01

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

    // clear screen + color
    ldx #250
    lda #0
!:  dex
    sta $400, x
    sta $400 + 250, x
    sta $400 + 500, x
    sta $400 + 750, x
    sta $d800, x
    sta $d800 + 250, x
    sta $d800 + 500, x
    sta $d800 + 750, x
    bne !-

    lda #$28
    sta player_x
    lda #$b5
    sta player_y
    lda #$06
    sta player_anim_delay



    // init music
    lda #$00
    jsr $1000


    lda #0
    sta current_level
    jsr show_level



    // show player sprite
    lda #sprite_data/64
    sta $07F8   // sprite data #1
    lda #%001
    sta $d015   // sprite enable
    lda #BLACK
    sta $d027   // sprite color #1

    lda #$01
    jsr start_animation

mainloop:
    // wait for HUD raster pos
    lda #$e2
    cmp $d012
    bne *-3
    // setup colors
    lda #00
    sta $d021
    sta $d022
    sta $d023
    // bank 1 - %10 - $4000–$7FFF
    lda $dd00
    and #$fc
    ora #$02
    sta $dd00

    lda #$e3
    cmp $d012
    bne *-3
    lda #13
    sta $d022
    lda #1
    sta $d023

    // after HUD
    lda #$ff
    cmp $d012
    bne *-3
    lda #12
    sta $d021
    // setup colors
    lda #12
    sta $d021
    lda #10
    sta $d022
    lda #11
    sta $d023
    // bank 0 - %11 - $0000–$3FFF
    lda $dd00
    and #$fc
    ora #$03
    sta $dd00


    // animate characters
    jsr char_animation

   // update music
    jsr $1003

    // update player sprite position
    jsr move_animation
    lda player_x
    sta $d000   // sprite x #1
    sta $d002   // sprite x #2
    lda player_x+1
    and #$01
    sta $d010
    lda player_y
    sta $d001   // sprite y #1
    sta $d003   // sprite y #2
    dec $d003

    jsr statemachine
    jmp mainloop


#import "portals.asm"
#import "collisions.asm"
#import "animations.asm"
#import "charanims.asm"
#import "levels.asm"



/////////////////////////////////////////////
// PLAYER DATA
fall_table:         .byte 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 2, 1, 1, 2, 2, 1, 2, 2, 2
.label fall_table_length = *-fall_table-1

/////////////////////////////////////////////
// IMPORT SOUND FROM GOATTRACKER
*=$1000 "Sound"
    .import binary "emptysfx.bin"
sfx1:
    .byte $00,$FA,$08,$B8,$81,$A4,$41,$A0,$B4,$81,$98,$92,$9C,$90,$95,$9E
    .byte $92,$80,$94,$8F,$8E,$8D,$8C,$8B,$8A,$89,$88,$87,$86,$84,$00

*=* "Statemachine"
#import "statemachine.asm"


/////////////////////////////////////////////
// LOAD MAP FROM CHARPAD FILE
*=$2000 "Font"
.var ctmTemplate = "Junk=0,Font=20,Color=2068,Map=2324"
.var map1 = LoadBinary("ten.ctm", ctmTemplate)
map_font:   .fill map1.getFontSize(),  map1.getFont(i)
map_colors: .fill map1.getColorSize(), map1.getColor(i)


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



level_pos_hi:
    .for (var l=0; l<10; l++) {
        .byte (map_data + (l*40*21)) >> 8
    }
level_pos_lo:
    .for (var l=0; l<10; l++) {
        .byte (map_data + (l*40*21)) & $ff
    }


line_pos_hi:
    .for (var y=0; y<25; y++) {
        .byte ($0400 + (y*40)) >> 8
    }
line_pos_lo:
    .for (var y=0; y<25; y++) {
        .byte ($0400 + (y*40)) & $ff
    }

