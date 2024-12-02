; Helper functions for updateGameState

get_right
  lda tileStore+1
  and #$0F
  rts

get_left
  lda tileStore+1
  lsr
  lsr
  lsr
  lsr
  rts

get_down
  lda tileStore
  and #$0F
  rts

get_up
  lda tileStore
  lsr
  lsr
  lsr
  lsr
  rts

get_mid
  lda tileStore+2
  and $0F
  rts


set_right
  sta temp
  lda #$F0
  and tileStore+1
  clc
  adc temp
  sta tileStore+1
  rts

set_left
  asl
  asl
  asl
  asl
  sta temp
  lda #$0F
  and tileStore+1
  clc
  adc temp
  sta tileStore+1
  rts

set_down
  sta temp
  lda #$F0
  and tileStore
  clc
  adc temp
  sta tileStore
  rts

set_up
  asl
  asl
  asl
  asl
  sta temp
  lda #$0F
  and tileStore
  clc
  adc temp
  sta tileStore
  rts

set_mid
  and #$0F
  sta tileStore+2
  rts

move_new_position_right
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

move_new_position_left
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

get_squarebot_draw_position
  sec
  lda squarebot_position
  sbc #[ROW_SIZE+1]
  sta squarebot_position
  lda squarebot_position+1
  sbc #0
  sta squarebot_position+1
  sec
  lda squarebot_color_position
  sbc #[ROW_SIZE+1]
  sta squarebot_color_position
  lda squarebot_color_position+1
  sbc #0
  sta squarebot_color_position+1
  rts

get_squarebot_game_position
  clc
  lda squarebot_position
  adc #[ROW_SIZE+1]
  sta squarebot_position
  lda squarebot_position+1
  adc #0
  sta squarebot_position+1
  clc
  lda squarebot_color_position
  adc #[ROW_SIZE+1]
  sta squarebot_color_position
  lda squarebot_color_position+1
  adc #0
  sta squarebot_color_position+1
  rts

get_new_draw_position
  sec
  lda new_position
  sbc #[ROW_SIZE+1]
  sta new_position
  lda new_position+1
  sbc #0
  sta new_position+1
  sec
  lda new_color_position
  sbc #[ROW_SIZE+1]
  sta new_color_position
  lda new_color_position+1
  sbc #0
  sta new_color_position+1
  rts

get_new_game_position
  clc
  lda new_position
  adc #[ROW_SIZE+1]
  sta new_position
  lda new_position+1
  adc #0
  sta new_position+1
  clc
  lda new_color_position
  adc #[ROW_SIZE+1]
  sta new_color_position
  lda new_color_position+1
  adc #0
  sta new_color_position+1
  rts

get_tiles_r
  jsr get_new_draw_position ; moves new_position and its color pos up and left one tile
  jsr get_mid
  jsr set_left
  jsr get_right
  jsr set_mid
  ldy #1
  lda (new_position),y
  jsr set_up
  ldy #[[ROW_SIZE*2]+1]
  lda (new_position),y
  jsr set_down
  ldy #[ROW_SIZE+2]
  lda (new_position),y
  jsr set_right
  jsr get_new_game_position ; move new_position and its color pos back
  rts

get_tiles_l
  jsr get_new_draw_position
  jsr get_mid
  jsr set_right
  jsr get_left
  jsr set_mid
  ldy #1
  lda (new_position),y
  jsr set_up
  ldy #[[ROW_SIZE*2]+1]
  lda (new_position),y
  jsr set_down
  ldy #ROW_SIZE
  lda (new_position),y
  jsr set_left
  jsr get_new_game_position
  rts