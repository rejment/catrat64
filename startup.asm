///////////////////////////////////////////////////////////
//
//  Kattrattan - A game by Hermanos
//
//  Design+GFX: Paulina Hermansson
//  Code+SFX: Daniel Rejment
//
//
BasicUpstart2(entrypoint)


entrypoint:

    sei

    //Bank out BASIC and Kernal ROM
    lda $01
    and #%11111000 
    ora #%00000101
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
    ldx #$0
!:  .for (var i=0; i<4; i++) {
    lda map_data+[250*i], x
    sta $400+[250*i], x
    tay
    lda map_colors, y
    sta $d800+[250*i],x
}
    inx
    cpx #250
    bne !-

    // copy hud
    ldx #$0
!:  lda hud_data, x
    sta $400+[22*40], x
    tay
    lda hud_colors, y
    sta $d800+[22*40],x
    inx
    cpx #120
    bne !-


    // show player sprite
    lda #sprite_data/64
    sta $07F8   // sprite data #1
    lda #$01
    sta $d015   // sprite enable
    lda #BLACK
    sta $d027   // sprite color #1

    lda #$01
    jsr start_animation

mainloop:
    // wait for HUD raster pos
    lda #$df
    cmp $d012
    bne *-3
    // setup colors
    lda #00
    sta $d021
    // screen=$400 font=$2000
    lda #%00011100
    sta $d018
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
    // screen=$400 font=$2000
    lda #%00011000
    sta $d018
    // setup colors
    lda #12
    sta $d021
    lda #10
    sta $d022
    lda #11
    sta $d023

   // update music
    jsr $1003

    // update player sprite position
    jsr move_animation
    lda player_x
    sta $d000   // sprite x #1
    lda player_x+1
    and #$01
    sta $d010
    lda player_y
    sta $d001   // sprite y #1


    // are we falling?
    lda player_x
    sta get_collision_x
    lda player_x+1
    sta get_collision_x+1
    lda player_y
    clc
    adc #$08
    sta get_collision_y
    jsr get_collision
    cmp #$10
    beq nofall
    lda player_x
    clc
    adc #$07
    sta get_collision_x
    lda player_x+1
    adc #$00
    sta get_collision_x+1
    jsr get_collision
    cmp #$10
    beq nofall

    // do the fall
    lda #$01
    sta player_falling
    ldx fall_index
    cpx fall_table_length
    beq !+
    inx
    stx fall_index
!:  lda fall_table, x
    clc
    adc player_y
    sta player_y
    jmp endfall
nofall:
    lda #$00
    sta player_falling
    sta fall_index

    // floor
    lda get_collision_result_y
    clc
    rol
    rol
    rol
    adc #$25-8
    sta player_y

endfall:


    // no moving when falling
    lda #$01
    cmp player_falling
    bne move
    jmp nomove
move:

    // hold up?
    lda $dc00
    and #%0001
    bne notu
    lda player_x
    clc
    adc #$03
    sta get_collision_x
    lda player_x+1
    adc #$00
    sta get_collision_x+1
    lda player_y
    clc
    adc #$04
    sta get_collision_y
    jsr get_collision
    cmp #$20 // up zip
    bne notu

    // zip up
    lda get_collision_result_x
    sta find_portal_x
    lda get_collision_result_y
    sta find_portal_y
    lda #$ff
    sta find_portal_direction
    jsr find_portal

    lda find_portal_result
    clc
    rol
    rol
    rol
    adc #$25
    sta player_y

    lda #<sfx1
    ldy #>sfx1
    ldx #14        //0, 7 or 14 for channels 1-3
    jsr $1000+6

notu:


    // hold down?
    lda $dc00
    and #%0010
    bne notd
    lda player_x
    clc
    adc #$03
    sta get_collision_x
    lda player_x+1
    adc #$00
    sta get_collision_x+1
    lda player_y
    clc
    adc #$04
    sta get_collision_y
    jsr get_collision
    cmp #$30 // down zip
    bne notd

    // zip down
    lda get_collision_result_x
    sta find_portal_x
    lda get_collision_result_y
    sta find_portal_y
    lda #$01
    sta find_portal_direction
    jsr find_portal

    lda find_portal_result
    clc
    rol
    rol
    rol
    adc #$25
    sta player_y

    lda #<sfx1
    ldy #>sfx1
    ldx #14        //0, 7 or 14 for channels 1-3
    jsr $1000+6
notd:


    // hold right?
    lda $dc00
    and #%1000
    bne notr

    lda #$3
    jsr start_animation

    // would collide?
    lda player_x
    clc
    adc #$08
    sta get_collision_x
    lda player_x+1
    adc #$00
    sta get_collision_x+1
    lda player_y
    sta get_collision_y
    jsr get_collision
    cmp #$10
    beq notr

    // move right
    lda player_x
    clc
    adc #$01
    sta player_x
    lda player_x+1
    adc #$00
    sta player_x+1
notr:

    // hold left?
    lda $dc00
    and #%0100
    bne notl

    lda #$2
    jsr start_animation

    // would collide?
    lda player_x
    sec
    sbc #$01
    sta get_collision_x
    lda player_x+1
    sbc #$00
    sta get_collision_x+1
    lda player_y
    sta get_collision_y
    jsr get_collision
    cmp #$10
    beq notl

    // move left
    lda player_x
    sec
    sbc #$01
    sta player_x
    lda player_x+1
    sbc #$00
    sta player_x+1
notl:

nomove:
    jmp mainloop


