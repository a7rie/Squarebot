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
new_position ds.w 1 ; use to store position of (proposed) new location for squarebot
new_color_position ds.w 1 ; use to store position of (proposed) new location for squarebot
current_time ds.b 1 ; store only the last byte of the jiffy clock
squarebot_position ds.w 1
squarebot_color_position ds.w 1
has_key ds.b 1
has_booster ds.b 1
jump_remaining ds.b 1 ; number of times the character should continue to move upwards in the current jump
tileStore ds.b 3 ; UUUUDDDD LLLLRRRR 0000MMMM
;colorStore ds.b 3 ; 0UUU0DDD 0LLL0RRR 00000MMM   not the most efficient storage but it needs to also be efficient to decompress
attached_powerups ds.b 2; 4 bits for each side, ordered U,D,L,R. 0=none 1=boost 2=activeBoost 3=key 4=spike 5=shield
temp ds.w 1 ; for temporary storage of things. mainly used in updateGameState
charandr ds.b 3 ; for the incredibly complex operation of anding chars
  seg

; constants
BLANK_CHAR = $20

SCREEN_CURSOR_BEGINNING_LOW_BYTE = $00
SCREEN_CURSOR_BEGINNING_HIGH_BYTE = $1e

; last screen location
END_OF_SCREEN_LOW_BYTE = $fa
END_OF_SCREEN_HIGH_BYTE = $1f

; beginning of color memory
COLOR_CURSOR_BEGINNING_LOW_BYTE = $00
COLOR_CURSOR_BEGINNING_HIGH_BYTE = $96
RED_COLOR_CODE = 0

SPACE_KEY = $20
W_KEY = $09
A_KEY = $11
S_KEY = $29
D_KEY = $12
SECRET_KEY = $0d ; press P to skip to next  level
RESET_KEY = $0a ; press R to restart level i assume
JUMP_SIZE = $3 ; number of characters a jump causes
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
  jsr wait_until_next_frame
  jsr wait_until_next_frame
  jmp gameLoop


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
  rts ; what is this for?


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
  sta attached_powerups
  sta attached_powerups+1
  
check_for_reset_key_return
  rts ; what is this for?

  include "updateLevel.s"
  include "updateGameState_new.s"
  include "updateGameStateHelper.s"

compressed_screen_data_start
  incbin "../data/titleScreenData_compressed" ; got via 'bsave ""'

level_data_start
  incbin "../data/levels/binary_levels/1"
  incbin "../data/levels/binary_levels/booster_test"
  incbin "../data/levels/binary_levels/key_test"
  incbin "../data/levels/binary_levels/2"
  incbin "../data/levels/binary_levels/3"
  incbin "../data/levels/binary_levels/4"
  incbin "../data/levels/binary_levels/5"
  incbin "../data/levels/binary_levels/6"

  include "memoryCheck.s" ; code to make sure the program isn't too large and enters screen memory


  org character_set_begin
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; blank 0
  BYTE $7E, $42, $7E, $42, $7E, $42, $7E, $42 ; ladder 1
  BYTE $FF, $5A, $00, $00, $00, $00, $00, $00 ; platform 2
  BYTE $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; wall 3
  BYTE $FF, $9D, $A3, $AC, $A5, $99, $C3, $FF ; exit (door) 4
  BYTE $FF, $FF, $C3, $C3, $E7, $E7, $E7, $FF ; locked wall 5
  BYTE $FF, $EE, $F1, $EF, $57, $8F, $F3, $FF ; breakable wall 6
  BYTE $3C, $42, $99, $BD, $89, $91, $42, $3C ; booster powerup 7
  BYTE $3C, $42, $99, $99, $91, $99, $42, $3C ; key powerup 8
  BYTE $3C, $42, $91, $99, $BD, $81, $42, $3C ; spike powerup 9
  BYTE $08, $38, $F0, $F0, $F0, $F0, $38, $08 ; booster attachment (R) 10
  BYTE $08, $38, $F1, $FF, $FE, $F1, $38, $08 ; activated booster attachment (R) 11
  BYTE $00, $00, $FE, $FE, $6A, $0A, $0E, $00 ; key attachment (R) 12
  BYTE $80, $C0, $F0, $FE, $F0, $C0, $80, $00 ; spike attachment (R) 13
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; charU 14
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; charD 15
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; charL 16
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; charR 17
  BYTE $FF, $81, $A5, $81, $BD, $81, $81, $FF ; squarebot 18