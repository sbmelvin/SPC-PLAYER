%if 0

SNEeSe, an Open Source Super NES emulator.


Copyright (c) 2002 Charles Bilyue'.

This is free software.  See 'LICENSE' for details.
You must read and accept the license prior to use.

%endif

; SPC700 opcodes 0x00-0x0F:
;    00: NOP             1,2
;    01: TCALL 0         1,8
;    02: SET1 dp.0       2,4
;    03: BBS dp.0,rel    3,5/7
;    04: OR  A,dp        2,3
;    05: OR  A,labs      3,4
;    06: OR  A,(X)       1,3
;    07: OR  A,(dp+X)    2,6
;    08: OR  A,#imm      2,2
;    09: OR  dp(d),dp(s) 3,6
;    0A: OR1 C,mem.bit   3,5
;    0B: ASL dp          2,4
;    0C: ASL labs        3,5
;    0D: PUSH PSW        1,4
;    0E: TSET1 labs      3,6
;    0F: BRK             1,8
;
; SPC700 opcodes 0x10-0x1F:
;    10: BPL rel         2,2/4
;    11: TCALL 1         1,8
;    12: CLR1 dp.0       2,4
;    13: BBC dp.0,rel    3,5/7
;    14: OR  A,dp+X      2,4
;    15: OR  A,labs+X    3,5
;    16: OR  A,labs+Y    3,5
;    17: OR  A,(dp)+Y    2,6
;    18: OR  dp,#imm     3,5
;    19: OR  (X),(Y)     1,5
;    1A: DECW dp         2,6
;    1B: ASL dp+X        2,5
;    1C: ASL A           1,2
;    1D: DEC X           1,2
;    1E: CMP X,labs      3,4
;    1F: JMP (labs+X)    3,6
;
; SPC700 opcodes 0x20-0x2F:
;    20: CLRP            1,2
;    21: TCALL 2         1,8
;    22: SET1 dp.1       2,4
;    23: BBS dp.1,rel    3,5/7
;    24: AND A,dp        2,3
;    25: AND A,labs      3,4
;    26: AND A,(X)       1,3
;    27: AND A,(dp+X)    2,6
;    28: AND A,#imm      2,2
;    29: AND dp(d),dp(s) 3,6
;    2A: OR1 C,/mem.bit  3,5
;    2B: ROL dp          2,4
;    2C: ROL labs        3,5
;    2D: PUSH A          1,4
;    2E: CBNE dp,rel     3,5/7
;    2F: BRA rel         2,4
;
; SPC700 opcodes 0x30-0x3F:
;    30: BMI rel         2,2/4
;    31: TCALL 3         1,8
;    32: CLR1 dp.1       2,4
;    33: BBC dp.1,rel    3,5/7
;    34: AND A,dp+X      2,4
;    35: AND A,labs+X    3,5
;    36: AND A,labs+Y    3,5
;    37: AND A,(dp)+Y    2,6
;    38: AND dp,#imm     3,5
;    39: AND (X),(Y)     1,5
;    3A: INCW dp         2,6
;    3B: ROL dp+X        2,5
;    3C: ROL A           1,2
;    3D: INC X           1,2
;    3E: CMP X,dp        2,3
;    3F: CALL labs       3,8
;
; SPC700 opcodes 0x40-0x4F:
;    40: SETP            1,2
;    41: TCALL 4         1,8
;    42: SET1 dp.2       2,4
;    43: BBS dp.2,rel    3,5/7
;    44: EOR A,dp        2,3
;    45: EOR A,labs      3,4
;    46: EOR A,(X)       1,3
;    47: EOR A,(dp+X)    2,6
;    48: EOR A,#imm      2,2
;    49: EOR dp(d),dp(s) 3,6
;    4A: AND1 C,mem.bit  3,4
;    4B: LSR dp          2,4
;    4C: LSR labs        3,5
;    4D: PUSH X          1,4
;    4E: TCLR1 labs      3,6
;    4F: PCALL upage     2,6
;
; SPC700 opcodes 0x50-0x5F:
;    50: BVC rel         2,2/4
;    51: TCALL 5         1,8
;    52: CLR1 dp.2       2,4
;    53: BBC dp.2,rel    3,5/7
;    54: EOR A,dp+X      2,4
;    55: EOR A,labs+X    3,5
;    56: EOR A,labs+Y    3,5
;    57: EOR A,(dp)+Y    2,6
;    58: EOR dp,#imm     3,5
;    59: EOR (X),(Y)     1,5
;    5A: CMPW YA,dp      2,4
;    5B: LSR dp+X        2,5
;    5C: LSR A           1,2
;    5D: MOV X,A         1,2
;    5E: CMP Y,labs      3,4
;    5F: JMP labs        3,3
;
; SPC700 opcodes 0x60-0x6F:
;    60: CLRC            1,2
;    61: TCALL 6         1,8
;    62: SET1 dp.3       2,4
;    63: BBS dp.3,rel    3,5/7
;    64: CMP A,dp        2,3
;    65: CMP A,labs      3,4
;    66: CMP A,(X)       1,3
;    67: CMP A,(dp+X)    2,6
;    68: CMP A,#imm      2,2
;    69: CMP dp(d),dp(s) 3,6
;    6A: AND1 C,/mem.bit 3,4
;    6B: ROR dp          2,4
;    6C: ROR labs        3,5
;    6D: PUSH Y          1,4
;    6E: DBNZ dp,rel     3,5/7
;    6F: RET             1,5
;
; SPC700 opcodes 0x70-0x7F:
;    70: BVS rel         2,2/4
;    71: TCALL 7         1,8
;    72: CLR1 dp.3       2,4
;    73: BBC dp.3,rel    3,5/7
;    74: CMP A,dp+X      2,4
;    75: CMP A,labs+X    3,5
;    76: CMP A,labs+Y    3,5
;    77: CMP A,(dp)+Y    2,6
;    78: CMP dp,#imm     3,5
;    79: CMP (X),(Y)     1,5
;    7A: ADDW YA,dp      2,5
;    7B: ROR dp+X        2,5
;    7C: ROR A           1,2
;    7D: MOV A,X         1,2
;    7E: CMP Y,dp        2,3
;    7F: RETI            1,6
;
; SPC700 opcodes 0x80-0x8F:
;    80: SETC            1,2
;    81: TCALL 8         1,8
;    82: SET1 dp.4       2,4
;    83: BBS dp.4,rel    3,5/7
;    84: ADC A,dp        2,3
;    85: ADC A,labs      3,4
;    86: ADC A,(X)       1,3
;    87: ADC A,(dp+X)    2,6
;    88: ADC A,#imm      2,2
;    89: ADC dp(d),dp(s) 3,6
;    8A: EOR1 C,mem.bit  3,5
;    8B: DEC dp          2,4
;    8C: DEC labs        3,5
;    8D: MOV Y,#imm      2,2
;    8E: POP PSW         1,4
;    8F: MOV dp,#imm     3,5
;
; SPC700 opcodes 0x90-0x9F:
;    90: BCC rel         2,2/4
;    91: TCALL 9         1,8
;    92: CLR1 dp.4       2,4
;    93: BBC dp.4,rel    3,5/7
;    94: ADC A,dp+X      2,4
;    95: ADC A,labs+X    3,5
;    96: ADC A,labs+Y    3,5
;    97: ADC A,(dp)+Y    2,6
;    98: ADC dp,#imm     3,5
;    99: ADC (X),(Y)     1,5
;    9A: SUBW YA,dp      2,5
;    9B: DEC dp+X        2,5
;    9C: DEC A           1,2
;    9D: MOV X,SP        1,2
;    9E: DIV YA,X        1,12
;    9F: XCN A           1,5
;
; SPC700 opcodes 0xA0-0xAF:
;    A0: EI              1,3
;    A1: TCALL 10        1,8
;    A2: SET1 dp.5       2,4
;    A3: BBS dp.5,rel    3,5/7
;    A4: SBC A,dp        2,3
;    A5: SBC A,labs      3,4
;    A6: SBC A,(X)       1,3
;    A7: SBC A,(dp+X)    2,6
;    A8: SBC A,#imm      2,2
;    A9: SBC dp(d),dp(s) 3,6
;    AA: MOV1 C,mem.bit  3,4
;    AB: INC dp          2,4
;    AC: INC labs        3,5
;    AD: CMP Y,#imm      2,2
;    AE: POP A           1,4
;    AF: MOV (X)+,A      1,4
;
; SPC700 opcodes 0xB0-0xBF:
;    B0: BCS rel         2,2/4
;    B1: TCALL 11        1,8
;    B2: CLR1 dp.5       2,4
;    B3: BBC dp.5,rel    3,5/7
;    B4: SBC A,dp+X      2,4
;    B5: SBC A,labs+X    3,5
;    B6: SBC A,labs+Y    3,5
;    B7: SBC A,(dp)+Y    2,6
;    B8: SBC dp,#imm     3,5
;    B9: SBC (X),(Y)     1,5
;    BA: MOVW YA,dp      2,5
;    BB: INC dp+X        2,5
;    BC: INC A           1,2
;    BD: MOV SP,X        1,2
;    BE: DAS A           1,3
;    BF: MOV A,(X)+      1,4
;
; SPC700 opcodes 0xC0-0xCF:
;    C0: DI              1,3
;    C1: TCALL 12        1,8
;    C2: SET1 dp.6       2,4
;    C3: BBS dp.6,rel    3,5/7
;    C4: MOV dp,A        2,4
;    C5: MOV labs,A      3,5
;    C6: MOV (X),A       1,4
;    C7: MOV (dp+X),A    2,7
;    C8: CMP X,#imm      2,2
;    C9: MOV labs,X      3,5
;    CA: MOV1 mem.bit,C  3,6
;    CB: MOV dp,Y        2,4
;    CC: MOV labs,Y      3,5
;    CD: MOV X,#imm      2,2
;    CE: POP X           1,4
;    CF: MUL YA          1,9
;
; SPC700 opcodes 0xD0-0xDF:
;    D0: BNE rel         2,2/4
;    D1: TCALL 13        1,8
;    D2: CLR1 dp.6       2,4
;    D3: BBC dp.6,rel    3,5/7
;    D4: MOV dp+X,A      2,5
;    D5: MOV labs+X,A    3,6
;    D6: MOV labs+Y,A    3,6
;    D7: MOV (dp)+Y,A    2,7
;    D8: MOV dp,X        2,4
;    D9: MOV dp+Y,X      2,5
;    DA: MOVW dp,YA      2,4
;    DB: MOV dp+X,Y      2,5
;    DC: DEC Y           1,2
;    DD: MOV A,Y         1,2
;    DE: CBNE dp+X,rel   3,6/8
;    DF: DAA A           1,3
;
; SPC700 opcodes 0xE0-0xEF:
;    E0: CLRV            1,2
;    E1: TCALL 14        1,8
;    E2: SET1 dp.7       2,4
;    E3: BBS dp.7,rel    3,5/7
;    E4: MOV A,dp        2,3
;    E5: MOV A,labs      3,4
;    E6: MOV A,(X)       1,3
;    E7: MOV A,(dp+X)    2,6
;    E8: MOV A,#imm      2,2
;    E9: MOV X,labs      3,4
;    EA: NOT1 mem.bit    3,5
;    EB: MOV Y,dp        2,3
;    EC: MOV Y,labs      3,4
;    ED: NOTC            1,3
;    EE: POP Y           1,4
;    EF: SLEEP           1,3
;
; SPC700 opcodes 0xF0-0xFF:
;    F0: BEQ rel         2,2/4
;    F1: TCALL 15        1,8
;    F2: CLR1 dp.7       2,4
;    F3: BBC dp.7,rel    3,5/7
;    F4: MOV A,dp+X      2,4
;    F5: MOV A,labs+X    3,5
;    F6: MOV A,labs+Y    3,5
;    F7: MOV A,(dp)+Y    2,6
;    F8: MOV X,dp        2,3
;    F9: MOV X,dp+Y      2,4
;    FA: MOV dp(d),dp(s) 3,5
;    FB: MOV Y,dp+X      2,4
;    FC: INC Y           1,2
;    FD: MOV Y,A         1,2
;    FE: DBNZ Y,rel      2,4/6
;    FF: STOP            1,3
;

