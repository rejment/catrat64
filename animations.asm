/////////////////////////////////////////
// START ANIMATION
//
start_animation:
    cmp player_anim
    beq !end+
    tax
    sta player_anim
    lda spr_anims_reload,x
    sta player_anim_delay
    inc player_anim_delay
    lda spr_anims_to,x
    sta player_anim_end
    inc player_anim_end
    lda spr_anims_from,x
    sta player_anim_frame
    clc
    adc #sprite_data/64
    sta $07F8   // sprite data #1
!end:
    rts

/////////////////////////////////////////
// MOVE ANIMATION
//
move_animation:
    lda player_anim
    tax
    dec player_anim_delay
    bpl !end+
    lda spr_anims_reload,x
    sta player_anim_delay

    inc player_anim_frame
    lda player_anim_frame
    cmp player_anim_end
    bne !+
    lda spr_anims_from,x
    sta player_anim_frame
!:
    clc
    adc #sprite_data/64
    sta $07F8   // sprite data #1
    sta $07F9   // sprite data #2

!end:
    rts
