.ifndef _STRUCTS_INC
_STRUCTS_INC = 1

  ;===============================================================
  ; We can handle a 32bit filesize
  ; Downloading takes place $10000 bytes into VRAM at at time
  ; * There are hiword(size) fastblocks of size $10000
  ; * Followed by a single slow block of loword(size) at the end
  ;===============================================================
  .struct Filesize
    slow_block    .word
    fast_blocks   .word
  .endstruct

  ;===============================================================
  ; Response we get from issue_atg()
  ;===============================================================
  .struct Response
    filesize      .tag Filesize
    status        .byte
  .endstruct

  ;===============================================================
  ; Hold the last CMDR-DOS status message
  ;===============================================================
  .struct DOSStatus
    code          .byte
    message       .res 40
  .endstruct

  ;===============================================================
  ; Register set for the TL16C2550 UART
  ;===============================================================
  .struct UART
    .union
      RBR         .byte                ; Receive Buffer
      THR         .byte                ; Transmit Holding
      DLL         .byte                ; Divisor Latch LSB
    .endunion                          ;
    .union                             ;
      IER         .byte                ; Interrupt Enable
      DLM         .byte                ; Divisor Latch MSB
    .endunion                          ;
    .union                             ;
      IIR         .byte                ; Interrupt Ident
      FCR         .byte                ; FIFO Control
    .endunion                          ;
    LCR           .byte                ; Line Control
    MCR           .byte                ; Modem Control
    LSR           .byte                ; Line Status
    MSR           .byte                ; Modem Status
    SCR           .byte                ; Scratch
  .endstruct

.endif
