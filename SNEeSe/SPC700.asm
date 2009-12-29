%if 0

SNEeSe, an Open Source Super NES emulator.


Copyright (c) 2002 Charles Bilyue'.

This is free software.  See 'LICENSE' for details.
You must read and accept the license prior to use.

* This code modified by Brad Martin for use with OpenSPC.  Derived from
* SNEeSe version .74.  Changes include removing code and variables that are
* unnecessary in this application, exporting some variables that needed to
* be accessed from outside these sources, and other small tweaks.  Last date
* of modification: Jan 8th 2003.

%endif

; SNEeSe SPC700 CPU emulation core
; Originally written by Lee Hammerton in AT&T assembly
; Maintained/rewritten/ported to NASM by Charles Bilyue'
;
; Compile under NASM
; This code assumes preservation of ebx, ebp, esi, edi in C/C++ calls

;%define TRACKERS 1048576
;%define WATCH_SPC_BREAKS
%define LOG_SOUND_DSP_READ
%define LOG_SOUND_DSP_WRITE
;%define TRAP_INVALID_READ
;%define TRAP_INVALID_WRITE

;%define UPDATE_SOUND_ON_RAM_WRITE

extern _SPC_DSP

extern _SPC_DSP_DATA
extern _SPC_READ_DSP,_SPC_WRITE_DSP
extern _Wrap_SPC_Cyclecounter
extern _Map_Byte,_Map_Address

extern _DisplaySPC

; This file contains:
;  CPU core info
;  Reset
;  Execution Loop
;  Invalid Opcode Handler
;  Flag format conversion tables
;  Variable definitions (registers, interrupt vectors, etc.)
;  CPU opcode emulation handlers
;  CPU opcode handler table
;  CPU opcode timing table
;
; CPU core info:
;  Nearly all general registers are now used in SPC700 emulation:
;   EAX,EBX are used by the memory mapper;
;   EDX is used as CPU work register;
;   EBP is used to hold cycle counter;
;   ESI is used by the opcode fetcher;
;   EDI is used as memory mapper work register.
;
;    A register              - _A
;    Y register              - _Y
;    YA register pair        - _YA
;    X register              - _X
;    Stack pointer           - _SP
;    Program Counter         - _PC
;    Processor status word   - _PSW
;       True x86 layout = |V|-|-|-|S|Z|-|A|-|-|-|C|
;    True SPC700 layout =         |N|V|P|B|H|I|Z|C|
;                   Using         |N|Z|P|H|B|I|V|C|
;
; SPC timers
;  SPC700 timing is not directly related to 65c816 timing, but for
;   simplicity in emulation we act as if it is. SPC gets 11264 cycles
;   for every 118125 (21.47727..MHz) 65c816 cycles. Since the timers
;   run at ~8KHz and ~64KHz and the main chip runs at 2.048Mhz, the
;   timers are clocked as follows:
;    2.048MHz / 8KHz  = 256 cycles    (Timers 0 and 1)
;    2.048MHz / 64KHz = 32  cycles    (Timer 2)
;
;

%define SNEeSe_SPC700_asm

%include "misc.ni"
%include "spc.ni"

extern _SPCRAM

section .text
EXPORT_C SPC_text_start
section .data
EXPORT_C SPC_data_start
section .bss
EXPORT_C SPC_bss_start

%define _SPC_CTRL 0xF1
%define _SPC_DSP_ADDR 0xF2

; These are the bits for flag set/clr operations
SPC_FLAG_C equ 1    ; Carry
SPC_FLAG_V equ 2    ; Overflow
SPC_FLAG_I equ 4    ; Interrupt Disable
SPC_FLAG_B equ 8    ; Break
SPC_FLAG_H equ 0x10 ; Half-carry
SPC_FLAG_P equ 0x20 ; Page (direct page)
SPC_FLAG_Z equ 0x40 ; Zero result
SPC_FLAG_N equ 0x80 ; Negative result

SPC_FLAG_NZ equ (SPC_FLAG_N | SPC_FLAG_Z)
SPC_FLAG_NZC equ (SPC_FLAG_NZ | SPC_FLAG_C)
SPC_FLAG_NHZC equ (SPC_FLAG_NZC | SPC_FLAG_H)

REAL_SPC_FLAG_C equ 1       ; Carry
REAL_SPC_FLAG_Z equ 2       ; Zero result
REAL_SPC_FLAG_I equ 4       ; Interrupt Disable
REAL_SPC_FLAG_H equ 8       ; Half-carry
REAL_SPC_FLAG_B equ 0x10    ; Break
REAL_SPC_FLAG_P equ 0x20    ; Page (direct page)
REAL_SPC_FLAG_V equ 0x40    ; Overflow
REAL_SPC_FLAG_N equ 0x80    ; Negative result

%define _PSW __SPC_PSW
%define _YA __SPC_YA
%define _A  __SPC_A
%define _Y  __SPC_Y
%define _X  __SPC_X
%define _SP __SPC_SP
%define _PC __SPC_PC

%define R_Base       R_SPC700_Base
%define R_Cycles     R_SPC700_Cycles
%define R_NativePC   R_SPC700_NativePC


%define B_SPC_Code_Base     [R_Base-SPC_Register_Base+SPC_Code_Base]
%define B_PC                [R_Base-SPC_Register_Base+_PC]
%define B_YA                [R_Base-SPC_Register_Base+_YA]
%define B_A                 [R_Base-SPC_Register_Base+_A]
%define B_Y                 [R_Base-SPC_Register_Base+_Y]
%define B_SPC_PAGE          [R_Base-SPC_Register_Base+SPC_PAGE]
%define B_SPC_PAGE_H        byte [R_Base-SPC_Register_Base+SPC_PAGE_H]
%define B_SP                [R_Base-SPC_Register_Base+_SP]
%define B_SPC_Cycles        [R_Base-SPC_Register_Base+_SPC_Cycles]
%define B_PSW               [R_Base-SPC_Register_Base+_PSW]
%define B_X                 [R_Base-SPC_Register_Base+_X]

%define B_N_flag            [R_Base-SPC_Register_Base+_N_flag]
%define B_V_flag            [R_Base-SPC_Register_Base+_V_flag]
%define B_P_flag            [R_Base-SPC_Register_Base+_P_flag]
%define B_H_flag            [R_Base-SPC_Register_Base+_H_flag]
%define B_Z_flag            [R_Base-SPC_Register_Base+_Z_flag]
%define B_I_flag            [R_Base-SPC_Register_Base+_I_flag]
%define B_B_flag            [R_Base-SPC_Register_Base+_B_flag]
%define B_C_flag            [R_Base-SPC_Register_Base+_C_flag]

