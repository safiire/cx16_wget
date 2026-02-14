.fopt           author,  "safiire"
.fopt           comment, "Commandline argument subroutines"
.setcpu         "65C02"
.listbytes      unlimited
.case           on
.smart          off
.debuginfo      off
.autoimport     off

.export         initialize_args, get_arg, get_argc

.include        "kernal_api.inc"
.include        "macros.inc"
.include        "enums.inc"

.segment        "BSS"

  ; TODO at this point maybe this should be a struct
  .align 256
  argv_data:    .res 256
  argc:         .res 1
  argv:         .res Config::max_args
  arg_area_size = * - argv_data

.segment        "RODATA"

  arg_pattern:  .byte BASIC::run, ':', BASIC::rem, ' '
  pattern_size  = * - arg_pattern

.segment        "CODE"

  ;===============================================================
  ; void zero_arg_area()
  ;   Initialize argument area to zero
  ;===============================================================
  .proc zero_arg_area
                fill_memory argv_data, arg_area_size, $00
                rts
  .endproc

  ;===============================================================
  ; c:bool any_args()
  ;   Checking the BASIC buffer for pattern: run:rem <arguments>
  ;===============================================================
  .proc any_args
                ldx   #(pattern_size - 1)
    loop:       lda   arg_pattern, x
                cmp   Address::basic_buffer, x
                bne   no
                dex
                bpl   loop
                sec
                rts
    no:         clc
                rts
  .endproc

  ;===============================================================
  ; a:argc initialize_args()
  ;   Parse arguments from BASIC buffer, and return argc
  ;   Returns: argc in A
  ;===============================================================
  .proc initialize_args
                comment = Address::basic_buffer + 3
                jsr   zero_arg_area
                jsr   any_args
                bcc   return

                ldx   #0                         ; x = index into comment
                ldy   #$FF                       ; y = index into argv
    loop:       lda   comment, x
                beq   return                     ; return if comment[x] == null

                cmp   #' '
                bne   write                      ; write to argv_data[x] if comment[x] != ' '

                lda   comment + 1, x
                cmp   #' '
                beq   next                       ; next if consecutive spaces

                jsr   advance_argc               ; try to advance to next argument if comment[x] == ' '
                bcs   return                     ; return if Config::max_args
                lda   #$00

    write:      sta   argv_data, x               ; argv_data[x] = comment[x] == ' ' ? null : comment[x]
    next:       inx
                bne   loop                       ; x++ and loop

    return:     lda   argc                       ; return argc
                rts
  .endproc

  ;===============================================================
  ; c:bool advance_argc(x:comment_index, y:argc)
  ;   Advance argc and set next argv pointer
  ;   Returns: C if we hit Config::max_args
  ;===============================================================
  .proc advance_argc
                lda   argc
                cmp   #Config::max_args
                bcc   less
                sec
                rts                              ; set carry if argc >= max_args

    less:       txa
                inc
                iny
                inc   argc                       ; advance argc count
                sta   argv, y                    ; argv[y] = lsb(&argv_data[x + 1])
                clc
                rts
  .endproc

  ;===============================================================
  ; a:x *get_arg(y:position)
  ; Return the address argv[y] in a:x
  ;===============================================================
  .proc get_arg
                lda   argv, y
                ldx   #>argv_data
                rts
  .endproc

  ;===============================================================
  ; a:argc get_argc()
  ; Return argc in a
  ;===============================================================
  .proc get_argc
                lda   argc
                rts
  .endproc
