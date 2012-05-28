/**************************************************************************

		Copyright (c) 2003 Brad Martin.
		Some portions copyright (c) 2002 Charles Bilyue'.

This file is part of OpenSPC.

SPCimpl.c: This file is a bridge between the OpenSPC library and the
specific SPC core implementation (in this case, SNEeSe's).  As the licensing
rights for SNEeSe are different from the rest of OpenSPC, none of the files
in this directory are LGPL.  Although this file was created by me (Brad
Martin), it contains some code derived from SNEeSe and therefore falls under
its license.  See the file 'LICENSE' in this directory for more information.

 **************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dsp.h"
#include "SPCimpl.h"

#undef NO_ENVX
#undef CLEAR_PORTS
#undef DBG_DSP

/**** Global variables ****/
unsigned char _SPCRAM[65536],
              _SPC_DSP[256];
unsigned long _Map_Byte,_Map_Address;
long _SPC_DSP_DATA;

/* Table for opcode lookup */
static const char *SPC_OpID[256] = {
 "NOP"            ,"TCALL 0"        ,"SET1 dp.0"      ,"BBS dp.0,rel"   ,
 "OR A,dp"        ,"OR A,labs"      ,"OR A,(X)"       ,"OR A,(dp+X)"    ,
 "OR A,#imm"      ,"OR dp(d),dp(s)" ,"OR1 C,mem.bit"  ,"ASL dp"         ,
 "ASL labs"       ,"PUSH PSW"       ,"TSET1 labs"     ,"BRK"            ,

 "BPL rel"        ,"TCALL 1"        ,"CLR1 dp.0"      ,"BBC dp.0,rel"   ,
 "OR A,dp+X"      ,"OR A,labs+X"    ,"OR A,labs+Y"    ,"OR A,(dp)+Y"    ,
 "OR dp,#imm"     ,"OR (X),(Y)"     ,"DECW dp"        ,"ASL dp+X"       ,
 "ASL A"          ,"DEC X"          ,"CMP X,labs"     ,"JMP (abs,x)"    ,

 "CLRP"           ,"TCALL 2"        ,"SET1 dp.1"      ,"BBS dp.1,rel"   ,
 "AND A,dp"       ,"AND A,labs"     ,"AND A,(X)"      ,"AND A,(dp+X)"   ,
 "AND A,#imm"     ,"AND dp(d),dp(s)","OR1 C,/mem.bit" ,"ROL dp"         ,
 "ROL labs"       ,"PUSH A"         ,"CBNE dp"        ,"BRA rel"        ,

 "BMI rel"        ,"TCALL 3"        ,"CLR1 dp.1"      ,"BBC dp.1,rel"   ,
 "AND A,dp+X"     ,"AND A,labs+X"   ,"AND A,labs+Y"   ,"AND A,(dp)+Y"   ,
 "AND dp,#imm"    ,"AND (X),(Y)"    ,"INCW dp"        ,"ROL dp+X"       ,
 "ROL A"          ,"INC X"          ,"CMP X,dp"       ,"CALL labs"      ,

 "SETP"           ,"TCALL 4"        ,"SET1 dp.2"      ,"BBS dp.2,rel"   ,
 "EOR A,dp"       ,"EOR A,labs"     ,"EOR A,(X)"      ,"EOR A,(dp+X)"   ,
 "EOR A,#imm"     ,"EOR dp(d),dp(s)","AND1 C,mem.bit" ,"LSR dp"         ,
 "LSR labs"       ,"PUSH X"         ,"TCLR1 labs"     ,"PCALL upage"    ,

 "BVC rel"        ,"TCALL 5"        ,"CLR1 dp.2"      ,"BBC dp.2,rel"   ,
 "EOR A,dp+X"     ,"EOR A,labs+X"   ,"EOR A,labs+Y"   ,"EOR A,(dp)+Y"   ,
 "EOR dp,#imm"    ,"EOR (X),(Y)"    ,"CMPW YA,dp"     ,"LSR dp+X"       ,
 "LSR A"          ,"MOV X,A"        ,"CMP Y,labs"     ,"JMP labs"       ,

 "CLRC"           ,"TCALL 6"        ,"SET1 dp.3"      ,"BBS dp.3,rel"   ,
 "CMP A,dp"       ,"CMP A,labs"     ,"CMP A,(X)"      ,"CMP A,(dp+X)"   ,
 "CMP A,#imm"     ,"CMP dp(d),dp(s)","AND1 C,/mem.bit","ROR dp"         ,
 "ROR labs"       ,"PUSH Y"         ,"DBNZ dp,rel"    ,"RET"            ,

 "BVS rel"        ,"TCALL 7"        ,"CLR1 dp.3"      ,"BBC dp.3,rel"   ,
 "CMP A,dp+X"     ,"CMP A,labs+X"   ,"CMP A,labs+Y"   ,"CMP A,(dp)+Y"   ,
 "CMP dp,#imm"    ,"CMP (X),(Y)"    ,"ADDW YA,dp"     ,"ROR dp+X"       ,
 "ROR A"          ,"MOV A,X"        ,"CMP Y,dp"       ,"RETI"           ,

 "SETC"           ,"TCALL 8"        ,"SET1 dp.4"      ,"BBS dp.4,rel"   ,
 "ADC A,dp"       ,"ADC A,labs"     ,"ADC A,(X)"      ,"ADC A,(dp+X)"   ,
 "ADC A,#imm"     ,"ADC dp(d),dp(s)","EOR1 C,mem.bit" ,"DEC dp"         ,
 "DEC labs"       ,"MOV Y,#imm"     ,"POP PSW"        ,"MOV dp,#imm"    ,

 "BCC rel"        ,"TCALL 9"        ,"CLR1 dp.4"      ,"BBC dp.4,rel"   ,
 "ADC A,dp+X"     ,"ADC A,labs+X"   ,"ADC A,labs+Y"   ,"ADC A,(dp)+Y"   ,
 "ADC dp,#imm"    ,"ADC (X),(Y)"    ,"SUBW YA,dp"     ,"DEC dp+X"       ,
 "DEC A"          ,"MOV X,SP"       ,"DIV YA,X"       ,"XCN A"          ,

 "EI"             ,"TCALL 10"       ,"SET1 dp.5"      ,"BBS dp.5,rel"   ,
 "SBC A,dp"       ,"SBC A,labs"     ,"SBC A,(X)"      ,"SBC A,(dp+X)"   ,
 "SBC A,#imm"     ,"SBC dp(d),dp(s)","MOV1 C,mem.bit" ,"INC dp"         ,
 "INC labs"       ,"CMP Y,#imm"     ,"POP A"          ,"MOV (X)+,A"     ,

 "BCS rel"        ,"TCALL 11"       ,"CLR1 dp.5"      ,"BBC dp.5,rel"   ,
 "SBC A,dp+X"     ,"SBC A,labs+X"   ,"SBC A,labs+Y"   ,"SBC A,(dp)+Y"   ,
 "SBC dp,#imm"    ,"SBC (X),(Y)"    ,"MOVW YA,dp"     ,"INC dp+X"       ,
 "INC A"          ,"MOV SP,X"       ,"DAS A"          ,"MOV A,(X)+"     ,

 "DI"             ,"TCALL 12"       ,"SET1 dp.6"      ,"BBS dp.6,rel"   ,
 "MOV dp,A"       ,"MOV labs,A"     ,"MOV (X),A"      ,"MOV (dp+X),A"   ,
 "CMP X,#imm"     ,"MOV labs,X"     ,"MOV1 mem.bit,C" ,"MOV dp,Y"       ,
 "MOV labs,Y"     ,"MOV X,#imm"     ,"POP X"          ,"MUL YA"         ,

 "BNE rel"        ,"TCALL 13"       ,"CLR1 dp.6"      ,"BBC dp.6,rel"   ,
 "MOV dp+X,A"     ,"MOV labs+X,A"   ,"MOV labs+Y,A"   ,"MOV (dp)+Y,A"   ,
 "MOV dp,X"       ,"MOV dp+Y,X"     ,"MOVW dp,YA"     ,"MOV dp+X,Y"     ,
 "DEC Y"          ,"MOV A,Y"        ,"CBNE dp+X,rel"  ,"DAA A"          ,

 "CLRV"           ,"TCALL 14"       ,"SET1 dp.7"      ,"BBS dp.7,rel"   ,
 "MOV A,dp"       ,"MOV A,labs"     ,"MOV A,(X)"      ,"MOV A,(dp+X)"   ,
 "MOV A,#imm"     ,"MOV X,labs"     ,"NOT1 mem.bit"   ,"MOV Y,dp"       ,
 "MOV Y,labs"     ,"NOTC"           ,"POP Y"          ,"SLEEP"          ,

 "BEQ rel"        ,"TCALL 15"       ,"CLR1 dp.7"      ,"BBC dp.7,rel"   ,
 "MOV A,dp+X"     ,"MOV A,labs+X"   ,"MOV A,labs+Y"   ,"MOV A,(dp)+Y"   ,
 "MOV X,dp"       ,"MOV X,dp+Y"     ,"MOV dp(d),dp(s)","MOV Y,dp+X"     ,
 "INC Y"          ,"MOV Y,A"        ,"DBNZ Y,rel"     ,"STOP"
};