; 00
ALIGNC
EXPORT_C SPC_NOP
 inc R_NativePC
 OPCODE_EPILOG

; 01
TCALL 0
; 02 - SPC_SET1 in SPCmain.S
; 03 - SPC_BBS in SPCmain.S
; 04
SPC_OR_A dp
; 05
SPC_OR_A abs
; 06
SPC_OR_A OXO
; 07
SPC_OR_A OOdp_XOO
; 08
ALIGNC
EXPORT_C SPC_OR_A_IM
 SPC_OP_A_IM_NZ OR

; 09
SPC_OR_mem dp_dp
; 0A
ALIGNC
EXPORT_C SPC_OR1    ; Carry flag = Carry flag OR mem.bit
 ADDR_membit        ; bx contains mem and cx contains bit number
 GET_BYTE_SPC
 ; C |= (byte & bit)
 mov cl,[offset_to_bit+ecx]
 and al,cl
 mov cl,B_C_flag
 or al,cl
 STORE_FLAGS_C al
 OPCODE_EPILOG

; 0B
SPC_ASL dp
; 0C
SPC_ASL abs
; 0D
ALIGNC
EXPORT_C SPC_PUSH_PSW
 inc R_NativePC
 SETUPFLAGS_SPC
 PUSH_B
 OPCODE_EPILOG