%define B_SPC_PORT0R        [R_Base-SPC_Register_Base+_SPC_PORT0R]
%define B_SPC_PORT1R        [R_Base-SPC_Register_Base+_SPC_PORT1R]
%define B_SPC_PORT2R        [R_Base-SPC_Register_Base+_SPC_PORT2R]
%define B_SPC_PORT3R        [R_Base-SPC_Register_Base+_SPC_PORT3R]
%define B_SPC_PORT0W        [R_Base-SPC_Register_Base+_SPC_PORT0W]
%define B_SPC_PORT1W        [R_Base-SPC_Register_Base+_SPC_PORT1W]
%define B_SPC_PORT2W        [R_Base-SPC_Register_Base+_SPC_PORT2W]
%define B_SPC_PORT3W        [R_Base-SPC_Register_Base+_SPC_PORT3W]
%ifdef DEBUG
%define B_SPC_TEMP_ADD      [R_Base-SPC_Register_Base+SPC_TEMP_ADD]
%endif

; Load cycle counter to register R_Cycles
%macro LOAD_CYCLES 0
 mov edi,[_SPC_Cycles]
 mov dword R_Cycles,[_TotalCycles]
 sub dword R_Cycles,edi
%endmacro

; Get cycle counter to register argument
%macro GET_CYCLES 1
 mov dword %1,[_SPC_Cycles]
 add dword %1,R_Cycles
%endmacro

; Save register R_Cycles to cycle counter
%macro SAVE_CYCLES 0
 GET_CYCLES edi
 mov [_TotalCycles],edi
%endmacro

; Load base pointer to CPU register set
%macro LOAD_BASE 0
 mov dword R_Base,SPC_Register_Base
%endmacro

; Load register R_NativePC with pointer to code at PC
%macro LOAD_PC 0
 mov dword R_NativePC,[SPC_Code_Base]
 add dword R_NativePC,[_PC]
%endmacro

; Get PC from register R_NativePC
;%1 = with
%macro GET_PC 1
%ifnidn %1,R_NativePC
 mov dword %1,R_NativePC
%endif
 sub dword %1,[SPC_Code_Base]
%endmacro

; Save PC from register R_NativePC
;%1 = with
%macro SAVE_PC 1
 GET_PC %1
 mov dword [_PC],%1
%endmacro

; Set up the flags from PC flag format to SPC flag format
; Corrupts arg 2, returns value in arg 3 (default to cl, al)
;%1 = break flag, %2 = scratchpad, %3 = output
%macro SETUPFLAGS_SPC 0-3 1,cl,al
;%macro Flags_Native_to_SPC 0-3 1,cl,al
 mov byte %2,B_N_flag
 add byte %2,%2
 adc byte %3,%3

 mov byte %2,B_V_flag
 add byte %2,-1
 adc byte %3,%3

 mov byte %2,B_P_flag
 add byte %2,-1
 adc byte %3,%3

 mov byte %2,B_H_flag
 add byte %3,%3
%if %1 != 0
 inc byte %3
%endif
 shl byte %2,4
 adc byte %3,%3

 mov byte %2,B_I_flag
 add byte %2,-1
 adc byte %3,%3

 mov byte %2,B_Z_flag
 cmp byte %2,1
 adc byte %3,%3

 mov byte %2,B_C_flag
 add byte %2,-1
 adc byte %3,%3
%endmacro

; Restore the flags from SPC flag format to PC flag format
; Corrupts arg 2, returns value in arg 3 (default to cl, al)
;%1 = break flag, %2 = scratchpad, %3 = input
%macro RESTOREFLAGS_SPC 0-3 1,cl,al
;%macro Flags_SPC_to_Native 0-3 1,cl,al
 add byte %3,%3 ;start first (negative)
 sbb byte %2,%2
 add byte %3,%3 ;start next (overflow)
 mov byte B_N_flag,%2

 sbb byte %2,%2
 add byte %3,%3 ;start next (direct page)
 mov byte B_V_flag,%2

 mov byte %2,0
 adc byte %2,%2
 add byte %3,%3 ;start next (break flag, ignore)
 mov byte B_P_flag,%2
 add byte %3,%3 ;start next (half-carry)
 mov byte B_SPC_PAGE_H,%2

 sbb byte %2,%2
 mov byte B_B_flag,%1

;and byte %2,0x10
 add byte %3,%3 ;start next (interrupt enable)
 mov byte B_H_flag,%2

 sbb byte %2,%2
 add byte %3,%3 ;start next (zero)
 mov byte B_I_flag,%2

 sbb byte %2,%2
 xor byte %2,0xFF
 add byte %3,%3 ;start next (carry)
 mov byte B_Z_flag,%2

 sbb byte %2,%2
 mov byte B_C_flag,%2
%endmacro


; SPC MEMORY MAPPER IS PLACED HERE (ITS SIMPLER THAN THE CPU ONE!)

; bx - contains the actual address, al is where the info should be stored, edi is free
; NB bx is not corrupted! edi is corrupted!
; NB eax is not corrupted barring returnvalue in al... e.g. ah should not be used etc!

section .text
%macro OPCODE_EPILOG 0
%if 0
 test R_Cycles,R_Cycles
 jle near SPC_START_NEXT
 jmp near SPC_OUT
%else
 jmp near SPC_RETURN
%endif
%endmacro

ALIGNC
EXPORT_C SPC_READ_MAPPER
;and ebx,0xFFFF
 test bh,bh
 jz _SPC_READ_ZERO_PAGE

 cmp ebx,0xFFC0
 jae _SPC_READ_RAM_ROM
EXPORT_C SPC_READ_RAM
 mov al,[_SPCRAM+ebx]
 ret

ALIGNC
EXPORT_C SPC_READ_RAM_ROM
 mov edi,[SPC_FFC0_Address]
 mov al,[ebx + edi]
 ret

ALIGNC
EXPORT_C SPC_READ_ZERO_PAGE
 cmp bl,0xF0
 jb _SPC_READ_RAM

EXPORT_C SPC_READ_FUNC
%ifdef LOG_SOUND_DSP_READ
 SAVE_PC edi
%endif
 SAVE_CYCLES
 jmp dword [Read_Func_Map - 0xF0 * 4 + ebx * 4]

ALIGNC
EXPORT_C SPC_READ_INVALID
 mov al,0xFF    ; v0.15
%ifdef TRAP_INVALID_READ
%ifdef DEBUG
extern _InvalidSPCHWRead
;and ebx,0xFFFF
 mov [_Map_Address],ebx ; Set up Map Address so message works!
 mov [_Map_Byte],al     ; Set up Map Byte so message works

 pusha
 call _InvalidSPCHWRead ; Display read from invalid HW warning
 popa
%endif
%endif
 ret

;   --------

EXPORT_C SPC_WRITE_MAPPER
;and ebx,0xFFFF
 test bh,bh
 jz _SPC_WRITE_ZERO_PAGE

