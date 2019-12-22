
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

.label zipwait = 10
zipdelay:   .byte 25
ziptarget:  .byte 0
ZipUp: {
    dec zipdelay
    bne wait

    lda ziptarget
    sta player_y

    lda #WAITING
    sta currentstate
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

    lda #ZIP_UP
    sta currentstate
    lda #zipwait
    sta zipdelay
    jmp ZipUp
}
ZipDown: {
    dec zipdelay
    bne wait

    lda ziptarget
    sta player_y

    jmp Waiting.Start
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
    lda #ZIP_DOWN
    sta currentstate
    lda #zipwait
    sta zipdelay
    jmp ZipDown
}

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

    // are we not on ground?
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

    lda #$5
    jsr start_animation

    lda #FALLING
    sta currentstate
    jmp statemachine
nofall:

notr:
    rts
}

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

    // are we not on ground?
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

    lda #$4
    jsr start_animation
    lda #FALLING
    sta currentstate
    jmp statemachine
nofall:

notl:

    rts
}


Falling: {
    // did we hit ground?
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
    lda #WAITING
    sta currentstate
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
endfall:
    rts
}

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
    jmp ZipUp.Start
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
    jmp ZipDown.Start
notd:

    rts

Start:
    lda #WAITING
    sta currentstate
    jmp statemachine
}