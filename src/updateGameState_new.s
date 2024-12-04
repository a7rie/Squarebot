START_OF_FIRST_ROW_LOW_BYTE = $e4
START_OF_FIRST_ROW_HIGH_BYTE = $1f

; main logic until line 113:
update_game_state
  lda squarebot_position ; likely unnecessary
  sta new_position
  lda squarebot_position+1
  sta new_position+1
  lda squarebot_color_position
  sta new_color_position
  lda squarebot_color_position+1
  sta new_color_position+1

jump_logic
  lda jump_num
  cmp #$00
  beq fall_logic
  ldy #0 ; up
  jsr move_dir
  bcs j_cont ; jump successful
  lda #$00 ; jump failed
  sta jump_num
  jmp update_return
j_cont
  sec
  dec jump_num
j_left
  lda jump_dir
  cmp #$01
  bne j_right
  jsr wait_until_next_frame
  ldy #2 ; left
  jsr move_dir
  jmp update_return
j_right
  cmp #$02
  bne update_return
  jsr wait_until_next_frame
  ldy #3 ; right
  jsr move_dir
  jmp update_return

fall_logic
  lda tile_store+1 ; down
  jsr fall_check ; check if we hit the ground, different from collision_handler since platforms are included
  bcc check_if_space_pressed
  ldy #1 ; down
  jsr move_dir
  lda tile_store+1 ; check if we hit ground again, if we didn't we can move in the jump_dir
  jsr fall_check
  bcs f_left
  lda #$00 ; otherwise we stay still
  sta jump_dir
  jmp update_return
f_left
  lda jump_dir
  cmp #$01
  bne f_right
  jsr wait_until_next_frame
  ldy #2 ; left
  jsr move_dir
  jmp update_return
f_right
  cmp #$02
  bne update_return
  jsr wait_until_next_frame
  ldy #3 ; right
  jsr move_dir
  jmp update_return

update_return
  clc ; reset numbers that should be
  lda #0
  sta temp
  sta temp+1
  sta temp+2
  sta temp+3
  rts

check_if_space_pressed
  lda currently_pressed_key
  cmp #SPACE_KEY
  bne check_if_q_pressed
  ldy #0 ; up
  jsr move_dir
  bcc update_return ; jump failed
  lda #JUMP_SIZE
  sta jump_num
  lda #$00
  sta jump_dir
  jmp update_return

check_if_q_pressed
  lda currently_pressed_key
  cmp #Q_KEY
  bne check_if_e_pressed
  ldy #0 ; up
  jsr move_dir
  bcc update_return ; jump failed
  lda #JUMP_SIZE
  sta jump_num
  lda #$01
  sta jump_dir
  jsr wait_until_next_frame
  ldy #2 ; left
  jsr move_dir
  jmp update_return

check_if_e_pressed
  cmp #E_KEY
  bne check_if_a_pressed
  ldy #0 ; up
  jsr move_dir
  bcc update_return ; jump failed
  lda #JUMP_SIZE
  sta jump_num
  lda #$02
  sta jump_dir
  jsr wait_until_next_frame
  ldy #3 ; right
  jsr move_dir
  jmp update_return

check_if_a_pressed
  cmp #A_KEY
  bne check_if_d_pressed
  ldy #2 ; left
  jsr move_dir
  jmp update_return

check_if_d_pressed
  cmp #D_KEY
  bne update_return
  ldy #3 ; right
  jsr move_dir
  jmp update_return

; The rest is subroutines

;current bugs:
;attached powerup sprites are not working
;jump direction is not reset properly
;platforms get deleted sometimes
;need to replace end screen



;store tile you are moving to
;if you win, win
;check collision:
;  store powerup in temp
;  return whether you can move or not
;if you can't move, return false
;apply powerups you moved into
;get new position
;refresh tiles
;apply powerup logic
;delete old position
;update position
;redraw chars
;draw new position
;wait a jiffy maybe
;check booster if we move again
move_dir
  sty move_dir_store
  lda (tile_store),y ; load colliding tile
  cmp #EXIT_CHAR
  bne cont_move
  lda #1 ; level complete
  sta level_completed
  sta level_reset
  jmp return_false_move
cont_move
  jsr collision_handler
  bcc return_false_move
  lda temp ; if we hit a powerup this will be its id
  cmp #$00
  beq post_powerup_move
  sta (attached_powerups),y ; attach powerup
  lda #$00
  sta (tile_store),y ; remove the powerup tile from the level