EXPORT_C SPC_WRITE_RAM
%ifdef UPDATE_SOUND_ON_RAM_WRITE
 push ecx
 push edx
 push eax
 SAVE_CYCLES    ; Set cycle counter
extern _update_sound
 call _update_sound
 pop eax
 pop edx
 pop ecx
%endif
 mov [_SPCRAM+ebx],al
 ret

ALIGNC
EXPORT_C SPC_WRITE_ZERO_PAGE
 cmp bl,0xF0
 jb _SPC_WRITE_RAM

EXPORT_C SPC_WRITE_FUNC
%ifdef LOG_SOUND_DSP_WRITE
 SAVE_PC edi
%endif
 SAVE_CYCLES
 jmp dword [Write_Func_Map - 0xF0 * 4 + ebx * 4]

EXPORT_C SPC_WRITE_INVALID
%ifdef TRAP_INVALID_WRITE
%ifdef DEBUG
extern _InvalidSPCHWWrite
;and ebx,0xFFFF
 mov [_Map_Address],ebx     ; Set up Map Address so message works!
 mov [_Map_Byte],al         ; Set up Map Byte so message works

 pusha
 call _InvalidSPCHWWrite    ; Display write to invalid HW warning
 popa
%endif
%endif
 ret

; GET_BYTE & GET_WORD now assume ebx contains the read address and 
; eax the place to store value also, corrupts edi

%macro GET_BYTE_SPC 0
;call _SPC_READ_MAPPER
 cmp ebx,0xFFC0
 jnb %%read_mapper

 test bh,bh
 jnz %%read_direct

 cmp bl,0xF0
 jb %%read_direct
 call _SPC_READ_FUNC
 jmp short %%done
%%read_mapper:
 call _SPC_READ_RAM_ROM
 jmp short %%done
%%read_direct:
 mov al,[_SPCRAM+ebx]
%%done:
%endmacro

%macro GET_WORD_SPC 0
 cmp ebx,0xFFC0-1
 jnb %%read_mapper

 test bh,bh
 jnz %%read_direct

 cmp bl,0xF0-1
 jb %%read_direct

 cmp bl,0xFF
 je %%read_mapper

 call _SPC_READ_FUNC
 mov ah,al
 inc ebx
 call _SPC_READ_FUNC
 ror ax,8
 jmp short %%done
%%read_mapper:
 call SPC_GET_WORD
 jmp short %%done
%%read_direct:
 mov ax,[_SPCRAM+ebx]
 inc ebx
%%done:
%endmacro

; SET_BYTE & SET_WORD now assume ebx contains the write address and 
; eax the value to write, corrupts edi

%macro SET_BYTE_SPC 0
%ifdef UPDATE_SOUND_ON_RAM_WRITE
 call _SPC_WRITE_MAPPER
%else
 test bh,bh
 jnz %%write_direct
 cmp bl,0xF0
 jb %%write_direct
 call _SPC_WRITE_FUNC
 jmp short %%done
%%write_direct:
 mov [_SPCRAM+ebx],al
%%done:
%endif
%endmacro

%macro SET_WORD_SPC 0
 SET_BYTE_SPC
 mov al,ah
 inc bx
 SET_BYTE_SPC
%endmacro

; Push / Pop Macros assume eax contains value - corrupt ebx,edi
%macro PUSH_B 0         ; Push Byte (SP--)
 mov ebx,B_SP
 mov [_SPCRAM+ebx],al   ; Store data on stack
 dec ebx
 mov B_SP,bl            ; Decrement S (Byte)
%endmacro

%macro POP_B 0          ; Pop Byte (++SP)
 mov ebx,B_SP
 inc bl
 mov B_SP,bl
 mov al,[_SPCRAM+ebx]   ; Fetch data from stack
%endmacro

%macro PUSH_W 0         ; Push Word (SP--)
 mov ebx,B_SP
 mov [_SPCRAM+ebx],ah   ; Store data on stack
 mov [_SPCRAM+ebx-1],al ; Store data on stack
 sub bl,2
 mov B_SP,bl            ; Postdecrement SP
%endmacro

%macro POP_W 0          ; Pop Word (++SP)
 mov ebx,B_SP
 add bl,2               ; Preincrement SP
 mov B_SP,bl
 mov ah,[_SPCRAM+ebx]   ; Fetch data from stack
 mov al,[_SPCRAM+ebx-1] ; Fetch data from stack
%endmacro

; --- Ease up on the finger cramps ;-)

;%1 = flag
%macro SET_FLAG_SPC 1
%if %1 & SPC_FLAG_N
 mov byte [_N_flag],0x80
%endif
%if %1 & SPC_FLAG_V
 mov byte [_V_flag],1
%endif
%if %1 & SPC_FLAG_Z
 mov byte [_Z_flag],0
%endif
%if %1 & SPC_FLAG_C
 mov byte [_C_flag],1
%endif
%if %1 & SPC_FLAG_P
 mov byte [_P_flag],1
%endif
%if %1 & SPC_FLAG_I
 mov byte [_I_flag],1
%endif
%if %1 &~ (SPC_FLAG_N | SPC_FLAG_V | SPC_FLAG_Z | SPC_FLAG_C | SPC_FLAG_P | SPC_FLAG_I)
%error Unhandled flag in SET_FLAG_SPC
%endif
%endmacro

;%1 = flag
%macro CLR_FLAG_SPC 1
%if %1 == SPC_FLAG_H
 mov byte [_H_flag],0
%endif
%if %1 == SPC_FLAG_V
 mov byte [_V_flag],0
%endif
%if %1 == SPC_FLAG_Z
 mov byte [_Z_flag],1
%endif
%if %1 == SPC_FLAG_C
 mov byte [_C_flag],0
%endif
%if %1 == SPC_FLAG_P
 mov byte [_P_flag],0
%endif
%if %1 == SPC_FLAG_I
 mov byte [_I_flag],0
%endif
%if %1 &~ (SPC_FLAG_H | SPC_FLAG_V | SPC_FLAG_Z | SPC_FLAG_C | SPC_FLAG_P | SPC_FLAG_I)
%error Unhandled flag in CLR_FLAG_SPC
%endif
%endmacro

;%1 = flag
%macro CPL_FLAG_SPC 1
%if %1 == SPC_FLAG_C
 push eax
 mov al,[_C_flag]
 test al,al
 setz [_C_flag]
 pop eax
%endif
%endmacro

;%1 = flag, %2 = wheretogo
%macro JUMP_FLAG_SPC 2
%if %1 == SPC_FLAG_N
 mov ch,B_N_flag
 test ch,ch
 js %2
%elif %1 == SPC_FLAG_Z
 mov ch,B_Z_flag
 test ch,ch
 jz %2
%elif %1 == SPC_FLAG_V
 mov ch,B_V_flag
 test ch,ch
 jnz %2
