%if 0

SNEeSe, an Open Source Super NES emulator.


Copyright (c) 2002 Charles Bilyue'.

This is free software.  See 'LICENSE' for details.
You must read and accept the license prior to use.

%endif

%ifndef SNEeSe_regs_i
%define SNEeSe_regs_i

%define R_65c816_MemMap_Data        al
%define R_65c816_MemMap_DataHigh    ah
%define R_65c816_MemMap_Addx        edi
%define R_65c816_P                  ecx
%define R_65c816_P_W                R_65c816_P
%define R_65c816_P_B                cl
%define R_65c816_Base               edx
%define R_65c816_Cycles             ebp
%define R_65c816_NativePC           esi
%define R_65c816_MemMap_Trash       edi

%define R_SPC700_MemMap_Data        al
%define R_SPC700_MemMap_DataHigh    ah
%define R_SPC700_MemMap_Addx        ebx
%define R_SPC700_PSW                ch
%define R_SPC700_PSW_B              R_SPC700_PSW
%define R_SPC700_Base               edx
%define R_SPC700_Cycles             ebp
%define R_SPC700_NativePC           esi
%define R_SPC700_MemMap_Trash       edi

%endif ; !SNEeSe_regs_i
