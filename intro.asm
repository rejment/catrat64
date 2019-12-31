intro: {
    jsr clearscreen

    lda #02
    sta $d020
    sta $d021
    lda #10
    sta $d022
    lda #11
    sta $d023

fade:

// copy
    ldx #$ff
!:
    .for (var i=0; i<4; i++) {
    lda map_data+(1*40*21) +180*i, x
    sta $400+180*i,x
    tay
    lda map_colors, y
    and #$0f
    sta $d800+180*i, x
    }
    dex
    bne !-

// wait
    ldx #100
!:  lda #$ff
    cmp $d012
    bne *-3
    cmp $d012
    beq *-3

    // fire to exit
    lda $dc00
    and #%10000
    beq return

    dex
    bne !-

// copy
    ldx #$ff
!:
    .for (var i=0; i<4; i++) {
    lda map_data+(0*40*21) +180*i, x
    sta $400+180*i,x
    tay
    lda map_colors, y
    and #$0f
    sta $d800+180*i, x
    }
    dex
    bne !-

// wait
    ldx #100
!:  lda #$ff
    cmp $d012
    bne *-3
    cmp $d012
    beq *-3
    // fire to exit
    lda $dc00
    and #%10000
    beq return
    dex
    bne !-


    jmp fade
return:
    rts
}