////////////////////////////////////////////////////////////////
// FIND_PORTAL
//
//
//
find_portal_x:          .byte 0
find_portal_y:          .byte 0
find_portal_direction:  .byte 0
find_portal_result:     .byte 0
find_portal:
    lda find_portal_y
    clc
    adc find_portal_direction
    sta find_portal_y
    tax
    lda line_pos_lo, x
    sta get_collision_temp
    lda line_pos_hi, x
    sta get_collision_temp+1
    lda (get_collision_temp),y
    tax
    lda map_colors, x
    and #$f0
    cmp #$30
    beq !+
    cmp #$20
    beq !+
    jmp find_portal
!:  
    lda find_portal_y
    // clc
    // adc #$ff
    sta find_portal_result

    rts


////////////////////////////////////////////////////////////////
// GET COLLISION
// $18 >= x < $0158
// $25 >= y < $ed
// col  = (x-$18)/8
// line = (y-$25)/8 
// offset = line*40+col
get_collision_x:        .byte 0, 0
get_collision_y:        .byte 0
get_collision_result:   .byte 0
get_collision_result_a: .byte 0
get_collision_result_x: .byte 0
get_collision_result_y: .byte 0
.label get_collision_temp = $fb
get_collision:
    lda #$0
    sta get_collision_result

    // right border?
    ldy get_collision_x+1
    beq !+
    lda get_collision_x
    cmp #$58
    bcs !border+
!:

    // left border?
    ldy get_collision_x+1
    bne !+
    lda get_collision_x
    cmp #$18
    bcc !border+
!:

    // read from map?
    lda get_collision_x+1
    ror
    lda get_collision_x
    ror
    clc
    ror
    clc
    ror
    sec
    sbc #$18/8
    tay
    sta get_collision_result_x

    lda get_collision_y
    sec
    sbc #$25
    clc
    ror
    clc
    ror
    clc
    ror
    tax
    sta get_collision_result_y

    // map_data + y*40 + x
    lda line_pos_lo, x
    sta get_collision_temp
    lda line_pos_hi, x
    sta get_collision_temp+1
    lda (get_collision_temp),y
    tax
    lda map_colors, x
    and #$f0
    sta get_collision_result
!end:
    rts
!border:
    lda #$10
    sta get_collision_result
    rts

/////////////////////////////////////////
// START ANIMATION
//
start_animation:
    cmp player_anim
    beq !end+
    tax
    sta player_anim
    lda spr_anims_reload,x
    sta player_anim_delay
    inc player_anim_delay
    lda spr_anims_to,x
    sta player_anim_end
    inc player_anim_end
    lda spr_anims_from,x
    sta player_anim_frame
    clc
    adc #sprite_data/64
    sta $07F8   // sprite data #1
!end:
    rts

/////////////////////////////////////////
// MOVE ANIMATION
//
move_animation:
    lda player_anim
    tax
    dec player_anim_delay
    bpl !end+
    lda spr_anims_reload,x
    sta player_anim_delay

    inc player_anim_frame
    lda player_anim_frame
    cmp player_anim_end
    bne !+
    lda spr_anims_from,x
    sta player_anim_frame
!:
    clc
    adc #sprite_data/64
    sta $07F8   // sprite data #1

!end:
    rts


/////////////////////////////////////////////
// PLAYER DATA
player_x:           .byte $40 // $18
                    .byte $00
player_y:           .byte $38
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

/////////////////////////////////////////////
// LOAD MAP FROM CHARPAD FILE
*=$2000 "Data"
.var ctmTemplate = "Junk=0,Font=20,Color=2068,Map=2324"
.var map1 = LoadBinary("pinkmap.ctm", ctmTemplate)
map_font:   .fill map1.getFontSize(),  map1.getFont(i)
map_data:   .fill map1.getMapSize()/2, map1.getMap(i*2)
map_colors: .fill map1.getColorSize(), map1.getColor(i)

/////////////////////////////////////////////
// LOAD HUD FROM CHARPAD FILE
*=$3000 "Data"
.var hudTemplate = "Junk=0,Font=20,Color=188,Map=209"
.var hud = LoadBinary("hud.ctm", hudTemplate)
hud_font:   .fill hud.getFontSize(),  hud.getFont(i)
hud_data:   .fill hud.getMapSize()/2, hud.getMap(i*2)
hud_colors: .fill hud.getColorSize(), hud.getColor(i)


/////////////////////////////////////////////
// LOAD SPRITES FROM SPRITEPAD FILE
.var spdTemplate = "Junk=0,SpriteCount=4,AnimationCount=5,SpriteData=9"
.var spritefile1 = LoadBinary("Kattrattan.spd", spdTemplate)
.align 64
sprite_data:        .fill 64*(spritefile1.getSpriteCount(0)+1), spritefile1.getSpriteData(i)
spr_anims_from:     .fill spritefile1.getAnimationCount(0)+1, spritefile1.getSpriteData(64*(spritefile1.getSpriteCount(0)+1) + i)
spr_anims_to:       .fill spritefile1.getAnimationCount(0)+1, spritefile1.getSpriteData(64*(spritefile1.getSpriteCount(0)+1) + (spritefile1.getAnimationCount(0)+1) + i)
spr_anims_reload:   .fill spritefile1.getAnimationCount(0)+1, spritefile1.getSpriteData(64*(spritefile1.getSpriteCount(0)+1) + (spritefile1.getAnimationCount(0)+1)*2 + i)
spr_anims_attrib:   .fill spritefile1.getAnimationCount(0)+1, spritefile1.getSpriteData(64*(spritefile1.getSpriteCount(0)+1) + (spritefile1.getAnimationCount(0)+1)*3 + i)


line_pos_hi:
    .for (var y=0; y<25; y++) {
        .byte (map_data + (y*40)) >> 8
    }
line_pos_lo:
    .for (var y=0; y<25; y++) {
        .byte (map_data + (y*40)) & $ff
    }

