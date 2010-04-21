// File: RIOAudioUnitLayer.mm
// Authors: Georg Essl
// Created: 8/25/09
// License: All rights reserved (c) 2009, Georg Essl. See LICENSE.txt for license details.

// Sources:
// http://michael.tyson.id.au/2008/11/04/using-remoteio-audio-unit/
// and aurioTouch
// The way I got here is basically by taking AurioTouch's code (initialization) and extract from the helper files only the needed parts.
// This makes this all much more legible and slim.
// Edit: More sources:
// http://lists.apple.com/archives/Coreaudio-api/2009/Feb/msg00508.html
// In an attempt to get iPod Touch plugging to work properly.

#include "RIOAudioUnitLayer.h"
#include "urSound.h"
#include "urAPI.h"

#define SINT32_MAXINT 2147483647
#define SINT16_MAXINT 32767

#define kPreferredBufferSize .005

// Below is to help detect the mic, which is missing for iPod touches without extra hardware. It does work plugging in, but if unplugging the restart of audio without speakers
// currently does not work. To be fixed eventually.
UInt32 gotMic = 0;

void CheckMic()
{
	UInt32 audioInputIsAvailable;
	UInt32 propertySize = sizeof (audioInputIsAvailable);
	
	AudioSessionGetProperty (
							 kAudioSessionProperty_AudioInputAvailable,
							 &propertySize,
							 &audioInputIsAvailable // A nonzero value on output means that
							 // audio input is available
							 );
	
	gotMic = audioInputIsAvailable;
}
 
// This data structure contains info that needs to be passed to callbacks. In aurio touch this was the app delegate

SInt16* currentMicBuffer;

typedef struct rioClientData
{
	AudioUnit					rioUnit;
	AURenderCallbackStruct		inputProc;
	AudioStreamBasicDescription	thruFormat;
	Float64						hwSampleRate;
} rioClientData_t;

rioClientData_t myRioData;

// From aurioTouch

