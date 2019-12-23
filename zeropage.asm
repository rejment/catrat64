*=2 "Zeropage" virtual
TEMP:    .byte 0

// collision
get_collision_temp: .word 0
get_collision_x:        .byte 0, 0
get_collision_y:        .byte 0
get_collision_result:   .byte 0
get_collision_result_a: .byte 0
get_collision_result_x: .byte 0
get_collision_result_y: .byte 0
get_collision_char:     .byte 0


// portals
find_portal_x:          .byte 0
find_portal_y:          .byte 0
find_portal_direction:  .byte 0
find_portal_result:     .byte 0

player_anim:        .byte $ff
player_anim_frame:  .byte $00
player_anim_end:    .byte $00
player_anim_delay:  .byte $06
player_falling:     .byte $00


player_x:           .byte $28
                    .byte $00
player_y:           .byte $b5
fall_index:         .byte $00




