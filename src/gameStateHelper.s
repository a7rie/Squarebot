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
  adc temp
  sta tileStore+1

set_left
  asl
  asl
  asl
  asl
  sta temp
  lda #$0F
  and tileStore+1
  adc temp
  sta tileStore+1

set_down
  sta temp
  lda #$F0
  and tileStore
  adc temp
  sta tileStore

set_up
  asl
  asl
  asl
  asl
  sta temp
  lda #$0F
  and tileStore
  adc temp
  sta tileStore

set_mid
  and #$0F
  sta tileStore+2

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



return_true
  sec
  rts

return_false
  clc
  rts

get_squarebot_draw_position
  lda squarebot_position
  sbc #[ROW_SIZE+1]
  sta squarebot_position
  lda squarebot_position+1
  sbc #0
  sta squarebot_position+1

  lda squarebot_color_position
  sbc #[ROW_SIZE+1]
  sta squarebot_color_position
  lda squarebot_color_position+1
  sbc #0
  sta squarebot_color_position+1

get_squarebot_game_position
  lda squarebot_position
  adc #[ROW_SIZE+1]
  sta squarebot_position
  lda squarebot_position+1
  adc #0
  sta squarebot_position+1

  lda squarebot_color_position
  adc #[ROW_SIZE+1]
  sta squarebot_color_position
  lda squarebot_color_position+1
  adc #0
  sta squarebot_color_position+1