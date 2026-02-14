.fopt           author,  "safiire"
.fopt           comment, "Shenanigans for using variable immediate strings"
.setcpu         "65C02"
.listbytes      unlimited
.case           on
.smart          off
.debuginfo      off
.autoimport     off

.export         get_variable_immediate

.segment        "ZEROPAGE"

  imm_ptr:      .res 2

.segment        "CODE"

  ;===============================================================
  ; a:x:immediate get_variable_immediate()
  ;   Calling this will:
  ;   * Find previous stack frame's return address
  ;   * Get a pointer to the variable immediate in previous frame
  ;   * Find the size of the variable immediate string
  ;   * Fix the previous stack frame's return address
  ;   Returns:
  ;     Pointer to string in A:X
  ;===============================================================
  .proc get_variable_immediate
              return_offset = $0103

              tsx
              phy
              lda   return_offset + 0, x
              ldy   return_offset + 1, x
              sta   imm_ptr + 0
              sty   imm_ptr + 1

              ldy   #0

              inc   imm_ptr + 0
              bne   loop
              inc   imm_ptr + 1                  ; immediate = ret address + 1

    loop:     lda   (imm_ptr), y
              beq   break
              iny
              bra   loop                         ; y = length of string

    break:    tya
              ply                                ; restore y
              inc                                ; a = y + 1 to account for null
              clc
              adc   return_offset, x
              sta   return_offset, x
              lda   #0
              adc   return_offset + 1, x         ; fix the return address
              sta   return_offset + 1, x         ; by adding a

              lda   imm_ptr + 0
              ldx   imm_ptr + 1                  ; return address of string
              rts
  .endproc
