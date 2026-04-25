.fopt           author,  "safiire"
.fopt           comment, "Wget for the CX16"
.setcpu         "65C02"
.listbytes      unlimited
.case           on
.smart          off
.debuginfo      off
.autoimport     off

.export         start

.import         get_arg, get_argc, initialize_args
.import         close_output_file, dos_status, enable_auto_tx, open_output_file, print_dos_status
.import         byte_to_hex, print_hex_bytes, printstr
.import         detect_uart, issue_atg, issue_atz, issue_command_impl, read_bytes_vram, uart_initialize
.import         uart_read_vram, uart_send_control_c, write_vram_bytes_to_file, write_vram_to_file

.include        "enums.inc"
.include        "structs.inc"
.include        "kernal_api.inc"
.include        "macros.inc"

.segment        "BSS"

  start_time:   .res 4
  end_time:     .res 4
  init_success: .res 1

.segment        "ZEROPAGE"

  response:     .tag Response

.segment        "CODE"

  ;===============================================================
  ; void start()
  ;   Entrypoint
  ;===============================================================
  .proc start
                stz   init_success
                jsr   initialize_screen
                jsr   show_banner

                jsr   process_arguments
                bcs   exit

                jsr   try_auto_tx

                jsr   initialize_modem
                bcs   exit

                jsr   fetch
    exit:       jsr   atexit
                rts
  .endproc

  ;===============================================================
  ; c:bool process_arguments()
  ;   Process arguments given in the BASIC buffer
  ;   Returns: C is set unless required args are given
  ;===============================================================
  .proc process_arguments
                jsr   initialize_args
                jsr   argument_debug
                jsr   get_argc
                cmp   #Config::required_args
                clc
                beq   return

                println "Usage: run:rem <uri> [@:]<output file>"
                sec
    return:     rts
  .endproc

  ;===============================================================
  ; void argument_debug()
  ;   Routine to help in debugging arguments
  ;===============================================================
  .proc argument_debug
    .if Config::debug
                print "[?] Argc "
                jsr   get_argc
                jsr   byte_to_hex
                jsr   Kernal::chrout
                txa
                jsr   Kernal::chrout
                println ""

                ldy   #0
    loop:       print "[?] Argv[] '"
                jsr   get_arg
                jsr   printstr
                println "'"

                iny
                cpy   #Config::max_args
                bne   loop
    .endif
                rts
  .endproc

  ;===============================================================
  ; void show_elapsed_time()
  ;   Display elapsed time to download a URI
  ;===============================================================
  .proc show_elapsed_time
                jsr   Kernal::clrchn

                sub32 end_time, start_time
                print "[*] Done in "

                ldy   #4
                lda   #<end_time
                ldx   #>end_time
                jsr   print_hex_bytes

                println " Jiffies"
                rts
  .endproc

  ;===============================================================
  ; void initialize_screen()
  ;   Intitalize banks and charset
  ;===============================================================
  .proc initialize_screen
                lda   #RAMBank::User1
                ldx   #ROMBank::Kernal
                sta   reg::ram_bank
                stx   reg::rom_bank
                lda   #Charset::PETUpperLower
                jsr   Kernal::set_charset
                rts
  .endproc

  ;===============================================================
  ; void show_banner()
  ;   Show the banner with version
  ;===============================================================
  .proc show_banner
                lda   #Version::Major
                sta   str + 14 + 21
                lda   #Version::Minor
                sta   str + 16 + 21
                lda   #Version::Patch
                sta   str + 18 + 21

                println "======================================"
    str:        println "CX16 wget                      vX.X.X "
                println "                   github.com/safiire "
                println "======================================"
                rts
  .endproc

  ;===============================================================
  ; c:bool initialize_modem()
  ;   Find a UART, Initialize it and hope it has ZiModem on
  ;   the other end, initialize ZiModem.
  ;   Probably an issue for people who have mulitple serial cards
  ;===============================================================
  .proc initialize_modem
                jsr   detect_uart
                bne   found
                println "[-] Error: uart not found"
                sec
                rts

    found:      tay
                txa
                jsr   byte_to_hex
                sta   str + 24
                stx   str + 25
                tya
                jsr   byte_to_hex
                sta   str + 26
                stx   str + 27

    str:        println "[+] Detected uart at XXXX"

                jsr   uart_initialize

                issue_command "ATE0Q0V1X1F0R1S45=3&P1B921600"

                lda   #1
                sta   init_success
                clc
                rts
  .endproc

  ;===============================================================
  ; void try_auto_tx()
  ;   Try to enable Auto-TX so we can save to the SDCard faster
  ;===============================================================
  .proc try_auto_tx
                message = dos_status + DOSStatus::message

                jsr   enable_auto_tx
                beq   success

                println "[-] Couldn't enable Auto-TX"
                jsr   print_dos_status
                bra   return

    success:    println "[+] Enabled Auto-TX"
    return:     rts
  .endproc

  ;===============================================================
  ; c:bool fetch()
  ;   Fetch the URI and save it to disk
  ;===============================================================
  .proc fetch
                println "[I] Fetching..."

                jsr initiate_fetch
                bcs abort

                jsr open_file
                bcs abort

                save_rdtime start_time
                jsr process_fastblocks
                jsr process_slowblock
                save_rdtime end_time

                issue_command ""                 ; receive the 'Ok'

                jsr close_file
                bcc success

    abort:      println "[-] Aborted"
                sec
                rts

    success:    jsr show_elapsed_time
                clc
                rts
  .endproc

  ;===============================================================
  ; c:bool initiate_fetch()
  ;   Initiate the fetch via ZiModem and see if it succeeds
  ;   Aborts the transfer if we can't handle it
  ;===============================================================
  .proc initiate_fetch
                status   = response + Response::status
                filesize = response + Response::filesize

                fill_memory response, .sizeof(Response), $00

                ldy   #0
                jsr   get_arg
                ldy   #filesize
                jsr   issue_atg

                lda   status
                asl
                tax
                jmp   (case, x)

    success:    println "[+] Success"
                clc
                rts
    failed:     println "[+] URI failed"
                sec
                rts
    overflow:   println "[-] Max download size is 2 GiB"
                jsr uart_send_control_c
                sec
                rts

    case:       .word success
                .word failed
                .word overflow
                .word overflow
  .endproc

  ;===============================================================
  ; c:bool open_file()
  ;   Open the filename in arg[1] for writing
  ;===============================================================
  .proc open_file
                file_exists = 63

                ldy   #1
                jsr   get_arg
                jsr   open_output_file
                beq   fileok
                cmp   #file_exists
                bne   generic
                println "[-] Prefix filename with @: to overwrite"
    generic:    println "[-] Could not open file for writing"
                jsr   print_dos_status
                sec
                rts
    fileok:     clc
                rts
  .endproc

  ;===============================================================
  ; c:bool close_file()
  ;   Closes the output file
  ;===============================================================
  .proc close_file
                jsr   close_output_file
                beq   closed
                println "[-] Could not close file"
                jsr   print_dos_status
                sec
                rts
    closed:     clc
                rts
  .endproc

  ;===============================================================
  ; void process_fastblocks()
  ;   Transfer and save any 64KiB fastblocks
  ;===============================================================
  .proc process_fastblocks
                filesize    = response + Response::filesize
                fast_blocks = filesize + Filesize::fast_blocks

                lda   fast_blocks + 0
                ora   fast_blocks + 1
                beq   return

                jsr   print_filesize
                jsr   uart_read_vram
                jsr   write_vram_to_file

                lda   fast_blocks + 0
                bne   skip
                dec   fast_blocks + 1
    skip:       dec   fast_blocks + 0
                bra   process_fastblocks
    return:     rts
  .endproc

  ;===============================================================
  ; void process_slowblock()
  ;   Transfer and save any remaining bytes
  ;===============================================================
  .proc process_slowblock
                filesize    = response + Response::filesize
                slow_block  = filesize + Filesize::slow_block

                lda   slow_block + 0
                ora   slow_block + 1
                beq   return

                jsr   print_filesize
                ldx   slow_block + 0
                ldy   slow_block + 1
                jsr   read_bytes_vram
                jsr   write_vram_bytes_to_file

                stz   slow_block + 0
                stz   slow_block + 1
    return:     jsr   print_filesize
                rts
  .endproc

  ;===============================================================
  ; void print_filesize()
  ;   Print the remaining bytes to download
  ;===============================================================
  .proc print_filesize
                filesize = response + Response::filesize

                jsr   Kernal::clrchn
                jsr   carriage_return

                print "[+] "
                ldy   #.sizeof(Response::filesize)
                lda   #<filesize
                ldx   #>filesize
                jsr   print_hex_bytes
                println " bytes left"
                rts
  .endproc

  ;===============================================================
  ; void carriage_return()
  ;   Set the cursor position back to column 0
  ;===============================================================
  .proc carriage_return
                sec
                jsr   Kernal::plot
                dex
                ldy   #0
                clc
                jsr   Kernal::plot
                rts
  .endproc

  ;===============================================================
  ; void atexit()
  ;   Cleanup and prepare to return to BASIC
  ;===============================================================
  .proc atexit
                lda   init_success
                beq   skip

                print "[+] Resetting ZiModem... "
                jsr   issue_atz
                println "Ok"

    skip:       lda   #RAMBank::System
                ldx   #ROMBank::BASIC
                sta   reg::ram_bank
                stx   reg::rom_bank
                rts
  .endproc
