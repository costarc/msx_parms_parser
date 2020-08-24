;|===========================================================================|
;|                                                                           |
;| MSX Command Line Parser for MSX-DOS 32K EEPROM                            |
;|                                                                           |
;| Version : 1.1                                                             |
;|                                                                           |
;| Copyright (c) 2020 Ronivon Candido Costa (ronivon@outlook.com)            |
;|                                                                           |
;| All rights reserved                                                       |
;|                                                                           |
;| Redistribution and use in source and compiled forms, with or without      |
;| modification, are permitted under GPL license.                            |
;|                                                                           |
;|===========================================================================|
;|                                                                           |
;| This file is part of msx_parms_parser project.                            |
;|                                                                           |
;| msx_parms_parser is free software: you can redistribute it and/or modify  |
;| it under the terms of the GNU General Public License as published by      |
;| the Free Software Foundation, either version 3 of the License, or         |
;| (at your option) any later version.                                       |
;|                                                                           |
;| MSX msx_parms_parser is distributed in the hope that it will be useful,   |
;| but WITHOUT ANY WARRANTY; without even the implied warranty of            |
;| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             |
;| GNU General Public License for more details.                              |
;|                                                                           |
;| You should have received a copy of the GNU General Public License         |
;| along with msx_parms_parser.  If not, see <http://www.gnu.org/licenses/>. |
;|===========================================================================|
;
; Compile this file with z80asm:
;  z80asm parser.asm -o parser.com
; File history :
; 1.0  - 10/08/2020 : initial version
; 1.1  - 24/08/2020 : Improved parsing of file name
;
; How to use:
; 1. Define you options in the parms_table
; 2. Add your data / flags requirements in table data_option_<function name>
; 3. Each option must have a "dw nnnn" entry, which is a label to the routine
;    that will implement the logic for that option
; 4. Code the routine for that optin, as a regular sub-routine, terminating 
;    with "ret"
; 5. If that routine is self-contained and don't need any further processing,
;    add this code before the "ret" instruction: "xor a; ld (ignorerc),a" 
; 6. Inside a routine for each argument, you can establish the order of 
;    processing as you wish. For example, in the /file routine, you can check
;    if the another mandatory option was passed, as for example:
;    "/e" to encode or "d" to decode -> these needs a flag set in the table
;    data_option_<fucntion name>. If the value is $ff than the parameters was
;    not passed.
;=============================================================================

BDOS: EQU     5

    org   $100
    call  parseargs
    ld    a,(ignorerc)          ; this byte tells the main program that it can exit
    or    a                     ; No additional processing is required because
    ret   z                     ; it is all done within the param_<option> routines
    ld    hl,txt_invparms
    ld    a,(parm_found)
    cp    $ff
    jp    z,print
    ld    hl,txt_needfname
    ld    a,(data_option_f)
    cp    $ff
    jp    z,print

                                ; Ssample code - display the file name passed from CLI in FCB format
                                ; <drive>FileNameExt" : 1 byte for drive, 11 bytes for filename
    call  PRINTNEWLINE
    ld    hl,data_option_f
    inc   hl
    call  PRINTFCBFNAME
    call  PRINTNEWLINE
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
    ld      (hl),0                      ; terminates the command line with zero
    pop     hl
parse_next:
    call    space_skip
    jr      c,parse_filename
    inc     hl
    ld      de,parms_table
    call    table_inspect
    jr      c,parse_filename
    ld      a,(parm_found)
    or      a
    jr      nz,parse_checkendofparms
    pop     hl                          ; get the address of the routine
                                        ; for this parameter
    ld      de,parse_checkendofparms
    push    de
    jp      (hl)                        ; jump to the routine for the parameter
parse_checkendofparms:
    ld      hl,(parm_address)
    jr      parse_next
    
; After parsing is complete for all options, run another check to check
; if filename was provided without the "/f" option. However, /if "/f" had
; already been provided, will simply ignore en exit this routine.
parse_filename:
    ld      a,(data_option_f)
    cp      $ff
    ret     nz
    ld      hl,$80
    ld      a,(hl)
    cp      2
    ret     c
parse_filename1:
    inc     hl
    ld      a,(hl)
    or      a
    jr      nz,parse_filename1