; 0E
ALIGNC
EXPORT_C SPC_TSET1  ; I have done this as TSB (65816) including the flag setting based on AND
 mov cl,B_A
 ADDR_abs
 mov ah,cl
 GET_BYTE_SPC   ; Get byte
 and cl,al      ; NZ set for: mem & A
 or al,ah
 STORE_FLAGS_NZ cl
 SET_BYTE_SPC   ; mem |= A
 OPCODE_EPILOG

; 0F - BRK - Not yet implemented (maybe never)

; 10
SPC_BFC BPL,SPC_FLAG_N
; 11
TCALL 1
; 12 - SPC_CLR1 in SPCmain.S
; 13 - SPC_BBC in SPCmain.S
; 14
SPC_OR_A Odp_XO
; 15
SPC_OR_A Oabs_XO
; 16
SPC_OR_A Oabs_YO
; 17
SPC_OR_A OOdpO_YO
; 18
SPC_OR_mem dp_IM
; 19
SPC_OR_mem OXO_OYO
; 1A

ALIGNC
EXPORT_C SPC_DECW_dp
 ADDR_dp
 GET_WORD_SPC            ; get DP word
 dec eax
 mov cl,ah
 STORE_FLAGS_N ah
 or cl,al
 dec bx
 STORE_FLAGS_Z cl
 SET_WORD_SPC
 OPCODE_EPILOG

; 1B
SPC_ASL Odp_XO
; 1C

ALIGNC
EXPORT_C SPC_ASL_A
 mov al,B_A
 inc R_NativePC
 add al,al
 sbb cl,cl
 STORE_FLAGS_NZC al,cl
 mov B_A,al
 OPCODE_EPILOG

; 1D
SPC_DEC_reg X,B_X
; 1E
SPC_CMP_X abs
; 1F

ALIGNC
EXPORT_C SPC_JMP_Oabs_XO
 ADDR_Oabs_XO
 GET_WORD_SPC
 cmp eax,0xFFC0
 mov R_NativePC,eax
 mov eax,[SPC_FFC0_Address]
 jnb .possible_rom
 mov eax,_SPCRAM
.possible_rom:
 add R_NativePC,eax
 mov B_SPC_Code_Base,eax
 OPCODE_EPILOG

; 20
ALIGNC
EXPORT_C SPC_CLRP
 inc R_NativePC
 STORE_FLAGS_P ah
 mov B_SPC_PAGE_H,ah
 OPCODE_EPILOG

