START_OF_FIRST_ROW_LOW_BYTE = $e4
START_OF_FIRST_ROW_HIGH_BYTE = $1f

; main logic until line 113:
update_game_state
  lda squarebot_position ; likely unnecessary
  sta new_position
  lda squarebot_position+1
  sta new_position+1
  lda squarebot_color_position
  sta new_color_position
  lda squarebot_color_position+1
  sta new_color_position+1

jump_logic
  jsr get_jump_num
  cmp #0
  beq fall_logic
  sec
  sbc #1
  jsr set_jump_num
  jsr move_up
  jsr get_jump_dir
j_left
  cmp #$10
  bne j_right
  jsr wait_until_next_frame
  jsr move_left
  jmp update_return
j_right
  cmp #$20
  bne update_return
  jsr wait_until_next_frame
  jsr move_right
  jmp update_return

fall_logic
  jsr get_down
  jsr fall_check
  bcc check_if_space_pressed
  jsr move_down
  jsr get_down
  jsr fall_check
  bcc update_return ; don't move if we land
  jsr get_jump_dir
f_left
  cmp #$10
  bne f_right
  jsr wait_until_next_frame
  jsr move_left
  jmp update_return
f_right
  cmp #$20
  bne update_return
  jsr wait_until_next_frame
  jsr move_right
  jmp update_return

update_return
  rts

check_if_space_pressed
  lda #$00
  sta jump_info ; double check we aren't falling in a direction
  lda currently_pressed_key
  cmp #SPACE_KEY
  bne check_if_q_pressed
  lda #JUMP_SIZE
  jsr set_jump_num
  lda #00
  jsr set_jump_dir
  jsr move_up
  jmp update_return

check_if_q_pressed
  cmp #Q_KEY
  bne check_if_e_pressed
  lda #JUMP_SIZE
  jsr set_jump_num
  lda #$10
  jsr set_jump_dir
  jsr move_up
  jsr wait_until_next_frame
  jsr move_left
  jmp update_return

check_if_e_pressed
  cmp #E_KEY
  bne check_if_a_pressed
  lda #JUMP_SIZE
  jsr set_jump_num
  lda #$20
  jsr set_jump_dir
  jsr move_up
  jsr wait_until_next_frame
  jsr move_right
  jmp update_return

check_if_a_pressed
  cmp #A_KEY
  bne check_if_d_pressed
  jsr move_left
  jmp update_return

check_if_d_pressed
  cmp #D_KEY
  bne update_return
  jsr move_right
  jmp update_return

; The rest is subroutines

;current bugs:
;attached powerup sprites are not working
;jump direction is not reset properly
;platforms get deleted sometimes
;need to replace end screen

move_up
  lda #$0
  sta temp
  jsr get_up
  cmp #EXIT_CHAR
  bne cont_u
  jsr delete_squarebot
  lda #1
  sta level_completed
  sta level_reset
  jmp return_u
cont_u
  jsr collision_handler
  bcc remove_jumps
  lda temp
  cmp #$0
  beq post_powerup_u
  and #$F0
  sta temp
  lda #$0F
  and attached_powerups
  clc
  adc temp
  sta attached_powerups
  lda #$0F
  and tile_store
  sta tile_store
post_powerup_u
  jsr delete_squarebot
  jsr move_new_position_up
  jsr get_tiles_u
  lda attached_powerups
  and #$0F
  cmp #$01
  bne no_booster_u
  lda attached_powerups
  and #$F0
  clc
  adc #$08
  sta attached_powerups
no_booster_u
  jsr apply_powerup_logic
  jsr update_squarebot
  jsr update_chars
  jsr draw_squarebot
  jsr wait_until_next_frame
  lda attached_powerups
  and #$0F
  cmp #$02
  beq move_up
return_u
  rts
remove_jumps
  lda jump_info
  and #$F0 ;remove jumps_remaining since we hit a wall
  sta jump_info
  jmp return_u

move_down
  lda #$0
  sta temp
  jsr get_down
  cmp #EXIT_CHAR
  bne cont_d
  jsr delete_squarebot
  lda #1
  sta level_completed
  sta level_reset
  jmp return_d 
cont_d
  cmp #PLATFORM_CHAR ; collision_handler assumes we go through these otherwise
  beq remove_fall
  jsr collision_handler
  bcc remove_fall
  lda temp
  cmp #$0
  beq post_powerup_d
  and #$0F
  sta temp
  lda #$F0
  and attached_powerups
  clc
  adc temp
  sta attached_powerups
  lda #$F0
  and tile_store
  sta tile_store
