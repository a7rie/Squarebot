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
jump_dir ds.b 1 ; 0 = up, 1=left, 2=right
jump_num ds.b 1
tile_store ds.b 5
;colorStore ds.b 5 ; U, D, L, R, M  not the most efficient storage but it needs to also be efficient to decompress
attached_powerups ds.b 4
; $0=none  $1=ignitedBooster $A=readyBooster  $B=activeBooster  $C=key  $D=spike(change into shield)
delta ds.b 5 ; U D L R M
chars ds.b 4
temp ds.b 4 ; for temporary storage of things. mainly used in updateGameState
move_dir_store ds.b 1 ; exclusively for move_dir and related subroutines
chareor ds.b 3 ; for the incredibly complex operation of eoring chars
count_chars_drawn ds.b 1 ; count number of chars drawn on screen in the current run
temp_a ds.b 1 ; store acc
temp_x ds.b 1 ; store x
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
Q_KEY = $30
W_KEY = $09
E_KEY = $31
A_KEY = $11
S_KEY = $29
D_KEY = $12
SECRET_KEY = $0d ; press P to skip to next  level
RESET_KEY = $0a ; press R to restart level i assume
JUMP_SIZE = $01 ; number of characters a jump causes
ROW_SIZE = $16

; memory locations
user_memory_start = $1001
currently_pressed_key =  $c5 ;proposed fix: mem editor 028 abc space bar loops
jiffy_clock = $A0
character_info_register = $9005
character_set_begin = $1c00
tile_store_addr = $16
attached_powerups_addr = $1b
delta_addr = $1f
chars_addr = $24

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
  sta count_chars_drawn
  sta jump_num
  sta jump_dir
  sta attached_powerups
  sta attached_powerups+1
  sta attached_powerups+2
  sta attached_powerups+3
  sta tile_store
  sta tile_store+1
  sta tile_store+2
  sta tile_store+3
  sta tile_store+4
  sta temp
  sta temp+1
  sta temp+2
  sta temp+3
  lda #1 ; up
  sta delta
  lda #[ROW_SIZE+ROW_SIZE+1] ; down
  sta delta+1
  lda #ROW_SIZE ; left
  sta delta+2
  lda #[ROW_SIZE+2] ; right
  sta delta+3
  lda #[ROW_SIZE+1] ; mid
  sta delta+4
  lda #CHAR_U ; index of powerup characters
  sta chars
  lda #CHAR_D
  sta chars+1
  lda #CHAR_L
  sta chars+2
  lda #CHAR_R
  sta chars+3

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
  jsr delete_squarebot
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
  jsr delete_squarebot
  lda #1
  sta level_reset
check_for_reset_key_return
  rts

  include "updateLevel.s"
  include "updateGameState_new.s"
  include "updateGameStateHelper.s"

compressed_screen_data_start
  incbin "../data/titleScreenData_compressed" 

level_data_start
  incbin "../data/levels/binary_levels/jesse_1"
  incbin "../data/levels/binary_levels/jesse_2"
  incbin "../data/levels/binary_levels/jesse_3"
  incbin "../data/levels/binary_levels/amin_1"
  incbin "../data/levels/binary_levels/amin_2"
  incbin "../data/levels/binary_levels/amin_3"
  incbin "../data/levels/binary_levels/amin_4"
  incbin "../data/levels/binary_levels/jesse_4"
  incbin "../data/levels/binary_levels/jesse_5"
  incbin "../data/levels/binary_levels/jesse_6"
  incbin "../data/levels/binary_levels/jesse_7"
  ; byte 2469
  ;copy paste script: python generateLevelBinary.py ascii_levels/<> binary_levels/<>

  org character_set_begin ; starts at byte 3079 i think
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; blank 0
  BYTE $7E, $42, $7E, $42, $7E, $42, $7E, $42 ; ladder 1
  BYTE $FF, $5A, $00, $00, $00, $00, $00, $00 ; platform 2
  BYTE $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF ; wall 3
  BYTE 0,60,98,94,86,102,60,0 ; exit (door) 4
  BYTE 255,129,157,161,173,153,129,255 ; locked exit 5
  BYTE 255,231,219,219,129,129,129,255 ; locked wall 6
  BYTE $FF, $EE, $F1, $EF, $57, $8F, $F3, $FF ; breakable wall 7
  BYTE 18,214,124,63,252,62,107,72 ; spike ball 8                     PETSCII WHY?? I CAN'T READ THIS!
  BYTE 24,60,60,60,126,82,8,36 ; booster powerup 9
  BYTE 24,36,36,24,16,24,16,24 ; key powerup A
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; empty B
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; empty C
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; empty D
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; empty E
  
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; charU F
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; charD 10
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; charL 11
  BYTE $00, $00, $00, $00, $00, $00, $00, $00 ; charR 12
  BYTE $FF, $81, $A5, $81, $BD, $81, $81, $FF ; squarebot 13 

  ; attachments
  BYTE 0,0,0,0,195,126,126,60 ; ready booster attachment up 14
  BYTE 60,126,126,195,0,0,0,0 ; rb down 15
  BYTE 8,14,7,7,7,7,14,8 ; rb left 16
  BYTE 16,112,224,224,224,224,112,16 ; rb right 17
  BYTE 60,126,60,24,219,126,126,60 ; active booster attachment up 18
  BYTE 60,126,126,219,24,60,126,60 ; ab down 19
  BYTE 8,78,231,255,255,231,78,8 ; ab left 1A
  BYTE 16,114,231,255,255,231,114,16 ; ab right 1B
  BYTE 0,30,20,30,24,24,24,60 ; key attachment up 1C
  BYTE 60,24,24,24,30,20,30,0 ; key down 1D
  BYTE 0,0,1,127,95,113,80,0 ; key left 1E
  BYTE 0,0,128,254,250,142,10,0 ; key right 1F
  
  ; for the title screen.......
  BYTE 255,128,128,128,128,129,131,135 ;20
  BYTE 255,0,0,0,192,224,48,248 ;21
  BYTE 255,0,0,0,0,0,0,0 ;22
  BYTE 255,1,1,1,1,1,1,1 ;23
  BYTE 143,155,131,131,128,128,128,128 ;24
  BYTE 224,224,224,224,0,0,0,0 ;25
  BYTE 1,7,31,7,7,7,0,0 ;26
  BYTE 241,193,193,193,193,193,1,1 ;27
  BYTE 128,128,129,128,152,152,156,143 ;28
  BYTE 0,0,192,112,30,3,0,255 ;29
  BYTE 0,0,0,0,0,128,240,28 ;2A
  BYTE 1,1,1,1,1,1,1,1 ;2B
  BYTE 143,159,159,158,128,128,128,255 ;2C
  BYTE 255,0,0,0,0,0,0,255 ;2D
  BYTE 7,0,0,0,0,0,0,255 ;2E
  BYTE 129,193,1,1,1,1,1,255 ;2F
  ;byte 3455
  include "memoryCheck.s" ; code to make sure the program isn't too large and enters screen memory

  ;possible optimizations:
  ;shift character set begin as far as i can
  ;generalize 16 bit arithmetic
  ;reuse switch statements