; 21
TCALL 2
; 22 - SPC_SET1 in SPCmain.S
; 23 - SPC_BBS in SPCmain.S
; 24
SPC_AND_A dp
; 25
SPC_AND_A abs
; 26
SPC_AND_A OXO
; 27
SPC_AND_A OOdp_XOO
; 28
ALIGNC
EXPORT_C SPC_AND_A_IM
 SPC_OP_A_IM_NZ AND

; 29
SPC_AND_mem dp_dp
; 2A
ALIGNC
EXPORT_C SPC_OR1C   ; Carry flag = Carry flag OR !mem.bit
 ADDR_membit    ; bx contains mem and cx contains bit number
 GET_BYTE_SPC
 ; C |= ((byte & bit) ^ bit)
 mov cl,[offset_to_bit+ecx]
 and al,cl
 xor al,cl
 mov cl,B_C_flag
 or al,cl
 STORE_FLAGS_C al
 OPCODE_EPILOG

; 2B
SPC_ROL dp
; 2C
SPC_ROL abs
; 2D
SPC_PUSH_reg A,B_A
; 2E
ALIGNC
EXPORT_C SPC_CBNE_dp
 mov ebx,B_SPC_PAGE
 mov bl,[1+R_NativePC]  ; get dp
 add R_NativePC,byte 3
 GET_BYTE_SPC           ; get (dp)
 cmp B_A,al
 je near SPC_RETURN

 movsx eax,byte [R_NativePC-1]  ; sign extend for addition
 add R_Cycles,byte 2    ; Branch taken
 add R_NativePC,eax
;add dword [_TotalCycles],byte 2    ; (0.32) Butcha - fix 'lost' SPC timer ticks!
 OPCODE_EPILOG

; 2F
ALIGNC
EXPORT_C SPC_BRA
 movsx eax,byte [1+R_NativePC]  ; sign extend for addition
 add R_NativePC,byte 2
 add R_NativePC,eax
 OPCODE_EPILOG

; 30
SPC_BFS BMI,SPC_FLAG_N
; 31
TCALL 3
; 32 - SPC_CLR1 in SPCmain.S
; 33 - SPC_BBC in SPCmain.S
; 34
SPC_AND_A Odp_XO
; 35
SPC_AND_A Oabs_XO
; 36
SPC_AND_A Oabs_YO
; 37
SPC_AND_A OOdpO_YO
; 38
SPC_AND_mem dp_IM
; 39
SPC_AND_mem OXO_OYO
; 3A

ALIGNC
EXPORT_C SPC_INCW_dp
 ADDR_dp
 GET_WORD_SPC       ; get DP word
 inc eax
 mov cl,ah
 STORE_FLAGS_N ah
 or cl,al
 dec bx
 STORE_FLAGS_Z cl
 SET_WORD_SPC
 OPCODE_EPILOG

; 3B
SPC_ROL Odp_XO
; 3C

ALIGNC
EXPORT_C SPC_ROL_A
 mov cl,B_C_flag
 inc R_NativePC
 add cl,255 ;MAKE_CARRY
 mov al,B_A
 adc al,al
 sbb cl,cl
 STORE_FLAGS_NZC al,cl
 mov B_A,al
 OPCODE_EPILOG

; 3D
SPC_INC_reg X,B_X
; 3E
SPC_CMP_X dp
; 3F

ALIGNC
EXPORT_C SPC_CALL
 GET_PC eax
 add eax,byte 3
 PUSH_W
 xor eax,eax
 mov al,[1+R_NativePC]
 mov ah,[2+R_NativePC]
 cmp eax,0xFFC0
 mov R_NativePC,eax
 mov eax,[SPC_FFC0_Address]
 jnb .possible_rom
 mov eax,_SPCRAM
.possible_rom:
 add R_NativePC,eax
 mov B_SPC_Code_Base,eax
 OPCODE_EPILOG

; 40
ALIGNC
EXPORT_C SPC_SETP
 mov al,1
 inc R_NativePC
 STORE_FLAGS_P al
 mov B_SPC_PAGE_H,al
 OPCODE_EPILOG

; 41
TCALL 4
; 42 - SPC_SET1 in SPCmain.S
; 43 - SPC_BBS in SPCmain.S
; 44
SPC_EOR_A dp
; 45
SPC_EOR_A abs
; 46
SPC_EOR_A OXO
; 47
SPC_EOR_A OOdp_XOO
; 48
ALIGNC
EXPORT_C SPC_EOR_A_IM
 SPC_OP_A_IM_NZ EOR

; 49
SPC_EOR_mem dp_dp
; 4A
ALIGNC
EXPORT_C SPC_AND1   ; Carry flag = Carry flag AND mem.bit
 ADDR_membit    ; bx contains mem and cx contains bit number
 GET_BYTE_SPC
 ; C = C && (byte & bit)
 mov cl,[offset_to_bit+ecx]
 and al,cl
 jnz near SPC_RETURN    ; C && 1 = C
 STORE_FLAGS_C al   ; C && 0 = 0
 OPCODE_EPILOG

; 4B
SPC_LSR dp
; 4C
SPC_LSR abs
; 4D
SPC_PUSH_reg X,B_X
; 4E
ALIGNC
EXPORT_C SPC_TCLR1  ; I have done this as TRB (65816) including the flag setting based on AND
 mov cl,B_A
 ADDR_abs
 mov ah,cl
 xor cl,0xFF
 GET_BYTE_SPC   ; Get byte
 and ah,al      ; NZ set for: mem & A
 STORE_FLAGS_NZ ah
 and al,cl
 SET_BYTE_SPC   ; mem &= ~A
 OPCODE_EPILOG

