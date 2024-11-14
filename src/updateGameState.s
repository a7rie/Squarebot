
MOVE_LEFT = 1
MOVE_RIGHT = 2
SQUAREBOT_CHAR = $1
SQUAREBOT_COLOR = $2

; handle player input, update current state of game objects
update_game_state
  lda squarebot_position
  sta new_position
  lda squarebot_position+1
  sta new_position+1
  lda squarebot_color_position
  sta new_color_position
  lda squarebot_color_position+1
  sta new_color_position+1

  lda currently_pressed_key
  cmp #A_KEY
  bne check_if_d_pressed
  jsr subtract_one_from_new_position
  jsr update_squarebot_position
  jmp handle_jump_logic

check_if_d_pressed
  cmp #D_KEY
  bne handle_jump_logic
  jsr add_one_to_new_position
  jsr update_squarebot_position

handle_jump_logic
 rts

update_squarebot_position
  jsr remove_char
  ; new positions are valid; set them to current positions
  lda new_position
  sta squarebot_position
  lda new_position+1
  sta squarebot_position+1

  lda new_color_position
  sta squarebot_color_position
  lda new_color_position+1
  sta squarebot_color_position+1
  
  ldy #0
  lda #SQUAREBOT_CHAR
  sta (squarebot_position),y
  lda #SQUAREBOT_COLOR
  sta (squarebot_color_position),y
  
  rts


add_one_to_new_position
  clc
  lda new_position ; load and add to low byte
  adc #$1
  sta new_position
  lda new_position+1
  adc #$0 ; add if carry flag is set (low byte overflowed)
  sta new_position+1

  clc
  lda new_color_position ; load and add to low byte
  adc #$1
  sta new_color_position
  lda new_color_position+1
  adc #$0 ; add if carry flag is set (low byte overflowed)
  sta new_color_position+1
  rts

subtract_one_from_new_position
  sec
  lda new_position 
  sbc #$1
  sta new_position
  lda new_position+1
  sbc #$0 
  sta new_position+1

  sec
  lda new_color_position 
  sbc #$1
  sta new_color_position
  lda new_color_position+1
  sbc #$0 
  sta new_color_position+1

  rts

remove_char ; remove squarebot from current screen location
  ldy #0
  lda #BLANK_CHAR
  sta (squarebot_position),Y
  lda #1
  sta (squarebot_color_position),Y
  rts
