MOVE_LEFT = 1
MOVE_RIGHT = 2
SQUAREBOT_CHAR = $1
SQUAREBOT_COLOR = $2
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

check_if_a_pressed
  lda currently_pressed_key
  cmp #A_KEY
  bne check_if_d_pressed
  ;switch statement on tile for all the things
  jsr move_new_position_to_left
  jmp collision_handler

check_if_d_pressed
  cmp #D_KEY
  bne collision_handler
  ;switch statement on tile for all the things
  jsr move_new_position_to_right
  jmp collision_handler


collision_handler ; accumulator is the character (the actual character code) in the position that squarebot wants to move to
; set carry flag if we can move to this char, otherwise clear it
  ldy #0
  lda (new_position),y

  cmp #BLANK_CHAR
  beq return_true
  
  cmp #EXIT_CHAR
  beq level_has_finished
  rts

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

continue_level
  jsr collision_handler
  bcc handle_jump_logic

  jsr update_squarebot_position

handle_jump_logic



return_true
  sec
  rts

return_false
  clc
  rts

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