/**** Shared functions ****/

void SPC_SetState(int pc,int a,int x,int y,int p,int sp,void *ram)
{
	memcpy(_SPCRAM,ram,65536);
	if(!(_SPCRAM[0xF1]&0x80))
		SPC_FFC0_Address=_SPCRAM;
	_SPC_T0_target=_SPCRAM[0xFA];
	if(_SPC_T0_target==0)
		_SPC_T0_target=0x100;
	_SPC_T1_target=_SPCRAM[0xFB];
	if(_SPC_T1_target==0)
		_SPC_T1_target=0x100;
	_SPC_T2_target=_SPCRAM[0xFC];
	if(_SPC_T2_target==0)
		_SPC_T2_target=0x100;
	_SPC_T0_counter=_SPCRAM[0xFD]&0xF;
	_SPC_T1_counter=_SPCRAM[0xFE]&0xF;
	_SPC_T2_counter=_SPCRAM[0xFF]&0xF;
	_SPC_PORT0R=_SPCRAM[0xF4];
	_SPC_PORT1R=_SPCRAM[0xF5];
	_SPC_PORT2R=_SPCRAM[0xF6];
	_SPC_PORT3R=_SPCRAM[0xF7];
	__SPC_PC=pc;
	__SPC_A=a;
	__SPC_X=x;
	__SPC_Y=y;
	__SPC_SP=sp;
	if(__SPC_PC<0xFFC0)
		SPC_Code_Base=_SPCRAM;
	/* Now we have to set up the PSW.  Unfortunately, SNEeSe doesn't 
	   have one central PSW, and doesn't export any functions to set it 
	   up, so we have to do this ourselves. */			
	__SPC_PSW=p;
	_N_flag=__SPC_PSW&0x80?0xFF:0;
	_V_flag=__SPC_PSW&0x40?0xFF:0;
	if(__SPC_PSW&0x20)
	{
		_P_flag=0x20;
		SPC_PAGE=0x00000100;
	}
	else
	{
		_P_flag=0;
		SPC_PAGE=0x00000000;
	}
	_B_flag=__SPC_PSW&0x10?1:0;
	_H_flag=__SPC_PSW&8?0xFF:0;
	_I_flag=__SPC_PSW&4?0xFF:0;
	_Z_flag=__SPC_PSW&2?0:0xFF;
	_C_flag=__SPC_PSW&1?0xFF:0;
#ifdef CLEAR_PORTS
	/* Hack: if any of the control port 'port clear' bits are set, carry
	   out that clear now.  Not sure how they would get set and not have
	   already been cleared, but I'm hoping this will fix an issue I'm
	   seeing with an SPC file that apparently does have it set. */
	/* Update: breaks Actraiser, so hack reverted */
	if(_SPCRAM[0xF1]&0x10)
		_SPC_PORT0R=_SPC_PORT1R=0;
	if(_SPCRAM[0xF1]&0x20)
		_SPC_PORT2R=_SPC_PORT3R=0;
#endif
}

