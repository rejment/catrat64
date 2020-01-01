/////////////////////////////////////////
// CHARACTER ANIMATIONS
// 
//
.align $100
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

    ldx char_animation_count     // X=list index
    jmp next
nextindex:
    lda charanim_hi-1,x
    sta loadchar+2
    sta savechar+2
    lda charanim_lo-1,x
    sta loadchar+1
    sta savechar+1
loadchar:
    lda $400
    beq skipchar
    sec
    sbc #$01
    cmp charanim_min-1, x
    bcs savechar
    lda charanim_max-1, x
savechar:
    sta $400
skipchar:
    dex
next:
    bne nextindex
    rts
}