int SetupRemoteIO (AudioUnit* inRemoteIOUnit, AURenderCallbackStruct inRenderProc, AudioStreamBasicDescription* outFormat)
{	
	// Open the output unit
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	
	AudioComponent comp = AudioComponentFindNext(NULL, &desc);
	
	AudioComponentInstanceNew(comp, inRemoteIOUnit);
	
	UInt32 one = 1;
	AudioUnitSetProperty(*inRemoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
	
	AudioUnitSetProperty(*inRemoteIOUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &inRenderProc, sizeof(inRenderProc));
	
	// set our required format - Canonical AU format: LPCM non-interleaved 8.24 fixed point

	outFormat->mFormatID = kAudioFormatLinearPCM;
	outFormat->mFormatFlags = kAudioFormatFlagsCanonical;
//	outFormat->mFormatFlags = kAudioFormatFlagsCanonical | (kAudioUnitSampleFractionBits << kLinearPCMFormatFlagsSampleFractionShift);
	outFormat->mChannelsPerFrame = 2;
	outFormat->mFramesPerPacket = 1;
	outFormat->mBitsPerChannel = 8 * sizeof(AudioUnitSampleType);
	outFormat->mBytesPerPacket = outFormat->mBytesPerFrame = sizeof(AudioUnitSampleType);
	outFormat->mFormatFlags |= kAudioFormatFlagIsNonInterleaved;
	
	AudioUnitSetProperty(*inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outFormat, sizeof(outFormat));
	AudioUnitSetProperty(*inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &outFormat, sizeof(outFormat));
	
	AudioUnitInitialize(*inRemoteIOUnit);
	
	return 0;
}

// This handles if for any reason the audio stream needs to be interrupted (incoming phone call?)

void rioInterruptionListener(void *inClientData, UInt32 inInterruption)
{
//	printf("Session interrupted! --- %s ---", inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
	
	rioClientData_t *THIS = (rioClientData_t*)inClientData;
	
	// Restart the stream after an interruption
	if (inInterruption == kAudioSessionEndInterruption) {
		// make sure we are again the active session
		AudioSessionSetActive(true);
		AudioOutputUnitStart(THIS->rioUnit);
	}
	
	// Stop the stream when interrupted
	if (inInterruption == kAudioSessionBeginInterruption) {
		AudioOutputUnitStop(THIS->rioUnit);
    }
}

#pragma mark -Audio Session Property Listener

// This handles audio rerouting, for example when headphones are plugged in.

void propListener( void * inClientData,
				  AudioSessionPropertyID inID,
				  UInt32 inDataSize,
				  const void * inData)
{
//	AudioControl *THIS = (AudioControl*)inClientData;
	rioClientData_t *THIS = (rioClientData_t*)inClientData;
	CFDictionaryRef routeChangeDictionary = (CFDictionaryRef)inData;
	CFNumberRef routeChangeReasonRef =
	(CFNumberRef) CFDictionaryGetValue (routeChangeDictionary,CFSTR (kAudioSession_AudioRouteChangeKey_Reason));
	Float32 bufferSize;//.005 020
	UInt32 siz = sizeof(bufferSize);
	
	SInt32 routeChangeReason; // 9
	
	CFNumberGetValue (routeChangeReasonRef,kCFNumberSInt32Type,&routeChangeReason);
	UInt32 audioCategory;
	UInt32 size = sizeof(audioCategory);
	AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &size, &audioCategory);
	UInt32 otherAudioIsPlaying;
	AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &otherAudioIsPlaying);
	
	if(otherAudioIsPlaying && routeChangeReason == kAudioSessionRouteChangeReason_CategoryChange)
	{
		UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;// kAudioSessionCategory_PlayAndRecord kAudioSessionCategory_RecordAudio
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
		Float32 preferredBufferSize = kPreferredBufferSize;//.005 020
		AudioSessionSetProperty (kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
		AudioSessionSetActive(true);
		AudioSessionGetProperty (kAudioSessionProperty_CurrentHardwareIOBufferDuration, &siz, &bufferSize);
		if(bufferSize > kPreferredBufferSize)
		{
			AudioSessionSetActive(false);
			AudioSessionSetActive(true);
		}
		AudioOutputUnitStart(THIS->rioUnit);
	}
	else if (inID == kAudioSessionProperty_AudioRouteChange && routeChangeReason != kAudioSessionRouteChangeReason_CategoryChange)
	{
		UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;// kAudioSessionCategory_PlayAndRecord kAudioSessionCategory_RecordAudio
		AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
		Float32 preferredBufferSize = kPreferredBufferSize;//.005 020
		AudioSessionSetProperty (kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
		AudioSessionSetActive(true);
		AudioSessionGetProperty (kAudioSessionProperty_CurrentHardwareIOBufferDuration, &siz, &bufferSize);
		if(bufferSize > kPreferredBufferSize){
			AudioSessionSetActive(false);
			AudioSessionSetActive(true);
		}
		// if there was a route change, we need to dispose the current rio unit and create a new one
		AudioComponentInstanceDispose(THIS->rioUnit);
		CheckMic();
		
		SetupRemoteIO(&(THIS->rioUnit), THIS->inputProc, &(THIS->thruFormat));
		
		UInt32 size = sizeof(THIS->hwSampleRate);
		AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &THIS->hwSampleRate);
		
		AudioOutputUnitStart(THIS->rioUnit);
		
		// we need to rescale the sonogram view's color thresholds for different input
		CFStringRef newRoute;
		size = sizeof(CFStringRef);
		AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute);
		if (newRoute)
		{
			if (CFStringCompare(newRoute, CFSTR("HeadsetInOut"), NULL) == kCFCompareEqualTo) // headset plugged in
			{
			}
			else if (CFStringCompare(newRoute, CFSTR("ReceiverAndMicrophone"), NULL) == kCFCompareEqualTo) // headset plugged in
			{
			}
			else if (CFStringCompare(newRoute, CFSTR("HeadphonesAndMicrophone"), NULL) == kCFCompareEqualTo) // headset plugged in
			{
			}
			else if (CFStringCompare(newRoute, CFSTR("LineOut"), NULL) == kCFCompareEqualTo) // headset plugged in
			{
			}
			else
			{
				
			}
		}
	}
	AudioSessionGetProperty (kAudioSessionProperty_CurrentHardwareIOBufferDuration, &siz, &bufferSize);
}

#pragma mark -RIO Render Callback

static OSStatus	PerformThru(
							void						*inRefCon, 
							AudioUnitRenderActionFlags 	*ioActionFlags, 
							const AudioTimeStamp 		*inTimeStamp, 
							UInt32 						inBusNumber, 
							UInt32 						inNumberFrames, 
							AudioBufferList 			*ioData)
{
	rioClientData_t *THIS = (rioClientData_t *)inRefCon;
	OSStatus err;
	if(gotMic)
		err = AudioUnitRender(THIS->rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	if (err) { printf("PerformThru: error %d\n", (int)err); return err; }
	
	currentMicBuffer = (SInt16*)(ioData->mBuffers[0].mData);
#ifdef ENABLE_URMICEVENTS
	callAllOnMicrophone(currentMicBuffer, inNumberFrames);
#endif
//	callAllMicSources(currentMicBuffer, inNumberFrames);
	
	for(UInt32 j = 0; j < ioData->mNumberBuffers; ++j)
	{

		SInt16* dataptr = (SInt16*)(ioData->mBuffers[j].mData);
	
#ifdef ENABLE_URSOUNDBUFFER		
		ur_GetSoundBuffer(dataptr, j+1, inNumberFrames);
#endif
	//	urs_PullActiveDacSinks(dataptr, inNumberFrames);
		for(int i=0; i<inNumberFrames; i++)
		{
			callAllMicSingleTickSources(dataptr[2*i]);
			dataptr[2*i]=urs_PullActiveDacSingleTickSinks()*SINT16_MAXINT;
			dataptr[2*i+1]=dataptr[2*i];
		}
	}
		
	return err;
}

void initializeRIOAudioLayer() 
{
	// From AurioTouch
	
	myRioData.inputProc.inputProc = PerformThru;
	myRioData.inputProc.inputProcRefCon = &myRioData; // myRioData replaces self throughout
	AudioSessionInitialize(NULL, NULL, rioInterruptionListener, &myRioData);
	AudioSessionSetActive(true);
	
	UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
	AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, &myRioData);

	Float32 preferredBufferSize = .005;
	AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);

	UInt32 size = sizeof(myRioData.hwSampleRate);
	AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &myRioData.hwSampleRate);
	memset (&(myRioData.thruFormat), 0, sizeof(AudioStreamBasicDescription));
	SetupRemoteIO(&(myRioData.rioUnit), myRioData.inputProc, &(myRioData.thruFormat));	

	UInt32 maxFPS;
	size = sizeof(maxFPS);
	AudioUnitGetProperty(myRioData.rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size);
	AudioOutputUnitStart(myRioData.rioUnit);

	size = sizeof(myRioData.thruFormat);
	AudioUnitGetProperty(myRioData.rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &myRioData.thruFormat, &size);

	CheckMic();
}

