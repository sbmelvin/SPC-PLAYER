#2003,2010 Stephen Melvin Jr  <stephenbmelvin@gmail.com>

NASM = nasm
MAFLAGS = --prefix _ -f macho 
NAFLAGS = -f elf
CC = gcc
#CFLAGS = -W -Wall -pedantic -g
MCFLAGS = -m32 -W -Wall -pedantic -framework CoreServices -framework AudioToolbox -framework CoreAudio -framework AudioUnit 
LCFLAGS = -Wall -pedantic 
SPC_IMPL = SNEeSe
SPCIMPL_OBJS = SNEeSe/SPC700.o SNEeSe/SPCimpl.o
LIB_OBJS = main.o dsp.o $(SPCIMPL_OBJS)
INSTALL_PATH = /usr/local

INSTALL_BIN_PATH = $(INSTALL_PATH)/bin
INSTALL_LIB_PATH = $(INSTALL_PATH)/lib
INSTALL_INC_PATH = $(INSTALL_PATH)/include


osx: CFLAGS = $(MCFLAGS)
osx: AFLAGS = $(MAFLAGS)
osx: SPCPLAYERFILE = spcplayerosx.c
osx: spcplayer

linux: CFLAGS = $(LCFLAGS)
linux: AFLAGS = $(LAFLAGS)
linux: SPCPLAYERFILE = spcplayerlinux.c
linux: spcplayer

spcplayer: libopenspc.a $(SPCPLAYERFILE)
	gcc $(CFLAGS) $(SPCPLAYERFILE) -o spcplayer -lz ./libopenspc.a


#install: libopenspc.so openspc.h
#	mkdir -p $(INSTALL_LIB_PATH) $(INSTALL_INC_PATH)
#	install -m 755 libopenspc.so $(INSTALL_LIB_PATH)/libopenspc.so
#	install -m 755 openspc.h $(INSTALL_INC_PATH)/openspc.h

install: soap
	install -m 755 soap /usr/local/bin/soap

libopenspc.a:: libopenspc.a($(LIB_OBJS))

#libopenspc.so: $(LIB_OBJS)
#	gcc $(LIB_OBJS) -o $@ -shared

main.o: main.c openspc.h dsp.h $(SPC_IMPL)/SPCimpl.h Makefile
	$(CC) $(CFLAGS) -I$(SPC_IMPL) -c main.c -o main.o

dsp.o: dsp.c dsp.h gauss.h $(SPC_IMPL)/SPCimpl.h Makefile
	$(CC) $(CFLAGS) -I$(SPC_IMPL) -c dsp.c -o dsp.o

$(SPC_IMPL)/SPCimpl.o: $(SPC_IMPL)/SPCimpl.c dsp.h Makefile
	$(CC) $(CFLAGS) -I. -c $(SPC_IMPL)/SPCimpl.c -o $(SPC_IMPL)/SPCimpl.o

SNEeSe/SPC700.o: SNEeSe/SPC700.asm SNEeSe/spc.ni SNEeSe/regs.ni \
 SNEeSe/spcaddr.ni SNEeSe/spcmacro.ni SNEeSe/spcops.ni SNEeSe/misc.ni \
 Makefile
	$(NASM) $(AFLAGS) -iSNEeSe/ -o SNEeSe/SPC700.o SNEeSe/SPC700.asm

clean:
	rm -f *.o $(SPC_IMPL)/*.o libopenspc.a soap spcplayer

uninstall:
	rm -f /usr/local/bin/soap
