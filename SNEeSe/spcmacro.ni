%if 0

SNEeSe, an Open Source Super NES emulator.


Copyright (c) 2002 Charles Bilyue'.

This is free software.  See 'LICENSE' for details.
You must read and accept the license prior to use.

%endif

; SPC instruction macros
;  Original code by Savoury SnaX
;  Rewritten/maintained by TRAC

; TCALL: Call through table in pageable 64-bytes of RAM
;%1 = vecnum
%macro TCALL 0-1
ALIGNC
EXPORT_C SPC_TCALL_%1
 GET_PC eax
 inc eax
 PUSH_W
 xor eax,eax
 mov ax,[_SPCRAM+0xFFC0+((15 - (%1)) << 1)]
 cmp eax,0xFFC0
 mov R_NativePC,eax
 mov eax,[SPC_FFC0_Address]
 jnb .possible_rom
 mov eax,_SPCRAM
.possible_rom:
 add R_NativePC,eax
 mov [SPC_Code_Base],eax
 OPCODE_EPILOG
%endmacro

;%1 = label, %2 = flag
%macro SPC_BFC 2
ALIGNC
EXPORT_C SPC_%1
 add R_NativePC,byte 2
 JUMP_FLAG_SPC %2,near SPC_RETURN   ; flag set
 movsx eax,byte [-1+R_NativePC]     ; sign extend for addition
 add R_Cycles,byte 2                ; Branch taken
;add dword [_TotalCycles],byte 2    ; (0.32) Butcha - fix 'lost' SPC timer ticks!
 add R_NativePC,eax
 OPCODE_EPILOG
%endmacro

;%1 = label, %2 = flag
%macro SPC_BFS 2
ALIGNC
EXPORT_C SPC_%1
 add R_NativePC,byte 2
 JUMP_NOT_FLAG_SPC %2,near SPC_RETURN   ; flag set
 movsx eax,byte [-1+R_NativePC]     ; sign extend for addition
 add R_Cycles,byte 2                ; Branch taken
;add dword [_TotalCycles],byte 2    ; (0.32) Butcha - fix 'lost' SPC timer ticks!
 add R_NativePC,eax
 OPCODE_EPILOG
%endmacro

;%1 = op
%macro SPC_OP_A_IM_NZ 1
 mov al,[1+R_NativePC]
 mov cl,B_A
 add R_NativePC,byte 2
 SPC_BASE_%1 cl,al
 mov B_A,cl
 STORE_FLAGS_NZ cl
 OPCODE_EPILOG
%endmacro

;%1 = reg
%macro SPC_MOV_reg_IM 1
 mov al,[1+R_NativePC]
 add R_NativePC,byte 2
 mov %1,al
 STORE_FLAGS_NZ al
 OPCODE_EPILOG
%endmacro

;%1 = reg
%macro SPC_CMP_reg_IM 1
 mov al,[1+R_NativePC]
 mov cl,%1
 add R_NativePC,byte 2
 sub cl,al
 sbb al,al
 STORE_FLAGS_N cl
 xor al,0xFF
 STORE_FLAGS_Z cl
 STORE_FLAGS_C al
 OPCODE_EPILOG
%endmacro

;%1 = op, %2 = reg, %3 = addr
%macro SPC_OP_REG_NZ 3
 ADDR_%3
 mov cl,%2
 GET_BYTE_SPC
 SPC_BASE_%1 cl,al
 mov %2,cl
 STORE_FLAGS_NZ cl
 OPCODE_EPILOG
%endmacro

;%1 = op, %2 = addr
%macro SPC_OP_mem_NZ 2
 ADDR2_%2 cl        ; cl is source byte, bx dest address
 GET_BYTE_SPC       ; al contains byte at dest address
 SPC_BASE_%1 al,cl
 STORE_FLAGS_NZ al
 SET_BYTE_SPC
 OPCODE_EPILOG
%endmacro

;%1 = dest, %2 = src
%macro SPC_BASE_MOV 2
 mov byte %1,%2
%endmacro

;%1 = dest, %2 = src
%macro SPC_BASE_OR 2
 or %1,%2
%endmacro

;%1 = addr
%macro SPC_OR_A 1
ALIGNC
EXPORT_C SPC_OR_A_%1
 SPC_OP_REG_NZ OR,B_A,%1
%endmacro

;%1 = addr
%macro SPC_OR_mem 1
ALIGNC
EXPORT_C SPC_OR_%1
 SPC_OP_mem_NZ OR,%1
%endmacro

;%1 = dest, %2 = src
%macro SPC_BASE_AND 2
 and %1,%2
%endmacro

