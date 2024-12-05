TITLE_SCREEN_CHAR_COLOR = 0
ENTER_KEY = $0f

display_title_screen
  lda #SCREEN_CURSOR_BEGINNING_LOW_BYTE
  sta screen_cursor
  lda #SCREEN_CURSOR_BEGINNING_HIGH_BYTE ; store 1e in location 01
  sta screen_cursor+1

  lda #COLOR_CURSOR_BEGINNING_LOW_BYTE
  sta color_cursor
  lda #COLOR_CURSOR_BEGINNING_HIGH_BYTE
  sta color_cursor+1

  ldy #$0 ; to use for indirect indexed addressing
  ldx #$0

  jsr draw_title_screen_chars_loop
  ldy #$0 ; to use for indirect indexed addressing
  ldx #$0


infinite_loop
  lda currently_pressed_key
  cmp #ENTER_KEY
  beq gameLoop
  jmp infinite_loop


draw_title_screen_chars_loop
  lda compressed_screen_data_start,X ; accumulator stores num times to repeat the byte
  jsr draw_character ; draw the character that many times
  inx 
  inx
  jsr check_if_screen_cursor_at_end
  bcc draw_title_screen_chars_loop
  rts


; draw the character in Y register for (value of accumulator) number of times
draw_character
  ; if accumulator == 0, return; otherwise, subtract 1 from accumulator and continue drawing the letter at Y
  beq draw_character_end
  sec
  sbc #1
  pha ; push accumulator onto stack

  ; store current char at screen cursor location
  ldy #0 
  lda compressed_screen_data_start+1,X ; load cur char to draw

; solid block in the title screen editor is the a0 character; we convert that to the equivalent here (wall), as we cant access that char
  cmp #$a0
  bne dont_map_wall
  lda #WALL_CHAR-128
  clc

dont_map_wall
  adc #128
  sta (screen_cursor),Y ; draw it on screen

  
  ; add color to the screen location if it's not a space
  ; because our title screen only has one color, and only displays it for characters that arent space, we can get away with this "optimization",
  ; and avoid adding color data
  cmp #BLANK_CHAR
  beq dont_color

  lda #TITLE_SCREEN_CHAR_COLOR
  sta (color_cursor),Y

dont_color
  jsr add_one_to_screen_cursor
  pla ; put the current 'count' (remaining times to draw character) back on accumulator
  jmp draw_character

draw_character_end
  rts


add_one_to_screen_cursor
  clc
  lda screen_cursor ; load and add to low byte
  adc #$1
  sta screen_cursor
  lda screen_cursor+1
  adc #$0 ; add if carry flag is set (low byte overflowed)
  sta screen_cursor+1

  ; add to color cursor as well
  clc
  lda color_cursor ; load and add to low byte
  adc #$1
  sta color_cursor
  lda color_cursor+1
  adc #$0 ; add if carry flag is set (low byte overflowed)
  sta color_cursor+1
  rts
   
check_if_screen_cursor_at_end ; set carry flag if screen_cursor at position $1ff9 (8185
  lda screen_cursor ; load value at screen_cursor low byte
  cmp #END_OF_SCREEN_LOW_BYTE
  bne check_if_screen_cursor_at_end_return_false ; if low byte doesnt match, return with carry flag as neg
  
  lda screen_cursor+1
  cmp #END_OF_SCREEN_HIGH_BYTE 
  beq check_if_screen_cursor_at_end_return_true ; if high byte matches, set carry flag

check_if_screen_cursor_at_end_return_false
  clc
  rts

check_if_screen_cursor_at_end_return_true
  sec
  rts 
