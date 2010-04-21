/*
 *  urSound.c
 *  urMus
 *
 *  Created by gessl on 9/13/09.
 *  Copyright 2009 Georg Essl. All rights reserved. See LICENSE.txt for license conditions.
 *
 */

#include "urSound.h"
#include "RIOAudioUnitLayer.h"
#include "urSTK.h"
#include "urSoundAtoms.h"

#define LOAD_STK_OBJECTS

// Parameter conversions
// From SpeedDial
// -1:1->FreqSpace: 55.0*pow(2.0,96*nrparam/12.0);

#define URS_SINKLISTSTARTSIZE 10

ursSinkList::ursSinkList() 
{
	sinks = new urSoundOut*[URS_SINKLISTSTARTSIZE]; 
	length = 0; 
	allocsize = URS_SINKLISTSTARTSIZE;
}


ursSinkList::~ursSinkList()
{
	for(int i=0; i<length; i++)
		sinks[i] = NULL;
	delete sinks;
}

void ursSinkList::AddSink(urSoundOut* sink)
{
	if(length < allocsize)
	{
		sinks[length++] = sink;
	}
	else
	{
		/* NYI */
	}
}

void ursSinkList::RemoveSink(urSoundOut* sink)
{
	for(int i=0; i<length; i++)
	{
		if(sink == sinks[i])
		{
			for(; i<length; i++)
			{
				sinks[i] = sinks[i+1];
			} 
			length--; 
			sinks[length] = NULL;
		}
	}
}

ursSinkList urActiveDacTickSinkList;
ursSinkList urActiveDacArraySinkList;

ursSinkList urActiveVisTickSinkList;
ursSinkList urActiveDrainTickSinkList;
ursSinkList urActiveDrainArraySinkList;
ursSinkList urActiveNetTickSinkList;


ursSinkList urActiveAudioFrameSinkList;

void urs_PullActiveDacSinks(SInt16 *buff, UInt32 len)
{
	ursObject *self;
	double out = 0.0;
	
	for(int i=0; i < urActiveDacArraySinkList.length; i++)
	{
		self = urActiveDacArraySinkList.sinks[i]->object;
		urActiveDacArraySinkList.sinks[i]->outFuncFillBuffer(self,buff,len);
	}
	for(int i=0; i<urActiveDacTickSinkList.length; i++)
	{
		self = urActiveDacTickSinkList.sinks[i]->object;
		for(int j=0; j<len; j++)
		{
			out = urActiveDacTickSinkList.sinks[i]->outFuncTick(self);// /65536;
			if(i==0)
				buff[j] = (SInt16)32767*out;
			else
				buff[j] += (SInt16)32767*out;
		}
	}
//	if(urActiveDacTickSinkList.length==0 && urActiveDacArraySinkList.length==0)
//	{
//		memset(buff,0,sizeof(SInt16)*len);
//	}
}

void urs_PullActiveTickSinks(ursSinkList& urActiveTickSinkList, SInt16 *buff, UInt32 len)
{
	ursObject *self;
	double out;
	
	for(int i=0; i<urActiveTickSinkList.length; i++)
	{
		self = urActiveTickSinkList.sinks[i]->object;
		for(int j=0; j<len; j++)
		{
			out = urActiveTickSinkList.sinks[i]->outFuncTick(self);
			buff[j] = (SInt16)32767*out;
		}
	}
}

double urs_PullActiveSingleTickSinks(ursSinkList& urActiveTickSinkList)
{
	ursObject *self;
	double out=0.0;
	
	for(int i=0; i<urActiveTickSinkList.length; i++)
	{
		self = urActiveTickSinkList.sinks[i]->object;
		out = out + urActiveTickSinkList.sinks[i]->outFuncTick(self);
	}
	return out;
}

double dacindata = 0.0;

double urs_PullActiveDacSingleTickSinks()
{
	double res = dacindata + urs_PullActiveSingleTickSinks(urActiveDacTickSinkList);
	dacindata = 0.0;
	return res;
}

void urs_PullActiveArraySinks(ursSinkList& urActiveArraySinkList, SInt16 *buff, UInt32 len)
{
	ursObject *self;
	
	for(int i=0; i < urActiveArraySinkList.length; i++)
	{
		self = urActiveArraySinkList.sinks[i]->object;
		urActiveArraySinkList.sinks[i]->outFuncFillBuffer(self,buff,len);
	}
}

#define DRAINBUFFER_MAXSIZE 512
SInt16 drainbuffer[DRAINBUFFER_MAXSIZE];
UInt32 drainbufferlen = DRAINBUFFER_MAXSIZE;

void urs_PullActiveDrainSinks(UInt32 len)
{
	urs_PullActiveTickSinks(urActiveDrainTickSinkList, drainbuffer, len);
}

void urs_PullActiveDrainFrameSinks(UInt32 len)
{
	urs_PullActiveArraySinks(urActiveDrainArraySinkList, drainbuffer, len);
}

void urs_PullActiveAudioFrameSinks()
{
	urs_PullActiveSingleTickSinks(urActiveAudioFrameSinkList);
}

double visindata = 0.0;
double visoutdata = 0.0;

double urs_PullActiveVisSinks()
{
	double res = visindata + urs_PullActiveSingleTickSinks(urActiveVisTickSinkList);
//	visindata = 0.0;
	return res;
}

void urs_PullVis()
{
	visoutdata = urs_PullActiveVisSinks();
}

double netindata = 0.0;
double netoutdata = 0.0;

double urs_PullActiveNetSinks()
{
	double res = netindata + urs_PullActiveSingleTickSinks(urActiveNetTickSinkList);
	//	visindata = 0.0;
	return res;
}

void urs_PullNet()
{
	netoutdata = urs_PullActiveNetSinks();
}

double pullindata = 0.0;

double urs_PullActivePullSinks()
{
	double res = pullindata + urs_PullActiveSingleTickSinks(urActiveVisTickSinkList);
	pullindata = 0.0;
	return res;
}

#define URS_SOURCELISTSTARTSIZE 10


void callAllAccelerateSources(double tilt_x, double tilt_y, double tilt_z)
{
	double tilt;
	
	for(int i=0; i<3; i++) // for all 3 dimensions
	{
		switch(i)
		{
			case 0 : tilt = tilt_x; break;
			case 1 : tilt = tilt_y; break;
			case 2 : tilt = tilt_z; break;
		}
		
		accelobject->CallAllPushOuts(tilt, i);
	}
}

void callAllCompassSources(double heading_x, double heading_y, double heading_z, double heading_north)
{
	double heading;
	
	for(int i=0; i<4; i++) // for all 3 dimensions
	{
		switch(i)
		{
			case 0 : heading = heading_x; break;
			case 1 : heading = heading_y; break;
			case 2 : heading = heading_z; break;
			case 3 : heading = heading_north; break;
		}
		
		compassobject->CallAllPushOuts(heading, i);
	}
}

