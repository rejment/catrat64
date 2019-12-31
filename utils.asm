clearscreen:
    // clear screen + color
    ldx #250
    lda #0
!:  dex
    sta $400, x
    sta $400 + 250, x
    sta $400 + 500, x
    sta $400 + 750, x
    sta $d800, x
    sta $d800 + 250, x
    sta $d800 + 500, x
    sta $d800 + 750, x
    bne !-
    rts

wait_fire:
    lda #%10000
    bit $dc00
    beq *-3
    bit $dc00
    bne *-3
    rts
