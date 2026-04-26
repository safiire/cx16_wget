.fopt           author, "safiire"
.fopt           comment, "UART Driver for CX16"
.setcpu         "65C02"
.listbytes      unlimited
.feature        string_escapes
.case           on
.smart          off
.debuginfo      off
.autoimport     off

.export         detect_uart, uart_initialize
.export         issue_command_impl, issue_atg, issue_atz, uart_send_control_c
.export         write_vram_to_file, uart_read_vram, read_bytes_vram, write_vram_bytes_to_file

.import         get_variable_immediate, parse_uint32

.include        "kernal_api.inc"
.include        "enums.inc"
.include        "structs.inc"
.include        "macros.inc"

.segment        "ZEROPAGE"

  uart:         .res 2
  uart_lsr:     .res 2

.segment        "BSS"

  start_time:   .res 4
  end_time:     .res 4

.segment        "RODATA"

  atz:          .asciiz "atz\x0A"
  atg_start:    .asciiz "at&g\""
  atg_end:      .asciiz "\"\x0A"
  control_c:    .asciiz "\x03"

  expansion_io: .lobytes $9F60, $9F80, $9FA0, $9FC0, $9FE0, $0000

.segment        "CODE"

  ;===============================================================
  ; void *detect_uart(void)
  ;   Check each expansion IO port for a UART, save it to globals: uart,
  ;   uart_lsr, then hope it happens to have ZiModem on the other end.
  ;   Returns: Address of first UART found or null
  ;===============================================================
  .proc detect_uart
                ptr = reg::r0
                lda   #<expansion_io
                ldx   #>expansion_io
                sta   ptr + 0
                stx   ptr + 1                    ; ptr = expansion_io

                lda   #Address::expansion_page
                sta   uart + 1                   ; msb(uart) = base page $9F
                sta   uart_lsr + 1

                ldy   #0
    body:       lda   (ptr), y
                beq   return                     ; return if expansion_io[y] == null

                sta   uart                       ; uart = $9f00 + expansion_io[y]
                jsr   detect_ier_register
                bcc   next
                jsr   detect_mcr_register
                bcs   found                      ; found if detected IER and MCR

    next:       iny
                bra   body                       ; y++ and loop

    found:      clc
                lda   #UART::LSR
                adc   uart + 0
                sta   uart_lsr + 0

                lda   uart
                ldx   #Address::expansion_page
                rts                              ; return the found uart address

    return:     stz   uart + 1
                stz   uart + 0
                stz   uart_lsr + 1
                stz   uart_lsr + 0
                lda   #0
                ldx   #0
                rts                              ; return 0
  .endproc

  ;===============================================================
  ; c:bool detect_ier_register()
  ;   The high nybble of IER is always clear
  ;===============================================================
  .proc detect_ier_register
                phx
                phy
                uart_set UART::IER, $FF
                uart_get UART::IER
                cmp   #$0F
                clc
                bne   no
                sec
    no:         uart_set UART::IER, $00          ; disable interrupts again
                ply
                plx
                rts
  .endproc

  ;===============================================================
  ; c:bool detect_mcr_register()
  ;   Bits 7 and 6 of MCR are always clear
  ;===============================================================
  .proc detect_mcr_register
                phx
                phy
                uart_set UART::MCR, $FF
                uart_get UART::MCR
                cmp   #$3F
                clc
                bne   no
                sec
    no:         uart_set UART::MCR, $00          ; Just zero it
                ply
                plx
                rts
  .endproc

  ;===============================================================
  ; void uart_initialize(void)
  ;   921600 baud, 8,N,1, AutoFlow Control, FIFOS, no interrupts
  ;===============================================================
  .proc uart_initialize
                uart_set UART::IER, $00          ; No Interrupts
                uart_set UART::LCR, $80          ; Set DLAB
                uart_set UART::DLM, $00          ;
                uart_set UART::DLL, $01          ; $0001 = 921600
                uart_set UART::LCR, $03          ; 8,N,1
                uart_set UART::FCR, $C7          ; FIFO enable & reset
                uart_set UART::MCR, $23          ; DTR/RTS & AutoFlow Control

                jsr   discard_banner
                rts
  .endproc

  ;===============================================================
  ; void discard_banner()
  ;   ZiModem sends a version banner of the `ati` command when the
  ;   ESP32 boots up.  Read it off if present
  ;   It is not always ready immediately so wait a tiny bit
  ;===============================================================
  .proc discard_banner
                wait_jiffies 20

                lda   (uart_lsr)
                and   #LSR::DR
                beq   return                     ; No banner present

                read_until "ready."
    return:     rts
  .endproc

  ;===============================================================
  ; Read from the UART into highmem
  ;===============================================================
  .proc read_until_impl
                match = reg::r0

                jsr   get_variable_immediate
                phy                              ; preserve y
                sta   match + 0
                stx   match + 1

                ldx   #0
                ldy   #0
    body:       lda   (match), y
                beq   break                      ; break if match[y] == null

    wait:       lda   (uart_lsr)
                and   #LSR::DR
                beq   wait

                lda   (uart)
                sta   Address::highmem, x
                inx

                cmp   (match), y
                beq   no_reset
                ldy   #$FF                       ; y = -1 if next_byte != match[y]
    no_reset:   iny
                bra   body

    break:      ply                              ; restore y
                txa                              ; return bytes read
                rts
  .endproc

  ;===============================================================
  ; A uart_read_one()
  ;   Read one byte from uart
  ;===============================================================
  .proc uart_read_one
                lda   (uart_lsr)
                and   #LSR::DR
                beq   uart_read_one
                lda   (uart)
                rts
  .endproc

  ;===============================================================
  ; Read 64KiB into VRAM $0:0000
  ;===============================================================
  .proc uart_read_vram
                jsr   reset_vera_data0
    loop:       lda   (uart_lsr)
                and   #LSR::DR
                beq   loop

                lda   (uart)
                sta   vera::data0

                lda   #1
                and   vera::addr_hi
                beq   loop
                rts
  .endproc

  ;===============================================================
  ;===============================================================
  .proc read_bytes_vram
                jsr   reset_vera_data0
    loop:       lda   (uart_lsr)
                and   #LSR::DR
                beq   loop

                lda   (uart)
                sta   vera::data0

                cpx   vera::addr_lo
                bne   loop
                cpy   vera::addr_mi
                bne   loop

                rts
  .endproc

  ;===============================================================
  ;===============================================================
  .proc write_vram_bytes_to_file
                stx   reg::r0 + 0
                sty   reg::r0 + 1

                ldx   Config::output_file
                jsr   Kernal::chkout
                jsr   reset_vera_data0

    pages:      lda   reg::r0 + 1
                beq   remainder
                sec
                lda   #0
                ldx   #<vera::data0
                ldy   #>vera::data0
                jsr   Kernal::mciout

                dec   reg::r0 + 1
                bra   pages

    remainder:  lda   reg::r0 + 0
                beq   done
                sec
                ldx   #<vera::data0
                ldy   #>vera::data0
                jsr   Kernal::mciout

    done:       jsr   Kernal::clrchn
                rts
  .endproc

  ;===============================================================
  ; void issue_command_impl()
  ;   Issue a command to ZiModem
  ;   Implementation for macro issue_command
  ;===============================================================
  .proc issue_command_impl
                jsr   get_variable_immediate
                jsr   uart_write
                read_until "OK"
                rts
  .endproc

  ;===============================================================
  ; void issue_atz()
  ;   After an atz, ZiModem responds with 'ok' instead of 'OK'
  ;   because we've undone PETSCII autotranslate mode
  ;===============================================================
  .proc issue_atz
                lda   #<atz
                ldx   #>atz
                jsr   uart_write
                read_until "ok"
                rts
  .endproc

  ;===============================================================
  ; void uart_send_control_c()
  ;   Send a control-c to ZiModem to cancel an AT&G transfer
  ;   In command mode this will receive no 'OK' and block forever
  ;===============================================================
  .proc uart_send_control_c
                lda   #<control_c
                ldx   #>control_c
                jsr   uart_write
                read_until "OK"
                rts
  .endproc

  ;===============================================================
  ; c:bool issue_atg(a:x:uri, *y:response)
  ;   Issue AT&G"<uri>" command.
  ;===============================================================
  .proc issue_atg
                phy
                pha
                phx
                lda   #<atg_start
                ldx   #>atg_start
                jsr   uart_write                 ; Start command

                plx
                pla
                jsr   uart_write                 ; Write URI

                lda   #<atg_end
                ldx   #>atg_end
                jsr   uart_write                 ; End command

                ply
                jsr   parse_get_header           ; Read response into *y
                rts                              ; On any error C is set
  .endproc

  ;===============================================================
  ; c:bool parse_get_header(*y:response)
  ;   Receive and parse AT&G's header
  ;     ex. [ 0 123456789 ]\r\n\0
  ;
  ;   Fills in Response struct
  ;   TODO: Why does this even use himem at this point?
  ;   Returns: C on overlow
  ;===============================================================
  .proc parse_get_header
                header = Address::highmem
                digits = header + 3

                jsr   uart_read_one
                cmp   #'['
                bne   error                     ; no [ it's going to say ERROR

                read_until " ]"                  ; A = bytes read

                sec
                sbc   #4
                tax
                stz   header, x                  ; header[bytes_read - 4] = '\0'

                lda   #<digits
                ldx   #>digits
                jsr   parse_uint32
                bcs   overflow

                jsr   is_int_max
                bcs   int_max

                lda   #FetchStatus::success
                sta   Response::status, y
                clc
                rts

    error:      read_until "ERROR"
                lda   #FetchStatus::failed
                sta   Response::status, y
                sec
                rts

    overflow:   lda   #FetchStatus::overflow_uint32
                sta   Response::status, y
                sec
                rts

    int_max:    lda   #FetchStatus::overflow_zimodem
                sta   Response::status, y
                sec
                rts
  .endproc

  ;===============================================================
  ; c:bool is_int_max(*y:response)
  ;   ZiModem clamps all downloads to INT_MAX, detect this
  ;   y->filesize == 0x7fffffff
  ;   Issue: https://github.com/bozimmerman/Zimodem/issues/179
  ;===============================================================
  .proc is_int_max
                lda   3, y
                cmp   #$7F
                bne   no

                lda   2, y
                and   1, y
                and   0, y
                cmp   #$FF
                bne   no

                sec
                rts

    no:         clc
                rts
  .endproc

  ;===============================================================
  ; void write_vram_to_file()
  ;   Write 64KiB from VRAM $0:0000 to Config::output_file
  ;===============================================================
  .proc write_vram_to_file
                ldx   #Config::output_file
                jsr   Kernal::chkout
                jsr   reset_vera_data0

    loop:       sec
                lda   #0
                ldx   #<vera::data0
                ldy   #>vera::data0
                jsr   Kernal::mciout

                lda   vera::addr_hi
                and   #1
                beq   loop

                rts
  .endproc

  ;===============================================================
  ; void reset_vera_data0()
  ;   Reset VERA's data0 pointer to $0:0000, address increment 1
  ;===============================================================
  .proc reset_vera_data0
                lda   #(1 << 4)
                stz   vera::ctrl
                stz   vera::addr_lo
                stz   vera::addr_mi
                sta   vera::addr_hi
                rts
  .endproc

  ;===============================================================
  ; y:size uart_write(a:x:string)
  ;   Write string in a:x to the uart
  ;   Returns: size of string
  ;===============================================================
  .proc uart_write
                ptr = reg::r1
                sta   ptr + 0
                stx   ptr + 1

                ldy   #0
    body:       lda   (ptr), y
                tax
                beq   return

    wait:       lda   (uart_lsr)
                and   #LSR::THRE
                beq   wait

                txa
                sta   (uart)
                iny
                bra   body

    return:     tya
                rts
  .endproc