%elif %1 == SPC_FLAG_C
 mov ch,B_C_flag
 test ch,ch
 jnz %2
%else
%error Unhandled flag in JUMP_FLAG_SPC
%endif
%endmacro

;%1 = flag, %2 = wheretogo
%macro JUMP_NOT_FLAG_SPC 2
%if %1 == SPC_FLAG_N
 mov ch,B_N_flag
 test ch,ch
 jns %2
%elif %1 == SPC_FLAG_Z
 mov ch,B_Z_flag
 test ch,ch
 jnz %2
%elif %1 == SPC_FLAG_V
 mov ch,B_V_flag
 test ch,ch
 jz %2
%elif %1 == SPC_FLAG_C
 mov ch,B_C_flag
 test ch,ch
 jz %2
%else
%error Unhandled flag in JUMP_NOT_FLAG_SPC
%endif
%endmacro

%macro STORE_FLAGS_P 1
 mov byte B_P_flag,%1
%endmacro

%macro STORE_FLAGS_V 1
 mov byte B_V_flag,%1
%endmacro

%macro STORE_FLAGS_H 1
 mov byte B_H_flag,%1
%endmacro

%macro STORE_FLAGS_N 1
 mov byte B_N_flag,%1
%endmacro

%macro STORE_FLAGS_Z 1
 mov byte B_Z_flag,%1
%endmacro

%macro STORE_FLAGS_I 1
 mov byte B_I_flag,%1
%endmacro

%macro STORE_FLAGS_C 1
 mov byte B_C_flag,%1
%endmacro

%macro STORE_FLAGS_NZ 1
 STORE_FLAGS_N %1
 STORE_FLAGS_Z %1
%endmacro

%macro STORE_FLAGS_NZC 2
 STORE_FLAGS_N %1
 STORE_FLAGS_Z %1
 STORE_FLAGS_C %2
%endmacro

