
.enum   { WAITING, FALLING, WALKING_RIGHT, WALKING_LEFT, ZIP_UP, ZIP_DOWN }

jumptable:
    .word Waiting, Falling, WalkingRight, WalkingLeft, ZipUp, ZipDown
currentstate:
    .byte WAITING


statemachine:
    lda currentstate
    clc
    rol
    tax
    lda jumptable, x
    sta j+1
    lda jumptable+1, x
    sta j+2
j:  jmp $0000

////////////////////////////////////////
//
//  ZIP UP
//
.label zipwait = 14
zipdelay:   .byte 25
ziptarget:  .byte 0
ZipUp: {
    dec zipdelay
    bne wait

    lda ziptarget
    sta player_y

    lda #WAITING
    sta currentstate
    jmp statemachine
wait:
    rts
Start:
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
    sta ziptarget

    lda #$6
    jsr start_animation

    lda #ZIP_UP
    sta currentstate
    lda #zipwait
    sta zipdelay
    rts
}

////////////////////////////////////////
//
//  ZIP DOWN
//
ZipDown: {
    dec zipdelay
    bne wait

    lda ziptarget
    sta player_y

    lda #WAITING
    sta currentstate
    jmp statemachine
wait:
    rts
Start:
    lda get_collision_result_x
    sta find_portal_x
    lda get_collision_result_y
    sta find_portal_y
    lda #$1
    sta find_portal_direction
    jsr find_portal
    lda find_portal_result
    clc
    rol
    rol
    rol
    adc #$25
    sta ziptarget

    lda #$6
    jsr start_animation

    lda #ZIP_DOWN
    sta currentstate
    lda #zipwait
    sta zipdelay
    rts
}

////////////////////////////////////////
//
//  WALKING RIGHT
//
WalkingRight: {
    lda #$3
    jsr start_animation

    lda $dc00
    and #%1000
    beq walking

    lda #WAITING
    sta currentstate
    jmp statemachine
walking:

    // would collide?
    ldx #$08
    ldy #$00
    jsr get_player_collision
    jsr pickup_loot
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

    // are we not on ground?
    ldx #$00
    ldy #$08
    jsr get_player_collision
    cmp #$10
    beq nofall
    ldx #$07
    ldy #$08
    jsr get_player_collision
    cmp #$10
    beq nofall

    lda #$5
    jsr start_animation

    lda #FALLING
    sta currentstate
    jmp statemachine
nofall:

notr:
    rts
}

////////////////////////////////////////
//
//  WALKING LEFT
//
WalkingLeft: {
    lda #$2
    jsr start_animation

    lda $dc00
    and #%100
    beq walking

    lda #WAITING
    sta currentstate
    jmp statemachine
walking:

    // would collide?
    ldx #$01
    ldy #$00
    jsr get_player_collision_left
    jsr pickup_loot
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

    // are we not on ground?
    ldx #$00
    ldy #$08
    jsr get_player_collision
    cmp #$10
    beq nofall
    ldx #$07
    ldy #$08
    jsr get_player_collision
    cmp #$10
    beq nofall

    lda #$4
    jsr start_animation
    lda #FALLING
    sta currentstate
    jmp statemachine
nofall:

notl:

    rts
}

////////////////////////////////////////
//
//  FALLING
//
Falling: {
    // did we hit ground?
    ldx #$00
    ldy #$08
    jsr get_player_collision
    cmp #$10
    beq nofall
    ldx #$07
    ldy #$08
    jsr get_player_collision
    cmp #$10
    beq nofall

    // do the fall
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
    lda #0
    sta fall_index

    // floor
    lda get_collision_result_y
    clc
    rol
    rol
    rol
    adc #$25-8
    sta player_y
    lda #WAITING
    sta currentstate
    jmp statemachine
endfall:
    rts
}

////////////////////////////////////////
//
//  WAITING
//
Waiting: {
    lda player_anim
    and #$01
    jsr start_animation

    // hold right?
    lda $dc00
    and #%1000
    bne notr
    lda #WALKING_RIGHT
    sta currentstate
    jmp statemachine
notr:

    // hold left?
    lda $dc00
    and #%100
    bne notl
    lda #WALKING_LEFT
    sta currentstate
    jmp statemachine
notl:

    // hold up?
    lda $dc00
    and #%0001
    bne notu
    ldx #$03
    ldy #$04
    jsr get_player_collision
    cmp #$30 // up zip
    bne notu
    jmp ZipUp.Start
 notu:

    // hold down?
    lda $dc00
    and #%0010
    bne notd
    ldx #$03
    ldy #$04
    jsr get_player_collision
    cmp #$20 // down zip
    bne notd
    jmp ZipDown.Start
notd:

    rts

Start:
    lda #WAITING
    sta currentstate
    jmp statemachine
}
