��!� N #�	6 �"C͂#.�T8�!Î!�͎7�����!"Î.~�7�#�/ ����T0�����7?��~� (�(	O� #�� 
og�7?�� ��� �7�~�7�� 7?�#�~���
 ͠>͠#����_� ����Command Line Parser for MSX-DOS
Format: parser </options> file.rom

/h Show this help
/s <slot number> (must be 2 digits)
/i Show initial 256 byets of the slot cartridge
/d Disable the EEPROM Software Data Protection before writing
/e Enable the EEPROM Software Data Protection after writing
/f File name with extension, for example game.rom
 Invalid parameters
 Filename:
 h &e /d 0i 1f 2   