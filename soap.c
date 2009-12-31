/*Stephen B Melvin Jr, <jinksys@gmail.com>
Version 0.3 OSX Core Audio Version
*/

#include <CoreServices/CoreServices.h>
#include <CoreAudio/CoreAudio.h>
#include <CoreServices/CoreServices.h>
#include <stdio.h>
#include <unistd.h>
#include <AudioUnit/AudioUnit.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <fcntl.h>
#include "openspc.h"
#include <unistd.h>
#include <sys/stat.h>
#include <ctype.h>
#include <string.h>
#include <errno.h>
#include <strings.h>

	UInt32	theFormatFlags =  kAudioFormatFlagIsSignedInteger | 
									kAudioFormatFlagsNativeEndian
									| kLinearPCMFormatFlagIsPacked
									| kAudioFormatFlagIsNonInterleaved;
	UInt32	theBytesPerFrame = 2,theBytesInAPacket = 2;
	UInt32	theBitsPerChannel = 16;
	AudioUnit gOutputUnit;
	UInt32 initAudio(void);
	void playAudio(void);
	OSStatus MyRenderer(void *inRefCon, 
					AudioUnitRenderActionFlags 	*ioActionFlags, 
					const AudioTimeStamp 		*inTimeStamp, 
					UInt32 						inBusNumber, 
					UInt32 						inNumberFrames, 
					AudioBufferList 			*ioData);
				void *buf;
int main(int argc, char *argv[])
{
	
	int fd;

	char spcFile[]="/Users/jinksys/Documents/Programming/soap-0.2/SMAS/smas-103.spc";
	char c;
	void *ptr;
	off_t size;

	buf=malloc(32000);
		
	fd=open(spcFile,O_RDONLY);
	if(fd==-1)
	{
		perror("open: ");	
		printf("BNOOM");
		return 1;
	}
		
	size=lseek(fd,0,SEEK_END);
		
	lseek(fd,0,SEEK_SET);
		
	ptr=malloc(size);
		read(fd,ptr,size);
		close(fd);
		

		//printf("b4 OSPC");
		fd=OSPC_Init(ptr,size);

		free(ptr);
	
	/*	while(1)
		{
			size=OSPC_Run(-1,buf,4096);
			write(STDOUT_FILENO,buf,size);
			printf("donkies");
			fflush(stdout);

		}
	*/
		//printf("b4 init");		
		fflush(stdout);
		initAudio();
		//printf("after init");
		fflush(stdout);
		playAudio();
		
		
		


		printf("\nGoodbye!\n");
		return 0;
}

UInt32 initAudio(void)
{
	//printf("[INIT]\n");
	OSStatus err = noErr;

	//An AudioUnit is an OS component.
	    //A component description must be setup, then used to
	    //initialize an AudioUnit

	    ComponentDescription desc;
	    Component comp;

	    //There are several Different types of AudioUnits.
	    //Some audio units serve as Outputs, Mixers, or DSP
	    //units. See AUComponent.h for listing

	    desc.componentType = kAudioUnitType_Output;

	    //Every Component has a subType, which will give a clearer picture
	    //of what this components function will be.

	    desc.componentSubType = kAudioUnitSubType_DefaultOutput;

	    //All AudioUnits in AUComponent.h must use
	    //"kAudioUnitManufacturer_Apple" as the Manufacturer

	    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	    desc.componentFlags = 0;
	    desc.componentFlagsMask = 0;

	    //Finds a component that meets the desc spec's
	    comp = FindNextComponent(NULL, &desc);
	    if (comp == NULL) exit (-1);
		printf("[BeforeOpenAComponent]\n");
	    //gains access to the services provided by the component
	    err = OpenAComponent(comp, &gOutputUnit);
	if (err) { printf ("AudioUnitSetProperty-CB=%ld\n", (long int)err); return; }
		printf("[OpenAComponent]\n");
	
		// Set up a callback function to generate output to the output unit
    	AURenderCallbackStruct input;
		input.inputProc = MyRenderer;
		input.inputProcRefCon = NULL;

		err = AudioUnitSetProperty (gOutputUnit, 
								kAudioUnitProperty_SetRenderCallback, 
								kAudioUnitScope_Input,
								0, 
								&input, 
								sizeof(input));
		if (err) { printf ("AudioUnitSetProperty-CB=%ld\n", (long int)err); return; }
//printf("Got Here");
//fflush(NULL);
}

