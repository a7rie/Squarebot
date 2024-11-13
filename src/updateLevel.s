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
BOOSTER = 160 ;  10100000

WALL_COLOR = 0
BREAKABLE_WALL_COLOR = 0
LOCKED_WALL_COLOR = 0
LADDER_COLOR = 0
EXIT_COLOR = 0
PLATFORM_COLOR = 0
KEY_COLOR = 0
SPIKE_COLOR = 0
BOOSTER_COLOR = 0

BLANK_SPACE_CHAR = $20 
WALL_CHAR = $3
BREAKABLE_WALL_CHAR = $7
LOCKED_WALL_CHAR = $6
LADDER_CHAR = $0  
EXIT_CHAR = $4
PLATFORM_CHAR = $2
KEY_CHAR =  $5
SPIKE_CHAR = $8
BOOSTER_CHAR = $9


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

dont_update
; now check if level reset was set
  lda level_reset
  cmp #0
  bne continue_update ; if not, go back to game loop
  rts

continue_update
  ; if it was, update the level
  lda #SCREEN_CURSOR_BEGINNING_LOW_BYTE
  sta screen_cursor
  lda #SCREEN_CURSOR_BEGINNING_HIGH_BYTE
  sta screen_cursor+1

  lda #COLOR_CURSOR_BEGINNING_LOW_BYTE
  sta color_cursor
  lda #COLOR_CURSOR_BEGINNING_HIGH_BYTE
  sta color_cursor+1

  ldx #0
  ldy #0
  sty level_data_index
  ; draw (or redraw) the current level
draw_level_loop
; y stores our index in the current level data
  ldy level_data_index
  lda (current_level),y ; accumulator stores the number of times to repeat the next byte  

  jsr draw_sequence

  ldy level_data_index
  iny ; set y to point to next length byte (iterate 2 at a time)
  iny
  sty level_data_index


  jsr check_if_screen_cursor_at_end
  bcc draw_level_loop


  ; update next level pointer to point to byte after current level
  lda current_level
  clc
  adc level_data_index
  sta next_level
  lda current_level+1
  adc #0
  sta next_level+1
  rts
  


; i love writing decompression code in assembly. i love writing decompression code in assembly. i love writing decompression code in assembly. 
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
  lda #BLANK_SPACE_CHAR ; todo; replace with actual chars
  ldx #1
  jsr draw_char_in_accumulator
  rts

check_if_starting_point
  cmp #STARTING_POINT
  bne check_if_wall
  lda #$1 ; fix later will need to update squarre bot position
  ldx #0
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
  lda #KEY_CHAR
  ldx #KEY_COLOR
  jsr draw_char_in_accumulator
  rts

check_if_spike
  cmp #SPIKE
  bne check_if_booster
  lda #SPIKE_CHAR
  ldx #SPIKE_COLOR
  jsr draw_char_in_accumulator
  rts
  
check_if_booster
  lda #BOOSTER_CHAR
  ldx #BOOSTER_COLOR
  jsr draw_char_in_accumulator
  rts


; char in accumulator goes in screen cursor, color in x register goes in color cursor, then update cursors

draw_char_in_accumulator
  ldy #0
  sta (screen_cursor),y

  txa
  sta (color_cursor),y

  jsr add_one_to_screen_cursor ; add to both screen and color cursor
  rts
