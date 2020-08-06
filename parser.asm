

BDOS: EQU     5

    org   $100
    call  parseargs
    ret

parseargs:
    ld      hl,$80
    ld      c,(hl)
    ld      b,0
    inc     hl
    push    hl
    add     hl,bc
    ld      (hl),0   ; terminates the command line with zero
    pop     hl
    ld      (parmspointer),hl
    call    space_skip
    inc     hl
    ld      de,parms_table
    call    table_inspect
    jr      c,nocliargs
    jp      (hl)

nocliargs:
    ld     hl,txt_parmerr
    jp     print

param_h:
    ld      hl,txt_help
    call    print
    scf
    ret

param_s:
    ret
param_e:
    ret
param_d:
    ret
param_i:
    ret
param_f:
    ld      hl,txt_parm_f
    jp      print

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

table_inspect:
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
    ld      a,(de)
    ld      l,a
    inc     de
    ld      a,(de)
    ld      h,a
    pop     af         ; discard HL to keep current arrgs index
    scf
    ccf
    ret

table_inspect_next:
    ld      a,(de)
    inc     de
    or      a
    jr      nz,table_inspect_next
    pop     hl
    inc     de
    inc     de
    ld      a,(de)
    or      a
    jr      nz,table_inspect 
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
txt_parmerr: db "Invalid parameters",13,10,0
txt_parm_f: db "Filename:",13,10,0
parms_table:
    db "h",0
    dw param_h
    db "e",0
    dw param_e
    db "d",0
    dw param_d
    db "i",0
    dw param_i
    db "f",0
    dw param_f
    db 0


parmspointer: dw 0000