/* These are to be called from SNEeSe ASM SPC core ONLY!  There is no header
   file for these! */

void _Wrap_SPC_Cyclecounter(void)
{
    _TotalCycles-=0xF0000000;
    _SPC_Cycles-=0xF0000000;
    _SPC_T0_cycle_latch-=0xF0000000;
    _SPC_T1_cycle_latch-=0xF0000000;
    _SPC_T2_cycle_latch-=0xF0000000;
}

void _DisplaySPC()
{
 char Message[9];
 int c;

 fprintf(stderr,"\nSPC registers\n");
 fprintf(stderr,"PC:%04lX  SP:%04lX  NVPBHIZC\n", __SPC_PC, __SPC_SP);

 __SPC_PSW = _get_SPC_PSW();
 for (c = 0; c < 8; c++) Message[7 - c] = (__SPC_PSW & (1 << c)) ? '1' : '0';
 Message[8] = 0;

 fprintf(stderr,"A:%02X  X:%02X  Y:%02X  %s\n",
  (unsigned) __SPC_A, (unsigned) __SPC_X, (unsigned) __SPC_Y, Message);

 fprintf(stderr,"SPC R  0:%02X  1:%02X  2:%02X  3:%02X\n",
  (unsigned) _SPC_PORT0R, (unsigned) _SPC_PORT1R,
  (unsigned) _SPC_PORT2R, (unsigned) _SPC_PORT3R);
 fprintf(stderr,"SPC W  0:%02X  1:%02X  2:%02X  3:%02X\n",
  (unsigned) _SPC_PORT0W, (unsigned) _SPC_PORT1W,
  (unsigned) _SPC_PORT2W, (unsigned) _SPC_PORT3W);
 fprintf(stderr,"SPC counters:%1X %1X %1X targets:%02X %02X %02X CTRL:%02X\n",
  _SPC_T0_counter, _SPC_T1_counter, _SPC_T2_counter,
  _SPC_T0_target & 0xFF, _SPC_T1_target & 0xFF, _SPC_T2_target & 0xFF,
  _SPCRAM[0xF1]);
 fprintf(stderr,"Op: %02X (%02X %02X)\n",_SPCRAM[__SPC_PC],
  _SPCRAM[__SPC_PC+1],_SPCRAM[__SPC_PC+2]);
}

void _InvalidSPCOpcode()
{
	_DisplaySPC();
	fprintf(stderr,"Unemulated SPC opcode 0x%02X (%s)\n",
	 (unsigned) _Map_Byte, SPC_OpID[_Map_Byte]);
	fprintf(stderr,"At address 0x%04X\n",(unsigned)(_Map_Address&0xFFFF));
	exit(1);
}

void _SPC_READ_DSP(void)
{
#ifdef DBG_DSP
fprintf(stderr,"Reading 0x%02X from DSP register 0x%02X\n",_SPC_DSP[_SPCRAM[0xF2]],_SPCRAM[0xF2]);*/
#endif
#ifdef NO_ENVX
	if((_SPCRAM[0xF2]&0xF)==8)
		_SPC_DSP[_SPCRAM[0xF2]]=0;
#endif
}

void _SPC_WRITE_DSP(void)
{
	int addr=_SPCRAM[0xF2];
#ifdef DBG_DSP
fprintf(stderr,"Writing 0x%02X to DSP register 0x%02X\n",_SPC_DSP_DATA,addr);
#endif
	if(addr==0x7C)
		DSP_WRITE_7C(_SPC_DSP_DATA);
	else
		_SPC_DSP[addr]=_SPC_DSP_DATA;
}
