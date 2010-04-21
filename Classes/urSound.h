/*
 *  urSound.h
 *  urMus
 *
 *  Created by gessl on 9/13/09.
 *  Copyright 2009 Georg Essl. All rights reserved.
 *
 */

#ifndef __URSOUND_H__
#define __URSOUND_H__

#include <CoreFoundation/CoreFoundation.h>

#define URSOUND_BUFFERSIZE 256
#define URS_OBJHISTORY URSOUND_BUFFERSIZE

double norm2Freq(double norm);
double norm2RevTime(double norm);
double norm2RevSamples(double a,double sr); 
double norm2RevSamples(double norm);
inline double csaporm(double norm);
double norm2PositiveLinear(double norm);
double norm2ModIndex(double norm);
double norm2PitchShift(double norm);

void urs_PullActiveDacSinks(SInt16 *buff, UInt32 len);
void urs_PullActiveAudioFrameSinks();
double urs_PullActiveVisSinks();
void urs_PullActiveDrainSinks(UInt32 len);
void urs_PullActiveDrainFrameSinks(UInt32 len);
double urs_PullActiveDacSingleTickSinks();

struct urSoundIn;
struct urSoundOut;
struct urSoundPullIn;
struct urSoundPushOut;

class Loop
{
public:
	Loop(long len, long maxlen=480000); // 10 seconds is lots of samples
	~Loop();
	double Tick();
	void SetNow(double indata);
	void SetAt(double indata, int pos);
	void SetBoundary();
private:
	long now;
	long looplength;
	long maxlength;
	long startpos;
	double *loop;
};

class ursObjectArray;

class ursObject
{
public:
	ursObject(const char* objname, void* (*objconst)(), void (*objdest)(ursObject*),int nrins = 0, int nrouts = 0, bool dontinstance = false, bool coupled = false, ursObjectArray* instancearray = NULL);
	~ursObject();
	ursObject* Clone();
	void AddOut(const char* outname, const char* outsemantics, double (*func)(ursObject *), double (*func3)(ursObject *), void (*func2)(ursObject*, SInt16*, UInt32));
	void AddIn(const char* inname, const char* insemantics, void (*func)(ursObject *, double));
	void AddPushOut(int idx, urSoundIn* in);
	void AddPullIn(int idx, urSoundOut* out);
	bool IsPushedOut(int idx, urSoundIn* in);
	bool IsPulledIn(int idx, urSoundOut* out);
	void RemovePushOut(int idx, urSoundIn* in);
	void RemovePullIn(int idx, urSoundOut* out);
	void SetCouple(int inidx, int outidx);
	double FeedAllPullIns(int minidx = 0);
	void CallAllPushOuts(double indata, int idx=0);
	double CallAllPullIns(int idx = 0);

	const char* name;
	bool fed;
	int lastin;
	int lastout;
	double lastindata[URS_OBJHISTORY];
	int indatapos;
	int outdatapos;
	bool filled;
	bool noninstantiable;
	ursObjectArray* instancelist;
	int instancenumber;
	int nr_ins;
	int nr_outs;
	urSoundIn* ins;
	urSoundPullIn** firstpullin;
	urSoundOut* outs;
	urSoundPushOut** firstpushout;
	int couple_in;
	int couple_out;
	bool iscoupled;
	void* (*DataConstructor)();
	void (*DataDestructor)(ursObject*);
	void* objectdata;
};

class ursObjectArray
{
public:
	ursObjectArray(int initmax = 10);
	~ursObjectArray();
	void Append(ursObject*);
	ursObject* Get(int);
	ursObject* operator[](int);
	int Last() { return current; };
private:
	ursObject**	objectlist;
	int max;
	int current;
};


/*class urPlainRateConverter 
{
public:
	urPlainRateConverter(double inrate, double outrate, int buffersize);
	~urPlainRateConverter();
	In(double);
	double Tick();
private:
	double* buffer;
	double inrate;
	double outrate;
	double inpos;
	double outpos;
	double ininc;
	double outinc;
};


urPlainRateConverter::In(double indata)
{
	buffer[(UInt32)inpos] = indata;
	
}
*/
struct urSoundPullIn
{
	struct urSoundOut* out;
	struct urSoundPullIn* next;
};

struct urSoundPushOut
{
	struct urSoundIn* in;
	struct urSoundPushOut* next;
};

struct urSoundIn
{
	const char* name;
	const char* semantics;
	void (*inFuncTick)(ursObject *self,double in);
	void (*inFuncFeedBuffer)(ursObject* self, const SInt16* in, UInt32 len);
	ursObject* object;
	void* data;
	struct urSoundPullOut* firstpullout;
	bool isplaced;
};

struct urSoundOut
{
	const char* name;
	const char* semantics;
	double (*outFuncTick)(ursObject *self);
	double (*outFuncValue)(ursObject *self);
	void (*outFuncFillBuffer)(ursObject* self,SInt16* out, UInt32 len);
	ursObject* object;
	void* data;
	struct urSoundPushIn* firstpushin;
	bool isplaced;
};