section .data
ALIGND
EXPORT SPCOpTable
dd _SPC_NOP          ,_SPC_TCALL_0       ,_SPC_SET1          ,_SPC_BBS                ; 00
dd _SPC_OR_A_dp      ,_SPC_OR_A_abs      ,_SPC_OR_A_OXO      ,_SPC_OR_A_OOdp_XOO
dd _SPC_OR_A_IM      ,_SPC_OR_dp_dp      ,_SPC_OR1           ,_SPC_ASL_dp
dd _SPC_ASL_abs      ,_SPC_PUSH_PSW      ,_SPC_TSET1         ,_SPC_INVALID
dd _SPC_BPL          ,_SPC_TCALL_1       ,_SPC_CLR1          ,_SPC_BBC                ; 10
dd _SPC_OR_A_Odp_XO  ,_SPC_OR_A_Oabs_XO  ,_SPC_OR_A_Oabs_YO  ,_SPC_OR_A_OOdpO_YO
dd _SPC_OR_dp_IM     ,_SPC_OR_OXO_OYO    ,_SPC_DECW_dp       ,_SPC_ASL_Odp_XO
dd _SPC_ASL_A        ,_SPC_DEC_X         ,_SPC_CMP_X_abs     ,_SPC_JMP_Oabs_XO
dd _SPC_CLRP         ,_SPC_TCALL_2       ,_SPC_SET1          ,_SPC_BBS                ; 20
dd _SPC_AND_A_dp     ,_SPC_AND_A_abs     ,_SPC_AND_A_OXO     ,_SPC_AND_A_OOdp_XOO
dd _SPC_AND_A_IM     ,_SPC_AND_dp_dp     ,_SPC_OR1C          ,_SPC_ROL_dp
dd _SPC_ROL_abs      ,_SPC_PUSH_A        ,_SPC_CBNE_dp       ,_SPC_BRA
dd _SPC_BMI          ,_SPC_TCALL_3       ,_SPC_CLR1          ,_SPC_BBC                ; 30
dd _SPC_AND_A_Odp_XO ,_SPC_AND_A_Oabs_XO ,_SPC_AND_A_Oabs_YO ,_SPC_AND_A_OOdpO_YO
dd _SPC_AND_dp_IM    ,_SPC_AND_OXO_OYO   ,_SPC_INCW_dp       ,_SPC_ROL_Odp_XO
dd _SPC_ROL_A        ,_SPC_INC_X         ,_SPC_CMP_X_dp      ,_SPC_CALL
dd _SPC_SETP         ,_SPC_TCALL_4       ,_SPC_SET1          ,_SPC_BBS                ; 40
dd _SPC_EOR_A_dp     ,_SPC_EOR_A_abs     ,_SPC_EOR_A_OXO     ,_SPC_EOR_A_OOdp_XOO
dd _SPC_EOR_A_IM     ,_SPC_EOR_dp_dp     ,_SPC_AND1          ,_SPC_LSR_dp
dd _SPC_LSR_abs      ,_SPC_PUSH_X        ,_SPC_TCLR1         ,_SPC_PCALL
dd _SPC_BVC          ,_SPC_TCALL_5       ,_SPC_CLR1          ,_SPC_BBC                ; 50
dd _SPC_EOR_A_Odp_XO ,_SPC_EOR_A_Oabs_XO ,_SPC_EOR_A_Oabs_YO ,_SPC_EOR_A_OOdpO_YO
dd _SPC_EOR_dp_IM    ,_SPC_EOR_OXO_OYO   ,_SPC_CMPW_YA_dp    ,_SPC_LSR_Odp_XO
dd _SPC_LSR_A        ,_SPC_MOV_X__A      ,_SPC_CMP_Y_abs     ,_SPC_JMP_abs
dd _SPC_CLRC         ,_SPC_TCALL_6       ,_SPC_SET1          ,_SPC_BBS                ; 60
dd _SPC_CMP_A_dp     ,_SPC_CMP_A_abs     ,_SPC_CMP_A_OXO     ,_SPC_CMP_A_OOdp_XOO
dd _SPC_CMP_A_IM     ,_SPC_CMP_dp_dp     ,_SPC_AND1C         ,_SPC_ROR_dp
dd _SPC_ROR_abs      ,_SPC_PUSH_Y        ,_SPC_DBNZ_dp       ,_SPC_RET
dd _SPC_BVS          ,_SPC_TCALL_7       ,_SPC_CLR1          ,_SPC_BBC                ; 70
dd _SPC_CMP_A_Odp_XO ,_SPC_CMP_A_Oabs_XO ,_SPC_CMP_A_Oabs_YO ,_SPC_CMP_A_OOdpO_YO
dd _SPC_CMP_dp_IM    ,_SPC_CMP_OXO_OYO   ,_SPC_ADDW_YA_dp    ,_SPC_ROR_Odp_XO
dd _SPC_ROR_A        ,_SPC_MOV_A__X      ,_SPC_CMP_Y_dp      ,_SPC_INVALID
dd _SPC_SETC         ,_SPC_TCALL_8       ,_SPC_SET1          ,_SPC_BBS                ; 80
dd _SPC_ADC_A_dp     ,_SPC_ADC_A_abs     ,_SPC_ADC_A_OXO     ,_SPC_ADC_A_OOdp_XOO
dd _SPC_ADC_A_IM     ,_SPC_ADC_dp_dp     ,_SPC_EOR1          ,_SPC_DEC_dp
dd _SPC_DEC_abs      ,_SPC_MOV_Y_IM      ,_SPC_POP_PSW       ,_SPC_MOV_dp_IM
dd _SPC_BCC          ,_SPC_TCALL_9       ,_SPC_CLR1          ,_SPC_BBC                ; 90
dd _SPC_ADC_A_Odp_XO ,_SPC_ADC_A_Oabs_XO ,_SPC_ADC_A_Oabs_YO ,_SPC_ADC_A_OOdpO_YO
dd _SPC_ADC_dp_IM    ,_SPC_ADC_OXO_OYO   ,_SPC_SUBW_YA_dp    ,_SPC_DEC_Odp_XO
dd _SPC_DEC_A        ,_SPC_MOV_X__SP     ,_SPC_DIV           ,_SPC_XCN
dd _SPC_EI           ,_SPC_TCALL_10      ,_SPC_SET1          ,_SPC_BBS                ; A0
dd _SPC_SBC_A_dp     ,_SPC_SBC_A_abs     ,_SPC_SBC_A_OXO     ,_SPC_SBC_A_OOdp_XOO
dd _SPC_SBC_A_IM     ,_SPC_SBC_dp_dp     ,_SPC_MOV1_C_       ,_SPC_INC_dp
dd _SPC_INC_abs      ,_SPC_CMP_Y_IM      ,_SPC_POP_A         ,_SPC_MOV_OXOInc_A
dd _SPC_BCS          ,_SPC_TCALL_11      ,_SPC_CLR1          ,_SPC_BBC                ; B0
dd _SPC_SBC_A_Odp_XO ,_SPC_SBC_A_Oabs_XO ,_SPC_SBC_A_Oabs_YO ,_SPC_SBC_A_OOdpO_YO
dd _SPC_SBC_dp_IM    ,_SPC_SBC_OXO_OYO   ,_SPC_MOVW_YA_dp    ,_SPC_INC_Odp_XO
dd _SPC_INC_A        ,_SPC_MOV_SP_X      ,_SPC_INVALID       ,_SPC_MOV_A_OXOInc
dd _SPC_DI           ,_SPC_TCALL_12      ,_SPC_SET1          ,_SPC_BBS                ; C0
dd _SPC_MOV_dp__A    ,_SPC_MOV_abs__A    ,_SPC_MOV_OXO__A    ,_SPC_MOV_OOdp_XOO__A
dd _SPC_CMP_X_IM     ,_SPC_MOV_abs__X    ,_SPC_MOV1__C       ,_SPC_MOV_dp__Y
dd _SPC_MOV_abs__Y   ,_SPC_MOV_X_IM      ,_SPC_POP_X         ,_SPC_MUL
dd _SPC_BNE          ,_SPC_TCALL_13      ,_SPC_CLR1          ,_SPC_BBC                ; D0
dd _SPC_MOV_Odp_XO__A,_SPC_MOV_Oabs_XO__A,_SPC_MOV_Oabs_YO__A,_SPC_MOV_OOdpO_YO__A
dd _SPC_MOV_dp__X    ,_SPC_MOV_Odp_YO__X ,_SPC_MOVW_dp_YA    ,_SPC_MOV_Odp_XO__Y
dd _SPC_DEC_Y        ,_SPC_MOV_A__Y      ,_SPC_CBNE_Odp_XO   ,_SPC_INVALID
dd _SPC_CLRV         ,_SPC_TCALL_14      ,_SPC_SET1          ,_SPC_BBS                ; E0
dd _SPC_MOV_A_dp     ,_SPC_MOV_A_abs     ,_SPC_MOV_A_OXO     ,_SPC_MOV_A_OOdp_XOO
dd _SPC_MOV_A_IM     ,_SPC_MOV_X_abs     ,_SPC_NOT1          ,_SPC_MOV_Y_dp
dd _SPC_MOV_Y_abs    ,_SPC_NOTC          ,_SPC_POP_Y         ,_SPC_INVALID ;_SPC_SLEEP
dd _SPC_BEQ          ,_SPC_TCALL_15      ,_SPC_CLR1          ,_SPC_BBC                ; F0
dd _SPC_MOV_A_Odp_XO ,_SPC_MOV_A_Oabs_XO ,_SPC_MOV_A_Oabs_YO ,_SPC_MOV_A_OOdpO_YO
dd _SPC_MOV_X_dp     ,_SPC_MOV_X_Odp_YO  ,_SPC_MOV_dp_dp     ,_SPC_MOV_Y_Odp_XO
dd _SPC_INC_Y        ,_SPC_MOV_Y__A      ,_SPC_DBNZ_Y        ,_SPC_INVALID ;_SPC_STOP

; This holds the base instruction timings in cycles
ALIGND
SPCCycleTable:
db 2,8,4,5,3,4,3,6,2,6,5,4,5,4,6,8  ; 00
db 2,8,4,5,4,5,5,6,5,5,6,5,2,2,4,6  ; 10
db 2,8,4,5,3,4,3,6,2,6,5,4,5,4,5,4  ; 20
db 2,8,4,5,4,5,5,6,5,5,6,5,2,2,3,8  ; 30
db 2,8,4,5,3,4,3,6,2,6,4,4,5,4,6,6  ; 40
db 2,8,4,5,4,5,5,6,5,5,4,5,2,2,4,3  ; 50
db 2,8,4,5,3,4,3,6,2,6,4,4,5,4,5,5  ; 60
db 2,8,4,5,4,5,5,6,5,5,5,5,2,2,3,6  ; 70
db 2,8,4,5,3,4,3,6,2,6,5,4,5,2,4,5  ; 80
db 2,8,4,5,4,5,5,6,5,5,5,5,2,2,12,5 ; 90
db 3,8,4,5,3,4,3,6,2,6,4,4,5,2,4,4  ; A0
db 2,8,4,5,4,5,5,6,5,5,5,5,2,2,3,4  ; B0
db 3,8,4,5,4,5,4,7,2,5,6,4,5,2,4,9  ; C0
db 2,8,4,5,5,6,6,7,4,5,4,5,2,2,6,3  ; D0
db 2,8,4,5,3,4,3,6,2,4,5,3,4,3,4,3  ; E0
db 2,8,4,5,4,5,5,6,3,4,5,4,2,2,4,3  ; F0