; 4F
ALIGNC
EXPORT_C SPC_PCALL  ; u-page is the last page on the SPC RAM (uppermost-page!)
 GET_PC eax
 add eax,byte 2
 PUSH_W
 mov eax,0xFF00
 mov al,[1+R_NativePC]  ; upage offset
 cmp al,0xC0
 mov R_NativePC,eax
 mov eax,[SPC_FFC0_Address]
 jnb .possible_rom
 mov eax,_SPCRAM
.possible_rom:
 add R_NativePC,eax
 mov B_SPC_Code_Base,eax
 OPCODE_EPILOG

; 50
SPC_BFC BVC,SPC_FLAG_V
; 51
TCALL 5
; 52 - SPC_CLR1 in SPCmain.S
; 53 - SPC_BBC in SPCmain.S
; 54
SPC_EOR_A Odp_XO
; 55
SPC_EOR_A Oabs_XO
; 56
SPC_EOR_A Oabs_YO
; 57
SPC_EOR_A OOdpO_YO
; 58
SPC_EOR_mem dp_IM
; 59
SPC_EOR_mem OXO_OYO
; 5A

ALIGNC
EXPORT_C SPC_CMPW_YA_dp
 ADDR_dp
 GET_WORD_SPC        ; get DP word
 mov edi,eax
 mov eax,B_YA
 sub ax,di
 ; (0.30) Butcha: + C flag
 sbb cl,cl
 or al,ah
 STORE_FLAGS_N ah
 xor cl,0xFF
 STORE_FLAGS_Z al
 STORE_FLAGS_C cl
 OPCODE_EPILOG

; 5B
SPC_LSR Odp_XO
; 5C

ALIGNC
EXPORT_C SPC_LSR_A
 mov al,B_A
 inc R_NativePC
 shr al,byte 1
 sbb cl,cl
 mov B_A,al
 STORE_FLAGS_NZC al,cl
 OPCODE_EPILOG

; 5D
SPC_MOV_reg_reg X__A,B_X,B_A
; 5E
SPC_CMP_Y abs
; 5F

ALIGNC
EXPORT_C SPC_JMP_abs
 mov al,[1+R_NativePC]
 mov ah,[2+R_NativePC]
 cmp eax,0xFFC0
 mov R_NativePC,eax
 mov eax,[SPC_FFC0_Address]
 jnb .possible_rom
 mov eax,_SPCRAM
.possible_rom:
 add R_NativePC,eax
 mov B_SPC_Code_Base,eax
 OPCODE_EPILOG

; 60
ALIGNC
EXPORT_C SPC_CLRC
 inc R_NativePC
 STORE_FLAGS_C ah
 OPCODE_EPILOG

; 61
TCALL 6
; 62 - SPC_SET1 in SPCmain.S
; 63 - SPC_BBS in SPCmain.S
; 64
SPC_CMP_A dp
; 65
SPC_CMP_A abs
; 66
SPC_CMP_A OXO
; 67
SPC_CMP_A OOdp_XOO
; 68
ALIGNC
EXPORT_C SPC_CMP_A_IM
 SPC_CMP_reg_IM B_A

; 69
SPC_CMP_mem dp_dp
; 6A
ALIGNC
EXPORT_C SPC_AND1C  ; Carry flag = Carry flag AND !mem.bit
 ADDR_membit    ; bx contains mem and cx contains bit number
 GET_BYTE_SPC
 ; C = C && !(byte & bit)
 mov cl,[offset_to_bit+ecx]
 and al,cl
 jz near SPC_RETURN     ; C && !0 = C
 STORE_FLAGS_C 0    ; C && !1 = 0
 OPCODE_EPILOG

; 6B
SPC_ROR dp
; 6C
SPC_ROR abs
; 6D
SPC_PUSH_reg Y,B_Y
; 6E
ALIGNC
EXPORT_C SPC_DBNZ_dp
 mov ebx,B_SPC_PAGE
 mov bl,[1+R_NativePC]  ; get dp
 add R_NativePC,byte 3
 GET_BYTE_SPC           ; get (dp)
 dec al
 SET_BYTE_SPC
 test al,al
 jz near SPC_RETURN

 movsx eax,byte [R_NativePC-1]  ; sign extend for addition
 add R_Cycles,byte 2    ; Branch taken
 add R_NativePC,eax
;add dword [_TotalCycles],byte 2    ; (0.32) Butcha - fix 'lost' SPC timer ticks!
 OPCODE_EPILOG

; 6F
ALIGNC
EXPORT_C SPC_RET
 POP_W
 cmp eax,0xFFC0
 mov R_NativePC,eax
 mov eax,[SPC_FFC0_Address]
 jnb .possible_rom
 mov eax,_SPCRAM
.possible_rom:
 add R_NativePC,eax
 mov B_SPC_Code_Base,eax
 OPCODE_EPILOG

; 70
SPC_BFS BVS,SPC_FLAG_V
; 71
TCALL 7
; 72 - SPC_CLR1 in SPCmain.S
; 73 - SPC_BBC in SPCmain.S
; 74
SPC_CMP_A Odp_XO
; 75
SPC_CMP_A Oabs_XO
; 76
SPC_CMP_A Oabs_YO
; 77
SPC_CMP_A OOdpO_YO
; 78
SPC_CMP_mem dp_IM
; 79
SPC_CMP_mem OXO_OYO
; 7A

