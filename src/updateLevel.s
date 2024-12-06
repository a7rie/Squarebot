LEVEL_IS_DONE = 1
LEVEL_NOT_DONE = 0
SHOULD_RESET = 1
SHOULD_NOT_RESET = 0

; only first 4 bits really matter here; refer to readme for guide on lvl format
BLANK_SPACE = 0 ; 000000000
STARTING_POINT = 16 ; 00010000
WALL = 32 ; 00100000
BREAKABLE_WALL = 48 ; 00110000
LOCKED_WALL = 64 ; 01000000
LADDER = 80 ; 01010000
EXIT = 96 ; 01100000
PLATFORM = 112 ; 01110000
KEY = 128 ; 10000000
SPIKE = 144 ; 10010000
BOOSTER = 160 ; 10100000

WALL_COLOR = 0
BREAKABLE_WALL_COLOR = 0
LOCKED_WALL_COLOR = 0
LADDER_COLOR = 0 ;6
EXIT_COLOR = 0 ;6
PLATFORM_COLOR = 0 ;4
SPIKE_COLOR = 0 ;2
KEY_P_COLOR = 0 ;7
SPIKE_P_COLOR = 0 ;6
BOOSTER_P_COLOR = 0 ;6
SQUAREBOT_COLOR = 2

BLANK_TILE_CHAR = $00 ; use this instead of BLANK_CHAR, allows me to save space with tile_store
LADDER_CHAR = $01
PLATFORM_CHAR = $02
WALL_CHAR = $03
EXIT_CHAR = $04
LOCKED_WALL_CHAR = $05
BREAKABLE_WALL_CHAR = $06
BOOSTER_P_CHAR = $07
KEY_P_CHAR =  $08
SPIKE_P_CHAR = $09
BOOSTER_A_CHAR = $0A
BOOSTER_AA_CHAR = $0B
KEY_A_CHAR = $0C
SPIKE_A_CHAR = $0D
CHAR_U = $0E
CHAR_D = $0F
CHAR_L = $10
CHAR_R = $11
SQUAREBOT_CHAR = $12
LEVEL_BEGINNING_LOW_BYTE = $17
LEVEL_BEGINNING_HIGH_BYTE = $1e
LEVEL_COLOR_BEGINNING_LOW_BYTE = $17
LEVEL_COLOR_BEGINNING_HIGH_BYTE = $96
END_OF_LEVEL_LOW_BYTE = $e5
END_OF_LEVEL_HIGH_BYTE = $1f

update_level
  ; check if the level is completed; set current_level to next_level if so
  lda level_completed
  cmp #LEVEL_IS_DONE ; (try optimizing later)
  bne dont_update
  
  ; level is done; reset level completed
  lda #LEVEL_NOT_DONE
  sta level_completed

  ; now set current_level to next_level
  lda next_level
  sta current_level
  lda next_level+1
  sta current_level+1

  lda #0
  sta count_chars_drawn

dont_update
; now check if level reset was set
  lda level_reset
  cmp #0
  bne continue_update ; if not, go back to game loop
  rts

continue_update
  ; if it was, update the level
  lda #LEVEL_BEGINNING_LOW_BYTE
  sta screen_cursor
  lda #LEVEL_BEGINNING_HIGH_BYTE
  sta screen_cursor+1

  lda #LEVEL_COLOR_BEGINNING_LOW_BYTE
  sta color_cursor
  lda #LEVEL_COLOR_BEGINNING_HIGH_BYTE
  sta color_cursor+1

  ldx #0
  ldy #0
  sty level_data_index
  
  lda #0
  sta jump_info
  sta attached_powerups
  sta attached_powerups+1
  sta tile_store
  sta tile_store+1
  sta tile_store+2

  ; draw (or redraw on reset) the current level
draw_level_loop
; y stores our index in the current level data
  jsr check_if_level_cursor_at_end
  bcs update_level_return

  ldy level_data_index
  lda (current_level),y ; accumulator stores the number of times to repeat the next byte  

  jsr draw_sequence

  ldy level_data_index
  iny ; set y to point to next length byte (iterate 2 at a time)
  iny
  sty level_data_index
  jmp draw_level_loop


update_level_return
  ; update next level pointer to point to byte after current level
  lda current_level
  clc
  adc level_data_index
  sta next_level
  lda current_level+1
  adc #0
  sta next_level+1
  rts
  