; This code should be copied into the top of the address space
ALIGND
EXPORT_C SPC_ROM_CODE
 db 0xCD,0xEF,0xBD,0xE8,0x00,0xC6,0x1D,0xD0
 db 0xFC,0x8F,0xAA,0xF4,0x8F,0xBB,0xF5,0x78
 db 0xCC,0xF4,0xD0,0xFB,0x2F,0x19,0xEB,0xF4
 db 0xD0,0xFC,0x7E,0xF4,0xD0,0x0B,0xE4,0xF5
 db 0xCB,0xF4,0xD7,0x00,0xFC,0xD0,0xF3,0xAB
 db 0x01,0x10,0xEF,0x7E,0xF4,0x10,0xEB,0xBA
 db 0xF6,0xDA,0x00,0xBA,0xF4,0xC4,0xF4,0xDD
 db 0x5D,0xD0,0xDB,0x1F,0x00,0x00,0xC0,0xFF

ALIGND
Read_Func_Map:              ; Mappings for SPC Registers
 dd _SPC_READ_INVALID
 dd _SPC_READ_CTRL
 dd _SPC_READ_DSP_ADDR
 dd _SPC_READ_DSP_DATA
 dd _SPC_READ_PORT0R
 dd _SPC_READ_PORT1R
 dd _SPC_READ_PORT2R
 dd _SPC_READ_PORT3R
 dd _SPC_READ_INVALID
 dd _SPC_READ_INVALID
 dd _SPC_READ_INVALID
 dd _SPC_READ_INVALID
 dd _SPC_READ_INVALID
 dd _SPC_READ_COUNTER_0
 dd _SPC_READ_COUNTER_1
 dd _SPC_READ_COUNTER_2

ALIGND
Write_Func_Map:             ; Mappings for SPC Registers
 dd _SPC_WRITE_INVALID
 dd _SPC_WRITE_CTRL
 dd _SPC_WRITE_DSP_ADDR
 dd _SPC_WRITE_DSP_DATA
 dd _SPC_WRITE_PORT0W
 dd _SPC_WRITE_PORT1W
 dd _SPC_WRITE_PORT2W
 dd _SPC_WRITE_PORT3W
 dd _SPC_WRITE_INVALID
 dd _SPC_WRITE_INVALID
 dd _SPC_WRITE_TIMER_0
 dd _SPC_WRITE_TIMER_1
 dd _SPC_WRITE_TIMER_2
 dd _SPC_WRITE_INVALID
 dd _SPC_WRITE_INVALID
 dd _SPC_WRITE_INVALID

offset_to_bit:  db 0x01,0x02,0x04,0x08,0x10,0x20,0x40,0x80
offset_to_not:  db 0xFE,0xFD,0xFB,0xF7,0xEF,0xDF,0xBF,0x7F

section .bss
ALIGNB
EXPORT_C TotalCycles,skipl

EXPORT_C SPC_T0_cycle_latch,skipl
EXPORT_C SPC_T0_position,skipw
EXPORT_C SPC_T0_target,skipw

EXPORT_C SPC_T1_cycle_latch,skipl
EXPORT_C SPC_T1_position,skipw
EXPORT_C SPC_T1_target,skipw

EXPORT_C SPC_T2_cycle_latch,skipl
EXPORT_C SPC_T2_position,skipw
EXPORT_C SPC_T2_target,skipw

EXPORT SPC_FFC0_Address,skipl

EXPORT_C SPC_T0_counter,skipb
EXPORT_C SPC_T1_counter,skipb
EXPORT_C SPC_T2_counter,skipb

ALIGNB
SPC_Register_Base:

EXPORT SPC_Code_Base,skipl

EXPORT _PC ,skipl
EXPORT _YA
EXPORT _A  ,skipb
EXPORT _Y  ,skipb
            skipw

EXPORT SPC_PAGE,skipl

SPC_PAGE_H equ SPC_PAGE+1
EXPORT _N_flag,skipb
EXPORT _H_flag,skipb
EXPORT _I_flag,skipb
EXPORT _B_flag,skipb
EXPORT _SP,skipl

EXPORT _SPC_Cycles,skipl    ; Number of cycles to execute for SPC

EXPORT _PSW,skipb   ; Processor status word
EXPORT _X  ,skipb
EXPORT _Z_flag,skipb
EXPORT _P_flag,skipb

EXPORT _V_flag,skipb
EXPORT _C_flag,skipb

EXPORT_C SPC_PORT0R,skipb
EXPORT_C SPC_PORT1R,skipb
EXPORT_C SPC_PORT2R,skipb
EXPORT_C SPC_PORT3R,skipb

EXPORT_C SPC_PORT0W,skipb
EXPORT_C SPC_PORT1W,skipb
EXPORT_C SPC_PORT2W,skipb
EXPORT_C SPC_PORT3W,skipb

ALIGNB
%ifdef DEBUG
SPC_TEMP_ADD:   skipl
%endif

section .text

ALIGNC
EXPORT_C Reset_SPC
 pusha

 ; Get ROM reset vector and setup Program Counter
 movzx eax,word [_SPC_ROM_CODE+(0xFFFE-0xFFC0)]
 mov [_PC],eax

 mov eax,0  ;[_SNES_Cycles]

 ; Reset the sound DSP registers
 mov [_SPC_Cycles],eax  ; Clear Cycle Count
 mov [_TotalCycles],eax
 mov [SPC_PAGE],eax     ; Used to save looking up P flag for Direct page stuff!
 mov dword [_SP],0x01EF ; Reset registers
 mov [_YA],eax
 mov [_X],al
 mov [_PSW],al          ; Clear Flags Register
 mov [_N_flag],al       ; Clear Flags Register
 mov byte [_Z_flag],1
 mov [_H_flag],al
 mov [_V_flag],al
 mov [_I_flag],al
 mov [_P_flag],al
 mov [_B_flag],al
 mov [_C_flag],al

 mov byte [_SPCRAM+_SPC_CTRL],0x80
 mov dword [SPC_FFC0_Address],_SPC_ROM_CODE-0xFFC0
 mov dword [SPC_Code_Base],_SPC_ROM_CODE-0xFFC0

 ; Reset timers
 mov [_SPC_T0_counter],al
 mov [_SPC_T1_counter],al
 mov [_SPC_T2_counter],al
 mov word [_SPC_T0_target],256
 mov word [_SPC_T1_target],256
 mov word [_SPC_T2_target],256
 mov [_SPC_T0_position],ax
 mov [_SPC_T1_position],ax
 mov [_SPC_T2_position],ax
 mov [_SPC_T0_cycle_latch],eax
 mov [_SPC_T1_cycle_latch],eax
 mov [_SPC_T2_cycle_latch],eax

 ; Reset SPC700 output ports
 mov [_SPC_PORT0W],al
 mov [_SPC_PORT1W],al
 mov [_SPC_PORT2W],al
 mov [_SPC_PORT3W],al

 ; Reset SPC700 input ports
 mov [_SPC_PORT0R],al
 mov [_SPC_PORT1R],al
 mov [_SPC_PORT2R],al
 mov [_SPC_PORT3R],al

 ; Reset sound DSP port address
 mov [_SPC_DSP+_SPC_DSP_ADDR],al
 mov [_SPC_DSP_DATA],eax

 popa
 ret

