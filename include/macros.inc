.ifndef _MACROS_INC
_MACROS_INC = 1

  ;===============================================================
  ; Macro to get character digits out of an address
  ;===============================================================
  .macro addr2chars address
    .assert     (address < 10000), error, "address too large"
    .byte       <(((address /  1000) .mod 10) + '0')
    .byte       <(((address /   100) .mod 10) + '0')
    .byte       <(((address /    10) .mod 10) + '0')
    .byte       <(((address /     1) .mod 10) + '0')
  .endmacro

  ;===============================================================
  ; Print a string using primm
  ;===============================================================
  .macro print string
                jsr     Kernal::primm
    .byte       string, $00
  .endmacro

  ;===============================================================
  ; Print a string with linefeed using primm
  ;===============================================================
  .macro println string
                jsr     Kernal::primm
    .byte       string, $0D, $00
  .endmacro

  ;===============================================================
  ; Issue a immediate command to the uart
  ;===============================================================
  .macro issue_command string
                jsr   issue_command_impl
    .byte       string, $0A, $00
  .endmacro

  ;===============================================================
  ; Read from the uart until we match an immediate string
  ;===============================================================
  .macro read_until match
                jsr   read_until_impl
    .byte       match, $0D, $0A, $00
  .endmacro

  ;===============================================================
  ; Fill memory with a value
  ;===============================================================
  .macro fill_memory address, size, value
                lda   #<address
                ldx   #>address
                sta   reg::r0 + 0
                stx   reg::r0 + 1
                lda   #<size
                ldx   #>size
                sta   reg::r1 + 0
                stx   reg::r1 + 1
                lda   #value
                jsr   Kernal::fill_memory
  .endmacro

  ;===============================================================
  ; Zero a 32-bit value at address
  ;===============================================================
  .macro stz32 address
                stz   address + 3
                stz   address + 2
                stz   address + 1
                stz   address + 0
  .endmacro

  ;===============================================================
  ; Copy a 32-bit value from source to dest
  ;===============================================================
  .macro copy32 source, dest
    .repeat 4, offset
                  lda   source + offset
                  sta   dest   + offset
    .endrepeat
  .endmacro

  ;===============================================================
  ; Copy a 16-bit value from source to dest
  ;===============================================================
  .macro copy16 source, dest
    .repeat 2, offset
                  lda   source + offset
                  sta   dest   + offset
    .endrepeat
  .endmacro

  ;===============================================================
  ; Logical Shift Right x count
  ;===============================================================
  .macro lsrx count
    .repeat count
                  lsr
    .endrepeat
  .endmacro

  ;===============================================================
  ; Arithmetic Shift Left a 32 bit value
  ; Optional branch for overflow
  ;===============================================================
  .macro asl32 address, count, overflow
    .repeat count
                  asl   address + 0
                  rol   address + 1
                  rol   address + 2
                  rol   address + 3
      .ifnblank overflow
                  bcs   overflow
      .endif
    .endrepeat
  .endmacro

  ;===============================================================
  ; Add the A register to a 32-bit value
  ; Optional branch for overflow
  ;===============================================================
  .macro add32a address, overflow
                  clc
                  adc   address + 0
                  sta   address + 0
    .repeat 3, offset
                  lda   #0
                  adc   address + 1 + offset
                  sta   address + 1 + offset
    .endrepeat
    .ifnblank overflow
                  bcs   overflow
    .endif
  .endmacro

  ;===============================================================
  ; Add two 32-bit values: *address1 = *address1 + *address2
  ; Optional branch for overflow
  ;===============================================================
  .macro add32 address1, address2, overflow
                  clc
    .repeat 4, offset
                  lda   address1 + offset
                  adc   address2 + offset
                  sta   address1 + offset
    .endrepeat
    .ifnblank overflow
                  bcs   overflow
    .endif
  .endmacro

  ;===============================================================
  ; Subtract two 32-bit values: *address1 = *address1 - *address2
  ;===============================================================
  .macro sub32 address1, address2
                  sec
    .repeat 4, offset
                  lda   address1 + offset
                  sbc   address2 + offset
                  sta   address1 + offset
    .endrepeat
  .endmacro

  ;===============================================================
  ; Decrement a 16-bit value: *address -= 1
  ; * Set Z on *address == $0000
  ;===============================================================
  .macro dec16 address
    .scope
                  lda   address + 0
                  bne   dec_lsb
                  dec   address + 1
      dec_lsb:    dec   address + 0
                  dec   a
                  ora   address + 1
    .endscope
  .endmacro

  ;===============================================================
  ; Set a register in the UART
  ;===============================================================
  .macro uart_set register, value
                  lda   #value
                  ldy   #register
                  sta   (uart), y
  .endmacro

  ;===============================================================
  ; Copy a register in the UART into A
  ;===============================================================
  .macro uart_get register, value
                  ldy   #register
                  lda   (uart), y
  .endmacro

  ;===============================================================
  ; Save an RDTIM to address
  ; It's 24-bit, but extend it to 32-bits
  ;===============================================================
  .macro save_rdtime address
                  jsr   Kernal::rdtim
                  sta   address + 0
                  stx   address + 1
                  sty   address + 2
                  stz   address + 3
  .endmacro

  ;===============================================================
  ; Wait for a few jiffies
  ;===============================================================
  .macro wait_jiffies jiffies
    .scope
                  save_rdtime start_time
      wait:       save_rdtime end_time
                  sub32 end_time, start_time
                  lda   #jiffies
                  cmp   end_time
                  bpl   wait
    .endscope
  .endmacro

  ;===============================================================
  ; Push a 16-bit value from memory on the stack
  ;===============================================================
  .macro push16 address
                  lda   address + 1
                  pha
                  lda   address + 0
                  pha
  .endmacro

  ;===============================================================
  ; Pop a 16-bit value from stack to memory
  ;===============================================================
  .macro pop16 address
                  pla
                  sta   address + 0
                  pla
                  sta   address + 1
  .endmacro
.endif