post_powerup_d
  jsr delete_squarebot
  jsr move_new_position_down
  jsr get_tiles_d
  lda attached_powerups
  and #$F0
  cmp #$10
  bne no_booster_d
  lda attached_powerups
  and #$0F
  clc
  adc #$80
  sta attached_powerups
no_booster_d
  jsr apply_powerup_logic
  jsr update_squarebot
  jsr update_chars
  jsr draw_squarebot
  jsr wait_until_next_frame
  lda attached_powerups
  and #$F0
  cmp #$20
  beq move_down
return_d
  rts
remove_fall
  lda #$00 ;landed on ground so we aren't jumping or falling
  sta jump_info
  jmp return_d

move_left
  lda #$0
  sta temp ; preset temp to 0 here so collision_handler logic is simpler
  jsr get_left
  cmp #EXIT_CHAR ; finish level check
  bne cont_l
  jsr delete_squarebot
  lda #1 ; finish level
  sta level_completed
  sta level_reset
  jmp return_l
cont_l
  jsr collision_handler ; check collision
  bcc return_l
  lda temp
  cmp #$0
  beq post_powerup_l
  and #$F0 ; save left
  sta temp
  lda #$0F ; assume we hit a powerup
  and attached_powerups+1
  clc
  adc temp
  sta attached_powerups+1
  lda #$0F ; clear left of powerup
  and tile_store+1
  sta tile_store+1
post_powerup_l
  jsr delete_squarebot ; delete character
  jsr move_new_position_left
  jsr get_tiles_l
  lda attached_powerups+1
  and #$0F
  cmp #$01
  bne no_booster_l
  lda attached_powerups+1
  and #$F0
  clc
  adc #$08 ; turn on the ignition
  sta attached_powerups+1
no_booster_l
  jsr apply_powerup_logic
  jsr update_squarebot ; update squarebot_position and its color pos
  jsr update_chars ; redraw adjacent characters
  jsr draw_squarebot ; put squarebot on screen
  jsr wait_until_next_frame
  lda attached_powerups+1 ; booster time, if we activated booster we move again in the same frame before handling jump logic
  and #$0F
  cmp #$02
  beq move_left
return_l
  rts 

move_right
  lda #$0
  sta temp ; preset temp to 0 here so collision_handler logic is simpler
  jsr get_right
  cmp #EXIT_CHAR ; check here if we finish the level so we can rts to game loop
  bne cont_r
  jsr delete_squarebot
  lda #1 ; finish level
  sta level_completed
  sta level_reset
  jmp return_r 
cont_r
  jsr collision_handler ; check rest of collision
  bcc return_r ; collided
  lda temp ; check for powerup (from collision_handler)
  cmp #$0 ; collision handler will put a 0 here unless we hit a powerup
  beq post_powerup_r
  and #$0F ; save right
  sta temp
  lda #$F0 ; its a powerup, add the powerup to attached_powerup
  and attached_powerups+1
  clc
  adc temp
  sta attached_powerups+1
  lda #$F0  ; clear right of powerup
  and tile_store+1
  sta tile_store+1
post_powerup_r
  jsr delete_squarebot ; delete character
  jsr move_new_position_right ; new position is where we want to move
  jsr get_tiles_r
  lda attached_powerups+1 ; if left powerup is readyBooster, change it to ignitedBooster, since apply_powerup_logic doesn't have directional context
  and #$F0
  cmp #$10
  bne no_booster_r
  lda attached_powerups+1
  and #$0F
  clc
  adc #$80 ; turn on the ignition
  sta attached_powerups+1
no_booster_r
  jsr apply_powerup_logic
  jsr update_squarebot ; update squarebot_position and its color pos
  jsr update_chars ; redraw adjacent characters
  jsr draw_squarebot ; put squarebot on screen
  jsr wait_until_next_frame
  lda attached_powerups+1 ; booster time, if we activated booster we move again in the same frame before handling jump logic
  and #$F0
  cmp #$20
  beq move_right
return_r
  rts

