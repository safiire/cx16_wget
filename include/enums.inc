.ifndef _ENUMS_INC
_ENUMS_INC = 1

  .include "config.inc"

  ;===============================================================
  ; This program's version number
  ;===============================================================
  .enum Version
    Major               = Config::major ^ $30
    Minor               = Config::minor ^ $30
    Patch               = Config::patch ^ $30
  .endenum

  ;===============================================================
  ; Fetch status codes
  ;===============================================================
  .enum FetchStatus
    success             = 0
    failed              = 1
    overflow_uint32     = 2
    overflow_zimodem    = 3
  .endenum

  ;===============================================================
  ; CX16 charsets
  ;===============================================================
  .enum Charset
    CustomPtrXY         = 0
    ISO                 = 1
    PETUpperGraph       = 2
    PETUpperLower       = 3
  .endenum

  .enum CharsetThin
    PETUpperGraph       = 4
    PETUpperLower       = 5
    ISO                 = 6
  .endenum

  ;===============================================================
  ; First 16 ROM banks on CX16
  ;===============================================================
  .enum ROMBank
    Kernal              = $00
    KeyBD               = $01
    CMDRDOS             = $02
    FAT32               = $03
    BASIC               = $04
    Monitor             = $05
    Charset             = $06
    Diag                = $07
    Graph               = $08
    Demo                = $09
    Audio               = $0A
    Util                = $0B
    Bannex              = $0C
    X16Edit             = $0D
    X16Edit2            = $0E
    Basload             = $0F
  .endenum

  ;===============================================================
  ; RAM banks, User[n] are Highmem banks
  ;===============================================================
  .enum RAMBank
    System              = $00
    User1               = $01
  .endenum

  ;===============================================================
  ; Bitfield masks for TL16C2550's Line Status Register
  ;===============================================================
  .enum LSR
    DR                  = %00000001 ; Data Ready
    OE                  = %00000010 ; Overrun Error
    PE                  = %00000100 ; Parity Error
    FE                  = %00001000 ; Framing Error
    BI                  = %00010000 ; Break Interrupt
    THRE                = %00100000 ; Transmit Holding Register Empty
    TEMT                = %01000000 ; Transmitter Empty
    RCVR                = %10000000 ; Error in RCVR FIFO
  .endenum

  ;===============================================================
  ; Banking registers and the zero page R registers
  ;===============================================================
  .enum reg
    ram_bank            = $00
    rom_bank            = $01
    r0                  = $02
    r1                  = $04
    r2                  = $06
    r3                  = $08
    r4                  = $0a
    r5                  = $0c
    r6                  = $0e
    r7                  = $10
    r8                  = $12
    r9                  = $14
    ra                  = $16
    rb                  = $18
    rc                  = $1a
    rd                  = $1c
    re                  = $1e
    rf                  = $20
  .endenum

  ;===============================================================
  ; Useful addresses
  ;===============================================================
  .enum Address
    basic_buffer        = $0200
    expansion_page      = $9F
    highmem             = $A000
  .endenum

  ;===============================================================
  ; BASIC commands
  ;===============================================================
  .enum BASIC
    eol                 = $00
    run                 = $8A
    rem                 = $8F
    sys                 = $9E
  .endenum

  ;===============================================================
  ; Register set for VERA
  ;===============================================================
  .enum vera
    addr_lo             = $9f20 ; VRAM Address( 7:0)
    addr_mi             = $9f21 ; VRAM Address(15:8)
    addr_hi             = $9f22 ; Address Increment(7:4), DECR(3), Nibble Inc(2), Nibble Addr(1), VRAM Address(16)
    data0               = $9f23 ; VRAM Data Port 0
    data1               = $9f24 ; VRAM Data Port 1
    ctrl                = $9f25 ; Reset(7), DCSEL(6:1), ADDRSEL(0)
    ien                 = $9f26 ; IRQ Line(8), Scan Line(8), -(5:4), AFLOW(3), SPRCOL(2), LINE(1), VSYNC(0)
    isr                 = $9f27 ; Sprite Collisions(7:4),            AFLOW(3), SPRCOL(2), LINE(1), VSYNC(0)
    irqline             = $9f28 ; IRQ Line(7:0) (write only)
    scanline            = $9f28 ; Scan Line(7:0) (read only)
    dc_video            = $9f29 ; Current Field(7), Sprites Enabled(6), Layer1 Enable(5), Layer0 Enable(4), NTSC/RGB:240p(3), NTSC:Chroma Disable/RGB:HV Sync(2) Output Mode(1:0)
    dc_hscale           = $9f2a ; Active Display H-Scale
    dc_vscale           = $9f2b ; Active Display V-Scale
    dc_border           = $9f2c ; Border Color
    l0_config           = $9f2d ; Map Height(7:6), Map Width(5:4), T256C(3), Bitmap Mode(2), Color Depth(1:0)
    l0_mapbase          = $9f2e ; Map Base Address(16:9) 17-bit adddress
    l0_tilebase         = $9f2f ; Tile Base Address(16:11), Tile Height(1), Tile  Width(0)
    l0_hscroll_lo       = $9f30 ; H-Scroll(7:0)
    l0_hscroll_hi       = $9f31 ; Unused(7:4), H-Scroll(11:8)
    l0_vscroll_lo       = $9f32 ; V-Scroll(7:0)
    l0_vscroll_hi       = $9f33 ; Unused(7:4), V-Scroll(11:8)
    l1_config           = $9f34 ; Map Height(7:6), Map Width(5:4), T256C(3), Bitmap Mode(2), Color Depth(1:0)
    l1_mapbase          = $9f35 ; Map Base Address(16:9) 17-bit adddress
    l1_tilebase         = $9f36 ; Tile Base Address(16:11), Tile Height(1), Tile  Width(0)
    l1_hscroll_lo       = $9f37 ; H-Scroll(7:0)
    l1_hscroll_hi       = $9f38 ; Unused(7:4), H-Scroll(11:8)
    l1_vscroll_lo       = $9f39 ; V-Scroll(7:0)
    l1_vscroll_hi       = $9f3a ; Unused(7:4), V-Scroll(11:8)
    audio_ctrl          = $9f3b ; FIFO Full/Reset(7:6), 16-bit(5), Stereo(4), PCM Volume(3:0)
    audio_rate          = $9f3c ; PCM Sample Rate
    audio_data          = $9f3d ; Audio FIFO data (write only)
    spi_data            = $9f3e ; Data
    spi_ctrl            = $9f3f ; Busy(7), Unused(6:3), Auto-TX(2), Slow Clock(1), Select(0)
  .endenum

.endif
