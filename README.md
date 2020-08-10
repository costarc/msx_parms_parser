msx_parms_parser - parser.com
=============================

A Z80 Assembly function to parse MSX-DOS command line parameters and execute the corresponding code.

How to use:
1. Define you options in the parms_table
2. Add your data / flags requirements in table data_option_<function name>
3. Each option must have a "dw nnnn" entry, which is a label to the routine
   that will implement the logic for that option
4. Code the routine for that optin, as a regular sub-routine, terminating 
   with "ret"
5. If that routine is self-contained and don't need any further processing,
   add this code before the "ret" instruction: "xor a; ld (ignorerc),a" 
6. Inside a routine for each argument, you can establish the order of 
   processing as you wish. For example, in the /file routine, you can check
   if the another mandatory option was passed, as for example:
   "/e" to encode or "d" to decode -> these needs a flag set in the table
   data_option_<fucntion name>. If the value is $ff than the parameters was
   not passed.