collision_handler ; accumulator is the character in the position that squarebot wants to move to
; set carry flag if we can move to this char, otherwise clear it
; if its a powerup, set temp to be the attached_powerup id + attached_powerup id <<4, otherwise return since temp is already 0
  cmp #BLANK_TILE_CHAR
  beq return_true
  cmp #PLATFORM_CHAR
  beq return_true ; moving down will double check anyway
  ;I'll figure out ladders later
  cmp #WALL_CHAR
  beq return_false
  cmp #BREAKABLE_WALL_CHAR
  beq return_false
  cmp #LOCKED_WALL_CHAR
  beq return_false
  ;else its a powerup
  cmp #BOOSTER_P_CHAR
  bne rpk
  lda #$11 ;set both hex characters to avoid dumb shifts taking up lots of space
  sta temp
  jmp return_true
rpk
  cmp #KEY_P_CHAR
  bne rps
  lda #$33
  sta temp
  jmp return_true
rps
  cmp #SPIKE_P_CHAR
  bne return_false
  lda #$44
  sta temp
  jmp return_true

return_true
  sec
  rts

return_false
  clc
  rts

fall_check
  cmp #PLATFORM_CHAR
  beq return_false
  cmp #WALL_CHAR
  beq return_false
  cmp #LOCKED_WALL_CHAR
  beq return_false
  cmp #BREAKABLE_WALL_CHAR
  beq return_false
  cmp #LADDER_CHAR
  beq return_false
  jmp return_true;

apply_powerup_logic
; ready booster: does nothing
; ignited booster: breaks breakable walls and changes to active booster 
; active booster: breaks breakable walls and changes to ready booster
; key: spends itself to break locked walls
  lda attached_powerups
  sta temp
  jsr get_up
  asl
  asl
  asl
  asl
  sta temp+1
  jsr get_down
  clc
  adc temp+1
  sta temp+1
  jsr power_pair_logic
  lda temp
  sta attached_powerups
  lda temp+1
  lsr
  lsr
  lsr
  lsr
  jsr set_up ; setting a tile effectively changes that character
  lda temp+1
  and #$0F
  jsr set_down

  lda attached_powerups+1
  sta temp
  jsr get_left
  asl
  asl
  asl
  asl
  sta temp+1
  jsr get_right
  clc
  adc temp+1
  sta temp+1
  jsr power_pair_logic
  lda temp
  sta attached_powerups+1
  lda temp+1
  lsr
  lsr
  lsr
  lsr
  jsr set_left
  lda temp+1
  and #$0F
  jsr set_right
  rts
  
power_pair_logic
  lda temp
  and #$F0
  cmp #$80 ; check ignited booster
  bne ppl1b
  lda temp+1
  and #$0F ; check opposite tile
  cmp #BREAKABLE_WALL_CHAR
  bne ppl1ab
  lda temp+1
  and #$F0
  sta temp+1 ; delete wall
ppl1ab
  lda temp
  and #$0F
  clc
  adc #$20 ; set active booster
  sta temp
  jmp ppl2
ppl1b
  cmp #$20 ; check active booster
  bne ppl1k
  lda temp+1
  and #$0F ; check opposite tile
  cmp #BREAKABLE_WALL_CHAR
  bne ppl1rb
  lda temp+1
  and #$F0
  sta temp+1 ; delete wall
ppl1rb
  lda temp
  and #$0F
  clc
  adc #$10 ; set ready booster
  sta temp
  jmp ppl2
ppl1k
  cmp #$30 ; check key
  bne ppl2
  lda temp+1
  and #$F0
  cmp #[LOCKED_WALL_CHAR << 4]
  bne ppl2
  lda temp
  and #$0F
  sta temp ; delete key
  lda temp+1
  and #$0F
  sta temp+1 ; delete wall
  jmp ppl2

ppl2
  lda temp
  and #$0F
  cmp #$08 ; check ignited booster
  bne ppl2b
  lda temp+1
  and #$F0
  cmp #[BREAKABLE_WALL_CHAR << 4]
  bne ppl2ab
  lda temp+1
  and #$0F
  sta temp+1 ; delete wall
ppl2ab
  lda temp
  and #$F0
  clc
  adc #$02 ; set active booster
  sta temp
  jmp pplend
ppl2b
  cmp #$02 ; check active booster
  bne ppl2k
  lda temp+1
  and #$F0
  cmp #[BREAKABLE_WALL_CHAR << 4]
  bne ppl2rb
  lda temp+1
  and #$0F
  sta temp+1 ; delete wall
