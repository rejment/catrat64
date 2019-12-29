
level_text: .byte 193, 186, 203, 186, 193
            .byte 154
            .byte 144
            .byte 145
show_level: {

    jsr clearscreen

    lda #10
    sta $d021

    ldx #0
    lda #154
!:  sta $400, x
    sta $400+256, x
    sta $400+512, x
    sta $400+512+256, x
    inx
    bne !-


    ldx #0
!:  lda level_text, x
    sta $400 + 8*40 + (20-5), x
    inx
    cpx #8
    bne !-

    lda #$00
    jsr $1000

!:  lda #$ff
    cmp $d012
    bne *-3
    lda $dc00
    eor #$ff
    and #%10000
    beq !-

    





    // screen off
    lda #$7b
    sta $d011
    // reset colors
    lda #12
    sta $d021
    lda #10
    sta $d022
    lda #11
    sta $d023

    lda #$00
    sta char_animation_count

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
    bne *+4
    inc map_data_ptr+1

    // screen and color are both aligned
    inc screen_data_ptr
    inc color_data_ptr
    bne *+6
    inc screen_data_ptr+1
    inc color_data_ptr+1

    // did we copy 40*21 chars?
    lda screen_data_ptr+1
    cmp #$07
    bne copy_char_loop
    lda screen_data_ptr
    cmp #$48
    bne copy_char_loop

    // ------------------------
    // reveal animation
    ldx #$e2-9
display:
    // screen on
    txa
    cmp $d012
    bne *-3
    lda #$1B
    sta $D011

    // screen off
    lda #$e2-8
    cmp $d012
    bne *-3
    // screen off
    lda #$7B
    sta $d011

    stx a+1
a:  lda #00
    sec
    sbc #$02
    tax
    cmp #$10
    bcs display

    lda #$1B
    sta $d011

    lda #$01
    jsr $1000

    lda #250
    sta player_time

    rts
}

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
    tay
    ldx char_animation_count
    inc char_animation_count

    lda material_min, y
    sta charanim_min, x

    lda material_max, y
    sta charanim_max, x

    lda screen_data_ptr
    sta charanim_lo, x

    lda screen_data_ptr+1
    sta charanim_hi, x
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