draw_sequence
; if acc == 0, return; otherwise subtract 1, draw the next 2 chars
  beq draw_sequence_end
  sec
  sbc #1
  pha ; push accumulator onto stack

  ldy level_data_index
  iny ; (so we can access the "element" byte after the length byte)
  lda (current_level),y ; get formatted byte (see squarebot doc)
  asl ; lol
  asl
  asl
  asl 
  jsr draw_high_bits ; draw char represented by the 4 high bits
  
  ldy level_data_index
  iny

  lda (current_level),y 
  jsr draw_high_bits

  pla 
  jmp draw_sequence

draw_sequence_end
  rts


; put the character in the high 4 bits of accumulator on screen (see readme), and move the color and screen cursors ahead
draw_high_bits
  and #240 ; shave off last 4 bits

  cmp #BLANK_SPACE
  bne check_if_starting_point
  lda #BLANK_TILE_CHAR ; todo; replace with actual chars
  ldx #1
  jsr draw_char_in_accumulator
  rts

check_if_starting_point
  cmp #STARTING_POINT
  bne check_if_wall
  
   ; set squarebot to starting point
  lda screen_cursor
  sta squarebot_position
  lda screen_cursor+1
  sta squarebot_position+1

  lda color_cursor
  sta squarebot_color_position
  lda color_cursor+1
  sta squarebot_color_position+1

  lda #SQUAREBOT_CHAR
  ldx #SQUAREBOT_COLOR
  jsr draw_char_in_accumulator
  rts

check_if_wall
  cmp #WALL
  bne check_if_breakable_wall
  lda #WALL_CHAR 
  ldx #WALL_COLOR
  jsr draw_char_in_accumulator
  rts
  
check_if_breakable_wall
  cmp #BREAKABLE_WALL
  bne check_if_locked_wall
  lda #BREAKABLE_WALL_CHAR
  ldx #BREAKABLE_WALL_COLOR
  jsr draw_char_in_accumulator
  rts

check_if_locked_wall
  cmp #LOCKED_WALL
  bne check_if_ladder
  lda #LOCKED_WALL_CHAR
  ldx #LOCKED_WALL_COLOR
  jsr draw_char_in_accumulator
  rts

check_if_ladder
  cmp #LADDER
  bne check_if_exit
  lda #LADDER_CHAR
  ldx #LADDER_COLOR
  jsr draw_char_in_accumulator
  rts

check_if_exit
  cmp #EXIT
  bne check_if_platform
  lda #EXIT_CHAR
  ldx #EXIT_COLOR
  jsr draw_char_in_accumulator
  rts

check_if_platform
  cmp #PLATFORM
  bne check_if_key
  lda #PLATFORM_CHAR
  ldx #PLATFORM_COLOR
  jsr draw_char_in_accumulator
  rts

check_if_key
  cmp #KEY
  bne check_if_spike
  lda #KEY_P_CHAR
  ldx #KEY_P_COLOR
  jsr draw_char_in_accumulator
  rts

check_if_spike
  cmp #SPIKE
  bne check_if_booster
  lda #SPIKE_P_CHAR
  ldx #SPIKE_P_COLOR
  jsr draw_char_in_accumulator
  rts
  
check_if_booster
  lda #BOOSTER_P_CHAR
  ldx #BOOSTER_P_COLOR
  jsr draw_char_in_accumulator
  rts



; char in accumulator goes in screen cursor, color in x register goes in color cursor, then update cursors

draw_char_in_accumulator
  ldy #0
  sta (screen_cursor),y

  txa
  sta (color_cursor),y

  jsr add_one_to_screen_cursor ; add to both screen and color cursor
  jsr update_screen_position_if_on_border
  rts



update_screen_position_if_on_border
  lda count_chars_drawn
  cmp #19
  bne add_and_return
  lda #0
  sta count_chars_drawn
  jsr add_one_to_screen_cursor
  jsr add_one_to_screen_cursor
  rts

  
add_and_return
  clc
  adc #1
  sta count_chars_drawn
  rts

check_if_level_cursor_at_end ; set carry flag if screen_cursor at position $1ff9 (8185
  lda screen_cursor ; load value at screen_cursor low byte
  cmp #END_OF_LEVEL_LOW_BYTE
  bne check_if_level_cursor_at_end_return_false ; if low byte doesnt match, return with carry flag as neg
  
  lda screen_cursor+1
  cmp #END_OF_LEVEL_HIGH_BYTE
  beq check_if_level_cursor_at_end_return_true ; if high byte matches, set carry flag

check_if_level_cursor_at_end_return_false
  clc
  rts

check_if_level_cursor_at_end_return_true
  sec
  rts 