#define URSOUND_DEFAULTSRATE 48000
//#define PI 3.1415926535

struct SinOsc_Data
{
	double lastout;
	double freq;
	double amp;
	double phase;
	double srate;
	double time;
	SinOsc_Data() { freq = 440; phase = 0; srate = URSOUND_DEFAULTSRATE; time = 0; }
};

struct OWF_Data
{
	double lastout;
	double freq;
	double amp;
	double phase;
	double srate;
	double time;
	OWF_Data() { freq = 440; phase = 0; srate = URSOUND_DEFAULTSRATE; time = 0; }
};

struct Gain_Data
{
	double lastout;
	double amp;
	Gain_Data() { amp = 0.95; }
};

struct Sample_Data
{
	bool playing;
	bool loop;
	SInt16** samplebuffer;//[8];
	SInt32 activesample;
	double lastout;
	SInt32 position;
	double realposition;
	UInt32 numsamples;
	UInt32 len[8];
	double rate;
	double amp;
	Sample_Data() { playing = true; loop = true; position = 0; realposition = 0.0; rate = 1.0; }
};

struct Sleigh_Data
{
	bool playing;
	bool loop;
	SInt16* Sleighbuffer[8];
	SInt32 activeSleigh;
	double lastout;
	SInt32 position;
	double realposition;
	UInt32 len[8];
	double rate;
	double amp;
	Sleigh_Data() { playing = true; loop = false; position = 0; realposition = 0.0; rate = 1.0; }
};

struct Looper_Data
{
	bool playing;
	bool loop;
	SInt16* samplebuffer;
	double lastout;
	SInt32 position;
	double realposition;
	UInt32 len;
	UInt32 playpos;
	UInt32 reclen;
	UInt32 recpos;
	bool recording;
	double rate;
	double amp;
	Looper_Data() { playing = true; loop = true; position = 0; realposition = 0.0; len = 0; rate = 1.0; }
};

struct LoopRhythm_Data
{
	Loop* loop;
	double btime;
	double bstep;
	double sampletime;
	double lastout;
};

struct CircleMap_Data
{
	double lastout;
	double freq;
	double nonl;
	double amp;
	double phase;
	double srate;
	double time;
	CircleMap_Data() { freq = 440; phase = 0; srate = URSOUND_DEFAULTSRATE; time = 0; nonl = 0; }
};

struct Avg_Data
{
	double lastout;
	double avg;
	long inpos;
	long outpos;
	double* buffer;
	long bufferlen;
	Avg_Data() { inpos = 0; outpos = 0; bufferlen = 0; }
};

class ursSinkList
{
public:
		urSoundOut** sinks;
		int length;
		ursSinkList();
		~ursSinkList();
		void AddSink(urSoundOut* sink);
		void RemoveSink(urSoundOut* sink);
private:
		int allocsize;
};

void Dac_In(ursObject* gself, double in);
void Vis_In(ursObject* gself, double in);
void Drain_In(ursObject* gself, double in);
void Pull_In(ursObject* gself, double in);

void* SinOsc_Constructor();
void SinOsc_Destructor(ursObject* gself);
double SinOsc_Tick(ursObject* gself);
double SinOsc_Out(ursObject* gself);
void SinOsc_FillBuffer(ursObject* gself, SInt16* buffer, UInt32 len);
void SinOsc_SetFreq(ursObject* gself, double infreq);
void SinOsc_SetAmp(ursObject* gself, double inamp);
void SinOsc_SetRate(ursObject* gself, double inrate);
void SinOsc_SetPhase(ursObject* gself, double inphase);

void* OWF_Constructor();
void OWF_Destructor(ursObject* gself);
double OWF_Tick(ursObject* gself);
double OWF_Out(ursObject* gself);
void OWF_FillBuffer(ursObject* gself, SInt16* buffer, UInt32 len);
void OWF_SetFreq(ursObject* gself, double infreq);
void OWF_SetAmp(ursObject* gself, double inamp);
void OWF_SetRate(ursObject* gself, double inrate);
void OWF_SetPhase(ursObject* gself, double inphase);

void* Sample_Constructor();
void Sample_Destructor(ursObject* gself);
double Sample_Tick(ursObject* gself);
double Sample_Out(ursObject* gself);
void Sample_SetAmp(ursObject* gself, double inamp);
void Sample_SetRate(ursObject* gself, double inrate);
void Sample_SetPos(ursObject* gself, double inpos);
void Sample_SetSample(ursObject* gself, double insample);
void Sample_AddFile(ursObject* gself, const char* filename);
void Sample_SetLoop(ursObject*gself, double instate);

void* Sleigh_Constructor();
void Sleigh_Destructor(ursObject* gself);
double Sleigh_Tick(ursObject* gself);
double Sleigh_Out(ursObject* gself);
void Sleigh_SetAmp(ursObject* gself, double inamp);
void Sleigh_SetRate(ursObject* gself, double inrate);
void Sleigh_SetPos(ursObject* gself, double inpos);
void Sleigh_SetSleigh(ursObject* gself, double inSleigh);
void Sleigh_Play(ursObject* gself, double inplay);
void Sleigh_Loop(ursObject* gself, double indata);

