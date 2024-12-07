SN      = $900d                 ; noise channel (these memory addresses are in the reference manual)
SV      = $900e                 ; volume
JC      = $00a2                 ; jiffy clock

STARTM  = 214                   ; initial pitch of move (must be between 129 and 255 ish, but you should already know that)

player_movement                 ; CALL THIS SUBROUTINE TO PLAY THE SOUND
        ldx #0
        ldy #STARTM             ; load the first pitch into the Y register
        sty SN                  ; write the note to the noise channel
player_movement_next
        lda mov_velocities,X    ; get the current note velocity
        sta SV                  ; set speakers to volume in accumulator
; check if we should exit on this note
        beq exit_move           ; if volume is 0, exit the main loop (this branches to an rts, essentially. my exit code is slightly more complicated)
; we should not exit on this note
        inx                     ; move on
; set up the jiffy waiting loop
        ldy JC                  ; load jiffy clock into Y register
        iny                     ; Y register now stores the desired end time (one jiffy away)
; wait one jiffy
jiffyM
        cpy JC
        bne jiffyM
; move on to the next velocity value
        beq player_movement_next ; restart main loop

; you can define the velocities here, it moves on to the next velocity after it waits a jiffy. a velocity of 0 is the delimiter (i.e. it exits when it hits 0)
mov_velocities
        dc  3, 6, 3, 0           ;sound duration

exit_move
        rts