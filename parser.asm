

BDOS: EQU     5

    org   $100
    call  parseargs
    ld    a,(ignorerc)
    or    a
    ret   z
    ld    hl,txt_invparms
    ld    a,(parm_found)
    cp    $ff
    jp    z,print
    ld    hl,txt_needfname
    ld    a,(data_option_f)
    cp    $ff
    jp    z,print
noparams:
    ld     hl,data_option_f
    call   print
    jr     exitmyprogram

exitmyprogram:
    ld    hl,txt_exit
    call  print
    ret    


parseargs:
    ld      hl,$80
    ld      a,(hl)
    or      a
    scf
    ret     z
    ld      c,a
    ld      b,0
    inc     hl
    push    hl
    add     hl,bc
    ld      (hl),0   ; terminates the command line with zero
    pop     hl
 parse_next:
    call    space_skip
    ret     c
    inc     hl
    ld      de,parms_table
    call    table_inspect
    ret     c
    ld      a,(parm_found)
    or      a
    jr      nz,parse_checkendofparms
    pop     hl ; get form stack the address of the routine for this parameter
    ld      de,parse_checkendofparms
    push    de
    jp      (hl)     ; jump to the routine for the parameter
parse_checkendofparms:
    ld      hl,(parm_address)
    jr      parse_next

param_h:
    xor     a
    ld      (ignorerc),a
    ld      hl,txt_help
    call    print
    or      a
    ret

param_e:
    ld      a,'E'
    call    PUTCHAR
    ret
param_d:
    ld      a,'D'
    call    PUTCHAR
    ret
param_i:
    ld      a,'I'
    call    PUTCHAR
    ret
param_f:
    ld      a,'F'
    call    PUTCHAR
    ld      hl,(parm_address) ; get current address in the bufer
    call    space_skip
    ld      (parm_address),hl
    ld      a,(hl)
    cp      '/'
    ret     z
    ld      de,data_option_f
    ld      b,8               ; filename in format "filename.ext"
    call    parm_f_0          ; get filename without extension
    ld      b,3               ; filename in format "filename.ext"
    ld      a,(hl)
    cp      '.'
    jr      nz,prm_g_a
    inc     hl
prm_g_a:
    ld      (parm_address),a
    call    parm_f_0          ; get filename without extension
    ret
parm_f_0:
    ld      a,(hl)
    or      a
    jr      z,parm_g_2
    cp      '/'
    jr      z,parm_g_2
    cp      ' '
    jr      z,parm_g_2
    cp      '.'
    jr      z,parm_g_2
prm_g_1:
    ld      (de),a
    inc     hl
    inc     de
    djnz    parm_f_0
    ld      (parm_address),hl
    ret
parm_g_2:
    ld      a,' '
    ld      (de),a
    inc     de
    djnz    parm_g_2
    ld      (parm_address),hl
    ret

; ================================================================================
; table_inspect: get next parameters in the buffer and verify if it is valid
; then return the address of the routine to process the parameter
;
; Inputs:
; HL = address of buffer with parameters to parse, teminated in zero
; Outputs:
; HL = address of the buffer updated
; Stack = address of the routine for the parameter
; 

table_inspect:
    ld      a,$ff
    ld      (parm_index),a
    ld      (parm_found),a
table_inspect0:
    push    hl         ; save the address of the parameters
table_inspect1:
    ld      a,(hl)
    cp      ' '
    jr      z,table_inspect_cmp
    or      a
    jr      z,table_inspect_cmp
    ld      c,a
    ld      a,(de)
    cp      c
    jr      nz,table_inspect_next  ; not this parameters, get next in the table
    inc     hl
    inc     de
    jr      table_inspect1
table_inspect_cmp:
    ld      a,(de)
    or      a
    jr      nz,table_inspect_next   ; not this parameters, check next in the table
    inc     de
    pop     af         ; discard HL to keep current arrgs index
    xor     a
    ld      (parm_found),a
    ld      a,(de)
    ld      c,a
    inc     de
    ld      a,(de)
    ld      b,a
    pop     de         ; get ret address out of the stack temporarily
    push    bc         ; push the routine address in the stack
    push    de         ; push the return addres of this routine back in the stack
    ld      (parm_address),hl
    scf
    ccf
    ret

table_inspect_next:
    ld      a,(de)
    inc     de
    or      a
    jr      nz,table_inspect_next
    ld      a,(parm_index)
    inc     a
    ld      (parm_index),a    ; this index will tell which parameter was found
    pop     hl
    inc     de
    inc     de
    ld      a,(de)
    or      a
    jr      nz,table_inspect0
    ;ld      a,$ff
    ;ld      (parm_index),a   ; parameter not found in the index
    scf
    ret


; Skip spaces in the args.
; Inputs: 
; HL = memory address to start testing
;
; Outputs:
; HL = updated memory address 
; Flac C: set if found end of string (zero)
;
space_skip:
    ld      a,(hl)
    or      a
    scf
    ret     z
    cp      ' '
    scf
    ccf
    ret     nz
    inc     hl
    jr      space_skip

;------------------------------------
; print a string terminated in zero |
;------------------------------------
print:
        ld      a,(hl)      ;get a character to print
        or      a
        ret     z           ; end of text
        cp      10
        jr      nz,PRINT1
        call    PUTCHAR
        ld      a,13
PRINT1:
        call    PUTCHAR     ;put a character
        inc     hl
        jr      print

PUTCHAR:
        push    bc
        push    de
        push    hl
        ld      e,a
        ld      c,2
        call    BDOS
        pop     hl
        pop     de
        pop     bc
        ret

txt_help: db "Command Line Parser for MSX-DOS",13,10
          db "Format: parser </options> file.rom",13,10,13,10
          db "/h Show this help",13,10
          db "/s <slot number> (must be 2 digits)",13,10
          db "/i Show initial 256 byets of the slot cartridge",13,10
          db "/d Disable the EEPROM Software Data Protection before writing",13,10
          db "/e Enable the EEPROM Software Data Protection after writing",13,10
          db "/f File name with extension, for example game.rom",13,10
          db 0
txt_invparms: db "Invalid parameters",13,10,0
txt_noparams: db "No command line parameters passed",13,10,0
txt_parm_f: db "Filename:",13,10,0
txt_exit: db "Returning to MSX-DOS",13,10,0
txt_needfname: db "File name not specified",13,10,0

parms_table:
    db "h",0
    dw param_h
    db "help",0
    dw param_h
    db "e",0
    dw param_e
    db "d",0
    dw param_d
    db "i",0
    dw param_i
    db "file",0
    dw param_f
    db 0

; each paramater from command line should have an impact in the program
; these options here are defined to store the results of the parsing for each argumen
; for example, if cli hard /help, then none of his is needed because the help will be displayed,
; and the program will exit to propt.
; However, if /enable option was passed, then we need a flag to indicate this case.
; "data_option_e" cnotain initially 1, but if the /enable was passed, then the routine "param_e"
; must change this value to zero.
; Another exampe is for the filename. The initial value in "data_option_f" contain a $ff in 
; the first position. If the filename is passed using /file <filename.ext>, this address should
; contain the actual filename in the format "filenameext" (11 chars).

parm_index: db $ff
parm_found: db $ff
ignorerc:   db $ff
parm_address: dw 0000
data_option_e: db 1
data_option_d: db 1
data_option_s: db 0
data_option_f: db $ff,0,0,0,0,0,0,0,0,0,0
               db 0