void* Looper_Constructor();
void Looper_Destructor(ursObject* gself);
double Looper_Tick(ursObject* gself);
double Looper_Out(ursObject* gself);
void Looper_SetAmp(ursObject* gself, double inamp);
void Looper_SetRate(ursObject* gself, double inrate);
void Looper_In(ursObject* gself, double indata);
void Looper_Record(ursObject* gself, double indata);
void Looper_Play(ursObject* gself, double indata);
void Looper_Pos(ursObject* gself, double indata);

void* Nope_Constructor();
void Nope_Destructor(ursObject* gself);
double Nope_Tick(ursObject* gself);
double Nope_Out(ursObject* gself);
void Nope_In(ursObject* gself, double in);

void* Oct_Constructor();
void Oct_Destructor(ursObject* gself);
double Oct_Tick(ursObject* gself);
double Oct_Out(ursObject* gself);
void Oct_In(ursObject* gself, double in);

void* Quant_Constructor();
void Quant_Destructor(ursObject* gself);
double Quant_Tick(ursObject* gself);
double Quant_Out(ursObject* gself);
void Quant_In(ursObject* gself, double in);

void* Gain_Constructor();
void Gain_Destructor(ursObject* gself);
double Gain_Tick(ursObject* gself);
double Gain_Out(ursObject* gself);
void Gain_In(ursObject* gself, double in);
void Gain_Amp(ursObject* gself, double in);

void* LoopRhythm_Constructor();
void LoopRhythm_Destructor(ursObject* gself);
double LoopRhythm_Tick(ursObject* gself);
double LoopRhythm_Out(ursObject* gself);
void LoopRhythm_SetSampleRate(ursObject* gself, double indata);
void LoopRhythm_SetHMP(ursObject* gself, double indata);
void LoopRhythm_SetBeatNow(ursObject* gself, double indata);

void* CircleMap_Constructor();
void CircleMap_Destructor(ursObject* gself);
double CircleMap_Tick(ursObject* gself);
double CircleMap_Out(ursObject* gself);
void CircleMap_SetFreq(ursObject* gself, double infreq);
void CircleMap_SetAmp(ursObject* gself, double inamp);
void CircleMap_SetRate(ursObject* gself, double inrate);
void CircleMap_SetPhase(ursObject* gself, double inphase);
void CircleMap_SetNonL(ursObject* gself, double indata);

void* Avg_Constructor();
void Avg_Destructor(ursObject* gself);
double Avg_Tick(ursObject* gself);
double Avg_Out(ursObject* gself);
void Avg_In(ursObject* gself, double indata);
void Avg_Len(ursObject* gself, double indata);

void urs_SetupObjects();

void callAllAccelerateSources(double tilt_x, double tilt_y, double tilt_z);
void callAllCompassSources(double heading_x, double heading_y, double heading_z, double heading_north);
void callAllLocationSources(double latitude, double longitude);
void callAllTouchSources(double touch_x, double touch_y, int idx);
void callAllMicSources(SInt16* buff, UInt32 len);
void callAllMicSingleTickSources(SInt16 data);
void callAllPushSources(double indata);

void urs_PullVis();

int urs_NumUrManipulatorObjects();
const char* urs_GetManipulatorObjectName(int pos);
int urs_NumUrSourceObjects();
const char* urs_GetSourceObjectName(int pos);
int urs_NumUrSinkObjects();
const char* urs_GetSinkObjectName(int pos);

int urs_NumUrSourceIns(int pos);
int urs_NumUrSourceOuts(int pos);
int urs_NumUrManipulatorIns(int pos);
int urs_NumUrManipulatorOuts(int pos);
int urs_NumUrSinkIns(int pos);
int urs_NumUrSinkOuts(int pos);
const char* urs_GetManipulatorIn(int pos, int in);
const char* urs_GetSinkIn(int pos, int in);
const char* urs_GetSourceOut(int pos, int out);
const char* urs_GetManipulatorOut(int pos, int out);

//extern int lastsourceobj;
//extern ursObject* ursourceobjectlist[];
extern ursObjectArray ursourceobjectlist;
//extern int lastmanipulatorobj;
//extern ursObject* urmanipulatorobjectlist[];
extern ursObjectArray urmanipulatorobjectlist;
//extern int lastsinkobj;
//extern ursObject* ursinkobjectlist[];
extern ursObjectArray ursinkobjectlist;
extern ursObject* sinobject;
extern ursObject* nopeobject;
extern ursObject* sampleobject;

extern ursObject* accelobject;
extern ursObject* compassobject;
extern ursObject* locationobject;
extern ursObject* touchobject;
extern ursObject* micobject;
extern ursObject* pushobject;
extern ursObject* fileobject;

extern ursObject* dacobject;
extern ursObject* visobject;
extern ursObject* drainobject;
extern ursObject* pullobject;

extern ursSinkList urActiveDacTickSinkList;
extern ursSinkList urActiveDacArraySinkList;
extern ursSinkList urActiveVisTickSinkList;

#endif /* __URSOUND_H__ */