void callAllLocationSources(double latitude, double longitude)
{
	double coord;
	
	for(int i=0; i<2; i++) // for all 2 dimensions
	{
		switch(i)
		{
			case 0 : coord = latitude; break;
			case 1 : coord = longitude; break;
		}
		
		locationobject->CallAllPushOuts(coord, i);
	}
}

void callAllTouchSources(double touch_x, double touch_y, int idx)
{
	double touch;
	
	for(int i=0; i<2; i++) // for all 2 dimensions
	{
		switch(i)
		{
			case 0 : touch = touch_x; break;
			case 1 : touch = touch_y; break;
		}
		
		touchobject->CallAllPushOuts(touch, i+2*idx);
	}
}


void callAllMicSources(SInt16* buff, UInt32 len)
{

	for(int i=0; i<len; i++)
	{
		micobject->CallAllPushOuts(buff[i]/32768.0);
	}
}


void callAllMicSingleTickSources(SInt16 data)
{
	
	micobject->CallAllPushOuts(data/32768.0);
}


void callAllNetSingleTickSources(SInt16 data)
{
	netinobject->lastindata[0] = (float)data/128.0;//32768.0;
	netinobject->CallAllPushOuts(data/128.0);//32768.0);
}

double NetIn_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return res;
}

double NetIn_Out(ursObject* gself)
{
	return gself->lastindata[0]+gself->CallAllPullIns();
}



ursObject::ursObject(const char* objname, void* (*objconst)(), void (*objdest)(ursObject*),int nrins, int nrouts, bool dontinstance, bool coupled, ursObjectArray* instancearray)
{
	nr_ins = nrins;
	nr_outs = nrouts;
	ins = new urSoundIn[nrins];
	outs = new urSoundOut[nrouts];
	firstpullin = new urSoundPullIn*[nrins];
	firstpushout = new urSoundPushOut*[nrouts];
	for(int i=0; i< nrins ; i++)
		firstpullin[i] = NULL;
	for(int i=0; i< nrouts; i++)
		firstpushout[i] = NULL;
	lastin = 0;
	lastout = 0;
	lastindata[0] = 0.0;
	indatapos = 0;
	outdatapos = 0;
	filled = false;
	noninstantiable = dontinstance;
	if(!noninstantiable && instancearray == NULL)
	{
		instancelist = new ursObjectArray();
		instancenumber = 0;
		instancelist->Append(this);
	}
	else if(!noninstantiable)
	{
		instancelist = instancearray;
		instancenumber = instancelist->Last();
		instancelist->Append(this);
	}
	else
		instancenumber = 0;
	name = objname;
	
	couple_in = -1;
	couple_out = -1;
	iscoupled = coupled;
	
	DataConstructor = objconst;
	DataDestructor = objdest;
	if(DataConstructor != NULL)
		objectdata = DataConstructor();
	fed = false;
}

ursObject::~ursObject()
{
	delete ins;
	delete outs;
}

ursObject* ursObject::Clone()
{
	if(noninstantiable)
		return this;

	ursObject* clone = new ursObject(name, DataConstructor, DataDestructor, nr_ins, nr_outs, this->noninstantiable, this->iscoupled, this->instancelist);
	
	for(int i=0; i<lastin; i++)
		clone->AddIn(ins[i].name,ins[i].semantics,ins[i].inFuncTick);
	
	for(int i=0; i<lastout; i++)
		clone->AddOut(outs[i].name,outs[i].semantics,outs[i].outFuncTick,outs[i].outFuncValue,outs[i].outFuncFillBuffer);

	return clone;
}


void ursObject::AddOut(const char* outname, const char* outsemantics, double (*func)(ursObject *), double (*func3)(ursObject *), void (*func2)(ursObject*, SInt16*, UInt32))
{
	if(lastout >= nr_outs)
	{
		int a = 0;
		/* NYI gotta grow here */
	}
	char* str = (char*)malloc(strlen(outname)+1);
	strcpy(str, outname);
	outs[lastout].name = str;
	str = (char *)malloc(strlen(outsemantics)+1);
	strcpy(str, outsemantics);
	outs[lastout].semantics = str;
	outs[lastout].outFuncTick = func;
	outs[lastout].outFuncFillBuffer = func2;
	outs[lastout].outFuncValue = func3;
	outs[lastout].object = this;
	outs[lastout].data = this->objectdata;
	lastout++;
}

void ursObject::AddIn(const char* inname, const char* insemantics, void (*func)(ursObject *, double))
{
	if(lastin >= nr_ins)
	{
		int a = 0;
		/* NYI gotta grow here */
	}
	ins[lastin].name = inname;
	ins[lastin].semantics = insemantics;
	ins[lastin].inFuncTick = func;
	ins[lastin].object = this;
	ins[lastin].data = this->objectdata;
	lastin++;
}

void ursObject::CallAllPushOuts(double indata, int idx)
{
	if(this->firstpushout[idx]!=NULL)
	{
		ursObject* inobject;
		urSoundPushOut* pushto = this->firstpushout[idx];
		for(;pushto!=NULL; pushto = pushto->next)
		{	
			urSoundIn* in = pushto->in;
			inobject = in->object;
			in->inFuncTick(inobject, indata);
		}
	}
}

double ursObject::FeedAllPullIns(int minidx)
{
	if(fed != true)
	{
		fed = true;
		
		for(int i=minidx; i< nr_ins; i++)
		{
			if(firstpullin[i]!=NULL)
			{
				ins[i].inFuncTick(this, CallAllPullIns(i));
			}
		}
		fed = false;
	}
}

double ursObject::CallAllPullIns(int idx)
{
	double res = 0.0;
	if(this->firstpullin[idx]!=NULL)
	{
		ursObject* outobject;
		urSoundPullIn* pullfrom = this->firstpullin[idx];
		for(; pullfrom != NULL; pullfrom = pullfrom->next)
		{	
			urSoundOut* out = pullfrom->out;
			outobject = out->object;
			res = res + out->outFuncTick(outobject);
		}
	}
	return res;
}

void ursObject::AddPushOut(int idx, urSoundIn* in)
{
	urSoundPushOut* self = new urSoundPushOut;
	self->in = in;
	in->isplaced = true;
	self->next = NULL;
	if(firstpushout[idx] == NULL)
	{
		firstpushout[idx] = self;
	}
	else
	{
		urSoundPushOut* finder = firstpushout[idx];
		for(;finder->next != NULL; finder = finder->next)
		{
		}
		finder->next = self;
	}
}

void ursObject::AddPullIn(int idx, urSoundOut* out)
{
	urSoundPullIn* self = new urSoundPullIn;
	self->out = out;
	out->isplaced = true;
	self->next = NULL;
	if(firstpullin[idx] == NULL)
	{
		firstpullin[idx] = self;
	}
	else
	{
		urSoundPullIn* finder = firstpullin[idx];
		for(;finder->next != NULL; finder = finder->next)
		{
		}
		finder->next = self;
	}
}

