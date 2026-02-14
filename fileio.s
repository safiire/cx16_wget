.fopt           author, "safiire"
.fopt           comment, "UART Driver for CX16"
.setcpu         "65C02"
.listbytes      unlimited
.case           on
.smart          off
.debuginfo      off
.autoimport     off

.export         close_output_file, dos_status, enable_auto_tx, open_output_file, print_dos_status

.import         parse_uint8, printstrln, strlen

.include        "kernal_api.inc"
.include        "macros.inc"
.include        "enums.inc"
.include        "structs.inc"

OUTPUT_FILE     = Config::output_file
COMMAND_CHANNEL = $0F
SD_CARD         = $08
FILE_SAVE       = $01

.segment        "BSS"

  dos_status:   .tag DOSStatus

.segment        "RODATA"

  auto_tx:      .byte "u0>b3"
  auto_tx_size  = * - auto_tx

.segment        "CODE"

  ;===============================================================
  ; c:bool enable_auto_tx()
  ;   Enable the auto-tx mode
  ;   This currently won't succeed on emulator
  ;   Returns: DOS Status code in A
  ;===============================================================
  .proc enable_auto_tx
                code  = dos_status + DOSStatus::code

                lda   #auto_tx_size
                ldx   #<auto_tx
                ldy   #>auto_tx
                jsr   Kernal::setnam

                lda   #COMMAND_CHANNEL
                ldx   #SD_CARD
                ldy   #COMMAND_CHANNEL
                jsr   Kernal::setlfs
                jsr   Kernal::open
                jsr   read_dos_status
                rts
  .endproc

  ;===============================================================
  ; a:status_code read_dos_status()
  ;   Populate the dos_status structure with the most recent
  ;   status from the command channel
  ;   Returns: DOS Status code in A
  ;===============================================================
  .proc read_dos_status
                code     = dos_status + DOSStatus::code
                message  = dos_status + DOSStatus::message
                max_size = .sizeof(DOSStatus::message)

                ldx   #COMMAND_CHANNEL
                jsr   Kernal::chkin

                ldx   #0
    loop:       jsr   Kernal::chrin
                tay
                jsr   Kernal::readst
                bne   parse

                tya
                sta   message, x
                inx

                cpx   #(max_size - 1)
                bne   loop

    parse:      stz   message, x                 ; Null terminate the message
                jsr   Kernal::clrchn

                lda   message + 0
                ldx   message + 1
                jsr   parse_uint8                ; first two characters are return code
                sta   code
                rts
  .endproc

  ;===============================================================
  ; void print_dos_status()
  ;   Print out the most recent CMDR DOS Status message
  ;===============================================================
  .proc print_dos_status
                message  = dos_status + DOSStatus::message

                print "[D] "
                lda   #<message
                ldx   #>message
                jsr   printstrln
                rts
  .endproc

  ;===============================================================
  ; c:bool open_output_file(a:x:filename)
  ;   Open a filename in a:x as logical file OUTPUT_FILE
  ;   Returns: DOS Status code in A
  ;===============================================================
  .proc open_output_file
                code  = dos_status + DOSStatus::code

                sta   reg::r0 + 0
                stx   reg::r0 + 1
                jsr   strlen
                tya
                ldx   reg::r0 + 0
                ldy   reg::r0 + 1
                jsr   Kernal::setnam

                lda   #OUTPUT_FILE
                ldx   #SD_CARD
                ldy   #FILE_SAVE
                jsr   Kernal::setlfs

                jsr   Kernal::open
                jsr   read_dos_status

                ldx   #OUTPUT_FILE
                jsr   Kernal::chkout
                jsr   Kernal::clrchn
                lda   code
                rts
  .endproc

  ;===============================================================
  ; void close_output_file()
  ;   Close the output file
  ;   Returns: DOS Status code in A
  ;===============================================================
  .proc close_output_file
                code  = dos_status + DOSStatus::code

                lda   #OUTPUT_FILE
                jsr   Kernal::close
                jsr   read_dos_status
                lda   code
                rts
  .endproc
