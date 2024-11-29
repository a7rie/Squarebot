; title screen program -- use hand-made compression method (esentially just RLE, see rleEncoding.py)
  processor 6502

  seg.u ZP
  org $0


screen_cursor ds.w 1  ; stores the current screen memory address
color_cursor ds.w 1 ; store current color memory address
current_level ds.w 1
next_level ds.w 1
level_reset ds.b 1
level_completed ds.b 1
level_data_index ds.b 1 ; for temporarily saving index registers
temp ds.b 1 ; for temporarily saving index registers
new_position ds.w 1 ; use to store position of (proposed) new location for squarebot
new_color_position ds.w 1 ; use to store position of (proposed) new location for squarebot
current_time ds.b 1 ; store only the last byte of the jiffy clock
squarebot_position ds.w 1
squarebot_color_position ds.w 1
has_key ds.b 1
has_booster ds.b 1
jump_remaining ds.b 1 ; number of times the character should continue to move upwards in the current jump
  seg

; constants
BLANK_CHAR = $20

SCREEN_CURSOR_BEGINNING_LOW_BYTE = $00
SCREEN_CURSOR_BEGINNING_HIGH_BYTE = $1e
BACKGROUND_COLOR_BYTE = $900f

; last screen location
END_OF_SCREEN_LOW_BYTE = $fa
END_OF_SCREEN_HIGH_BYTE = $1f

; beginning of color memory
COLOR_CURSOR_BEGINNING_LOW_BYTE = $00
COLOR_CURSOR_BEGINNING_HIGH_BYTE = $96
RED_COLOR_CODE = 0

SPACE_KEY = $20
ENTER_KEY = $0f
W_KEY = $09
A_KEY = $11
S_KEY = $29
D_KEY = $12
SECRET_KEY = $0d ; press P to skip to next  level
RESET_KEY = $34
JUMP_SIZE = $4 ; number of characters a jump causes
ROW_SIZE = $16

; memory locations
user_memory_start = $1001
currently_pressed_key =  $c5
jiffy_clock = $A0
character_info_register = $9005
character_set_begin = $1c00

  ; begin location counter at 4096 (user memory)
  org user_memory_start
  include "stub.s" ; stub contains BASIC sys cmd to run the machine language code

start  
  LDA #14 ; black screen blue border
  STA BACKGROUND_COLOR_BYTE

  ; use combination of RAM (first 128 chars at 7168) & ROM character set
  lda #255
  sta character_info_register

  ; initialize some variables in the zero page
  lda #1
  sta level_reset
  lda #0
  sta level_completed

  lda #<level_data_start
  sta current_level
  lda #>level_data_start
  sta current_level+1

  lda #0
  sta jump_remaining
  sta has_booster
  sta has_key

  include "titleScreen.s"  


; title screen code jumps here once space pressed
gameLoop
  jsr update_level
  lda #0
  sta level_reset
  jsr update_game_state
  jsr check_for_secret_key
  jsr check_for_reset_key
  jsr wait_until_next_frame
  jsr wait_until_next_frame
  jsr wait_until_next_frame
  jsr wait_until_next_frame
  JMP gameLoop


wait_until_next_frame ; wait one jiffy before completing game loop
  lda jiffy_clock+2
  cmp current_time
  beq wait_until_next_frame
  sta current_time
  rts

; update level_completed and level_reset if secret_key pressed
check_for_secret_key
  lda currently_pressed_key
  cmp #SECRET_KEY
  bne check_for_secret_key_return
  lda #1
  sta level_completed
  lda #1
  sta level_reset

check_for_secret_key_return
  rts


check_for_reset_key
  lda currently_pressed_key
  cmp #RESET_KEY
  bne check_for_secret_key_return ; todo -- reset  a bunch of state (has_key, )
  lda #1
  sta level_reset
  lda #0
  sta has_booster
  sta has_key
  sta jump_remaining
  
check_for_reset_key_return
  rts

  include "updateLevel.s"
  include "updateGameState.s"

compressed_screen_data_start
  incbin "../data/titleScreenData_compressed" ; got via 'bsave ""'

level_data_start
  incbin "../data/levels/binary_levels/1"
  incbin "../data/levels/binary_levels/2"
  incbin "../data/levels/binary_levels/3"
  incbin "../data/levels/binary_levels/4"
  incbin "../data/levels/binary_levels/5"
  incbin "../data/levels/binary_levels/6"
  incbin "../data/levels/binary_levels/7"
  incbin "../data/levels/binary_levels/8"
  incbin "../data/levels/binary_levels/9"
  incbin "../data/levels/binary_levels/10"

  include "memoryCheck.s" ; code to make sure the program isn't too large and enters screen memory


  org character_set_begin
  BYTE 129,255,255,129,129,255,255,129 ; ladder 0
  BYTE 255,129,165,129,165,153,129,255 ; squarebot 1
  BYTE 255,255,0,0,0,0,0,0 ; platform 2
  BYTE 255,255,255,255,255,255,255,255 ; wall 3
  BYTE 126,231,129,129,225,129,129,255 ; exit (door) 4
  BYTE 24,36,24,24,30,24,30,24 ; key powerup 5 
  BYTE 255,255,239,239,239,227,255,255 ;locked wall 6
  BYTE 255,189,253,183,127,239,231,255 ; breakable wall 7
  BYTE 0,0,24,60,126,126,0,0 ; spike 8
  BYTE 0,112,72,120,72,72,112,0 ; booster powerup 9