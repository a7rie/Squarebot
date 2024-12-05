C_NOTE = 225
CSHARP_NOTE = 227
D_NOTE = 228
E_NOTE = 228
G_NOTE = 235
A_NOTE = 219
F_NOTE = 232
DSHARP_NOTE = 231
LOW_E_NOTE = 207
PLAY_NOTHING = 0

updateSound
  lda attach_booster_sound
  cmp #0
  beq updateSound_1

updateSound_1


turn_off_attach_booster