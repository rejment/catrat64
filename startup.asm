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

    // $A000-BFFF   ram
    // $D000-DFFF   i/o
    // $E000-FFFF   ram
    lda #$35
    sta $01

    // init music
    lda #$00
    jsr $1000

    // set multicolor
    lda #%11011000
    sta $d016

    // black border
    lda #0
    sta $d020

    // copy map
.for (var i=0; i<4; i++) {
    ldx #$0
!:  stx lo+1
    lda map_data+[256*i], x
    sta $400+[256*i], x
    tay
    lda map_colors, y
    sta $d800+[256*i],x

    // check for animated materials
    and #$f0
    cmp #$20
    bcc !notanimated+
    lsr
    lsr
    lsr
    lsr
    //and #$0f
    tay

    // x is "pushed" into lo+1
    ldx char_animation_count
    lda material_min, y
    sta charanim_min, x
    lda material_max, y
    sta charanim_max, x
    lda #$04 + i
    sta charanim_hi, x
lo:
    lda #$00
    sta charanim_lo, x
    inc char_animation_count
    ldx lo+1        // restore x
!notanimated:
    inx
    cpx #$00 // overflowed?
    bne !-
}

    // copy hud
    ldx #$0
!:  lda hud_data, x
    sta $4400+[22*40], x
    tay
    lda hud_colors, y
    sta $d800+[22*40],x
    inx
    cpx #120
    bne !-


    // bank 0 - %11 - $0000–$3FFF
    lda $dd00
    and #$fc
    ora #$03
    sta $dd00
    // screen=$400 font=$2000
    lda #%00011000
    sta $d018


    // show player sprite
    lda #sprite_data/64
    sta $07F8   // sprite data #1
    lda #%001
    sta $d015   // sprite enable
    lda #BLACK
    sta $d027   // sprite color #1
    lda #DARK_GRAY
    sta $d028   // sprite color #1

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



/////////////////////////////////////////////
// PLAYER DATA
player_x:           .byte $28
                    .byte $00
player_y:           .byte $b5
player_anim:        .byte $ff
player_anim_frame:  .byte $00
player_anim_end:    .byte $00
player_anim_delay:  .byte $06

player_falling:     .byte $00
fall_index:         .byte $00

fall_table:         .byte 1, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1, 2, 1, 1, 2, 2, 1, 2, 2, 2
.label fall_table_length = *-fall_table

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
*=$2000 "Map"
.var ctmTemplate = "Junk=0,Font=20,Color=2068,Map=2324"
.var map1 = LoadBinary("pinkmap.ctm", ctmTemplate)
map_font:   .fill map1.getFontSize(),  map1.getFont(i)
map_data:   .fill map1.getMapSize()/2, map1.getMap(i*2)
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

/////////////////////////////////////////////
// LOAD HUD FROM CHARPAD FILE
*=$6000 "Hud"
.var hudTemplate = "Junk=0,Font=20,Color=188,Map=209"
.var hud = LoadBinary("hud.ctm", hudTemplate)
hud_font:   .fill hud.getFontSize(),  hud.getFont(i)
hud_data:   .fill hud.getMapSize()/2, hud.getMap(i*2)
hud_colors: .fill hud.getColorSize(), hud.getColor(i)


line_pos_hi:
    .for (var y=0; y<25; y++) {
        .byte ($0400 + (y*40)) >> 8
    }
line_pos_lo:
    .for (var y=0; y<25; y++) {
        .byte ($0400 + (y*40)) & $ff
    }

