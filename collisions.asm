////////////////////////////////////////////////////////////////
// GET COLLISION
// $18 >= x < $0158
// $25 >= y < $ed
// col  = (x-$18)/8
// line = (y-$25)/8 
// offset = line*40+col
get_collision:
    lda #$0
    sta get_collision_result

    // right border?
    ldy get_collision_x+1
    beq !+
    lda get_collision_x
    cmp #$58-8
    bcs !border+
!:

    // left border?
    ldy get_collision_x+1
    bne !+
    lda get_collision_x
    cmp #$18+8
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
    sta get_collision_char
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

get_player_collision: {
    stx x+1
    sty y+1
    lda player_x
    clc
x:  adc #$00
    sta get_collision_x
    lda player_x+1
    adc #$00
    sta get_collision_x+1
    lda player_y
    clc
y:  adc #$00
    sta get_collision_y
    jmp get_collision
}

get_player_collision_left: {
    stx x+1
    sty y+1
    lda player_x
    sec
x:  sbc #$00
    sta get_collision_x
    lda player_x+1
    sbc #$00
    sta get_collision_x+1
    lda player_y
    clc
y:  adc #$00
    sta get_collision_y
    jmp get_collision
}

///////////////////////////
//
// PICKUP LOOT
//
pickup_loot: {
    sta ra+1
    stx rx+1
    sty ry+1

    lda get_collision_result
    cmp #$30
    bne exit

    ldx get_collision_result_y
    lda line_pos_lo, x
    sta get_collision_temp
    lda line_pos_hi, x
    sta get_collision_temp+1
    lda #$00
    ldy get_collision_result_x
    sta (get_collision_temp),y

exit:
rx: ldx #$ff
ry: ldy #$ff
ra: lda #$ff
    rts
}
