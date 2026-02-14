.fopt           author,  "safiire"
.fopt           comment, "String subroutines"
.setcpu         "65C02"
.listbytes      unlimited
.case           on
.smart          off
.debuginfo      off
.autoimport     off

.export         byte_to_hex, parse_uint32, parse_uint8, print_hex_bytes, printstr, printstrln, strlen

.include        "kernal_api.inc"
.include        "macros.inc"
.include        "enums.inc"

.segment        "ZEROPAGE"

  ptr:         .res 2
  a32:         .res 4
  b32:         .res 4

.segment        "CODE"

  ;===============================================================
  ; Convert a byte into two hex characters
  ;   a:x byte_to_hex(uint8_t byte)
  ;   Arguments: byte to convert
  ;   Returns:   high nibble in a, low nibble in x
  ;===============================================================
  .proc byte_to_hex
                tax
                lsrx  4
                jsr   hexify
                pha
                txa
                and   #$0f
                jsr   hexify
                tax
                pla
                rts
    hexify:     eor   #'0'
                cmp   #'9' + 1
                bcc   return
                adc   #$86
    return:     rts
  .endproc

  ;===============================================================
  ; c:bool parse_uint32(a:x:digits, *y:out)
  ;
  ;   Parse a string of digits in a:x into a u32 pointed to by out
  ;   Returns: Sets C on overflow
  ;===============================================================
  .proc parse_uint32
                parsed = a32
                temp   = b32

                phy
                sta   ptr + 0
                stx   ptr + 1
                stz32 parsed

                ldy   #0
    loop:       lda   (ptr), y
                beq   return
                sec
                sbc   #'0'                       ; 10^y's digit value

                tax
                asl32  parsed, 1,    overflow
                copy32 parsed, temp
                asl32  parsed, 2,    overflow    ; parsed * 10 =
                add32  parsed, temp, overflow    ;  (parsed << 3) + (parsed << 1)
                txa
                add32a parsed,       overflow    ;  parsed * 10 + 10^ys digit

                iny
                bne   loop

    overflow:   ply
                sec
                rts                              ; fix stack and return C

    return:     ply
                sty   ptr + 0
                stz   ptr + 1                    ; ptr = y

                ldy   #0
   .repeat 4, i                                  ; memcpy(parsed, ptr, sizeof(uint32_t))
                lda   parsed + i
                sta   (ptr), y
                iny
   .endrepeat
                ldy   ptr + 0                    ; restore y
                clc
                rts
  .endproc

  ;===============================================================
  ; uint8:a parse_uint8(a:10s_digit, x:1s_digit)
  ;   Parse decimal uint8 out of characters in a:x
  ;===============================================================
  .proc parse_uint8
                parsed = a32
                sec
                sbc   #'0'                       ; 10s digit value
                asl
                sta   parsed
                asl
                asl
                clc
                adc   parsed
                sta   parsed                     ; a * 10 = (a << 3) + (a << 1)
                txa
                sec
                sbc   #'0'                       ; 1s digit value
                clc
                adc   parsed                     ; a = a * 10 + x
                rts
  .endproc

  ;===============================================================
  ; Print out Y bytes from address in a:x
  ;===============================================================
  .proc print_hex_bytes
                dey
                sta   reg::r0 + 0
                stx   reg::r0 + 1

    loop:       lda   (reg::r0), y
                jsr   byte_to_hex
                jsr   Kernal::chrout
                txa
                jsr   Kernal::chrout
                dey
                cpy   #$FF
                bne   loop
                rts
  .endproc

  ;===============================================================
  ; void printstr(a:x:string)
  ;   Print a null terminated string in a:x
  ;===============================================================
  .proc printstr
                ptr = reg::r0
                phy
                sta   ptr + 0
                stx   ptr + 1

                ldy   #0
    loop:       lda   (ptr), y
                beq   return
                jsr   Kernal::chrout
                iny
                bra   loop

    return:     ply
                rts
  .endproc

  ;===============================================================
  ; Print a null terminated string in a:x + newline
  ;===============================================================
  .proc printstrln
                jsr   printstr
                lda   #$0D
                jsr   Kernal::chrout
                rts
  .endproc

  ;===============================================================
  ; Length of null terminated string in a:x
  ; Returns: Length in y
  ;===============================================================
  .proc strlen
                ptr  = reg::r0
                tay
                push16 ptr

                sty   ptr + 0
                stx   ptr + 1

                ldy   #0
    loop:       lda   (ptr), y
                beq   return
                iny
                bne   loop

    return:     pop16 ptr
                rts
  .endproc