ALIGNC
EXPORT_C SPC_ADDW_YA_dp
 STORE_FLAGS_V ah
 ADDR_dp
 GET_WORD_SPC        ; get DP word
 mov ebx,B_YA
 add bx,ax
 lahf
 mov B_YA,ebx
 jno .no_overflow
 STORE_FLAGS_V 1
.no_overflow:
 sbb cl,cl
 STORE_FLAGS_N bh
 or bl,bh
 STORE_FLAGS_C cl
 STORE_FLAGS_Z bl
 STORE_FLAGS_H ah
 OPCODE_EPILOG

; 7B
SPC_ROR Odp_XO
; 7C

ALIGNC
EXPORT_C SPC_ROR_A
 mov cl,B_C_flag
 inc R_NativePC
 add cl,255 ;MAKE_CARRY
 mov al,B_A
 rcr al,1
 sbb cl,cl
 mov B_A,al
 STORE_FLAGS_NZC al,cl
 OPCODE_EPILOG

; 7D
SPC_MOV_reg_reg A__X,B_A,B_X
; 7E
SPC_CMP_Y dp
; 7F - RETI - not yet implemented

; 80
ALIGNC
EXPORT_C SPC_SETC
 mov al,1
 inc R_NativePC
 STORE_FLAGS_C al
 OPCODE_EPILOG

; 81
TCALL 8
; 82 - SPC_SET1 in SPCmain.S
; 83 - SPC_BBS in SPCmain.S
; 84
SPC_ADC_A dp
; 85
SPC_ADC_A abs
; 86
SPC_ADC_A OXO
; 87
SPC_ADC_A OOdp_XOO
; 88
ALIGNC
EXPORT_C SPC_ADC_A_IM
 STORE_FLAGS_V ah
 mov al,[1+R_NativePC]
 mov cl,B_C_flag
 add R_NativePC,byte 2
 add cl,255 ;MAKE_CARRY
 mov cl,B_A
 adc cl,al
 lahf
 mov B_A,cl
 jno .no_overflow
 STORE_FLAGS_V 1
.no_overflow:
 sbb al,al
 STORE_FLAGS_NZ cl
 STORE_FLAGS_C al
 STORE_FLAGS_H ah
 OPCODE_EPILOG

; 89
SPC_ADC_mem dp_dp
; 8A
ALIGNC
EXPORT_C SPC_EOR1   ; Carry flag = Carry flag EOR mem.bit
 ADDR_membit    ; bx contains mem and cx contains bit number
 GET_BYTE_SPC
 mov cl,[offset_to_bit+ecx]
 and al,cl
 jz near SPC_RETURN     ; C = C EOR 0 -> C = C
 mov al,B_C_flag
 cmp al,1
 sbb al,al
 STORE_FLAGS_C al   ; C = C EOR 1 -> C = !C
 OPCODE_EPILOG

; 8B
SPC_DEC dp
; 8C
SPC_DEC abs
; 8D
ALIGNC
EXPORT_C SPC_MOV_Y_IM
 SPC_MOV_reg_IM B_Y

; 8E
ALIGNC
EXPORT_C SPC_POP_PSW
 inc R_NativePC
 POP_B
 RESTOREFLAGS_SPC
 OPCODE_EPILOG

; 8F
ALIGNC
EXPORT_C SPC_MOV_dp_IM
 ADDR2_dp_IM al ; immediate byte in al
 SET_BYTE_SPC
 OPCODE_EPILOG

; 90
SPC_BFC BCC,SPC_FLAG_C
; 91
TCALL 9
; 92 - SPC_CLR1 in SPCmain.S
; 93 - SPC_BBC in SPCmain.S
; 94
SPC_ADC_A Odp_XO
; 95
SPC_ADC_A Oabs_XO
; 96
SPC_ADC_A Oabs_YO
; 97
SPC_ADC_A OOdpO_YO
; 98
SPC_ADC_mem dp_IM
; 99
SPC_ADC_mem OXO_OYO
; 9A

ALIGNC
EXPORT_C SPC_SUBW_YA_dp
 STORE_FLAGS_V ah
 ADDR_dp
 GET_WORD_SPC        ; get DP word
 mov ebx,B_YA
 sub bx,ax
 lahf
 mov B_YA,ebx
 jno .no_overflow
 STORE_FLAGS_V 1
.no_overflow:
 sbb cl,cl
 STORE_FLAGS_N bh
 or bl,bh
 xor cl,0xFF
 STORE_FLAGS_Z bl
 STORE_FLAGS_C cl
 STORE_FLAGS_H ah
 OPCODE_EPILOG

; 9B
SPC_DEC Odp_XO
; 9C
SPC_DEC_reg A,B_A
; 9D
SPC_MOV_reg_reg X__SP,B_X,B_SP
; 9E

ALIGNC
EXPORT_C SPC_DIV    ; This may not be 100% due to overflow checking!
 inc R_NativePC
 xor ebx,ebx
 mov bl,B_X
 test bl,bl         ; If zero skip divide!
 jz .overflow
 mov ax,B_YA        ; Dividend
 xor edx,edx
 div bx             ; Result is ax=quotient,dx=remainder
 test ah,ah         ; Check for overflow
 jnz .overflow
