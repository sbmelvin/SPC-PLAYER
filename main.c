/************************************************************************

		Copyright (c) 2003 Brad Martin.

This file is part of OpenSPC.

OpenSPC is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

OpenSPC is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with OpenSPC; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA



main.c: implements functions intended for external use of the libopenspc
library.

 ************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zlib.h>

#include "openspc.h"
#include "dsp.h"
#include "SPCimpl.h"

#undef NO_CLEAR_ECHO

static int mix_left;

/**** Internal (static) functions ****/

static int Load_SPC(void *buf,size_t size)
{
	const char ident[]="SNES-SPC700 Sound File Data";
	struct SPC_FILE
	{
		char ident[37] __attribute__ ((packed));
		unsigned short PC __attribute__ ((packed));
		unsigned char A __attribute__ ((packed)),
		              X __attribute__ ((packed)),
		              Y __attribute__ ((packed)),
		              P __attribute__ ((packed)),
	     	              SP __attribute__ ((packed));
		char junk[212] __attribute__ ((packed)),
		     RAM[65536] __attribute__ ((packed)),
		     DSP[128] __attribute__ ((packed));
	} *spc_file;
	if(size<sizeof(spc_file))
		return 1;
	spc_file=(struct SPC_FILE *)buf;
			
	if(memcmp(buf,ident,strlen(ident)))
		return 1;
	SPC_SetState(spc_file->PC,spc_file->A,spc_file->X,spc_file->Y,
	  spc_file->P,0x100+spc_file->SP,spc_file->RAM);
	memcpy(DSPregs,spc_file->DSP,128);
	return 0;
}

static int Load_ZST(void *buf,size_t size)
{
	int p;
	const char ident[]="ZSNES Save State File";
	struct ZST_FILE
	{
		char ident[26] __attribute__ ((packed)),
		     junk[199673] __attribute__ ((packed)),
		     RAM[65536] __attribute__ ((packed)),
		     junk2[16] __attribute__ ((packed));
		long PC __attribute__ ((packed)),
		     A __attribute__ ((packed)),
		     X __attribute__ ((packed)),
		     Y __attribute__ ((packed)),
		     P __attribute__ ((packed)),
		     P2 __attribute__ ((packed)),
		     SP __attribute__ ((packed));
		char junk3[420] __attribute__ ((packed)),
		     v_on[8] __attribute__ ((packed)),
		     junk4[916] __attribute__ ((packed)),
		     DSP[256] __attribute__ ((packed));
	} *zst_file;
	
	if(size<sizeof(struct ZST_FILE))
		return 1;
	zst_file=(struct ZST_FILE *)buf;
	
	if(memcmp(buf,ident,strlen(ident)))
		return 1;
	p=zst_file->P;
	if(zst_file->P2==0)
		p|=2;
	else
		p&=~2;
	if(zst_file->P2&0x80)
		p|=0x80;
	else
		p&=~0x80;
	SPC_SetState(zst_file->PC,zst_file->A,zst_file->X,zst_file->Y,p,
	  zst_file->SP,zst_file->RAM);
	memcpy(DSPregs,zst_file->DSP,256);
	/* Little hack to turn on voices that were already on when state
	   was saved.  Doesn't restore the entire state of the voice, just
	   starts it over from the beginning. */
	for(p=0;p<8;p++)
		if(zst_file->v_on[p])
			DSPregs[0x4C]|=(1<<p);
	return 0;
}

static int GZ_Read(void *buf,size_t size,z_streamp zsp)
{
	zsp->next_out=buf;
	zsp->avail_out=size;
	return inflate(zsp,Z_SYNC_FLUSH);
}

