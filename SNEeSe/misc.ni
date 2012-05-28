%if 0

SNEeSe, an Open Source Super NES emulator.


Copyright (c) 2002 Charles Bilyue'.

This is free software.  See 'LICENSE' for details.
You must read and accept the license prior to use.

%endif

%ifndef SNEeSe_misc_i
%define SNEeSe_misc_i

%macro DUPLICATE 3      ;vartype, count, data
times %2 %1 %3
%endmacro

%macro skipb 0-1 1      ;count=1
resb %1
%endmacro

%macro skipw 0-1 1      ;count=1
resw %1
%endmacro

%macro skipl 0-1 1      ;count=1
resd %1
%endmacro

%macro skipk 0-1 1      ;count=1
resb %1*1024
%endmacro

%macro EXPORT 1-2+      ;label
global %1
%1:
%2
%endmacro

%macro EXPORT_C 1-2+    ;label
global _%1
_%1:
%2
%endmacro

%macro EXPORT_EQU 2     ;label
global %1
%1 equ (%2)
%endmacro

%macro EXPORT_EQU_C 2   ;label
global _%1
_%1 equ (%2)
%endmacro

%macro ALIGNC 0
align 16
%endmacro

%macro ALIGND 0
alignb 16,db 0
%endmacro

%macro ALIGNB 0
alignb 16
%endmacro

%endif ;!SNEeSe_misc_i
