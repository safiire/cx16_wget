.fopt           author,  "safiire"
.fopt           comment, "The EXEHDR for the binary"
.setcpu         "65C02"
.listbytes      unlimited
.case           on
.smart          off
.debuginfo      off
.autoimport     off

.import         start

.include        "enums.inc"
.include        "macros.inc"

line_number     = $10AD
no_next         = $0000

.segment "EXEHDR"
                .addr         next
                .word         line_number
                .byte         BASIC::sys
                addr2chars    start
                .byte         BASIC::eol
next:           .addr         no_next