.no_overflow:
 mov [_Y],dl        ; Remainder in Y
 LOAD_BASE
 mov [_A],al        ; Quotient in A
 STORE_FLAGS_V ah
 STORE_FLAGS_NZ al
 OPCODE_EPILOG
ALIGNC
.overflow:
 LOAD_BASE
 mov ebx,0x80
 mov dword [_YA],0xFFFF
 STORE_FLAGS_N bl
 STORE_FLAGS_Z bl
 STORE_FLAGS_V bl
 OPCODE_EPILOG

; 9F

ALIGNC
EXPORT_C SPC_XCN
 mov al,B_A
 rol al,4
 inc R_NativePC
 mov B_A,al
 STORE_FLAGS_NZ al
 OPCODE_EPILOG

; A0
ALIGNC
EXPORT_C SPC_EI
 mov al,1
 inc R_NativePC
 STORE_FLAGS_I al
 OPCODE_EPILOG

; A1
TCALL 10
; A2 - SPC_SET1 in SPCmain.S
; A3 - SPC_BBS in SPCmain.S
; A4
SPC_SBC_A dp
; A5
SPC_SBC_A abs
; A6
SPC_SBC_A OXO
; A7
SPC_SBC_A OOdp_XOO
; A8 
ALIGNC
EXPORT_C SPC_SBC_A_IM
 STORE_FLAGS_V ah
 mov al,[1+R_NativePC]
 mov cl,B_C_flag
 add R_NativePC,byte 2
 cmp cl,1 ;MAKE_NOT_CARRY
 mov cl,B_A
 sbb cl,al
 lahf
 mov B_A,cl
 jno .no_overflow
 STORE_FLAGS_V 1
.no_overflow:
 sbb al,al
 STORE_FLAGS_N cl
 xor al,0xFF
 STORE_FLAGS_Z cl
 STORE_FLAGS_C al
 STORE_FLAGS_H ah
 OPCODE_EPILOG

; A9
SPC_SBC_mem dp_dp
; AA
ALIGNC
EXPORT_C SPC_MOV1_C_    ; Carry flag = mem.bit
 ADDR_membit        ; bx contains mem and cx contains bit number
 GET_BYTE_SPC
 mov cl,[offset_to_bit+ecx]
 and al,cl
 STORE_FLAGS_C al
 OPCODE_EPILOG

; AB
SPC_INC dp
; AC
SPC_INC abs
; AD
ALIGNC
EXPORT_C SPC_CMP_Y_IM
 SPC_CMP_reg_IM B_Y

; AE
SPC_POP_reg A,B_A
; AF
ALIGNC
EXPORT_C SPC_MOV_OXOInc_A
 ADDR_OXOInc
 mov al,B_A
 SET_BYTE_SPC
 OPCODE_EPILOG

; B0
SPC_BFS BCS,SPC_FLAG_C
; B1
TCALL 11
; B2 - SPC_CLR1 in SPCmain.S
; B3 - SPC_BBC in SPCmain.S
; B4
SPC_SBC_A Odp_XO
; B5
SPC_SBC_A Oabs_XO
; B6
SPC_SBC_A Oabs_YO
; B7
SPC_SBC_A OOdpO_YO
; B8
SPC_SBC_mem dp_IM
; B9
SPC_SBC_mem OXO_OYO
; BA

ALIGNC
EXPORT_C SPC_MOVW_YA_dp
 ADDR_dp
 xor eax,eax
 GET_WORD_SPC
 mov cl,al
 mov B_YA,eax
 or cl,ah
 STORE_FLAGS_N ah
 STORE_FLAGS_Z cl
 OPCODE_EPILOG

; BB
SPC_INC Odp_XO
; BC
SPC_INC_reg A,B_A
; BD

ALIGNC
EXPORT_C SPC_MOV_SP_X
 mov al,B_X
 inc R_NativePC
 mov B_SP,al
 OPCODE_EPILOG

; BE - DAS - not yet implemented
; BF

ALIGNC
EXPORT_C SPC_MOV_A_OXOInc
 ADDR_OXOInc
 GET_BYTE_SPC
 mov B_A,al
 STORE_FLAGS_NZ al
 OPCODE_EPILOG

; C0
ALIGNC
EXPORT_C SPC_DI
 inc R_NativePC
 STORE_FLAGS_I ah
 OPCODE_EPILOG

; C1
TCALL 12
; C2 - SPC_SET1 in SPCmain.S
; C3 - SPC_BBS in SPCmain.S
; C4
SPC_MOV_mem_A dp
; C5
SPC_MOV_mem_A abs
; C6
SPC_MOV_mem_A OXO
; C7
SPC_MOV_mem_A OOdp_XOO
; C8
ALIGNC
EXPORT_C SPC_CMP_X_IM
 SPC_CMP_reg_IM B_X

; C9
SPC_MOV_mem_X abs
; CA
ALIGNC
EXPORT_C SPC_MOV1__C    ; mem.bit = Carry flag
 ADDR_membit        ; bx contains mem and cx contains bit number
 GET_BYTE_SPC

 mov ah,B_C_flag
 test ah,ah
 jz .clear_bit

 mov cl,[offset_to_bit+ecx]
 or al,cl
 SET_BYTE_SPC
 OPCODE_EPILOG

ALIGNC
.clear_bit:
 mov cl,[offset_to_not+ecx]
 and al,cl
 SET_BYTE_SPC
 OPCODE_EPILOG