bool ursObject::IsPushedOut(int idx, urSoundIn* in)
{
	if(firstpushout[idx] == NULL )
		return false;
	
	urSoundPushOut* finder = firstpushout[idx];
	for(;finder != NULL && finder->in != in ; finder = finder->next)
	{
	}
	if(finder != NULL && finder->in == in)
	{
		return true;
	}
	return false;
}

bool ursObject::IsPulledIn(int idx, urSoundOut* out)
{
	if(firstpullin[idx] == NULL)
		return false;
	
	urSoundPullIn* finder = firstpullin[idx];
	for(;finder->out != out && finder != NULL; finder = finder->next)
	{
	}
	if(finder != NULL && finder->out == out)
	{
		return true;
	}
	return false;
}

void ursObject::RemovePushOut(int idx, urSoundIn* in)
{
	in->isplaced = false;
	if(firstpushout[idx] == NULL)
		return;
	
	urSoundPushOut* finder = firstpushout[idx];
	urSoundPushOut* previous = NULL;
	for(;finder != NULL && finder->in != in ; finder = finder->next)
	{
		previous = finder;
	}
	if(finder != NULL && finder->in == in)
	{
		if(previous != NULL)
			previous->next = finder->next;
		
		if (firstpushout[idx] == finder)
			firstpushout[idx] = NULL;
		delete finder;
	}
}

void ursObject::RemovePullIn(int idx, urSoundOut* out)
{
	out->isplaced = false;
	if(firstpullin[idx] == NULL)
		return;
	
	urSoundPullIn* finder = firstpullin[idx];
	urSoundPullIn* previous = NULL;
	for(;finder != NULL && finder->out != out; finder = finder->next)
	{
		previous = finder;
	}
	if(finder != NULL && finder->out == out)
	{
		if(previous != NULL)
			previous->next = finder->next;
		if (firstpullin[idx] == finder)
			firstpullin[idx] = NULL;
		delete finder;
	}
}

void ursObject::SetCouple(int inidx, int outidx)
{
	couple_in = inidx;
	couple_out = outidx;
	iscoupled = true;
}

// An object array to help us keep objects by type and by instance.

ursObjectArray::ursObjectArray(int initmax)
{
	objectlist = new ursObject*[initmax];
	max = initmax;
	current = 0;
	for(int i=0; i< initmax; i++)
		objectlist[i] = NULL;
}

ursObjectArray::~ursObjectArray()
{
	for(int i=0; i<current; i++)
	{
		if(objectlist[i] != NULL)
			delete objectlist[i];
	}
	delete objectlist;
}

void ursObjectArray::Append(ursObject* object)
{
	if(current >= max)
	{
		max = max*2; // Yes we don't grow exponentially because we want to be kind to memory... and we definitely don't grow enough to make a huge dent in the asymptotic difference here.
		ursObject** newlist = new ursObject*[max];
		for(int i=0; i<current; i++)
		{
			newlist[i] = objectlist[i];
			objectlist[i] = NULL;
		}
		delete objectlist;
		objectlist = newlist;
	}
	
	objectlist[current] = object;
	current++;
}

ursObject* ursObjectArray::Get(int idx)
{
	if(idx >=0 && idx < current)
		return objectlist[idx];
	else
		return NULL;
}

ursObject* ursObjectArray::operator[](int idx)
{
	if(idx >=0 && idx < current)
		return objectlist[idx];
	else
		return NULL;
}

//#define MAX_URMANIPULATOROBJECTS 40
//int lastmanipulatorobj = 0;
//ursObject* urmanipulatorobjectlist[MAX_URMANIPULATOROBJECTS];
ursObjectArray urmanipulatorobjectlist;

int urs_NumUrManipulatorObjects()
{
	return urmanipulatorobjectlist.Last(); //lastmanipulatorobj;
}

const char* urs_GetManipulatorObjectName(int pos)
{
	if(pos >= urmanipulatorobjectlist.Last()) return NULL;
	
	return urmanipulatorobjectlist[pos]->name;
}

int urs_NumUrManipulatorIns(int pos)
{
	return urmanipulatorobjectlist[pos]->nr_ins;
}

int urs_NumUrManipulatorOuts(int pos)
{
	return urmanipulatorobjectlist[pos]->nr_outs;
}

//#define MAX_URSOURCEOBJECTS 10
//int lastsourceobj = 0;
//ursObject* ursourceobjectlist[MAX_URSOURCEOBJECTS];
ursObjectArray ursourceobjectlist;

int urs_NumUrSourceObjects()
{
	return ursourceobjectlist.Last();
}

const char* urs_GetSourceObjectName(int pos)
{
	if(pos >= ursourceobjectlist.Last()) return NULL;
	
	return ursourceobjectlist[pos]->name;
}

int urs_NumUrSourceIns(int pos)
{
	return ursourceobjectlist[pos]->nr_ins;
}

int urs_NumUrSourceOuts(int pos)
{
	return ursourceobjectlist[pos]->nr_outs;
}


//#define MAX_URSINKOBJECTS 10
//int lastsinkobj = 0;
//ursObject* ursinkobjectlist[MAX_URSINKOBJECTS];
ursObjectArray ursinkobjectlist;

int urs_NumUrSinkObjects()
{
	return ursinkobjectlist.Last();
}

const char* urs_GetSinkObjectName(int pos)
{
	if(pos >= ursinkobjectlist.Last()) return NULL;
	
	return ursinkobjectlist[pos]->name;
}

int urs_NumUrSinkIns(int pos)
{
	return ursinkobjectlist[pos]->nr_ins;
}

int urs_NumUrSinkOuts(int pos)
{
	return ursinkobjectlist[pos]->nr_outs;
}

const char* urs_GetManipulatorIn(int pos, int in)
{
	return urmanipulatorobjectlist[pos]->ins[in].name;
}

const char* urs_GetSinkIn(int pos, int in)
{
	return ursinkobjectlist[pos]->ins[in].name;
}

const char* urs_GetSourceOut(int pos, int out)
{
	return ursourceobjectlist[pos]->outs[out].name;
}

const char* urs_GetManipulatorOut(int pos, int out)
{
	return urmanipulatorobjectlist[pos]->outs[out].name;
}

Loop::Loop(long len, long maxlen)
{
	loop = new double[maxlen];
	now = 0;
	looplength = len;
	startpos = -1;
	maxlength = maxlen;
}

Loop::~Loop()
{
	delete loop;
}

double Loop::Tick()
{
	now = now + 1 % looplength;
	return loop[now];
}

void Loop::SetNow(double indata)
{
	loop[now] = indata;
}

void Loop::SetAt(double indata, int pos)
{
	pos = pos % looplength;
	loop[pos] = indata;
}

void Loop::SetBoundary()
{
	if(startpos == -1)
	{
		startpos = now;
	}
	else
	{
		looplength = now-startpos;
		if(looplength > maxlength) looplength = maxlength;
		startpos = now;
	}
}


ursObject* sinobject;
ursObject* nopeobject;
ursObject* sampleobject;
ursObject* looprhythmobject;

