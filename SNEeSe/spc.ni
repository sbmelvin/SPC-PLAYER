%if 0

SNEeSe, an Open Source Super NES emulator.


Copyright (c) 2002 Charles Bilyue'.

This is free software.  See 'LICENSE' for details.
You must read and accept the license prior to use.

* This code modified by Brad Martin for use with OpenSPC.  Derived from
* SNEeSe version .74.  Changes include removing code and variables that are
* unnecessary in this application, exporting some variables that needed to
* be accessed from outside these sources, and other small tweaks.  Last date
* of modification: Jan 8th 2003

%endif

%ifndef SNEeSe_SPC_i
%define SNEeSe_SPC_i

%if 0 ; *** Undefined for 1.024MHz operation for OpenSPC
%define SPC2MHz
%endif

%include "regs.ni"

%ifndef SNEeSe_SPC700_asm

%define _SPC_CTRL 0xF1
extern _SPCRAM
extern _TotalCycles
extern _SPC_T0_cycle_latch,_SPC_T0_target,_SPC_T0_position
extern _SPC_T0_cycle_latch,_SPC_T0_counter
extern _SPC_T1_cycle_latch,_SPC_T1_target,_SPC_T1_position
extern _SPC_T1_cycle_latch,_SPC_T1_counter
extern _SPC_T2_cycle_latch,_SPC_T2_target,_SPC_T2_position
extern _SPC_T2_cycle_latch,_SPC_T2_counter

%endif

;%1 = timer
%macro Update_SPC_Timer 1
 test byte [_SPCRAM+_SPC_CTRL],1 << %1
 je %%done

 mov edx,[_SPC_T%1_cycle_latch]
 mov ecx,[_TotalCycles]
 sub ecx,edx
 mov eax,ecx

%ifdef SPC2MHz
%if %1 != 2
 mov cl,0
 shr eax,8
%else
 and ecx,byte ~31
 shr eax,5
%endif
%else
%if %1 != 2
 and ecx,byte ~127
 shr eax,7
%else
 and ecx,byte ~15
 shr eax,4
%endif
%endif
 add edx,ecx
 add ax,[_SPC_T%1_position]
 mov [_SPC_T%1_cycle_latch],edx
 mov cx,[_SPC_T%1_target]
 mov [_SPC_T%1_position],ax
 cmp ax,cx
 jb %%done

 xor edx,edx
 div cx
 mov cl,[_SPC_T%1_counter]
 mov [_SPC_T%1_position],dx
 add al,cl
 and al,15
 mov [_SPC_T%1_counter],al

%%done:
%endmacro

%endif ; SNEeSe_SPC_i
