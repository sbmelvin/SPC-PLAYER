#SPCPLAYER
##SNES SPC player for Linux and OSX

###Compilation
**Linux**

    make linux

**OS X**

    make osx

The linux version uses OSS for sound output. It was last tested to run on Ubuntu 9.10. spcplayer may not always be able to successfully open /dev/dsp. If that occurs, verify you have write permissions on /dev/dsp and try again.

Make sure you have zlib devel installed before attempting to build.

**Usage on both systems**
    
    ./spcplayer filename.spc