static z_streamp GZ_Open(unsigned char *buf,size_t size)
{
	struct gz_header
	{
		unsigned char id1 __attribute__ ((packed)),
		              id2 __attribute__ ((packed)),
		              cm __attribute__ ((packed)),
		              flg __attribute__ ((packed));
		unsigned long mtime __attribute__ ((packed));
		unsigned char xfl __attribute__ ((packed)),
		              os __attribute__ ((packed));
	} *gzh=(struct gz_header *)buf;
	z_streamp zsp;
	size_t skip=sizeof(struct gz_header);
	/* First, verify the GZ header */
	if((gzh->id1!=0x1F)||(gzh->id2!=0x8B)||(gzh->cm!=0x08)||
	  (gzh->flg&0xE0))
		return NULL;
	if(gzh->flg&0x04)
		skip+=(int)buf[skip]+(int)(buf[skip+1]<<8)+2;
	if(gzh->flg&0x08)
		while((skip<size)&&(buf[skip]!='\0'))
			skip++;
	if(gzh->flg&0x10)
		while((skip<size)&&(buf[skip]!='\0'))
			skip++;
	if(gzh->flg&0x02)
		skip+=2;
	if(skip>=size)
		return NULL;
	zsp=malloc(sizeof(z_stream));
	zsp->next_in=buf+skip;
	zsp->avail_in=size-skip;
	zsp->zalloc=Z_NULL;
	zsp->zfree=Z_NULL;
	zsp->opaque=Z_NULL;
	if(inflateInit2(zsp,-MAX_WBITS)!=Z_OK)
	{
		fprintf(stderr,"ZLib init error: '%s'\n",zsp->msg);
		return NULL;
	}
	return zsp;
}

static void GZ_Close(z_streamp zsp)
{
	inflateEnd(zsp);
	free(zsp);
}

static int Load_S9X(void *buf,size_t size)
{
	struct S9X_APU_BLOCK
	{
		unsigned long Cycles __attribute__ ((packed));
		unsigned char ShowROM __attribute__ ((packed)),
		              Flags __attribute__ ((packed)),
		              KeyedChannels __attribute__ ((packed)),
		              OutPorts[4] __attribute__ ((packed)),
		              DSP[0x80] __attribute__ ((packed)),
		              ExtraRAM[64] __attribute__ ((packed));
		unsigned short Timer[3] __attribute__ ((packed)),
		               TimerTarget[3] __attribute__ ((packed));
		unsigned char TimerEnabled[3] __attribute__ ((packed)),
		              TimerValueWritten[3] __attribute__ ((packed));
	};
	struct S9X_APUREGS_BLOCK
	{
		unsigned char P __attribute__ ((packed)),
		              A __attribute__ ((packed)),
		              Y __attribute__ ((packed)),
		              X __attribute__ ((packed)),
		              S __attribute__ ((packed)),
		              PCh __attribute__ ((packed)),
		              PCl __attribute__ ((packed));
	} SnapAPURegisters;
	const char ident[]="#!snes9";
	const int bufsize=65536;
	char *obuf=malloc(bufsize),*RAM=malloc(65536);
	z_streamp zsp=GZ_Open(buf,size);
	int i,blen,foundRAM=0,foundRegs=0;

	if(zsp==NULL)
		return 1;
	i=GZ_Read(obuf,14,zsp);
	if(memcmp(ident,obuf,strlen(ident)))
	{
		GZ_Close(zsp);
		return 1;
	}
	while(GZ_Read(obuf,11,zsp)!=Z_STREAM_END)
	{
		for(i=0;(i<11)&&(obuf[i]!=':');i++);
		blen=strtol(&obuf[i+1],NULL,10);
		if(!memcmp(obuf,"APU",3))
		{
			if(blen>=bufsize)
			{
				GZ_Read(obuf,bufsize,zsp);
				blen-=bufsize;
			}
			else
			{
				GZ_Read(obuf,blen,zsp);
				blen=0;
			}
			memcpy(DSPregs,
			 ((struct S9X_APU_BLOCK *)obuf)->DSP,0x80);
		}
		else if(!memcmp(obuf,"ARE",3))
		{
			if(blen>=(int)sizeof(struct S9X_APUREGS_BLOCK))
			{
				GZ_Read(&SnapAPURegisters,
				 sizeof(struct S9X_APUREGS_BLOCK),zsp);
				blen-=sizeof(struct S9X_APUREGS_BLOCK);
			}
			else
			{
				GZ_Read(&SnapAPURegisters,blen,zsp);
				blen=0;
			}
			foundRegs=1;
		}
		else if(!memcmp(obuf,"ARA",3))
		{
			if(blen>=65536)
			{
				GZ_Read(RAM,65536,zsp);
				blen-=65536;
			}
			else
			{
				GZ_Read(RAM,blen,zsp);
				blen=0;
			}
			foundRAM=1;
		}
		
		while(blen>bufsize)
		{
			GZ_Read(obuf,bufsize,zsp);
			blen-=bufsize;
		}
		GZ_Read(obuf,blen,zsp);
	}
	
	free(obuf);
	if(!foundRAM||!foundRegs)
	{
		free(RAM);
		return 1;
	}
	/* Now that we have all the info, load the state */
	SPC_SetState(((int)SnapAPURegisters.PCh<<8)+SnapAPURegisters.PCl,
	 SnapAPURegisters.A,SnapAPURegisters.X,SnapAPURegisters.Y,
	 SnapAPURegisters.P,(int)SnapAPURegisters.S+0x100,RAM);
	free(RAM);
	return 0;
}

