.ifndef _KERNAL_API_INC
_KERNAL_API_INC = 1

  .enum Kernal
    mciout        = $FEB1
    fill_memory   = $FEE4
    set_charset   = $FF62
    primm         = $FF7D
    readst        = $FFB7
    setlfs        = $FFBA
    setnam        = $FFBD
    open          = $FFC0
    close         = $FFC3
    chkin         = $FFC6
    chkout        = $FFC9
    clrchn        = $FFCC
    chrin         = $FFCF
    chrout        = $FFD2
    rdtim         = $FFDE
    plot          = $FFF0
  .endenum

.endif
