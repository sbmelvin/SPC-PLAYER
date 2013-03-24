#SPCPLAYER
##SNES SPC player for Linux and OSX

##To compile:
Linux: make linux

OSX  : make osx

The linux version, which was originally written in 2003, uses the old OSS methods for sound output.
That is, it writes to /dev/dsp after setting up the sound system.
It was tested on Ubuntu 9.10 and the only bug I know of is you don't always get a successful opening of /dev/dsp the first try.
Make sure you have zlib devel installed before attempting to build.

Usage on both systems:  ./spcplayer filename.spc

