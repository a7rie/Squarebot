BYTES_USED = .-$1001 ; location counter minus starting location = total bytes used
SCREEN_MEMORY_START = $1e00
  echo [BYTES_USED]d, "bytes used"
  echo "Ending program at memory location (base 10): ", [.]d
  if . >= SCREEN_MEMORY_START ; if program entering screen memory
  echo "Throwing error because program is too large, and has entered screen memory!"
  err
  endif