post_powerup_move
  jsr delete_squarebot
  ldy move_dir_store
  jsr move_new_position
  jsr get_tiles
  lda #$01 ; eor y with 1 to get opposite side
  eor move_dir_store
  tay
  lda (attached_powerups),y ; ignite ready booster
  cmp #$0A
  bne post_booster
  lda #$01
  sta (attached_powerups),y
post_booster
  jsr apply_powerup_logic
  jsr update_squarebot
  jsr update_chars
  jsr draw_squarebot
  jsr wait_until_next_frame
  lda #$01 ; eor y with 1 to get opposite side
  eor move_dir_store
  tay
  lda (attached_powerups),y
  cmp #$0B
  ldy move_dir_store
  beq move_dir ; if booster activated go again
  sec
  rts ; return true move
return_false_move
  clc
  rts

;-----
collision_handler ; accumulator is the character in the position that squarebot wants to move to
; set carry flag if we can move to this char, otherwise clear it
; if its a powerup, set temp to be the attached_powerup id + attached_powerup id <<4, otherwise return since temp is already 0
  cmp #BLANK_TILE_CHAR
  beq return_true
  cmp #PLATFORM_CHAR
  beq return_true ; moving down will double check anyway
  cmp #LADDER_CHAR
  beq return_true ; not fully implemented though
  cmp #WALL_CHAR
  beq return_false
  cmp #BREAKABLE_WALL_CHAR
  beq return_false
  cmp #LOCKED_WALL_CHAR
  beq return_false
  ;else its a powerup
  cmp #BOOSTER_P_CHAR
  bne rpk
  lda #$0A ;set both hex characters to avoid dumb shifts taking up lots of space
  sta temp
  jmp return_true
rpk
  cmp #KEY_P_CHAR
  bne rps
  lda #$0C
  sta temp
  jmp return_true
rps
  cmp #SPIKE_P_CHAR ; not functional
  bne return_false
  lda #$0D
  sta temp
  jmp return_true

return_true
  sec
  rts

return_false
  clc
  rts

;-----
fall_check
  cmp #PLATFORM_CHAR
  beq return_false
  cmp #WALL_CHAR
  beq return_false
  cmp #LOCKED_WALL_CHAR
  beq return_false
  cmp #BREAKABLE_WALL_CHAR
  beq return_false
  cmp #LADDER_CHAR
  beq return_false
  jmp return_true;

;-----
delete_squarebot
  jsr get_squarebot_draw_position

  ldy #DELTA_U
  lda tile_store ; up
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  ldy #DELTA_D
  lda tile_store+1 ;down
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  ldy #DELTA_L
  lda tile_store+2 ; left
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  ldy #DELTA_R
  lda tile_store+3 ;right
  sta (squarebot_position),y
  lda #0

  ldy #DELTA_M
  lda tile_store+4 ; mid
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  jsr get_squarebot_game_position
  rts

;-----
move_new_position
  jsr get_new_draw_position

  clc
  lda new_position
  adc (DELTA_U),y ; y is the index of the move_dir
  sta new_position
  lda new_position+1
  adc #0
  sta new_position+1
  clc
  lda new_color_position
  adc (DELTA_U),y
  sta new_color_position
  lda new_color_position+1
  adc #0
  sta new_position+1
  clc
  rts ; no need to undo get_new_draw_position

;-----
get_tiles
  jsr get_new_draw_position

  lda tile_store+4 ; get mid
  lda #$01 ; eor move_dir with 1 to get opposite side
  eor move_dir_store
  tay
  sta (tile_store),y ; set opposite dir

  ldy move_dir_store
  lda (tile_store),y ;get dir
  sta tile_store+4 ; set mid

  lda (DELTA_U),y
  tay
  lda (new_position),y ; get tile_dir
  ldy move_dir_store
  sta (tile_store),y  ; set tile_dir

  lda #$02 ; get perpendicular tiles
  eor move_dir_store
  tay ; eor move_dir with 2 to get perpendicular directions
  sta temp
  lda (DELTA_U),y
  tay
  lda (new_position),y
  ldy temp
  sta (tile_store),y

  lda #$01
  eor temp
  tay
  sta temp
  lda (DELTA_U),y
  tay
  lda (new_position),y
  ldy temp
  sta (tile_store),y

  jsr get_new_game_position
  rts

