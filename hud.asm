update_hud:

    // clear line 24
    ldx #40
!:  lda #0
    sta $400 + 40*24-1,x
    lda #1
    sta $d800 + 40*24-1,x
    dex
    bne !-

    lda player_score
    sta print_decimal_value
    lda player_score+1
    sta print_decimal_value+1
    lda #($400 + 40*24) & $ff
    sta print_decimal_target
    lda #(($400 + 40*24) >> 8) & $ff
    sta print_decimal_target+1
    jsr print_decimal

    lda player_time
    sta print_decimal_value
    lda #0
    sta print_decimal_value+1
    lda #($400 + 40*24+37) & $ff
    sta print_decimal_target
    lda #(($400 + 40*24+3) >> 8) & $ff
    sta print_decimal_target+1
    jsr print_decimal

    rts

print_decimal:
    jsr convert_to_bcd
    jsr convert_to_decimal

    ldx #0
    ldy #0
!:  lda print_decimal_string,x
    bne !+
    cpx #5
    beq !+
    inx
    jmp !-
!:
    lda print_decimal_string,x
    clc
    adc #134
    sta (print_decimal_target),y
    inx
    iny
    cpx #6
    bne !- 
    rts


convert_to_decimal:
    ldx #0
    ldy #0
!:  lda print_decimal_bcd,y
    lsr
    lsr
    lsr
    lsr
    and #$0f
    sta print_decimal_string, x
    inx
    lda print_decimal_bcd,y
    and #$0f
    sta print_decimal_string, x
    inx
    iny
    cpy #3
    bne !-
    rts

convert_to_bcd:
    sed
	lda #0
    sta print_decimal_bcd+0
    sta print_decimal_bcd+1
    sta print_decimal_bcd+2
    ldx #16
!:	asl print_decimal_value+0
    rol print_decimal_value+1
    lda print_decimal_bcd+2
    adc print_decimal_bcd+2
    sta print_decimal_bcd+2
    lda print_decimal_bcd+1
    adc print_decimal_bcd+1
    sta print_decimal_bcd+1
    lda print_decimal_bcd+0
    adc print_decimal_bcd+0
    sta print_decimal_bcd+0
    dex
	bne !-
	cld
    rts