parse_filename2:
    dec     hl
    ld      a,(hl)
    cp      ' ' 
    jr      nz,parse_filename2
    inc     hl
    ld      (parm_address),hl
    xor      a
    ld      (parm_found),a
    jp      param_f
    
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
    ld      hl,(parm_address) ; get current address in the bufer
    call    space_skip
    ld      (parm_address),hl
    ld      a,(hl)
    cp      '/'
    ret     z
    ld      de,data_option_f
                              ;check if drive letter was passed
    inc     hl
    ld      a,(hl)
    dec     hl
    cp      ':'
    ld      c,0
    jr      nz,parm_f_a
    ld      a,(hl)
    inc     hl
    inc     hl
    cp      'a'
    jr      c,param_is_uppercase
    sub     'a'
    jr      param_checkvalid
param_is_uppercase:
    sub     'A'
param_checkvalid:
    jr      c,param_invaliddrive
    inc     a
    ld      c,a
    jr      parm_f_a
param_invaliddrive:
    ld      c,$ff             ; ivalid drive, BDOS will return error when called    
parm_f_a:
    ld      a,c
    ld      (de),a            ; drive number
    inc     de
    ld      b,8               ; filename in format "filename.ext"
    call    parm_f_0          ; get filename without extension
    ld      b,3               ; filename in format "filename.ext"
    ld      a,(hl)
    cp      '.'
    jr      nz,parm_f_b
    inc     hl
parm_f_b:
    ld      (parm_address),a
    call    parm_f_0          ; get filename without extension
    ret
parm_f_0:
    ld      a,(hl)
    or      a
    jr      z,parm_f_2
    cp      '/'
    jr      z,parm_f_2
    cp      ' '
    jr      z,parm_f_2
    cp      '.'
    jr      z,parm_f_2
parm_f_1:
    ld      (de),a
    inc     hl
    inc     de
    djnz    parm_f_0
    ld      (parm_address),hl
    ret
parm_f_2:
    ld      a,' '
    ld      (de),a
    inc     de
    djnz    parm_f_2
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
    push    hl                       ; save the address of the parameters
table_inspect1:
    ld      a,(hl)
    cp      ' '
    jr      z,table_inspect_cmp
    or      a
    jr      z,table_inspect_cmp
    ld      c,a
    ld      a,(de)
    cp      c
    jr      nz,table_inspect_next   ; not this parameters, get next in the table
    inc     hl
    inc     de
    jr      table_inspect1
table_inspect_cmp:
    ld      a,(de)
    or      a
    jr      nz,table_inspect_next   ; not this parameters, check next in the table
    inc     de
    pop     af                      ; discard HL to keep current arrgs index
    xor     a
    ld      (parm_found),a
    ld      a,(de)
    ld      c,a
    inc     de
    ld      a,(de)
    ld      b,a
    pop     de                      ; get ret address out of the stack temporarily
    push    bc                      ; push the routine address in the stack
    push    de                      ; push the return addres of this routine back in the stack
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

PRINTNEWLINE:
    push     hl
    ld       hl,txt_newline
    call     print
    pop      hl
    ret

;-------------------------------------------
; print file name from FCB properly parsed |
;-------------------------------------------
PRINTFCBFNAME:
    ld       b,8
    call     PRINTFCBFNAME2
    ld       a,'.'
    call     PUTCHAR
    ld       b,3
    call     PRINTFCBFNAME2
    ret
PRINTFCBFNAME2:
    ld       a,(hl)
    inc      hl
    cp       ' '
    jr       z,PRINTFCBFNAME3
    call     PUTCHAR
PRINTFCBFNAME3:
    djnz     PRINTFCBFNAME2
    ret

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
txt_newline:   db 13,10,0

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

; Each paramater from command line should have an impact in the program
; These options here are defined to store the results of the parsing for each argument
; For example, if cli had /help, then none of this is needed because the help will be displayed,
; and the program will exit to prompt.
; However, if /enable option was passed, then we need a flag to indicate this case.
; "data_option_e" contain initially $ff, but if the /enable was passed, then the routine "param_e"
; must change this value to zero.
; Another exampe is for the filename. The initial value in "data_option_f" contain a $ff in 
; the first position. If the filename is passed using /file <filename.ext>, this address should
; contain the actual filename in the format <drive>"filenameext" (1 byte + 11 chars).

parm_index: db $ff
parm_found: db $ff
ignorerc:   db $ff
parm_address: dw 0000
data_option_e: db $ff
data_option_d: db $ff
data_option_s: db $ff
data_option_f: db $ff,$ff,0,0,0,0,0,0,0,0,0,0
               db 0
