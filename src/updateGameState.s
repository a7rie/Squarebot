
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

  lda currently_pressed_key
  cmp #A_KEY
  bne check_if_d_pressed
  jsr move_new_position_to_left
  jmp check_if_new_position_valid

check_if_d_pressed
  cmp #D_KEY
  bne check_if_new_position_valid
  jsr move_new_position_to_right
  jmp check_if_new_position_valid

check_if_new_position_valid
  ldy #0
  lda (new_position),y
  cmp #EXIT_CHAR
  bne continue_level
  jsr level_has_finished
  rts

continue_level
  jsr collision_handler
  bcc handle_jump_logic

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
  
  cmp #EXIT_CHAR
  beq level_has_finished
  
  jsr collision_handler
  bcs handle_gravity

skip_validity_check
  lda has_booster ; if we have the booster, set jump_remaining to twice as high, then get rid of the booster
  cmp #1
  bne regular_jump
  lda #JUMP_SIZE*2
  sta jump_remaining
  lda #0
  sta has_booster
  jmp handle_jumps_remaining


regular_jump
  lda #JUMP_SIZE
  sta jump_remaining

handle_jumps_remaining
  jsr move_new_position_up
  ldy #0
  lda (new_position),y
  cmp #EXIT_CHAR
  beq level_has_finished
  
  jsr collision_handler
  bcc jump_is_invalid
  
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

  cmp #EXIT_CHAR
  beq level_has_finished
  
  jsr collision_handler
  bcc do_nothing


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

level_has_finished
  lda #1
  sta level_completed
  sta level_reset
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


remove_char ; remove squarebot from current screen location
  ldy #0
  lda #BLANK_CHAR
  sta (squarebot_position),Y
  lda #1
  sta (squarebot_color_position),Y
  rts

collision_handler ; accumulator is the character (the actual character code) in the position that squarebot wants to move to
; set carry flag if we can move to this char, otherwise clear it
  cmp #BLANK_CHAR
  beq return_true
  
  CMP #BOOSTER_P_CHAR
  bne key_check
  lda #1
  sta has_booster
  jmp return_true

key_check
  cmp #KEY_P_CHAR
  bne locked_wall_check
  lda #1
  sta has_key
  jmp return_true

locked_wall_check
  cmp #LOCKED_WALL_CHAR
  bne return_false

  lda has_key ; if locked wall, but player doesnt have key, cant do anything
  cmp #0
  beq return_false
  
  lda #0 ; but if locked wall and has key, get rid of the locked wall and the key
  sta has_key
  jmp return_true


squarebot_on_first_row ; set carry flag to 0 if squarebot_position is on bottom of screen; otherwise set to 1
  lda squarebot_position+1
  cmp #START_OF_FIRST_ROW_HIGH_BYTE
  bcc return_false ; compare high bits; return false if current position high bit is smaller than high bit of leftmost position on first row
  lda squarebot_position
  cmp #START_OF_FIRST_ROW_LOW_BYTE
  bcc return_false

return_true
  sec
  rts

return_false
  clc
  rts


;plan for attachable powerups
;5 variables to store the 5 tiles the player is on: tileU, tileD, tileR, tileL, tileM
;maybe combine to save space?
;4 characters to store each powerup spot: charU, charD, charR, charL
;1 variable to store character's current powerups: attached_powerups

;when moving the character right: ASSUMING THIS DOESN'T FLICKER
;  delete L, U and D and draw original tiles there
;  tileU = new, tileD = new, tileL = tileM, tileM = tileR, tileR = new
;  update chars
;  draw chars in the new place
;same deal for moving in any direction


;for moving while jumping, something about register 028C which counts down until a refresh on the button or something


;this is for drawing the attachable powerup.
;first draw the tile onto the character

;set x to the address of the attachment
;set y to 1
;go to nestedloop

;outerloop:
;if y && 128 = 1 end loop
;otherwise shift y right 1
;run nestedloop

;nestedloop:
  ;lda [character_set_begin+[16*8]]^[[character_set_begin+[16*8]]&arithTemp]

;target row = targetrow ^ [x & y]
;go through each row at x, check if x && y = 1
;if yes, XOR the correct bit on the character with 1 I think xor is ^
;if the loop is done go to outerloop
;otherwise nestedloop


;option 2:

;store each row of charL ^ powerup in tempArith
;load tempArith into accumulator and store it in charL
;clear tempArith

;so
;for each a=1 a<<1 a < 129
;and charL

;I don't think there is a generalized way to do this
;it has to be brute force, unique for each direction i think
;there is no simple way to store the fact that a bit is 1 and dynamically figure out how to change the character accordingly
;unless?



;variables: position (first 4 bits are byte position, second 4 bits are bit position)
;good gosh you can't shift accumulator multiple bits at a time.

;check each bit of the attachment, if its 1 set accumulator to 1 - nested for loop
;go to directional implementation

;right
;shift accumulator to the correct bit - for loop since accumulator only shifts 1 bit at a time
; ldx -1
;shiftloop:
; inx
; asl
; cpx [position>>4]%16
; bne shiftloop

;eor accumulator with the correct row in charR - EOR charR+[position%16]
;increase position

;

;lets figure out the rest of the logic.
;start of level need to set the tiles and chars and everything, and when you reset too

;check if you press a or d:
; check tile if you can move
; if you can't, jump to fall
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





;powerup logic:



;feedback:
;more intermediate levels
;jump left and jump right (uncontrollable jump movement)
;better colored powerups
;tutorial text
;jumping animation? change his face.