/**** Exported library interfaces ****/

int OSPC_Init(void *buf, size_t size)
{
	int ret;
#ifndef NO_CLEAR_ECHO
	int start,len;
#endif
	mix_left=0;
	SPC_Reset();
	DSP_Reset();
	ret=Load_SPC(buf,size);
	if(ret==1)	/* Return 1 means wrong format */
		ret=Load_ZST(buf,size);
	if(ret==1)
		ret=Load_S9X(buf,size);

/* New file formats could go on from here, for example:
	if(ret==1)
		ret=Load_FOO(buf,size);
	...
*/
#ifndef NO_CLEAR_ECHO
	/* Because the emulator that generated the SPC file most likely did
	   not correctly support echo, it is probably necessary to zero out
	   the echo region of memory to prevent pops and clicks as playback
	   begins. */
	if(!(DSPregs[0x6C]&0x20))
	{
		start=(unsigned char)DSPregs[0x6D]<<8;
		len=(unsigned char)DSPregs[0x7D]<<11;
		if(start+len>0x10000)
			len=0x10000-start;
		memset(&SPC_RAM[start],0,len);
	}
#endif
	return ret;
}

int OSPC_Run(int cyc, short *s_buf, int s_size)
{
	int i,buf_inc=s_buf?2:0;
	
	if((cyc<0)||((s_buf!=NULL)&&(cyc>=(s_size>>2)*TS_CYC+mix_left)))
	{   /* Buffer size is the limiting factor */
		s_size&=~3;
		if(mix_left)
			SPC_Run(mix_left);
		for(i=0;i<s_size;i+=4,s_buf+=buf_inc)
		{
			DSP_Update(s_buf);
			SPC_Run(TS_CYC);
		}
		mix_left=0;
		return s_size;
	}
	
	/* Otherwise, use the cycle count */
	if(cyc<mix_left)
	{
		SPC_Run(cyc);
		mix_left-=cyc;
		return 0;
	}
	if(mix_left)
	{
		SPC_Run(mix_left);
		cyc-=mix_left;
	}
	for(i=0;cyc>=TS_CYC;i+=4,cyc-=TS_CYC,s_buf+=buf_inc)
	{
		DSP_Update(s_buf);
		SPC_Run(TS_CYC);
	}
	if(cyc)
	{
		DSP_Update(s_buf);
		SPC_Run(cyc);
		mix_left=TS_CYC-cyc;
		i+=4;
	}
	return i;
}

void OSPC_WritePort0(char data)
{
	WritePort0(data);
}

void OSPC_WritePort1(char data)
{
	WritePort1(data);
}

void OSPC_WritePort2(char data)
{
	WritePort2(data);
}

void OSPC_WritePort3(char data)
{
	WritePort3(data);
}

char OSPC_ReadPort0(void)
{
	return ReadPort0();
}

char OSPC_ReadPort1(void)
{
	return ReadPort1();
}

char OSPC_ReadPort2(void)
{
	return ReadPort2();
}

char OSPC_ReadPort3(void)
{
	return ReadPort3();
}