;%1 = addr
%macro SPC_AND_A 1
ALIGNC
EXPORT_C SPC_AND_A_%1
 SPC_OP_REG_NZ AND,B_A,%1
%endmacro

;%1 = addr
%macro SPC_AND_mem 1
ALIGNC
EXPORT_C SPC_AND_%1
 SPC_OP_mem_NZ AND,%1
%endmacro

;%1 = dest, %2 = src
%macro SPC_BASE_EOR 2
 xor %1,%2
%endmacro

;%1 = addr
%macro SPC_EOR_A 1
ALIGNC
EXPORT_C SPC_EOR_A_%1
 SPC_OP_REG_NZ EOR,B_A,%1
%endmacro

;%1 = addr
%macro SPC_EOR_mem 1
ALIGNC
EXPORT_C SPC_EOR_%1
 SPC_OP_mem_NZ EOR,%1
%endmacro

;%1 = reg, %2 = addr
%macro SPC_CMP 2
 ADDR_%2
 mov cl,%1
 GET_BYTE_SPC
 sub cl,al
 sbb al,al
 STORE_FLAGS_N cl
 xor al,0xFF
 STORE_FLAGS_Z cl
 STORE_FLAGS_C al
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_CMP_A 1
ALIGNC
EXPORT_C SPC_CMP_A_%1
 SPC_CMP B_A,%1
%endmacro

;%1 = addr
%macro SPC_CMP_X 1
ALIGNC
EXPORT_C SPC_CMP_X_%1
 SPC_CMP B_X,%1
%endmacro

;%1 = addr
%macro SPC_CMP_Y 1
ALIGNC
EXPORT_C SPC_CMP_Y_%1
 SPC_CMP B_Y,%1
%endmacro

;%1 = addr
%macro SPC_CMP_mem 1
ALIGNC
EXPORT_C SPC_CMP_%1
 ADDR2_%1 cl        ; cl is source byte, bx dest address
 GET_BYTE_SPC       ; al contains byte at dest address
 sub al,cl
 sbb cl,cl
 STORE_FLAGS_N al
 xor cl,0xFF
 STORE_FLAGS_Z al
 STORE_FLAGS_C cl
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_ADC_A 1
ALIGNC
EXPORT_C SPC_ADC_A_%1
;STORE_FLAGS_V ah
 ADDR_%1
 mov cl,B_C_flag
 GET_BYTE_SPC
 add cl,255 ;MAKE_CARRY
 mov cl,B_A
 adc cl,al
 lahf
 mov B_A,cl
;jno .no_overflow
;STORE_FLAGS_V 1
 seto B_V_flag
.no_overflow:
 sbb al,al
 STORE_FLAGS_NZC cl,al
 STORE_FLAGS_H ah
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_ADC_mem 1
ALIGNC
EXPORT_C SPC_ADC_%1
;STORE_FLAGS_V ah
 ADDR2_%1 cl
 mov ah,B_C_flag
 GET_BYTE_SPC
 add ah,255 ;MAKE_CARRY
 adc al,cl
 lahf
 STORE_FLAGS_N al
;jno .no_overflow
;STORE_FLAGS_V 1
 seto B_V_flag
.no_overflow:
 sbb cl,cl
 STORE_FLAGS_Z al
 STORE_FLAGS_C cl
 STORE_FLAGS_H ah
 SET_BYTE_SPC
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_SBC_A 1
ALIGNC
EXPORT_C SPC_SBC_A_%1
;STORE_FLAGS_V ah
 ADDR_%1
 mov cl,B_C_flag
 GET_BYTE_SPC
 cmp cl,1 ;MAKE_NOT_CARRY
 mov cl,B_A
 sbb cl,al
 lahf
 mov B_A,cl
;jno .no_overflow
;STORE_FLAGS_V 1
 seto B_V_flag
.no_overflow:
 sbb al,al
 STORE_FLAGS_N cl
 xor al,0xFF
 STORE_FLAGS_Z cl
 STORE_FLAGS_C al
 STORE_FLAGS_H ah
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_SBC_mem 1
ALIGNC
EXPORT_C SPC_SBC_%1
;STORE_FLAGS_V ah
 ADDR2_%1 cl
 mov ah,B_C_flag
 GET_BYTE_SPC
 cmp ah,1 ;MAKE_NOT_CARRY
 sbb al,cl      ; (0.30) Butcha - switched these, wrong order
 lahf
 STORE_FLAGS_N al
;jno .no_overflow
;STORE_FLAGS_V 1
 seto B_V_flag
.no_overflow:
 sbb cl,cl
 STORE_FLAGS_Z al
 xor cl,0xFF
 STORE_FLAGS_H ah
 STORE_FLAGS_C cl
 SET_BYTE_SPC
 OPCODE_EPILOG
