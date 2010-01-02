/**************************************************************************

		Copyright (c) 2003 Brad Martin.

This file is part of OpenSPC.

SPCimpl.h: This file is a bridge between the OpenSPC library and the
specific SPC core implementation (in this case, SNEeSe's).  As the licensing
rights for SNEeSe are different from the rest of OpenSPC, none of the files
in this directory are LGPL.  Although this file was created by me (Brad
Martin), it contains some code derived from SNEeSe and therefore falls under
its license.  See the file 'LICENSE' in this directory for more information.

 **************************************************************************/

#ifndef SPCIMPL_H
#define SPCIMPL_H


#ifdef __APPLE__
#define ASMCALL "pusha;call __SPC_START;popa"
#define _SPC_START __SPC_START
#endif

#ifdef __linux__
#define ASMCALL "pusha;call _SPC_START;popa"
#endif

extern unsigned char _SPCRAM[65536],_SPC_DSP[256];
extern unsigned long __SPC_PC,__SPC_SP,_SPC_Cycles,_TotalCycles,
  _Map_Byte,_Map_Address;
extern unsigned short __SPC_YA,_SPC_T0_target,_SPC_T1_target,_SPC_T2_target;
extern unsigned char __SPC_A,__SPC_Y,__SPC_X,__SPC_PSW,
  _SPC_PORT0R,_SPC_PORT1R,_SPC_PORT2R,_SPC_PORT3R,
  _SPC_PORT0W,_SPC_PORT1W,_SPC_PORT2W,_SPC_PORT3W,
  _SPC_T0_counter,_SPC_T1_counter,_SPC_T2_counter,
  _N_flag,_H_flag,_I_flag,_B_flag,_Z_flag,_P_flag,_V_flag,_C_flag;
extern void *SPC_FFC0_Address,*SPC_Code_Base;
extern long SPC_PAGE;
extern unsigned long _SPC_T0_cycle_latch,_SPC_T1_cycle_latch,
                     _SPC_T2_cycle_latch;

void _Reset_SPC(void);
void _SPC_START(void);
unsigned char _get_SPC_PSW(void);
void SPC_SetState(int pc,int a,int x,int y,int p,int sp,void *ram);
void _Wrap_SPC_Cyclecounter(void);

#define SPC_Run(c)\
{\
	_SPC_Cycles+=(c);\
	if((signed long)_TotalCycles<0)\
	    _Wrap_SPC_Cyclecounter();\
	__asm__(ASMCALL);\
}

#define SPC_Reset()\
{\
	_Reset_SPC();\
}

#define SPC_RAM _SPCRAM
#define DSPregs _SPC_DSP

#define WritePort0(x) _SPC_PORT0R=x
#define WritePort1(x) _SPC_PORT1R=x
#define WritePort2(x) _SPC_PORT2R=x
#define WritePort3(x) _SPC_PORT3R=x

#define ReadPort0() _SPC_PORT0W
#define ReadPort1() _SPC_PORT1W
#define ReadPort2() _SPC_PORT2W
#define ReadPort3() _SPC_PORT3W

#endif /* #ifndef SPCIMPL_H */