;-----
apply_powerup_logic
  ;call prepare_logic for index temp+3 = 0,1,2, and 3. store index in temp+3 since we change y often
  lda #$0
  sta temp+3
  tay
  jsr prepare_logic
  inc temp+3
  jsr prepare_logic
  inc temp+3
  jsr prepare_logic
  inc temp+3
  jsr prepare_logic
  lda #$0
  sta temp
  sta temp+1
  sta temp+2
  sta temp+3
  tay ; clean up just to be safe
  rts

  ;temp = powerup,   temp+1 = tile behind powerup,   temp+2 = tile opposite powerup
prepare_logic
  ldy temp+3
  lda (attached_powerups),y
  sta temp
  lda (tile_store),y
  sta temp+1
  lda #$01
  eor temp+3
  tay ; eor with 1 which gets us the tile opposite the powerup
  lda (tile_store),y
  sta temp+2
  jsr powerup_logic ; perform logic
  ldy temp+3
  lda temp
  sta (attached_powerups),y
  lda temp+1
  sta (tile_store),y
  lda #$01
  eor temp+3
  tay
  lda temp+2
  sta (tile_store),y
  rts
  
; ready booster: does nothing
; ignited booster: breaks breakable walls and changes to active booster 
; active booster: breaks breakable walls and changes to ready booster
; key: spends itself to break locked walls
powerup_logic ;temp = powerup,   temp+1 = tile behind powerup,   temp+2 = tile opposite powerup
  lda temp
  cmp #$01 ; check ignited booster
  bne pl_b
  lda temp+2 ; check opposite tile
  cmp #BREAKABLE_WALL_CHAR
  bne pl_ab
  lda #$00
  sta temp+2 ; delete wall
pl_ab
  lda #$0B ; set active booster
  sta temp
  jmp pl_return
pl_b
  cmp #$0B ; check active booster
  bne pl_k
  lda temp+2 ; check opposite tile
  cmp #BREAKABLE_WALL_CHAR
  bne pl_rb
  lda #$00
  sta temp+2 ; delete wall
pl_rb
  lda #$0A ; set ready booster
  sta temp
  jmp pl_return
pl_k
  cmp #$0C ; check key, slightly unnecessary
  bne pl_return
  lda temp+1
  cmp #LOCKED_WALL_CHAR
  bne pl_return
  lda #$00
  sta temp ; delete key
  sta temp+1 ; delete wall
  jmp pl_return
pl_return
  rts ;-64 lines optimized

;-----
update_squarebot
  lda new_position
  sta squarebot_position
  lda new_position+1
  sta squarebot_position+1

  lda new_color_position
  sta squarebot_color_position
  lda new_color_position+1
  sta squarebot_color_position+1
  rts

;-----
update_chars ; chareor = tile*8,   chareor+1 = powerup*8,   chareor+2 = char*8
  ldy #$0
  sty temp+1 ; x and temp are being used by update_char

update_char_dir_loop
  lda (tile_store),y
  asl
  asl
  asl ; multiply by 8 since there are 8 bytes per character
  sta chareor
  lda (attached_powerups),y
  ;add index for rotation
  asl
  asl
  asl
  sta chareor+1
  lda (CHAR_U),y
  asl
  asl
  asl
  sta chareor+2
  jsr update_char
  inc temp+1
  ldy temp+1

  cpy #4
  bne update_char_dir_loop

  rts

update_char ; chareor = tile*8,   chareor+1 = powerup*8,   chareor+2 = char*8
  ldx #0 ; x is the incrementer
update_char_loop
  txa
  clc
  adc chareor
  tay
  lda (#character_set_begin),y
  sta temp

  txa
  clc
  adc chareor+1
  tay
  lda (#character_set_begin),y
  eor temp
  sta temp

  txa
  clc
  adc chareor+2
  tay
  lda temp
  sta (#character_set_begin),y

  inx
  cpx #8
  bne update_char_loop

  rts

; if there is a powerup:
; for each of 8 bytes:
; load tile byte
; eor with powerup tile byte
; store in char byte

;-----
draw_squarebot
  jsr get_squarebot_draw_position

  lda #CHAR_U
  ldy #1
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  lda #CHAR_D
  ldy #[[ROW_SIZE*2]+1]
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  lda #CHAR_L
  ldy #ROW_SIZE
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  lda #CHAR_R
  ldy #[ROW_SIZE+2]
  sta (squarebot_position),y
  lda #0
  sta (squarebot_color_position),y

  lda #SQUAREBOT_CHAR
  ldy #[ROW_SIZE+1]
  sta (squarebot_position),y
  lda #SQUAREBOT_COLOR
  sta (squarebot_color_position),y

  jsr get_squarebot_game_position
  rts