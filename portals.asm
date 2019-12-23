////////////////////////////////////////////////////////////////
// FIND_PORTAL
//
//
//
find_portal:
    lda find_portal_y
    clc
    adc find_portal_direction
    cmp #00
    beq fail
    cmp #21
    beq fail
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
    cmp #$20
    beq !+
    jmp find_portal
!:  
    lda find_portal_y
    // clc
    // adc #$ff
    sta find_portal_result
    rts
fail:
    lda #$ff
    sta find_portal_result
    rts