SPC_SHOW_REGISTERS:
 pusha
 call _DisplaySPC
 popa
 ret

ALIGNC
EXPORT_C get_SPC_PSW
 LOAD_BASE
 SETUPFLAGS_SPC
 ret

ALIGNC
SPC_GET_WORD:
 GET_BYTE_SPC
 mov ah,al
 inc bx
 GET_BYTE_SPC
 ror ax,8
 ret

ALIGNC
EXPORT_C SPC_START
%ifdef WATCH_SPC_BREAKS
extern _BreaksLast
 inc dword [_BreaksLast]
%endif

 LOAD_CYCLES
 LOAD_PC
 LOAD_BASE
 xor eax,eax
 jmp short SPC_START_NEXT

ALIGNC
SPC_RETURN:
;cmp R_Base,SPC_Register_Base
;jne 0b

%ifdef DEBUG
;mov ebx,[SPC_TEMP_ADD]
;mov [_OLD_SPC_ADDRESS],ebx
%endif
 test R_Cycles,R_Cycles
%ifdef TRACKERS
 jg near SPC_OUT        ; Do another instruction if cycles left
%else
 jg SPC_OUT             ; Do another instruction if cycles left
%endif

SPC_START_NEXT:

; This code is for a SPC-tracker dump... #define TRACKERS to make a dump
; of the CPU state before each instruction - uncomment the calls to
; _Wangle__Fv and _exit to force the emulator to exit when the buffer
; fills. TRACKERS must be defined to the size of the buffer to be used -
; which must be a power of two, and the variables required by this and the
; write in Wangle() (romload.cc) exist only if DEBUG and SPCTRACKERS are
; also defined in romload.cc.
%ifdef TRACKERS
extern _SPC_LastIns
extern _SPC_InsAddress
extern _Wangle__Fv
extern _exit
 mov edi,[_SPC_LastIns]     ;
 add edi,[_SPC_InsAddress]  ;
 SAVE_PC eax                ;
 mov [edi],ah               ;
 mov [1+edi],al             ;
 mov al,[_A]                ;
 mov [2+edi],al             ;
 mov al,[_X]                ;
 mov [3+edi],al             ;
 mov al,[_Y]                ;
 mov [4+edi],al             ;
 mov al,[_SP]               ;
 mov [5+edi],al             ;
 SETUPFLAGS_SPC             ;
 mov [6+edi],al             ;

 mov al,[esi]               ;
 mov [7+edi],al             ;
 mov eax,[1+esi]            ;
 mov [8+edi],eax            ;
 mov eax,[5+esi]            ;
 mov [12+edi],eax           ;

 mov edi,[_SPC_LastIns]     ;
 add edi,byte 16            ;
 and edi,(TRACKERS-1)       ;
 mov [_SPC_LastIns],edi     ;
 test edi,edi               ;
 jnz .buffer_not_full       ;
 call _Wangle__Fv           ;
 jmp _exit                  ;
                            ;
.buffer_not_full:           ;
 xor eax,eax                ;
%endif

;mov ebx,[_PC]          ; PC now setup
;mov R_NativePC,[SPC_Code_Base]
;add R_NativePC,ebx
%ifdef DEBUG
;mov [SPC_TEMP_ADD],ebx
%endif

 xor eax,eax
 mov al,[R_NativePC]    ; Fetch opcode
 xor ebx,ebx
 mov bl,[SPCCycleTable+eax]
 add R_Cycles,ebx               ; Update cycle counter
 jmp dword [SPCOpTable+eax*4]   ; jmp to opcode handler

ALIGNC
SPC_OUT:
 SAVE_PC R_NativePC
 SAVE_CYCLES   ; Set cycle counter

%ifdef INDEPENDENT_SPC
 ; Update SPC timers to prevent overflow
 Update_SPC_Timer 0
 Update_SPC_Timer 1
 Update_SPC_Timer 2
%endif

 ret                    ; Return to CPU emulation

%include "spcaddr.ni"   ; Include addressing mode macros
%include "spcmacro.ni"  ; Include instruction macros

EXPORT_C spc_ops_start

ALIGNC
EXPORT_C SPC_INVALID
 mov [_Map_Byte],al     ; al contains opcode!

 SAVE_PC R_NativePC
 SAVE_CYCLES   ; Set cycle counter

 mov eax,[_PC]          ; Adjust address to correct for pre-increment
 mov [_Map_Address],eax ; this just sets the error output up correctly!

extern _InvalidSPCOpcode
 jmp _InvalidSPCOpcode  ; This exits.. avoids conflict with other things!

ALIGNC
EXPORT_C SPC_SET1
 shr eax,5
 mov ebx,B_SPC_PAGE
 mov bl,[1+R_NativePC]
 add R_NativePC,byte 2
 mov ah,[offset_to_bit+eax]
 GET_BYTE_SPC     
 or al,ah
 SET_BYTE_SPC
 OPCODE_EPILOG

ALIGNC
EXPORT_C SPC_CLR1
 shr eax,5
 mov ebx,B_SPC_PAGE
 mov bl,[1+R_NativePC]
 add R_NativePC,byte 2
 mov ah,[offset_to_not+eax]
 GET_BYTE_SPC     
 and al,ah
 SET_BYTE_SPC
 OPCODE_EPILOG

ALIGNC
EXPORT_C SPC_BBS
 shr eax,5
 mov ebx,B_SPC_PAGE
 mov bl,[1+R_NativePC]
 mov ah,[offset_to_bit+eax]
 GET_BYTE_SPC
 test al,ah
 jz .not_taken
 movsx eax,byte [2+R_NativePC]
 add R_NativePC,eax
 add R_Cycles,byte 2    ; branch taken
.not_taken:
 add R_NativePC,byte 3
 OPCODE_EPILOG

ALIGNC
EXPORT_C SPC_BBC
 shr eax,5
 mov ebx,B_SPC_PAGE
 mov bl,[1+R_NativePC]
 mov ah,[offset_to_bit+eax]
 GET_BYTE_SPC         
 test al,ah
 jnz .not_taken
 movsx eax,byte [2+R_NativePC]
 add R_NativePC,eax
 add R_Cycles,byte 2    ; branch taken
.not_taken:
 add R_NativePC,byte 3
 OPCODE_EPILOG

%include "spcops.ni"    ; Include opcodes