void playRIOAudioLayer()
{
	OSStatus status = AudioOutputUnitStart(myRioData.rioUnit);
}

void stopRIOAudioLayer()
{
	OSStatus status = AudioOutputUnitStop(myRioData.rioUnit);
}

void cleanupRIOAudioLayer()
{
	AudioUnitUninitialize(myRioData.rioUnit);
}

void* LoadAudioFileData(const char *filename, UInt32 *outDataSize, UInt32*	outSampleRate)
{
	OSStatus						err = noErr;	
	SInt64							theFileLengthInFrames = 0;
	AudioStreamBasicDescription		theFileFormat;
	UInt32							thePropertySize = sizeof(theFileFormat);
	ExtAudioFileRef					extRef = NULL;
	void*							theData = NULL;
	AudioStreamBasicDescription		theOutputFormat;
	
	NSString *filename2 = [[NSString alloc] initWithUTF8String:filename]; // Leak here, fix.
	NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename2]; // Leak here, fix.
	CFURLRef inFileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)filePath, kCFURLPOSIXPathStyle, false); // Leak here, fix.
	// Open a file with ExtAudioFileOpen()
	err = ExtAudioFileOpenURL(inFileURL, &extRef);
	if(err) {
	// NYI
	}

	// Get the audio data format
	err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileDataFormat, &thePropertySize, &theFileFormat);
	if(err) {// NYI
	}
	if (theFileFormat.mChannelsPerFrame > 2)  { 
	// NYI
	}
	
	// Set the client format to 16 bit signed integer (native-endian) data
	// Maintain the channel count and sample rate of the original source format
	theOutputFormat.mSampleRate = theFileFormat.mSampleRate;
	theOutputFormat.mChannelsPerFrame = theFileFormat.mChannelsPerFrame;
	
	theOutputFormat.mFormatID = kAudioFormatLinearPCM;
	theOutputFormat.mBytesPerPacket = 2 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mFramesPerPacket = 1;
	theOutputFormat.mBytesPerFrame = 2 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mBitsPerChannel = 16;
	theOutputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
	
	// Set the desired client (output) data format
	err = ExtAudioFileSetProperty(extRef, kExtAudioFileProperty_ClientDataFormat, sizeof(theOutputFormat), &theOutputFormat);
	if(err) { // NYI
	}
	
	// Get the total frame count
	thePropertySize = sizeof(theFileLengthInFrames);
	err = ExtAudioFileGetProperty(extRef, kExtAudioFileProperty_FileLengthFrames, &thePropertySize, &theFileLengthInFrames);
	if(err) { 
	// NYI
	}
	
	// Read all the data into memory
	UInt32		dataSize = theFileLengthInFrames * theOutputFormat.mBytesPerFrame;;
	theData = malloc(dataSize);
	if (theData)
	{
		AudioBufferList		theDataBuffer;
		theDataBuffer.mNumberBuffers = 1;
		theDataBuffer.mBuffers[0].mDataByteSize = dataSize;
		theDataBuffer.mBuffers[0].mNumberChannels = theOutputFormat.mChannelsPerFrame;
		theDataBuffer.mBuffers[0].mData = theData;
		
		// Read the data into an AudioBufferList
		err = ExtAudioFileRead(extRef, (UInt32*)&theFileLengthInFrames, &theDataBuffer);
		if(err == noErr)
		{
			// success
			*outDataSize = theFileLengthInFrames; //dataSize;
			//*outDataFormat = (theOutputFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
			*outSampleRate = theOutputFormat.mSampleRate;
		}
		else 
		{ 
			// failure
			free (theData);
			theData = NULL; // make sure to return NULL
			printf("MyGetOpenALAudioData: ExtAudioFileRead FAILED, Error = %ld\n", err); goto Exit;
		}	
	}
	
Exit:
	[filename2 release];
	[filePath release];
	// Dispose the ExtAudioFileRef, it is no longer needed
	if (extRef) ExtAudioFileDispose(extRef);
	return theData;
}