ppl2rb
  lda temp
  and #$F0
  clc
  adc #$01 ; set ready booster
  sta temp
  jmp pplend
ppl2k
  cmp #$03 ; key
  bne pplend
  lda temp+1
  and #$0F
  cmp #LOCKED_WALL_CHAR
  bne pplend
  lda temp
  and #$F0
  sta temp ; delete key
  lda temp+1
  and #$F0
  sta temp+1 ; delete wall
  jmp pplend

pplend
  rts


delete_squarebot
  jsr get_squarebot_draw_position

  ldy #[ROW_SIZE + 1]
  jsr get_mid
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  ldy #1
  jsr get_up
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  ldy #[[ROW_SIZE*2] + 1]
  jsr get_down
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  ldy #ROW_SIZE
  jsr get_left
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  ldy #[ROW_SIZE + 2]
  jsr get_right
  sta (squarebot_position),y
  lda #0

  jsr get_squarebot_game_position

  rts


update_squarebot
  lda new_position
  sta squarebot_position
  lda new_position+1
  sta squarebot_position+1

  lda new_color_position
  sta squarebot_color_position
  lda new_color_position+1
  sta squarebot_color_position+1
  rts


update_chars
  jsr get_up
  asl
  asl
  asl ; multiply by 8
  sta charandr
  lda attached_powerups
  lsr
  lsr
  lsr
  lsr
  cmp #$00
  beq update_char_u
  clc
  adc #$09
  asl
  asl
  asl ; we could simplify this but at this rate a few more asls isn't going to be the main thing slowing down the code
update_char_u
  sta charandr+1
  lda #[CHAR_U << 3]
  sta charandr+2
  jsr update_char
  ;keep in mind we haven't rotated it yet

  jsr get_down
  asl
  asl
  asl
  sta charandr
  lda attached_powerups
  and #$0F
  cmp #$00
  beq update_char_d
  clc
  adc #$09
  asl
  asl
  asl
update_char_d
  sta charandr+1
  lda #[CHAR_D << 3]
  sta charandr+2
  jsr update_char

  jsr get_left
  asl
  asl
  asl
  sta charandr
  lda attached_powerups+1
  lsr
  lsr
  lsr
  lsr
  cmp #$00
  beq update_char_l
  clc
  adc #$09
  asl
  asl
  asl
update_char_l
  sta charandr+1
  lda #[CHAR_L << 3]
  sta charandr+2
  jsr update_char

  jsr get_right
  asl
  asl
  asl
  sta charandr
  lda attached_powerups+1
  and #$0F
  cmp #$00
  beq update_char_r
  clc
  adc #$09
  asl
  asl
  asl
update_char_r
  sta charandr+1
  lda #[CHAR_R << 3]
  sta charandr+2
  jsr update_char

  rts ;casual 98 line function


update_char
  ldx #$00
update_char_loop
  txa
  clc
  adc charandr
  tay
  lda (#character_set_begin),y
  sta temp

  txa
  clc
  adc charandr+1
  tay
  lda (#character_set_begin),y
  eor temp
  sta temp

  txa
  clc
  adc charandr+2
  tay
  lda temp
  sta (#character_set_begin),y

  inx
  cpx #$08
  bne update_char_loop
  rts

; if there is a powerup:
; for each of 8 bytes:
; load tile byte
; eor with powerup tile byte
; store in char byte

draw_squarebot
  jsr get_squarebot_draw_position

  lda #CHAR_U
  ldy #1
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  lda #CHAR_D
  ldy #[[ROW_SIZE*2]+1]
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  lda #CHAR_L
  ldy #ROW_SIZE
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  lda #CHAR_R
  ldy #[ROW_SIZE+2]
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  lda #SQUAREBOT_CHAR
  ldy #[ROW_SIZE+1]
  sta (squarebot_position),y
  lda #SQUAREBOT_COLOR
  sta (squarebot_color_position),y

  jsr get_squarebot_game_position
  rts

;real how it works:

;l/r movement:
;store l/r tile you want to move to
;if you win, win
;check collision:
;  store powerup in temp
;  return whether you can move or not
;if you can't move, goto j/f movement
;apply powerup
;get new position
;refresh tiles
;apply powerup logic
;delete old position
;update position
;redraw chars
;draw new position
;wait a jiffy maybe
;check booster
;
;j/f movement
;do similar thing