EXPORT_C SPC_READ_CTRL
EXPORT_C SPC_READ_DSP_ADDR
 mov al,[_SPCRAM+ebx]
 ret

EXPORT_C SPC_READ_DSP_DATA
 push ecx
 push edx
 push eax
 call _SPC_READ_DSP
 xor ecx,ecx
 pop eax
 mov cl,[_SPCRAM+_SPC_DSP_ADDR]
 pop edx
 mov al,[_SPC_DSP+ecx]    ; read from DSP register
 pop ecx
 ret

EXPORT_C SPC_READ_PORT0R
 mov al,[_SPC_PORT0R]
 ret
EXPORT_C SPC_READ_PORT1R
 mov al,[_SPC_PORT1R]
 ret
EXPORT_C SPC_READ_PORT2R
 mov al,[_SPC_PORT2R]
 ret
EXPORT_C SPC_READ_PORT3R
 mov al,[_SPC_PORT3R]
 ret

; WOOPS... TIMER registers are write only, the actual timer clock is internal not accessible!

; COUNTERS ARE 4 BIT, upon read they reset to 0 status

EXPORT_C SPC_READ_COUNTER_0
 push ecx
 push edx
 push eax
 Update_SPC_Timer 0
;call _Update_SPC_Timer_0
 pop eax
 pop edx
 pop ecx
 mov al,[_SPC_T0_counter]
 mov [_SPC_T0_counter],bh
 ret

EXPORT_C SPC_READ_COUNTER_1
 push ecx
 push edx
 push eax
 Update_SPC_Timer 1
;call _Update_SPC_Timer_1
 pop eax
 pop edx
 pop ecx
 mov al,[_SPC_T1_counter]
 mov byte [_SPC_T1_counter],bh
 ret

EXPORT_C SPC_READ_COUNTER_2
 push ecx
 push edx
 push eax
 Update_SPC_Timer 2
;call _Update_SPC_Timer_2
 pop eax
 pop edx
 pop ecx
 mov al,[_SPC_T2_counter]
 mov byte [_SPC_T2_counter],bh
 ret

; | ROMEN | TURBO | PC32  | PC10  | ----- |  ST2  |  ST1  |  ST0  |
;
; ROMEN - enable mask ROM in top 64-bytes of address space for CPU read
; TURBO - enable turbo CPU clock ???
; PC32  - clear SPC read ports 2 & 3
; PC10  - clear SPC read ports 0 & 1
; ST2   - start timer 2 (64kHz)
; ST1   - start timer 1 (8kHz)
; ST0   - start timer 0 (8kHz)

EXPORT_C SPC_WRITE_CTRL
 push eax
 mov ah,0
 test al,al     ; New for 0.25 - read hidden RAM
 mov edi,_SPCRAM
 jns .rom_disabled
 mov edi,_SPC_ROM_CODE-0xFFC0

.rom_disabled:
 mov [SPC_FFC0_Address],edi

 test al,0x10       ; Reset ports 0/1 to 00 if set
 jz .no_clear_01
 mov [_SPC_PORT0R],ah   ; Ports read by SPC should be reset! 
 mov [_SPC_PORT1R],ah   ; Thanks to Butcha for fix!

.no_clear_01:
 test al,0x20       ; Reset ports 2/3 to 00 if set
 jz .no_clear_23
 mov [_SPC_PORT2R],ah
 mov [_SPC_PORT3R],ah

.no_clear_23:
 mov edi,[_TotalCycles]
 test byte [_SPCRAM+ebx],4
 jnz .no_enable_timer_2
 test al,4
 jz  .no_enable_timer_2
 mov byte [_SPC_T2_counter],0
 mov word [_SPC_T2_position],0
 mov [_SPC_T2_cycle_latch],edi

.no_enable_timer_2:
 test byte [_SPCRAM+ebx],2
 jnz .no_enable_timer_1
 test al,2
 jz .no_enable_timer_1
 mov byte [_SPC_T1_counter],0
 mov word [_SPC_T1_position],0
 mov [_SPC_T1_cycle_latch],edi

.no_enable_timer_1:
 test byte [_SPCRAM+ebx],1
 jnz .no_enable_timer_0
 test al,1
 jz .no_enable_timer_0
 mov byte [_SPC_T0_counter],0
 mov word [_SPC_T0_position],0
 mov [_SPC_T0_cycle_latch],edi

.no_enable_timer_0:
 pop eax
 mov [_SPCRAM+ebx],al
 ret

EXPORT_C SPC_WRITE_DSP_ADDR
 mov [_SPCRAM+ebx],al
 ret

EXPORT_C SPC_WRITE_DSP_DATA
 mov [_SPC_DSP_DATA],al
 push ecx
 push edx
 push eax
 call _SPC_WRITE_DSP
 pop eax
 pop edx
 pop ecx
 ret

EXPORT_C SPC_WRITE_PORT0W
 mov [_SPC_PORT0W],al
 ret
EXPORT_C SPC_WRITE_PORT1W
 mov [_SPC_PORT1W],al
 ret
EXPORT_C SPC_WRITE_PORT2W
 mov [_SPC_PORT2W],al
 ret
EXPORT_C SPC_WRITE_PORT3W
 mov [_SPC_PORT3W],al
 ret

EXPORT_C SPC_WRITE_TIMER_0
 cmp [_SPC_T0_target],al
 je .no_change
 push ecx
 push edx
 push eax
 Update_SPC_Timer 0
;call _Update_SPC_Timer_0   ; Timer must catch up before changing target
 pop eax
 pop edx
 pop ecx
 test al,al
 mov [_SPC_T0_target],al    ; (0.32) Butcha - timer targets are writable
 setz [_SPC_T0_target+1]    ; 0 = 256
.no_change:
 ret

EXPORT_C SPC_WRITE_TIMER_1
 cmp [_SPC_T1_target],al
 je .no_change
 push ecx
 push edx
 push eax
 Update_SPC_Timer 1
;call _Update_SPC_Timer_1   ; Timer must catch up before changing target
 pop eax
 pop edx
 pop ecx
 test al,al
 mov [_SPC_T1_target],al    ; (0.32) Butcha - timer targets are writable
 setz [_SPC_T1_target+1]    ; 0 = 256
.no_change:
 ret

EXPORT_C SPC_WRITE_TIMER_2
 cmp [_SPC_T2_target],al
 je .no_change
 push ecx
 push edx
 push eax
 Update_SPC_Timer 2
;call _Update_SPC_Timer_2   ; Timer must catch up before changing target
 pop eax
 pop edx
 pop ecx
 test al,al
 mov [_SPC_T2_target],al    ; (0.32) Butcha - timer targets are writable
 setz [_SPC_T2_target+1]    ; 0 = 256
.no_change:
 ret

section .text
ALIGNC
section .data
ALIGND
section .bss
ALIGNB
