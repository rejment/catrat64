
level_text: .byte 193, 186, 203, 186, 193
            .byte 154
            .byte 144
            .byte 145
show_level: {

    // screen off
    lda #$7b
    sta $d011

    jsr clearscreen

    ldx #4*40 + 1
!:  lda #119
    sta $400 + 40*21 - 1, x
    lda #0
    sta $d800 + 40*21 - 1, x
    dex
    bne !-

    // reset colors
    lda #0
    sta $d020
    lda #12
    sta $d021
    lda #10
    sta $d022
    lda #11
    sta $d023

    lda #$00
    sta charanim_speedcode_ptr

    // setup ptrs
    ldx current_level
    lda level_pos_lo, x
    sta map_data_ptr
    lda level_pos_hi, x
    sta map_data_ptr+1

    lda #$00
    sta screen_data_ptr
    lda #$04
    sta screen_data_ptr+1

    lda #$00
    sta color_data_ptr
    lda #$d8
    sta color_data_ptr+1


copy_char_loop:
    ldy #$00
    lda (map_data_ptr),y
    sta (screen_data_ptr),y
    tax
    lda map_colors, x
    sta (color_data_ptr),y
    jsr extract_animated_char

    inc map_data_ptr
    bne !+
    inc map_data_ptr+1
!:
    // screen and color are both aligned
    inc screen_data_ptr
    inc color_data_ptr
    bne !+
    inc screen_data_ptr+1
    inc color_data_ptr+1
!:

    // did we copy 40*21 chars?
    lda screen_data_ptr+1
    cmp #$07
    bne copy_char_loop
    lda screen_data_ptr
    cmp #$48
    bne copy_char_loop

    lda #$60    // rts
    ldx charanim_speedcode_ptr
    sta charanim_speedcode, x


    // ------------------------
    // reveal animation
    ldx #11+16
reveal:
    stx reload_x+1
    jsr render_blinds
reload_x:
    ldx #00
    dex
    bne reveal


    lda #$1B
    sta $d011

    // lda #$01
    // jsr $1000

    lda #250
    sta player_time

    lda #0
    sta player_keys

    rts
}
blind:
    .byte 0
blinds:
    .fill 11, 0 // end with all open
    .fill 16, i // 0 - 16
    .fill 11, 17 // all closed

    .label FIRST_LINE = $32
render_blinds:
    lda #$ff
    cmp $d012
    bne *-3
    lda #FIRST_LINE+1
    cmp $d012
    bne *-3
    lda #$1b    // on
    sta $d011

    lda #FIRST_LINE
    sta start_of_blind+1
one_blind:
    lda blinds,x
    beq skip_blind  // no blind
start_of_blind:
    ldy #$00
    cpy $d012
    bne *-3
    ldy #$7b        // off
    sty $d011
    cmp #16
    bcs skip_blind  // no opening
    clc
    adc start_of_blind+1
    ldy #$1b    // on
    cmp $d012
    bne *-3
    sty $d011
skip_blind:
    inx
    lda start_of_blind+1
    clc
    adc #16
    sta start_of_blind+1
    cmp #FIRST_LINE + 16*11
    bne one_blind

    cmp $d012
    bne *-3
    ldy #$7b        // off
    sty $d011
    rts

////////////////////////////////////////////////
// 
// EXTRACT ANIMATED CHAR
//
extract_animated_char:
    and #$f0
    lsr
    lsr
    lsr
    lsr

    cmp #$02
    beq animated
    cmp #$03
    beq animated
    cmp #$04
    beq starting_pos
    rts

animated:
    ldx charanim_speedcode_ptr
    clc
    adc #$8d - 2// sta/stx
    sta charanim_speedcode + 0, x
    lda screen_data_ptr
    sta charanim_speedcode + 1, x
    lda screen_data_ptr + 1
    sta charanim_speedcode + 2, x
    inc charanim_speedcode_ptr
    inc charanim_speedcode_ptr
    inc charanim_speedcode_ptr
    rts

starting_pos:
    ldx screen_data_ptr
    ldy screen_data_ptr+1
    tya             //divide offset by 40 to get the row#:
    lsr             //first divide by 8, ignoring the screen base address
    sta temp
    txa
    ror
    lsr temp
    ror
    lsr
    sta temp       //then divide by 5
    lsr
    adc #13
    adc temp
    ror
    lsr
    lsr
    adc temp
    ror
    adc temp
    ror
    lsr
    lsr
    tay

    asl             //screen row * 8 + 50 -> sprite y-pos
    asl
    asl
    adc #50-13
    sta player_y

    txa             //offset lowbyte - offset[screenrow] = screen column
    sec
    sbc rowlo,y
    clc
    adc #3          //(column + 3) * 8 -> sprite x-pos
    asl
    asl
    asl
    sta player_x
    lda #$00
    adc #$00
    sta player_x+1

    lda #$06
    sta player_anim_delay

    rts


rowlo:
    .byte $00,$28,$50,$78, $a0,$c8,$f0,$18
    .byte $40,$68,$90,$b8, $e0,$08,$30,$58
    .byte $80,$a8,$d0,$f8, $20,$48,$70,$98
    .byte $c0
