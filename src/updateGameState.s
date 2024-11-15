
MOVE_LEFT = 1
MOVE_RIGHT = 2
SQUAREBOT_CHAR = $1
SQUAREBOT_COLOR = $2
START_OF_FIRST_ROW_LOW_BYTE = $e4
START_OF_FIRST_ROW_HIGH_BYTE = $1f

; handle player input, update current state of game objects
; some pseudocode to provide a better idea of what we're doing here:

; new_position = squarebot_position
; if A pressed
;   new_position += 1 (move right one char)
; if D pressed
;   new_position -= 1 (move left one char)
; if not valid(new_position)
;   new_position = squarebot_position

; if jump_remaining = 0 and space not pressed:
;   return
; if jump_remaining = 0 and space is pressed:
;   jump remaining = JUMP_SIZE


; if jump_remaining > 0
;   new_position -= 22 (go up one)
;   if not valid(new_position):
;     new_position = squarebot_position
;     jump_remaining = 0
; else
;   new_position += 22 (go down one)
;   jump_remaining -= 1
;   if not valid(new_position):
;     jump_remaining = 0
;     new_position = o
; 
;

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
  jsr move_new_position_to_left
  jmp check_if_new_position_valid

check_if_d_pressed
  cmp #D_KEY
  bne check_if_new_position_valid
  jsr move_new_position_to_right

check_if_new_position_valid
  ldy #0
  lda (new_position),y
  cmp #BLANK_CHAR
  bne handle_jump_logic
  jsr update_squarebot_position

handle_jump_logic
  lda jump_remaining ; how many more upward motions for current jump
  cmp #0
  bne handle_jumps_remaining


handle_no_jumps_remaining ; if no jumps left, then start jump if space is pressed, otherwise just skip and handle gravity
  lda currently_pressed_key
  cmp #SPACE_KEY
  bne handle_gravity



  jsr squarebot_on_first_row ; if on first row, we dont care about what character lies below
  bcs skip_validity_check

; check if character below is blank; if so dont allow us to set jump_remaining
  ldy #ROW_SIZE
  lda (squarebot_position),y
  cmp #BLANK_SPACE_CHAR
  beq handle_gravity

skip_validity_check 
  lda #JUMP_SIZE
  sta jump_remaining

handle_jumps_remaining
  jsr move_new_position_up
  ldy #0
  lda (new_position),y
  cmp #BLANK_CHAR
  bne jump_is_invalid ; cant continue moving up; somethings in the way
  
  jsr update_squarebot_position
  
  lda jump_remaining
  sec
  sbc #1
  sta jump_remaining
  rts ; no gravity effect after moving upwards from jump


jump_is_invalid
  lda #0
  sta jump_remaining
  rts

handle_gravity ; on first row - do nothing
  jsr move_new_position_down

  jsr squarebot_on_first_row
  bcs do_nothing

  ldy #0
  lda (new_position),y
  cmp #BLANK_CHAR
  bne do_nothing


  jsr update_squarebot_position

do_nothing
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


move_new_position_to_right
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

move_new_position_to_left
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

  
move_new_position_up
  sec
  lda new_position 
  sbc #ROW_SIZE
  sta new_position
  lda new_position+1
  sbc #$0 
  sta new_position+1
  sec
  lda new_color_position 
  sbc #ROW_SIZE
  sta new_color_position
  lda new_color_position+1
  sbc #$0 
  sta new_color_position+1
  rts

move_new_position_down
  clc
  lda new_position ; load and add to low byte
  adc #ROW_SIZE
  sta new_position
  lda new_position+1
  adc #$0 ; add if carry flag is set (low byte overflowed)
  sta new_position+1
  clc
  lda new_color_position ; load and add to low byte
  adc #ROW_SIZE
  sta new_color_position
  lda new_color_position+1
  adc #$0 ; add if carry flag is set (low byte overflowed)
  sta new_color_position+1
  rts

reset_new_position
  lda squarebot_position
  sta new_position
  lda squarebot_position+1
  sta new_position+1
  
  lda squarebot_color_position
  sta new_color_position
  lda squarebot_color_position+1
  sta squarebot_color_position+1
  rts

remove_char ; remove squarebot from current screen location
  ldy #0
  lda #BLANK_CHAR
  sta (squarebot_position),Y
  lda #1
  sta (squarebot_color_position),Y
  rts

squarebot_on_first_row ; set carry flag to 0 if squarebot_position is on bottom of screen; otherwise set to 1
  lda squarebot_position+1
  cmp #START_OF_FIRST_ROW_HIGH_BYTE
  bcc return_false ; compare high bits; return false if current position high bit is smaller than high bit of leftmost position on first row
  lda squarebot_position
  CMP #START_OF_FIRST_ROW_LOW_BYTE
  bcc return_false

return_true
  sec
  rts

return_false
  clc
  rts