ursObject* accelobject;
ursObject* compassobject;
ursObject* locationobject;
ursObject* touchobject;
ursObject* micobject;
ursObject* netinobject;
ursObject* pushobject;
ursObject* fileobject;

ursObject* dacobject;
ursObject* visobject;
ursObject* netobject;
ursObject* drainobject;
ursObject* pullobject;

ursObject* object;

void urs_SetupObjects()
{
	
	accelobject = new ursObject("Accel", NULL, NULL, 0, 3, true);
	accelobject->AddOut("X", "TimeSeries", NULL, NULL, NULL); // Pushers cannot be ticked (oh the poetic justice)
	accelobject->AddOut("Y", "TimeSeries", NULL, NULL, NULL); 
	accelobject->AddOut("Z", "TimeSeries", NULL, NULL, NULL); 
	ursourceobjectlist.Append(accelobject);
	compassobject = new ursObject("Compass", NULL, NULL, 0, 4, true);
	compassobject->AddOut("X", "TimeSeries", NULL, NULL, NULL); // Pushers cannot be ticked (oh the poetic justice)
	compassobject->AddOut("Y", "TimeSeries", NULL, NULL, NULL); 
	compassobject->AddOut("Z", "TimeSeries", NULL, NULL, NULL); 
	compassobject->AddOut("North", "TimeSeries", NULL, NULL, NULL); 
	ursourceobjectlist.Append(compassobject);
	locationobject = new ursObject("Location", NULL, NULL, 0, 2, true);
	locationobject->AddOut("Lat", "TimeSeries", NULL, NULL, NULL); // Pushers cannot be ticked (oh the poetic justice)
	locationobject->AddOut("Long", "TimeSeries", NULL, NULL, NULL); 
	ursourceobjectlist.Append(locationobject);
	touchobject = new ursObject("Touch", NULL, NULL, 0, 20, true);
	touchobject->AddOut("X1", "TimeSeries", NULL, NULL, NULL); // Pushers cannot be ticked (oh the poetic justice)
	touchobject->AddOut("Y1", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("X2", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("Y2", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("X3", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("Y3", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("X4", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("Y4", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("X5", "TimeSeries", NULL, NULL, NULL);
	touchobject->AddOut("Y5", "TimeSeries", NULL, NULL, NULL);
	touchobject->AddOut("X6", "TimeSeries", NULL, NULL, NULL); // Pushers cannot be ticked (oh the poetic justice)
	touchobject->AddOut("Y6", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("X7", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("Y7", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("X8", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("Y8", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("X9", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("Y9", "TimeSeries", NULL, NULL, NULL); 
	touchobject->AddOut("X10", "TimeSeries", NULL, NULL, NULL);
	touchobject->AddOut("Y10", "TimeSeries", NULL, NULL, NULL); 
	ursourceobjectlist.Append(touchobject);
	micobject = new ursObject("Mic", NULL, NULL, 0, 1, true);
	micobject->AddOut("Out", "TimeSeries", NULL, NULL, NULL);
	ursourceobjectlist.Append(micobject);
	netinobject = new ursObject("NetIn", NULL, NULL, 0, 1, true);
	netinobject->AddOut("Out", "Event", NetIn_Tick, NetIn_Out, NULL);
	ursourceobjectlist.Append(netinobject);
	pushobject = new ursObject("Push", NULL, NULL, 0, 1); // An event based source ("bang" in PD parlance)
	pushobject->AddOut("Out", "Event", NULL, NULL, NULL);
	ursourceobjectlist.Append(pushobject);
//	fileobject = new ursObject("File", NULL, NULL, 0, 1); // An file based source
//	fileobject->AddOut("Out", "Event", NULL, NULL, NULL);
//	ursourceobjectlist.Append(fileobject);
	
	sinobject = new ursObject("SinOsc", SinOsc_Constructor, SinOsc_Destructor,4,1);
	sinobject->AddOut("WaveForm", "TimeSeries", SinOsc_Tick, SinOsc_Out, NULL);
//	sinobject->AddOut("WaveForm", "TimeSeries", NULL, SinOsc_FillBuffer);
	sinobject->AddIn("Freq", "Frequency", SinOsc_SetFreq);
	sinobject->AddIn("Amp", "Amplitude", SinOsc_SetAmp);
	sinobject->AddIn("SRate", "Rate", SinOsc_SetRate);
	sinobject->AddIn("Time", "Time", SinOsc_SetPhase);
	urmanipulatorobjectlist.Append(sinobject);
//	urmanipulatorobjectlist[lastmanipulatorobj++] = sinobject;
	
	object = new ursObject("OWF", OWF_Constructor, OWF_Destructor,4,1);
	object->AddOut("WaveForm", "TimeSeries", OWF_Tick, OWF_Out, NULL);
	object->AddIn("Freq", "Frequency", OWF_SetFreq);
	object->AddIn("Amp", "Amplitude", OWF_SetAmp);
	object->AddIn("SRate", "Rate", OWF_SetRate);
	object->AddIn("Time", "Time", OWF_SetPhase);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("Avg", Avg_Constructor, Avg_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", Avg_Tick, Avg_Out, NULL);
	object->AddIn("In", "TimeSeries", Avg_In);
	object->AddIn("Len", "Length", Avg_Len);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	urSoundAtoms_Setup();
	
	object = new ursObject("Oct", Oct_Constructor, Oct_Destructor,1,1);
	object->AddOut("Out", "Generic", Oct_Out, Oct_Tick, NULL);
	object->AddIn("In", "Generic", Oct_In);
//	object->AddIn("Base", "Frequency", Oct_Oct);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("Quant", Quant_Constructor, Quant_Destructor,1,1);
	object->AddOut("Out", "Generic", Quant_Out, Quant_Tick, NULL);
	object->AddIn("In", "Generic", Quant_In);
	//	object->AddIn("Base", "Frequency", Quant_Oct);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("Gain", Gain_Constructor, Gain_Destructor,2,1);
	object->AddOut("Out", "Generic", Gain_Out, Gain_Tick, NULL);
	object->AddIn("In", "Generic", Gain_In);
	object->AddIn("Amp", "Amplitude", Gain_Amp);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	sampleobject = new ursObject("Sample", Sample_Constructor, Sample_Destructor,5,1);
	sampleobject->AddOut("WaveForm", "TimeSeries", Sample_Tick, Sample_Out, NULL);
	sampleobject->AddIn("Amp", "Amplitude", Sample_SetAmp);
	sampleobject->AddIn("Rate", "Rate", Sample_SetRate);
	sampleobject->AddIn("Pos", "Position", Sample_SetPos);
	sampleobject->AddIn("Sample", "Sample", Sample_SetSample);
	sampleobject->AddIn("Loop", "State", Sample_SetLoop);
//	urmanipulatorobjectlist[lastmanipulatorobj++] = sampleobject;
	urmanipulatorobjectlist.Append(sampleobject);

	object = new ursObject("Sleigh", Sleigh_Constructor, Sleigh_Destructor,6,1);
	object->AddOut("WaveForm", "TimeSeries", Sleigh_Tick, Sleigh_Out, NULL);
	object->AddIn("Amp", "Amplitude", Sleigh_SetAmp);
	object->AddIn("Rate", "Rate", Sleigh_SetRate);
	object->AddIn("Pos", "Position", Sleigh_SetPos);
	object->AddIn("Sleigh", "Sleigh", Sleigh_SetSleigh);
	object->AddIn("Play", "Play", Sleigh_Play);
	object->AddIn("Loop", "Loop", Sleigh_Loop);
	//	urmanipulatorobjectlist[lastmanipulatorobj++] = Sleighobject;
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("Looper", Looper_Constructor, Looper_Destructor,6,1);
	object->AddOut("WaveForm", "TimeSeries", Looper_Tick, Looper_Out, NULL);
	object->AddIn("In", "TimeSeries", Looper_In);
	object->AddIn("Amp", "Amplitude", Looper_SetAmp);
	object->AddIn("Rate", "Rate", Looper_SetRate);
	object->AddIn("Record", "Trigger", Looper_Record);
	object->AddIn("Play", "Trigger", Looper_Play);
	object->AddIn("Pos", "Time", Looper_Pos);
	urmanipulatorobjectlist.Append(object);
	
	looprhythmobject = new ursObject("LoopRhythm", LoopRhythm_Constructor, LoopRhythm_Destructor,3,1);
	looprhythmobject->AddOut("Beats", "TimeSeries", LoopRhythm_Tick, LoopRhythm_Out, NULL);
	looprhythmobject->AddIn("BMP", "Rate", LoopRhythm_SetHMP);
	looprhythmobject->AddIn("Now", "Event", LoopRhythm_SetBeatNow);
	looprhythmobject->AddIn("Pos", "Position", LoopRhythm_Pos);
//	urmanipulatorobjectlist[lastmanipulatorobj++] = looprhythmobject;
	urmanipulatorobjectlist.Append(looprhythmobject);
	
	object = new ursObject("CMap", CircleMap_Constructor, CircleMap_Destructor,5,1);
	object->AddOut("WaveForm", "TimeSeries", CircleMap_Tick, CircleMap_Out, NULL);
	object->AddIn("Freq", "Frequency", CircleMap_SetFreq);
	object->AddIn("NonL", "Generic", CircleMap_SetNonL);
	object->AddIn("Amp", "Amplitude", CircleMap_SetAmp);
	object->AddIn("SRate", "Rate", CircleMap_SetRate);
	object->AddIn("Time", "Time", CircleMap_SetPhase);
	urmanipulatorobjectlist.Append(object);

	dacobject = new ursObject("Dac", NULL, NULL, 1, 0, true);
	dacobject->AddIn("In", "TimeSeries", Dac_In);
	ursinkobjectlist.Append(dacobject);

	visobject = new ursObject("Vis", NULL, NULL, 1, 0, true);
	visobject->AddIn("In", "TimeSeries", Vis_In);
	ursinkobjectlist.Append(visobject);

	netobject = new ursObject("Net", NULL, NULL, 1, 0, true);
	netobject->AddIn("In", "Event", Net_In);
	ursinkobjectlist.Append(netobject);
	
	//	drainobject = new ursObject("Drain", NULL, NULL, 1, 0);
//	drainobject->AddIn("In", "TimeSeries", Drain_In); // A rate based drain
//	ursinkobjectlist.Append(drainobject);
	
	pullobject = new ursObject("Pull", NULL, NULL, 1, 0);
	pullobject->AddIn("In", "Event", Pull_In); // A event based drain ("bang" drain in PD parlance)
	ursinkobjectlist.Append(pullobject);

#ifdef LOAD_STK_OBJECTS
	urSTK_Setup();
#endif
	
}

// DPS Objects (aka Unit Generators) below


void Dac_In(ursObject* gself, double in)
{
	dacindata = in;
}

void Vis_In(ursObject* gself, double in)
{
	visindata = in;
}

void Net_Send(float data);

void Net_In(ursObject* gself, double in)
{
	netindata = in;
	Net_Send(netindata);
}

void Drain_In(ursObject* gself, double in)
{
}

void Pull_In(ursObject* gself, double in)
{
	pullindata = in;
}

void* Oct_Constructor()
{
	return NULL;
}

void Oct_Destructor(ursObject* gself)
{
}

double Oct_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return ((1.0+res)/2.0*0.125*2);
}

double Oct_Out(ursObject* gself)
{
	return ((1.0+gself->CallAllPullIns())/2.0*0.125*2);
	//	return gself->lastindata[0];
}


void Oct_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(((1.0+in)/2.0*0.125+2*0.125));
}


void* Quant_Constructor()
{
	return NULL;
}

void Quant_Destructor(ursObject* gself)
{
}

double Quant_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	float quantstep = 0.125/12.0;
	return (floor((res/quantstep)+0.5)*quantstep);
}

double Quant_Out(ursObject* gself)
{
	float quantstep = 0.125/12.0;
	return (floor((gself->CallAllPullIns()/quantstep)+0.5)*quantstep);
	//	return gself->lastindata[0];
}

                
void Quant_In(ursObject* gself, double in)
{
	float quantstep = 0.125/12.0;
	gself->CallAllPushOuts(floor((in/quantstep)+0.5)*quantstep);
}

void* Gain_Constructor()
{
	Gain_Data* self = new Gain_Data;
	self->amp = 0.95;
	return (void*)self;
}

void Gain_Destructor(ursObject* gself)
{
	Gain_Data* self = (Gain_Data*)gself->objectdata;
	delete (Gain_Data*)self;
}

double Gain_Tick(ursObject* gself)
{
	Gain_Data* self = (Gain_Data*)gself->objectdata;
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	res = res * self->amp;
	return (res);
}

double Gain_Out(ursObject* gself)
{
	Gain_Data* self = (Gain_Data*)gself->objectdata;
	return self->amp*gself->CallAllPullIns();
}

void Gain_In(ursObject* gself, double in)
{
	Gain_Data* self = (Gain_Data*)gself->objectdata;
	gself->lastindata[0] = in;
	gself->CallAllPushOuts(in*self->amp);
}

void Gain_Amp(ursObject* gself, double in)
{
	Gain_Data* self = (Gain_Data*)gself->objectdata;
	self->amp = in;
}

void* SinOsc_Constructor()
{
	SinOsc_Data* self = new SinOsc_Data;
	self->freq = 440;
	self->srate = URSOUND_DEFAULTSRATE;
	self->time = 0;
	self->phase = 0;
	self->amp = 1.0;//2147483647;//32767;
	return (void*)self;
}

void SinOsc_Destructor(ursObject* gself)
{
	SinOsc_Data* self = (SinOsc_Data*)gself->objectdata;
	delete (SinOsc_Data*)self;
}

double SinOsc_Tick(ursObject* gself)
{
	SinOsc_Data* self = (SinOsc_Data*)gself->objectdata;
	gself->FeedAllPullIns(); // This is decoupled so no forwarding, just pulling to propagate our natural rate
	self->phase = self->phase + 2.0*PI*self->freq/self->srate;
	double out = self->amp*sin(self->phase /*+ PI*self->phase*/);
//	self->time = self->time + 1;
	self->lastout = out;
	return out;
}

double SinOsc_Out(ursObject* gself)
{
	SinOsc_Data* self = (SinOsc_Data*)gself->objectdata;
	return self->lastout;
}

void SinOsc_FillBuffer(ursObject* gself, SInt16* buffer, UInt32 len)
{
	SinOsc_Data* self = (SinOsc_Data*)gself->objectdata;
	for(int i=0; i<len; i++)
	{
		self->phase = self->phase + 2.0*PI*self->freq/self->srate;
		buffer[i] =  32767*self->amp*sin(self->phase /*+ PI*self->phase*/);
//		self->time = self->time + 1;
	}
	self->lastout = buffer[len-1];
}

void SinOsc_SetFreq(ursObject* gself, double infreq)
{
	SinOsc_Data* self = (SinOsc_Data*)gself->objectdata;

	self->freq = norm2Freq(infreq);
}

void SinOsc_SetAmp(ursObject* gself, double inamp)
{
	SinOsc_Data* self = (SinOsc_Data*)gself->objectdata;
	self->amp = capNorm(inamp); //*(2147483647/256);
}


void SinOsc_SetRate(ursObject* gself, double inrate)
{
	SinOsc_Data* self = (SinOsc_Data*)gself->objectdata;
	self->srate = (inrate+1.0)*96000;//(inrate+256)/256.0*96000;
}

void SinOsc_SetPhase(ursObject* gself, double inphase)
{
	SinOsc_Data* self = (SinOsc_Data*)gself->objectdata;
	self->phase = inphase;
}

// OWF

void* OWF_Constructor()
{
	OWF_Data* self = new OWF_Data;
	self->freq = 440;
	self->srate = URSOUND_DEFAULTSRATE;
	self->time = 0;
	self->phase = 0;
	self->amp = 1.0;//2147483647;//32767;
	return (void*)self;
}

void OWF_Destructor(ursObject* gself)
{
	OWF_Data* self = (OWF_Data*)gself->objectdata;
	delete (OWF_Data*)self;
}

float saw(float t)
{
	return fmod(t,2.0*PI)*2/2*PI-1;
}

float rect(float t)
{
	float res = 0;
	
	if (fmod(t,2*PI)<PI)
		return -1;
	else
		return 1;
}

double OWF_Tick(ursObject* gself)
{
	OWF_Data* self = (OWF_Data*)gself->objectdata;
	gself->FeedAllPullIns(); // This is decoupled so no forwarding, just pulling to propagate our natural rate
	self->phase = self->phase + 2.0*PI*self->freq/self->srate;
	double out = 0.25*self->amp*(rect(2*self->phase)*(rect(self->phase)+saw(self->phase)+saw(self->phase/2))*saw(self->phase/2))/6.0;
	//	self->time = self->time + 1;
	self->lastout = out;
	return out;
}

double OWF_Out(ursObject* gself)
{
	OWF_Data* self = (OWF_Data*)gself->objectdata;
	return self->lastout;
}

void OWF_FillBuffer(ursObject* gself, SInt16* buffer, UInt32 len)
{
	OWF_Data* self = (OWF_Data*)gself->objectdata;
	for(int i=0; i<len; i++)
	{
		self->phase = self->phase + 2.0*PI*self->freq/self->srate;
		buffer[i] =  32767*self->amp*sin(self->phase /*+ PI*self->phase*/);
		//		self->time = self->time + 1;
	}
	self->lastout = buffer[len-1];
}

void OWF_SetFreq(ursObject* gself, double infreq)
{
	OWF_Data* self = (OWF_Data*)gself->objectdata;
	
	self->freq = norm2Freq(infreq);
}

void OWF_SetAmp(ursObject* gself, double inamp)
{
	OWF_Data* self = (OWF_Data*)gself->objectdata;
	self->amp = capNorm(inamp); //*(2147483647/256);
}


void OWF_SetRate(ursObject* gself, double inrate)
{
	OWF_Data* self = (OWF_Data*)gself->objectdata;
	self->srate = (inrate+1.0)*96000;//(inrate+256)/256.0*96000;
}

void OWF_SetPhase(ursObject* gself, double inphase)
{
	OWF_Data* self = (OWF_Data*)gself->objectdata;
	self->phase = inphase;
}



// Sample

void* Sample_Constructor()
{
//	UInt32 frate;
	Sample_Data* self = new Sample_Data;
	self->numsamples = 0;
	self->activesample = 0;
	self->amp = 1.0; //64*65535;//2147483647;//32767;
	return (void*)self;
}

void Sample_AddFile(ursObject* gself, const char* filename)
{
	Sample_Data* self = (Sample_Data*)gself->objectdata;
	UInt32 frate;

	self->numsamples = self->numsamples+1;
	if(self->numsamples == 1)
		self->samplebuffer = (SInt16**)malloc(sizeof(SInt16*));
	else
		self->samplebuffer = (SInt16**)realloc(self->samplebuffer, sizeof(SInt16*)*self->numsamples);
	self->samplebuffer[self->numsamples-1] = (SInt16*)LoadAudioFileData(filename, &self->len[self->numsamples-1], &frate);
	self->len[self->numsamples-1] = self->len[self->numsamples-1]-1;
	self->rate = 48000.0/frate;
}

void Sample_Destructor(ursObject* gself)
{
	Sample_Data* self = (Sample_Data*)gself->objectdata;
	delete (Sample_Data*)self;
}

double Sample_Tick(ursObject* gself)
{	
	Sample_Data* self = (Sample_Data*)gself->objectdata;
	gself->FeedAllPullIns(); // This is decoupled so no forwarding, just pulling to propagate our natural rate
	double out = 0;
	if(self->playing && self->numsamples > 0)
	{
		int t = self->activesample;
		out = self->amp*self->samplebuffer[self->activesample][self->position]/32767.0;
		self->realposition = self->realposition + self->rate;
		self->position = (SInt32)self->realposition;
		if(self->loop)
		{
			self->position = self->position % self->len[self->activesample];
			while(self->position < 0)
				self->position += self->len[self->activesample];
		}
		else
		{
			if(self->position >= self->len[self->activesample] || self->position < 0)
				self->playing = false;
		}
	}
	self->lastout = out;
	return out;
}

double Sample_Out(ursObject* gself)
{
	Sample_Data* self = (Sample_Data*)gself->objectdata;
	return self->lastout;
}

void Sample_SetAmp(ursObject* gself, double inamp)
{
	Sample_Data* self = (Sample_Data*)gself->objectdata;
	self->amp = inamp;// *(128*65535/256);
}


void Sample_SetRate(ursObject* gself, double inrate)
{
	Sample_Data* self = (Sample_Data*)gself->objectdata;
	self->rate = 4.0*inrate;// /128.0;
}

void Sample_SetPos(ursObject* gself, double inpos)
{
	Sample_Data* self = (Sample_Data*)gself->objectdata;
	if(inpos < 0)
		inpos = 1.0 + inpos;
	
	self->position = self->len[self->activesample]*inpos;
	self->realposition  = self->len[self->activesample]*inpos;
	if(self->position >= self->len[self->activesample] || self->position < 0)
		self->playing = false;
	else
		self->playing = true;
}

void Sample_SetSample(ursObject* gself, double insample)
{
	Sample_Data* self = (Sample_Data*)gself->objectdata;

	self->activesample = (int)(insample*7.0-0.00001);
	if(self->activesample < 0) self->activesample = 0;

	self->position = self->position % self->len[self->activesample];
	while(self->position < 0)
		self->position += self->len[self->activesample];
}

void Sample_SetLoop(ursObject*gself, double instate)
{
	Sample_Data* self = (Sample_Data*)gself->objectdata;
	if(instate > 0.0)
		self->loop = true;
	else
		self->loop = false;
}

// Sleigh

void* Sleigh_Constructor()
{
	UInt32 frate;
	Sleigh_Data* self = new Sleigh_Data;
	self->Sleighbuffer[0] = (SInt16* )LoadAudioFileData("sleighbells.wav", &self->len[0], &frate);
	self->activeSleigh = 0;
	self->len[0] = self->len[0]-1;
	self->rate = 48000.0/frate;
	self->amp = 1.0; //64*65535;//2147483647;//32767;
	return (void*)self;
}

void Sleigh_Destructor(ursObject* gself)
{
	Sleigh_Data* self = (Sleigh_Data*)gself->objectdata;
	delete (Sleigh_Data*)self;
}

double Sleigh_Tick(ursObject* gself)
{	
	Sleigh_Data* self = (Sleigh_Data*)gself->objectdata;
	gself->FeedAllPullIns(); // This is decoupled so no forwarding, just pulling to propagate our natural rate
	double out = 0;
	if(self->playing==true)
	{
		out = self->amp*self->Sleighbuffer[self->activeSleigh][self->position]/32767.0;
		self->realposition = self->realposition + self->rate;
		self->position = (SInt32)self->realposition;
		if(self->loop)
		{
			self->position = self->position % self->len[self->activeSleigh];
			while(self->position < 0)
				self->position += self->len[self->activeSleigh];
		}
		else
		{
			if(self->position >= self->len[self->activeSleigh] || self->position < 0)
				self->playing = false;
		}
	}
	self->lastout = out;
	return out;
}

double Sleigh_Out(ursObject* gself)
{
	Sleigh_Data* self = (Sleigh_Data*)gself->objectdata;
	return self->lastout;
}

void Sleigh_SetAmp(ursObject* gself, double inamp)
{
	Sleigh_Data* self = (Sleigh_Data*)gself->objectdata;
	self->amp = inamp;// *(128*65535/256);
}


void Sleigh_SetRate(ursObject* gself, double inrate)
{
	Sleigh_Data* self = (Sleigh_Data*)gself->objectdata;
	self->rate = 4.0*inrate;// /128.0;
}

void Sleigh_SetPos(ursObject* gself, double inpos)
{
	Sleigh_Data* self = (Sleigh_Data*)gself->objectdata;
	if(inpos < 0)
		inpos = 1.0 + inpos;
	
	self->position = self->len[self->activeSleigh]*inpos;
	self->realposition  = self->len[self->activeSleigh]*inpos;
}

void Sleigh_Play(ursObject* gself, double inplay)
{
	Sleigh_Data* self = (Sleigh_Data*)gself->objectdata;

	if(self->playing && inplay > 0.5)
	{
		self->position = 0;
		self->realposition = 0.0;
	}
	else if(!self->playing && inplay > 0.5)
	{
		self->position = 0;
		self->realposition = 0.0;
		self->playing = true;
	}		
}

void Sleigh_Loop(ursObject* gself, double inloop)
{
	Sleigh_Data* self = (Sleigh_Data*)gself->objectdata;

	if(inloop >= 0.5)
		self->loop = true;
	else
		self->loop = false;
	
}

void Sleigh_SetSleigh(ursObject* gself, double inSleigh)
{
	Sleigh_Data* self = (Sleigh_Data*)gself->objectdata;
	
	self->activeSleigh = (int)(inSleigh*7.0-0.00001);
	if(self->activeSleigh < 0) self->activeSleigh = 0;
	
	self->position = self->position % self->len[self->activeSleigh];
	while(self->position < 0)
		self->position += self->len[self->activeSleigh];
}

// Looper

// Space for 10 second loop is default
#define MAX_LOOPER_DEFAULT 48000*10


void* Looper_Constructor()
{
//	UInt32 frate;
	Looper_Data* self = new Looper_Data;
	self->samplebuffer = new SInt16[MAX_LOOPER_DEFAULT];
	self->len = 0;
	self->amp = 1.0; //64*65535;//2147483647;//32767;
	self->recpos = 0;
	self->playpos = 0;
	self->reclen = 0;
	self->recording = false;
	self->playing = false;
	self->loop = true;
	return (void*)self;
}

void Looper_Destructor(ursObject* gself)
{
	Looper_Data* self = (Looper_Data*)gself->objectdata;
	delete (Looper_Data*)self;
}

double Looper_Tick(ursObject* gself)
{	
	Looper_Data* self = (Looper_Data*)gself->objectdata;
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate
	double out = 0;
	if(self->playing)
	{
		out = self->amp*self->samplebuffer[self->position]/32767.0;
		self->realposition = self->realposition + self->rate;
		self->position = (SInt32)self->realposition;
		if(self->loop)
		{
			self->position = self->position % self->len;
			while(self->position < 0)
				self->position += self->len;
		}
		else
		{
			if(self->position >= self->len || self->position < 0)
				self->playing = false;
		}
	}
	self->lastout = out;
	return out;
}

double Looper_Out(ursObject* gself)
{
	Looper_Data* self = (Looper_Data*)gself->objectdata;
	return self->lastout;
}

void Looper_SetAmp(ursObject* gself, double inamp)
{
	Looper_Data* self = (Looper_Data*)gself->objectdata;
	self->amp = inamp;// *(128*65535/256);
}


void Looper_SetRate(ursObject* gself, double inrate)
{
	Looper_Data* self = (Looper_Data*)gself->objectdata;
	self->rate = 4.0*inrate;// /128.0;
}

void Looper_In(ursObject* gself, double indata)
{
	Looper_Data* self = (Looper_Data*)gself->objectdata;
	if(self->recording)
	{
		self->samplebuffer[self->recpos++] = indata*32767.0;
		if(self->recpos >= MAX_LOOPER_DEFAULT || self->recpos >= self->reclen)
			self->recording = false;
	}
}

// Placing virtual zero at below 24 bit resolution. This should be fine for virtually all applications.
#define VIRTUAL_ZERO 1.0/(65536.0*64.0)

void Looper_Record(ursObject* gself, double indata)
{
	Looper_Data* self = (Looper_Data*)gself->objectdata;
	if(indata < VIRTUAL_ZERO)
	{
		self->recording = false;
		self->reclen = self->recpos;
		self->len = self->recpos;
	}
	else
	{
		self->reclen = MAX_LOOPER_DEFAULT*indata;
		self->recpos = 0;
		self->recording = true;
	}
}

void Looper_Play(ursObject* gself, double indata)
{
	Looper_Data* self = (Looper_Data*)gself->objectdata;
	if(indata < VIRTUAL_ZERO)
	{
		self->playing = false;
	}
	else
	{
		self->len = self->reclen*indata;
		self->position = 0;
		self->realposition = 0.0;
		self->playing = true;
	}
}

void Looper_Pos(ursObject* gself, double indata)
{
	Looper_Data* self = (Looper_Data*)gself->objectdata;
	self->realposition = self->reclen*indata;
}

// LoopRhythm

void* LoopRhythm_Constructor()
{
	LoopRhythm_Data* self = new LoopRhythm_Data;
	self->loop = new Loop(16);
	self->btime = 0.0;
	self->bstep = 1/90.0; // Default HPM = 90
	self->sampletime = 1/48000.0; // Default sample time = 1/SR
	self->lastout = 0.0;
	return (void*)self;
}

void LoopRhythm_Destructor(ursObject* gself)
{
	LoopRhythm_Data* self = (LoopRhythm_Data*)gself->objectdata;
	delete self->loop;
	delete (LoopRhythm_Data*)self;
}

double LoopRhythm_Tick(ursObject* gself)
{
	LoopRhythm_Data* self = (LoopRhythm_Data*)gself->objectdata;
	gself->FeedAllPullIns(); // This is decoupled so no forwarding, just pulling to propagate our natural rate
	double res = 0.0;
	self->btime = self->btime + self->sampletime;
	if(self->btime > self->bstep) // Keeping this double means that it will re-align. It's accurate on average but will be quantized by SR.
	{
		self->btime = self->btime - self->bstep;
		res = self->loop->Tick();
		self->lastout = res;
	}
	return res;
}

double LoopRhythm_Out(ursObject* gself)
{
	LoopRhythm_Data* self = (LoopRhythm_Data*)gself->objectdata;
	return self->lastout;
}

void LoopRhythm_SetSampleRate(ursObject* gself, double indata)
{
	LoopRhythm_Data* self = (LoopRhythm_Data*)gself->objectdata;
	self->sampletime = 1.0/indata;
}


// Hits per minute (beat usually means a number of "hits". Smallest beat granularity really.
void LoopRhythm_SetHMP(ursObject* gself, double indata)
{
	LoopRhythm_Data* self = (LoopRhythm_Data*)gself->objectdata;
	self->bstep = 1.0/indata;
}

void LoopRhythm_SetBeatNow(ursObject* gself, double indata)
{
	LoopRhythm_Data* self = (LoopRhythm_Data*)gself->objectdata;
	self->loop->SetNow(norm2PositiveLinear(indata)); // No point in allowing negative beats.
}

void LoopRhythm_Pos(ursObject* gself, double indata)
{
	LoopRhythm_Data* self = (LoopRhythm_Data*)gself->objectdata;
}

// CircleMap

void* CircleMap_Constructor()
{
	CircleMap_Data* self = new CircleMap_Data;
	self->freq = 440;
	self->srate = URSOUND_DEFAULTSRATE;
	self->time = 0;
	self->phase = 0;
	self->amp = 1.0;//2147483647;//32767;
	self->nonl = 0.0;
	return (void*)self;
}

void CircleMap_Destructor(ursObject* gself)
{
	CircleMap_Data* self = (CircleMap_Data*)gself->objectdata;
	delete (CircleMap_Data*)self;
}

double CircleMap_Tick(ursObject* gself)
{
	CircleMap_Data* self = (CircleMap_Data*)gself->objectdata;
	gself->FeedAllPullIns(); // This is decoupled so no forwarding, just pulling to propagate our natural rate
	self->phase = self->phase + 2.0*PI*self->freq/self->srate;
	double out = self->amp*sin(self->phase + self->nonl*sin(2.0*PI*self->lastout));
	self->lastout = out;
	return out;
}

double CircleMap_Out(ursObject* gself)
{
	CircleMap_Data* self = (CircleMap_Data*)gself->objectdata;
	return self->lastout;
}

void CircleMap_SetFreq(ursObject* gself, double infreq)
{
	CircleMap_Data* self = (CircleMap_Data*)gself->objectdata;
	
	self->freq = norm2Freq(infreq);
}

void CircleMap_SetAmp(ursObject* gself, double inamp)
{
	CircleMap_Data* self = (CircleMap_Data*)gself->objectdata;
	self->amp = capNorm(inamp); //*(2147483647/256);
}


void CircleMap_SetRate(ursObject* gself, double inrate)
{
	CircleMap_Data* self = (CircleMap_Data*)gself->objectdata;
	self->srate = (inrate+1.0)*96000;//(inrate+256)/256.0*96000;
}

void CircleMap_SetPhase(ursObject* gself, double inphase)
{
	CircleMap_Data* self = (CircleMap_Data*)gself->objectdata;
	self->phase = inphase;
}

void CircleMap_SetNonL(ursObject* gself, double indata)
{
	CircleMap_Data* self = (CircleMap_Data*)gself->objectdata;
	self->nonl = 10*indata/PI;
}


// Avg

void* Avg_Constructor()
{
	Avg_Data* self = new Avg_Data;
	self->bufferlen = 256;//32;
	self->buffer = new double[256];
	for (int i=0; i < self->bufferlen; i++)
		self->buffer[i] = 0.0;
	self->inpos = 0;
	self->outpos = 0;
	self->avg = 0.0;
	return (void*)self;
}

void Avg_Destructor(ursObject* gself)
{
	Avg_Data* self = (Avg_Data*)gself->objectdata;
	delete (Avg_Data*)self;
}

double Avg_Tick(ursObject* gself)
{
	Avg_Data* self = (Avg_Data*)gself->objectdata;
	return self->avg/self->bufferlen;
}

double Avg_Out(ursObject* gself)
{
	Avg_Data* self = (Avg_Data*)gself->objectdata;
	return self->avg/self->bufferlen;
}

void Avg_In(ursObject* gself, double indata)
{
	Avg_Data* self = (Avg_Data*)gself->objectdata;
	double outvalue = self->buffer[self->inpos];
	double invalue = fabs(indata);
	self->buffer[self->inpos++] = invalue;
	self->avg += invalue - outvalue;
	if(self->inpos >= self->bufferlen) self->inpos = 0;
	double out = self->avg/self->bufferlen > 0.005 ? self->avg/self->bufferlen : 0.0;
	gself->CallAllPushOuts(out);
}

void Avg_Len(ursObject* gself, double indata)
{
	Avg_Data* self = (Avg_Data*)gself->objectdata;
	self->bufferlen = 1+255*norm2PositiveLinear(indata);
}
