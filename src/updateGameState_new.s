START_OF_FIRST_ROW_LOW_BYTE = $e4
START_OF_FIRST_ROW_HIGH_BYTE = $1f

update_game_state
  lda squarebot_position ; likely unnecessary
  sta new_position
  lda squarebot_position+1
  sta new_position+1
  lda squarebot_color_position
  sta new_color_position
  lda squarebot_color_position+1
  sta new_color_position+1

check_if_d_pressed
  lda currently_pressed_key
  cmp #D_KEY
  bne check_if_a_pressed
d_pressed
  lda #$0
  sta temp ; preset temp to 0 here so collision_handler logic is simpler
  jsr get_right
  cmp #EXIT_CHAR ; check here if we finish the level so we can rts to game loop
  bne cont_r
  lda #1 ; finish level
  sta level_completed
  sta level_reset
  rts 
cont_r
  jsr collision_handler ; check rest of collision
  bcc hop_to_handle_jump_logic ; collided
  lda temp ; check for powerup (from collision_handler)
  cmp #$0 ; collision handler will put a 0 here unless we hit a powerup
  beq post_powerup_r
  and #$0F ; save right
  sta temp
  lda #$F0 ; its a powerup, add the powerup to attached_powerup
  and attached_powerups+1
  adc temp
  sta attached_powerups+1
  lda #$F0  ; clear right of powerup
  and tileStore+1
  sta tileStore+1
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
  adc #$80 ; turn on the ignition
  sta attached_powerups+1
  jsr apply_powerup_logic
no_booster_r
  jsr update_squarebot ; update squarebot_position and its color pos
  jsr update_chars ; redraw adjacent characters
  jsr draw_squarebot ; put squarebot on screen
  ;perhaps we wait a jiffy
  lda attached_powerups+1 ; booster time, if we activated booster we move again in the same frame before handling jump logic
  and #$F0
  cmp #$20
  beq d_pressed
  jmp handle_jump_logic ; now we handle going up and down

hop_to_handle_jump_logic
  bcc handle_jump_logic ;dang code is long, hoping to use this trick as few times as possible

check_if_a_pressed
  cmp #A_KEY
  bne handle_jump_logic
a_pressed
  lda #$0
  sta temp ; preset temp to 0 here so collision_handler logic is simpler
  jsr get_left
  cmp #EXIT_CHAR ; finish level check
  bne cont_l
  lda #1 ; finish level
  sta level_completed
  sta level_reset
  rts 
cont_l
  jsr collision_handler ; check collision
  bcc handle_jump_logic
  lda temp
  cmp #$0
  beq post_powerup_l
  and #$F0 ; save left
  sta temp
  lda #$0F ; assume we hit a powerup
  and attached_powerups+1
  adc temp
  sta attached_powerups+1
  lda #$0F ; clear left of powerup
  and tileStore+1
  sta tileStore+1
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
  adc #$08 ; turn on the ignition
  sta attached_powerups+1
  jsr apply_powerup_logic
no_booster_l
  jsr update_squarebot ; update squarebot_position and its color pos
  jsr update_chars ; redraw adjacent characters
  jsr draw_squarebot ; put squarebot on screen
  ;perhaps we wait a jiffy
  lda attached_powerups+1 ; booster time, if we activated booster we move again in the same frame before handling jump logic
  and #$0F
  cmp #$02
  beq a_pressed
  jmp handle_jump_logic ; now we handle going up and down  

handle_jump_logic
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

apply_powerup_logic
; ready bosoter: does nothing
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
  cmp #0
  beq update_blank_u
  adc #9
  asl
  asl
  asl ; we could simplify this but at this rate a few more asls isn't going to be the main thing slowing down the code
update_blank_u
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
  and $0F
  cmp #0
  beq update_blank_d
  adc #9
  asl
  asl
  asl
update_blank_d
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
  cmp #0
  beq update_blank_l
  adc #9
  asl
  asl
  asl
update_blank_l
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
  and $0F
  cmp #0
  beq update_blank_r
  adc #9
  asl
  asl
  asl
update_blank_r
  sta charandr+1

  lda #[CHAR_R << 3]
  sta charandr+2

  jsr update_char

  rts ;casual 98 line function


update_char
  ldx #0
update_char_loop
  txa
  adc charandr
  tay
  lda (#character_set_begin),y
  sta temp

  txa
  adc charandr+1
  tay
  lda (#character_set_begin),y
  eor temp
  sta temp

  txa
  adc charandr+2
  tay
  lda temp
  sta (#character_set_begin),y

  inx
  cpx #8
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