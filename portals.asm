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
