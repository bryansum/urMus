// File: RIOAudioUnitLayer.h
// Authors: Georg Essl
// Created: 8/25/09
// Modified: 2/5/10
// License: All rights reserved, full displaimer of liabilities and warranty, free for University of Michigan courses

// This is just in case we get a C/C++ context include.
#ifndef __RIOAUDIOUNITLAYER_H__
#define __RIOAUDIOUNITLAYER_H__

#include <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioToolbox.h>
#include <CoreAudio/CoreAudioTypes.h>
#include <CoreFoundation/CoreFoundation.h>

int SetupRemoteIO (AudioUnit* inRemoteIOUnit, AURenderCallbackStruct inRenderProcm, AudioStreamBasicDescription* outFormat);

void initializeRIOAudioLayer();
void playRIOAudioLayer();
void stopRIOAudioLayer();
void cleanupRIOAudioLayer();

void rioInterruptionListener(void *inClientData, UInt32 inInterruption);
void propListener(	void *                  inClientData,
					AudioSessionPropertyID	inID,
					UInt32                  inDataSize,
					const void *            inData);
static OSStatus	PerformThru(
							void						*inRefCon, 
							AudioUnitRenderActionFlags 	*ioActionFlags, 
							const AudioTimeStamp 		*inTimeStamp, 
							UInt32 						inBusNumber, 
							UInt32 						inNumberFrames, 
							AudioBufferList 			*ioData);

void* LoadAudioFileData(const char* filename, UInt32 *outDataSize, UInt32* outSampleRate);

#endif /* __RIOAUDIOUNITLAYER_H__ */
