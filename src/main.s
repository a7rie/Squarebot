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
current_time ds 3 ; store only the last byte of the jiffy clock

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
RED_COLOR_CODE = 2
SPACE_KEY = $20

SECRET_KEY = $0d ; translates to "P"

; memory locations
user_memory_start = $1001
currently_pressed_key =  $c5
jiffy_clock = $A0



  ; begin location counter at 4096 (user memory)
  org user_memory_start
  include "stub.s" ; stub contains BASIC sys cmd to run the machine language code

start  
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


  include "titleScreen.s"  


; title screen code jumps here once space pressed
gameLoop
  jsr update_level
  lda #0
  sta level_reset

  jsr check_for_secret_key
  jsr wait_until_next_frame
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

  include "updateLevel.s"


compressed_screen_data_start
  incbin "../data/titleScreenData_compressed" ; got via 'bsave ""'

level_data_start
  incbin "../data/levels/binary_levels/1"
  incbin "../data/levels/binary_levels/2"
  incbin "../data/levels/binary_levels/3"
  incbin "../data/levels/binary_levels/4"

  include "memoryCheck.s" ; code to make sure the program isn't too large and enters screen memory