; CB
SPC_MOV_mem_Y dp
; CC
SPC_MOV_mem_Y abs
; CD
ALIGNC
EXPORT_C SPC_MOV_X_IM
 SPC_MOV_reg_IM B_X

; CE
SPC_POP_reg X,B_X
; CF
ALIGNC
EXPORT_C SPC_MUL
 inc R_NativePC
 mov al,B_Y
 mul byte B_A
 mov cl,al
 mov B_YA,eax
 or cl,ah
 STORE_FLAGS_N ah
 STORE_FLAGS_Z cl
 OPCODE_EPILOG

; D0
SPC_BFC BNE,SPC_FLAG_Z
; D1
TCALL 13
; D2 - SPC_CLR1 in SPCmain.S
; D3 - SPC_BBC in SPCmain.S
; D4
SPC_MOV_mem_A Odp_XO
; D5
SPC_MOV_mem_A Oabs_XO
; D6
SPC_MOV_mem_A Oabs_YO
; D7
SPC_MOV_mem_A OOdpO_YO
; D8
SPC_MOV_mem_X dp
; D9
SPC_MOV_mem_X Odp_YO
; DA

ALIGNC
EXPORT_C SPC_MOVW_dp_YA
 ADDR_dp
 mov eax,B_YA
 SET_WORD_SPC
 OPCODE_EPILOG

; DB
SPC_MOV_mem_Y Odp_XO
; DC
SPC_DEC_reg Y,B_Y
; DD
SPC_MOV_reg_reg A__Y,B_A,B_Y
; DE

ALIGNC
EXPORT_C SPC_CBNE_Odp_XO
 mov ebx,B_SPC_PAGE
 mov al,B_X
 mov bl,[1+R_NativePC]  ; get dp
 add R_NativePC,byte 3
 add bl,al
 GET_BYTE_SPC           ; Get (dp)
 cmp B_A,al
 je near SPC_RETURN

 movsx eax,byte [R_NativePC-1]  ; sign extend for addition
 add R_Cycles,byte 2    ; Branch taken
 add R_NativePC,eax
;add dword [_TotalCycles],byte 2
 OPCODE_EPILOG

; DF - DAA - not yet implemented

; E0
ALIGNC
EXPORT_C SPC_CLRV
 inc R_NativePC
 STORE_FLAGS_H ah
 STORE_FLAGS_V ah
 OPCODE_EPILOG

; E1
TCALL 14
; E2 - SPC_SET1 in SPCmain.S
; E3 - SPC_BBS in SPCmain.S
; E4
SPC_MOV_A_mem dp
; E5
SPC_MOV_A_mem abs
; E6
SPC_MOV_A_mem OXO
; E7
SPC_MOV_A_mem OOdp_XOO
; E8
ALIGNC
EXPORT_C SPC_MOV_A_IM
 SPC_MOV_reg_IM B_A

; E9
SPC_MOV_X_mem abs
; EA
ALIGNC
EXPORT_C SPC_NOT1   ; !mem.bit
 ADDR_membit    ; bx contains mem and cx contains bit number
 GET_BYTE_SPC
 mov cl,[offset_to_bit+ecx]
 xor al,cl      ; complement the bit
 SET_BYTE_SPC
 OPCODE_EPILOG

; EB
SPC_MOV_Y_mem dp
; EC
SPC_MOV_Y_mem abs
; ED
ALIGNC
EXPORT_C SPC_NOTC
 mov al,B_C_flag
 inc R_NativePC
 cmp al,1
 sbb al,al
 STORE_FLAGS_C al
 OPCODE_EPILOG

; EE
SPC_POP_reg Y,B_Y
; EF
ALIGNC
EXPORT_C SPC_SLEEP
 OPCODE_EPILOG  ; What else can sleep do?

; F0
SPC_BFS BEQ,SPC_FLAG_Z
; F1
TCALL 15
; F2 - SPC_CLR1 in SPCmain.S
; F3 - SPC_BBC in SPCmain.S
; F4
SPC_MOV_A_mem Odp_XO
; F5
SPC_MOV_A_mem Oabs_XO
; F6
SPC_MOV_A_mem Oabs_YO
; F7
SPC_MOV_A_mem OOdpO_YO
; F8
SPC_MOV_X_mem dp
; F9
SPC_MOV_X_mem Odp_YO
; FA

ALIGNC
EXPORT_C SPC_MOV_dp_dp
 ADDR2_dp_dp al ; al is (s), bx d
 SET_BYTE_SPC
 OPCODE_EPILOG

; FB
SPC_MOV_Y_mem Odp_XO
; FC
SPC_INC_reg Y,B_Y
; FD
SPC_MOV_reg_reg Y__A,B_Y,B_A
; FE

ALIGNC
EXPORT_C SPC_DBNZ_Y
 mov al,B_Y
 add R_NativePC,byte 2
 dec al
 mov B_Y,al
 jz near SPC_RETURN

 movsx eax,byte [R_NativePC-1]  ; sign extend for addition
 add R_Cycles,byte 2    ; Branch taken
 add R_NativePC,eax
;add dword [_TotalCycles],byte 2    ; (0.32) Butcha - fix 'lost' SPC timer ticks!
 OPCODE_EPILOG

; FF

ALIGNC
EXPORT_C SPC_STOP
 OPCODE_EPILOG  ; What else can stop do?
