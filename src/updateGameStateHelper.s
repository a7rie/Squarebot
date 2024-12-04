; Helper functions for updateGameState

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