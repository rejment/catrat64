/////////////////////////////////////////
// CHARACTER ANIMATIONS
// 
//
charanim_hi:    .fill 64, 0
charanim_lo:    .fill 64, 0
charanim_min:   .fill 64, 0
charanim_max:   .fill 64, 0
material_min:   .byte $00, $00, 11, 1
material_max:   .byte $00, $00, 13, 10
char_animation_delay: .byte 1
char_animation_count: .byte 0

char_animation: {
    dec char_animation_delay
    beq !doit+
    rts
!doit:
    lda #$08
    sta char_animation_delay

    ldx #$0     // X=list index
    jmp next
nextindex:
    lda charanim_hi,x
    sta loadchar+2
    sta savechar+2
    lda charanim_lo,x
    sta loadchar+1
    sta savechar+1
loadchar:
    lda $400
    beq skipchar
    clc
    adc #$01
    cmp charanim_max, x
    bcc savechar
    beq savechar
    lda charanim_min, x
savechar:
    sta $400
skipchar:
    inx
next:
    cpx char_animation_count
    bne nextindex
    rts
}
