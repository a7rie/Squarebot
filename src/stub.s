SYS_CMD_TOKEN = $9e
STUB_LINE_NUMBER = 10
; BASIC stub -- SYS cmd to run machine language 
  dc.w nextstmt ; link; beginning of basic
  dc.w STUB_LINE_NUMBER ; line number 
  dc.b SYS_CMD_TOKEN, [start]d, 0 ; token for sys with operand as address to "start" label
nextstmt
  dc.w 0