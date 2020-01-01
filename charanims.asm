/////////////////////////////////////////
// CHARACTER ANIMATIONS
// 
//
.align $100
charanim_speedcode:   .fill 256, $60 // fill with rts
material_cur:   .byte 11, 1
material_min:   .byte 11, 1
material_max:   .byte 14, 11
char_animation_delay: .byte 1

char_animation: {
    dec char_animation_delay
    beq !doit+
    rts
!doit:
    lda #$08
    sta char_animation_delay

    clc
    lda material_cur+1
    adc #$1
    cmp material_max+1
    bne !+
    lda material_min+1
!:  sta material_cur+1

    clc
    lda material_cur
    adc #$1
    cmp material_max
    bne !+
    lda material_min
!:  sta material_cur

    ldx material_cur+1
    jmp charanim_speedcode
}

char_animation_remove: {
    tya
    clc
    adc get_collision_temp
    sta get_collision_temp
    lda get_collision_temp+1
    adc #0
    sta get_collision_temp+1

    ldx #0
try:
    lda get_collision_temp
    cmp charanim_speedcode+1, x
    bne next
    lda get_collision_temp+1
    cmp charanim_speedcode+2, x
    bne next
    lda #$0c // TOP
    sta charanim_speedcode,x
    rts
next:
    inx
    inx
    inx
    cpx charanim_speedcode_ptr
    bne try
done:
    rts
}