OSStatus	MyRenderer(void 				*inRefCon, 
				AudioUnitRenderActionFlags 	*ioActionFlags, 
				const AudioTimeStamp 		*inTimeStamp, 
				UInt32 						inBusNumber, 
				UInt32 						inNumberFrames, 
				AudioBufferList 			*ioData)
{
//	printf("asking for %d frames\n", inNumberFrames);
	fflush(stdout);
	int frame=0;
	int size,channel=0;
	size=OSPC_Run(-1,buf,inNumberFrames*4);
	//write(STDOUT_FILENO, buf, size);
	for(frame; frame<inNumberFrames; ++frame)
	{
		//bzero(ioData->mBuffers[0].mData, ioData->mBuffers[0].mDataByteSize);
		//bzero(ioData->mBuffers[1].mData, ioData->mBuffers[1].mDataByteSize);
		
		memcpy(ioData->mBuffers[0].mData+(frame*2), buf+(frame*4), 2);
		memcpy(ioData->mBuffers[1].mData+(frame*2), buf+(frame*4)+2, 2);	
	}
	
	//memcpy(ioData->mBuffers[0].mData, buf, inNumberFrames);
	//memcpy(ioData->mBuffers[1].mData, buf, inNumberFrames);
	
	/*
	for (channel; channel < ioData->mNumberBuffers; channel++)
	{	while(frame<inNumberFrames)
		{
			ioData->mBuffers[channel].mData[frame
		}
		memcpy (ioData->mBuffers[channel].mData,buf,ioData->mBuffers[channel].mDataByteSize);
	}*/
	
	return noErr;
}

		void	playAudio()
		{
			OSStatus err = noErr;

			// We tell the Output Unit what format we're going to supply data to it
			// this is necessary if you're providing data through an input callback
			// AND you want the DefaultOutputUnit to do any format conversions
			// necessary from your format to the device's format.
			AudioStreamBasicDescription streamFormat;
				streamFormat.mSampleRate = 32000.0;		//	the sample rate of the audio stream
				streamFormat.mFormatID = kAudioFormatLinearPCM;;			//	the specific encoding type of audio stream
				streamFormat.mFormatFlags = theFormatFlags;		//	flags specific to each format
				streamFormat.mBytesPerPacket = theBytesInAPacket;	
				streamFormat.mFramesPerPacket = 1;	
				streamFormat.mBytesPerFrame = theBytesPerFrame;		
				streamFormat.mChannelsPerFrame = 2;	
				streamFormat.mBitsPerChannel = theBitsPerChannel;	
			err = AudioUnitSetProperty (gOutputUnit,
									kAudioUnitProperty_StreamFormat,
									kAudioUnitScope_Input,
									0,
									&streamFormat,
									sizeof(AudioStreamBasicDescription));
			if (err) { printf ("AudioUnitSetProperty-SF=%4.4s, %ld\n", (char*)&err, (long int)err); return; }

		    // Initialize unit
			err = AudioUnitInitialize(gOutputUnit);
			if (err) { printf ("AudioUnitInitialize=%ld\n", (long int)err); return; }

			Float64 outSampleRate;
			UInt32 size = sizeof(Float64);
			err = AudioUnitGetProperty (gOutputUnit,
									kAudioUnitProperty_SampleRate,
									kAudioUnitScope_Output,
									0,
									&outSampleRate,
									&size);
			if (err) { printf ("AudioUnitSetProperty-GF=%4.4s, %ld\n", (char*)&err, (long int)err); return; }

			// Start the rendering
			// The DefaultOutputUnit will do any format conversions to the format of the default device
			err = AudioOutputUnitStart (gOutputUnit);
			if (err) { printf ("AudioOutputUnitStart=%ld\n", (long int)err); return; }

					// we call the CFRunLoopRunInMode to service any notifications that the audio
					// system has to deal with
			printf("CFLOOP");
			CFRunLoopRun();
			//CFRunLoopRunInMode(kCFRunLoopDefaultMode, 20, false);
			printf("AFCF");
		// REALLY after you're finished playing STOP THE AUDIO OUTPUT UNIT!!!!!!	
		// but we never get here because we're running until the process is nuked...	
			verify_noerr (AudioOutputUnitStop (gOutputUnit));

		    err = AudioUnitUninitialize (gOutputUnit);
			if (err) { printf ("AudioUnitUninitialize=%ld\n", (long int)err); return; }
		}

		void CloseDefaultAU ()
		{
			// Clean up
			CloseComponent (gOutputUnit);
		}
	
