

BDOS: EQU     5

    org   $100
    call  parseargs
    jr    nc,exitmyprogram
    ld    a,(parm_index)
    cp    $ff
    jr    nz,invalidparms
noparams:
    add    $31
    call   PUTCHAR
    ld     hl,txt_noparams
    call   print
    jr     exitmyprogram

invalidparms:
    add    $31
    call   PUTCHAR
    ld     hl,txt_invparms
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
    call    space_skip
    ret     c
    inc     hl
    ld      de,parms_table
    call    table_inspect
    ret     ; jump to the routine for the parameter

param_h:
    ld      a,(parm_index)
    add     $31
    call    PUTCHAR
    ld      hl,txt_help
    call    print
    ret

param_s:
    ld      a,(parm_index)
    add     $31
    call    PUTCHAR
    ret
param_e:
    ld      a,(parm_index)
    add     $31
    call    PUTCHAR
    ret
param_d:
    ld      a,(parm_index)
    add     $31
    call    PUTCHAR
    ret
param_i:
    ld      a,(parm_index)
    add     $31
    call    PUTCHAR
    ret
param_f:
    ld      a,(parm_index)
    add     $31
    call    PUTCHAR
    ld      hl,txt_parm_f
    jp      print

; ================================================================================
init:
	xor     a
	ld      (parm_index),a
	ret

; Find Command Line Argument.
; Inputs: 
; E = Parameter to search for
; HL = memory address to start testing
;
; Outputs:
; HL = updated memory address to the next valid char after the parameters if it was found,
;      otherwise return the original value
; Flac: C if did not find the parameter
;      NC if found the parameters. 
; A = 0 if found a valid parameter (prefixed by "/")
; A = 1 if parameter is a string (not pre-fixed by "/") - this means this should be treated 
;       as the last parameter in the command line. 
; A = 255 if no parameters were found, therefore there is not parameters passed in the CLI
; HL = Relevant address according to the result of the function. 
;      if A = 0  : HL = Next valid memory address string
;                  DE = Address of the routine for this prameter
;      if A = 1  : HL = Next valid memory address string
;                : DE = not valid as ther is no parameter for this in the parameters table
;      if A = 255: HL = invalid address since there is no parameter in the CLI
;                : DE = not valid as ther is no parameter for this in the parameters table
parm_search:
    call    space_skip
    ret     c
    ld      de,parms_table
parm_search1:
    ld      a,(hl)
    or      a
    scf
    ret     z
    inc     hl
    cp      '/'
    jr      nz,parm_search1
    push    hl
    push    de
    call    table_inspect
    jr      nc,parm_search_found
    pop     de
    pop     hl
    jr      parm_search1
parm_search_found:
    pop     af     ; discard DE in stack because DE returned by table_inspect
                   ; contain the address of the routine for this parameter
    pop     af     ; discard HL in the stack because HL returned bt table_inspect
                   ; contain the next addres of the arguments to be processed
    scf
    ccf
    ret

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
    ld      a,255
    ld      (parm_index),a
    ld      (parm_nofound),a
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
    ld      (parm_nofound),a
    ld      a,(de)
    ld      c,a
    inc     de
    ld      a,(de)
    ld      b,a
    pop     de         ; get ret address out of the stack temporarily
    push    bc         ; push the routine address in the stack
    push    de         ; push the return addres of this routine back in the stack
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

parm_index: db $ff
parm_nofound: db $ff
parmspointer: dw 0000
