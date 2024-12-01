START_OF_FIRST_ROW_LOW_BYTE = $e4
START_OF_FIRST_ROW_HIGH_BYTE = $1f

update_game_state
  lda squarebot_position
  sta new_position
  lda squarebot_position+1
  sta new_position+1
  lda squarebot_color_position
  sta new_color_position
  lda squarebot_color_position+1
  sta new_color_position+1

check_if_d_pressed
  cmp #D_KEY
  bne check_if_a_pressed
d_pressed
  jsr get_right
  cmp #EXIT_CHAR ; check here if we finish the level so we can rts to game loop
  beq level_has_finished
  jsr collision_handler ; returns true if we can move
  bcc handle_jump_logic ; no move
  lda temp ; check for powerup
  cmp #$0
  beq post_powerup_r ;no powerup
  lda #$F0
  and attached_powerups ; clear original powerup
  adc temp
  sta attached_powerups ; insert new one
  lda #$F0
  and tileStore+2
  sta tileStore+2 ; clear powerup tile
post_powerup_r
  jsr move_new_position_to_right
  ;get new tiles
  jsr get_mid 
  jsr set_left
  jsr get_right
  jsr set_mid
  jsr get_squarebot_draw_position
  ldy #[ROW_SIZE+3]
  lda (squarebot_position),y
  jsr set_right
  ldy #2
  lda (squarebot_position),y
  jsr set_up
  ldy #[[ROW_SIZE*2]+2]
  lda (squarebot_position),y
  jsr set_down
  ;powerup logic

  ;draw chars

  jsr delete_squarebot
  jsr update_squarebot
  jsr draw_squarebot ;TODO: DRAW HIM


check_if_a_pressed
  lda currently_pressed_key
  cmp #A_KEY
  bne handle_jump_logic
a_pressed
  jsr get_left
  cmp #EXIT_CHAR
  beq level_has_finished
  jsr collision_handler
  bcc handle_jump_logic

level_has_finished
  lda #1
  sta level_completed
  sta level_reset
  rts 

handle_jump_logic

collision_handler ; accumulator is the character (the actual character code) in the position that squarebot wants to move to
; set carry flag if we can move to this char, otherwise clear it
  cmp #BLANK_CHAR
  beq return_true

  cmp #BOOSTER_P_CHAR
  bne key_check
  lda #1
  sta has_booster
  jmp return_true

key_check
  cmp #KEY_P_CHAR
  bne return_false
  lda #1
  sta has_key
  jmp return_true

delete_squarebot
  jsr get_squarebot_draw_position

  ldy #[ROW_SIZE + 1]
  jsr get_mid
  sta (squarebot_position),y
  lda #1
  sta (squarebot_color_position),y

  ldy #1
  jsr get_up
  sta (squarebot_position),y
  lda #1
  sta (squarebot_color_position),y

  ldy #[[ROW_SIZE*2] + 1]
  jsr get_down
  sta (squarebot_position),y
  lda #1
  sta (squarebot_color_position),y

  ldy #ROW_SIZE
  jsr get_left
  sta (squarebot_position),y
  lda #1
  sta (squarebot_color_position),y

  ldy #[ROW_SIZE + 2]
  jsr get_right
  sta (squarebot_position),y
  lda #1

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

draw_squarebot

;start of level need to set the tiles and chars and everything, and when you reset too

;check if you press a or d:
; check tile if you can move
; if you can't, jump/fall
; otherwise, move new position and apply powerup if you collide with one
; refresh tiles
; call powerup logic for each powerup.
; draw powerup characters
; delete old character
; display character and powerups
; wait a jiffy probably
; booster check, if booster activated do this move again

;check if you are falling or jumping
; basically do all the same stuff but for up and down


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
;redraw chars
;delete old position
;update position
;draw new position
;wait a jiffy maybe
;check booster
;
;j/f movement