%endmacro

;%1 = label, %2 = reg
%macro SPC_DEC_reg 2
ALIGNC
EXPORT_C SPC_DEC_%1
 mov al,%2
 inc R_NativePC
 dec al
 mov %2,al
 STORE_FLAGS_NZ al
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_DEC 1
ALIGNC
EXPORT_C SPC_DEC_%1
 ADDR_%1
 GET_BYTE_SPC
 dec al
 STORE_FLAGS_NZ al
 SET_BYTE_SPC
 OPCODE_EPILOG
%endmacro

;%1 = label, %2 = reg
%macro SPC_INC_reg 2
ALIGNC
EXPORT_C SPC_INC_%1
 mov al,%2
 inc R_NativePC
 inc al
 mov %2,al
 STORE_FLAGS_NZ al
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_INC 1
ALIGNC
EXPORT_C SPC_INC_%1
 ADDR_%1
 GET_BYTE_SPC
 inc al
 STORE_FLAGS_NZ al
 SET_BYTE_SPC
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_ASL 1
ALIGNC
EXPORT_C SPC_ASL_%1
 ADDR_%1
 GET_BYTE_SPC
 add al,al
 sbb cl,cl
 STORE_FLAGS_NZC al,cl
 SET_BYTE_SPC
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_LSR 1
ALIGNC
EXPORT_C SPC_LSR_%1
 ADDR_%1
 GET_BYTE_SPC
 shr al,byte 1
 sbb cl,cl
 STORE_FLAGS_NZC al,cl
 SET_BYTE_SPC
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_ROL 1
ALIGNC
EXPORT_C SPC_ROL_%1
 ADDR_%1
 mov cl,B_C_flag
 GET_BYTE_SPC
 add cl,255 ;MAKE_CARRY
 adc al,al
 sbb cl,cl
 STORE_FLAGS_NZC al,cl
 SET_BYTE_SPC
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_ROR 1
ALIGNC
EXPORT_C SPC_ROR_%1
 ADDR_%1
 mov cl,B_C_flag
 GET_BYTE_SPC
 add cl,255 ;MAKE_CARRY
 rcr al,1
 sbb cl,cl
 STORE_FLAGS_NZC al,cl
 SET_BYTE_SPC
 OPCODE_EPILOG
%endmacro

;%1 = label, %2 = dest, %3 = src
%macro SPC_MOV_reg_reg 3
ALIGNC
EXPORT_C SPC_MOV_%1
 mov al,%3
 inc R_NativePC
 mov %2,al
 STORE_FLAGS_NZ al
 OPCODE_EPILOG
%endmacro

;%1 = addr, %2 = reg
%macro SPC_MOV_mem_reg 2
 ADDR_%1
 mov al,%2
 SET_BYTE_SPC
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_MOV_mem_A 1
ALIGNC
EXPORT_C SPC_MOV_%1__A
 SPC_MOV_mem_reg %1,B_A
%endmacro

;%1 = addr
%macro SPC_MOV_mem_X 1
ALIGNC
EXPORT_C SPC_MOV_%1__X
 SPC_MOV_mem_reg %1,B_X
%endmacro

;%1 = addr
%macro SPC_MOV_mem_Y 1
ALIGNC
EXPORT_C SPC_MOV_%1__Y
 SPC_MOV_mem_reg %1,B_Y
%endmacro

;%1 = reg, %2 = addr
%macro SPC_MOV_reg_mem 2
 ADDR_%2
 GET_BYTE_SPC
 mov %1,al
 STORE_FLAGS_NZ al
 OPCODE_EPILOG
%endmacro

;%1 = addr
%macro SPC_MOV_A_mem 1
ALIGNC
EXPORT_C SPC_MOV_A_%1
 SPC_MOV_reg_mem B_A,%1
%endmacro

;%1 = addr
%macro SPC_MOV_X_mem 1
ALIGNC
EXPORT_C SPC_MOV_X_%1
 SPC_MOV_reg_mem B_X,%1
%endmacro

;%1 = addr
%macro SPC_MOV_Y_mem 1
ALIGNC
EXPORT_C SPC_MOV_Y_%1
 SPC_MOV_reg_mem B_Y,%1
%endmacro

;%1 = label, %2 = reg
%macro SPC_PUSH_reg 2
ALIGNC
EXPORT_C SPC_PUSH_%1
 inc R_NativePC
 mov al,%2
 PUSH_B
 OPCODE_EPILOG
%endmacro

;%1 = label, %2 = reg
%macro SPC_POP_reg 2
ALIGNC
EXPORT_C SPC_POP_%1
 inc R_NativePC
 POP_B
 mov %2,al
 OPCODE_EPILOG
%endmacro
