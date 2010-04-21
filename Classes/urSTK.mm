/*
 *  urSTK.mm
 *  urMus
 *
 *  Created by gessl on 10/16/09.
 *  Copyright 2009 Georg Essl. All rights reserved. See LICENSE.txt for license conditions.
 *
 */

#include "urSound.h"
#include "urSTK.h"

/*
#include "ADSR.h"
#include "Asymp.h"
#include "BandedWG.h"
#ifdef SAMPLEBASED_STKS
#include "BeeThree.h"
#endif
#include "Blit.h"
#include "BlitSaw.h"
#include "BlitSquare.h"
#include "BlowBotl.h"
#include "BlowHole.h"
#include "Bowed.h"
#include "Brass.h"
#include "Chorus.h"
#include "Clarinet.h"
#include "Echo.h"
#include "Flute.h"
#ifdef SAMPLEBASED_STKS
#include "FMVoices.h"
#include "HevyMetl.h"
#endif
#include "JCRev.h"
#ifdef SAMPLEBASED_STKS
#include "Mandolin.h"
#endif
#include "ModalBar.h"
#include "Modulate.h"
#include "Moog.h"
#include "Noise.h"
#include "NRev.h"
#include "PercFlut.h"
#include "PitShift.h"
#include "Plucked.h"
#include "PRCRev.h"
#include "Rhodey.h"
#include "Saxofony.h"
#include "Shakers.h"
#include "Sitar.h"
#include "StifKarp.h"
#include "TubeBell.h"
#include "VoicForm.h"
#include "Whistle.h"
#include "Wurley.h"

#include "urSound.h"

using namespace stk;
*/

// Interface - ADSR

void* ADSR_Constructor()
{
	ADSR* self = new ADSR;
	return (void*)self;
}

void ADSR_Destructor(ursObject* gself)
{
	ADSR* self = (ADSR*)gself->objectdata;
	delete (ADSR*)self;
}

double ADSR_Tick(ursObject* gself)
{
	ADSR* self = (ADSR*)gself->objectdata;
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate
	
	return gself->CallAllPullIns()*self->tick(); //gself->lastindata[0]*self->tick();
}

double ADSR_Out(ursObject* gself)
{
	ADSR* self = (ADSR*)gself->objectdata;
	return self->lastOut();
}

void ADSR_In(ursObject* gself, double indata)
{
	ADSR* self = (ADSR*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void ADSR_SetAttack(ursObject* gself, double indata)
{
	ADSR* self = (ADSR*)gself->objectdata;
	self->setAttackRate(indata);
}


void ADSR_SetDecay(ursObject* gself, double indata)
{
	ADSR* self = (ADSR*)gself->objectdata;
	self->setDecayRate(indata);
}

void ADSR_SetSustain(ursObject* gself, double indata)
{
	ADSR* self = (ADSR*)gself->objectdata;
	self->setSustainLevel(indata);
}

void ADSR_SetRelease(ursObject* gself, double indata)
{
	ADSR* self = (ADSR*)gself->objectdata;
	self->setReleaseRate(indata);
}

// Interface - Asymp

void* Asymp_Constructor()
{
	Asymp* self = new Asymp;
	return (void*)self;
}

void Asymp_Destructor(ursObject* gself)
{
	Asymp* self = (Asymp*)gself->objectdata;
	delete (Asymp*)self;
}

double Asymp_Tick(ursObject* gself)
{
	Asymp* self = (Asymp*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return gself->CallAllPullIns()*self->tick();
}

double Asymp_Out(ursObject* gself)
{
	Asymp* self = (Asymp*)gself->objectdata;
	return self->lastOut();
}

void Asymp_In(ursObject* gself, double indata)
{
	Asymp* self = (Asymp*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->setTarget(indata);
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Asymp_SetTau(ursObject* gself, double indata)
{
	Asymp* self = (Asymp*)gself->objectdata;
	self->setTau(norm2PositiveLinear(indata)*0.0005);
}

// Interface - BandedWG

void* BandedWG_Constructor()
{
	BandedWG* self = new BandedWG;
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void BandedWG_Destructor(ursObject* gself)
{
	BandedWG* self = (BandedWG*)gself->objectdata;
	delete (BandedWG*)self;
}

double BandedWG_Tick(ursObject* gself)
{
	BandedWG* self = (BandedWG*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double BandedWG_Out(ursObject* gself)
{
	BandedWG* self = (BandedWG*)gself->objectdata;
	return self->lastOut();
}

void BandedWG_Pluck(ursObject* gself, double indata)
{
	BandedWG* self = (BandedWG*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->pluck(indata);
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void BandedWG_SetFrequency(ursObject* gself, double indata)
{
	BandedWG* self = (BandedWG*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void BandedWG_SetPosition(ursObject* gself, double indata)
{
	BandedWG* self = (BandedWG*)gself->objectdata;
	self->setStrikePosition(norm2PositiveLinear(indata));
}

// Interface - BeeThree

#ifdef SAMPLEBASED_STKS
void* BeeThree_Constructor()
{
	BeeThree* self = new BeeThree;
	return (void*)self;
}

void BeeThree_Destructor(ursObject* gself)
{
	BeeThree* self = (BeeThree*)gself->objectdata;
	delete (BeeThree*)self;
}

double BeeThree_Tick(ursObject* gself)
{
	BeeThree* self = (BeeThree*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double BeeThree_Out(ursObject* gself)
{
	BeeThree* self = (BeeThree*)gself->objectdata;
	return self->lastOut();
}

// NYI Needs split of parameters here. Excite and setFrequency
void BeeThree_In(ursObject* gself, double indata)
{
	BeeThree* self = (BeeThree*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->noteOn(440.0,indata); // HACK needs fixing, NYI
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

/*void BeeThree_SetFrequency(ursObject* gself, double indata)
{
	BeeThree* self = (BeeThree*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}*/

void BeeThree_SetModulationFrequency(ursObject* gself, double indata)
{
	BeeThree* self = (BeeThree*)gself->objectdata;
	self->setModulationSpeed(norm2Freq(indata));
}

void BeeThree_SetModulationDepth(ursObject* gself, double indata)
{
	BeeThree* self = (BeeThree*)gself->objectdata;
	self->setModulationDepth(indata);
}

#endif

// Interface - BiQuad
// NYI This should be separated out into various useful less generic and more "atomic" blocks

void* BiQuad_Constructor()
{
	BiQuad_Data* self = new BiQuad_Data();
	self->stkobject = new BiQuad;
	self->stkobject->setResonance(self->reson, self->q);
	self->stkobject->setNotch(self->notch, self->nq);
	return (void*)self;
}

void BiQuad_Destructor(ursObject* gself)
{
	BiQuad_Data* self = (BiQuad_Data*)gself->objectdata;
	delete self->stkobject;
	delete (BiQuad_Data*)self;
}

double BiQuad_Tick(ursObject* gself)
{
	BiQuad* self = ((BiQuad_Data*)gself->objectdata)->stkobject;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double BiQuad_Out(ursObject* gself)
{
	BiQuad* self = ((BiQuad_Data*)gself->objectdata)->stkobject;
	return self->lastOut();
}

// NYI Needs split of parameters here. Excite and setFrequency
void BiQuad_In(ursObject* gself, double indata)
{
	BiQuad* self = ((BiQuad_Data*)gself->objectdata)->stkobject;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void BiQuad_SetResonance(ursObject* gself, double indata)
{
	BiQuad_Data* self = (BiQuad_Data*)gself->objectdata;
	self->reson = norm2Freq(indata);
	self->stkobject->setResonance(self->reson, self->q);
}

void BiQuad_SetQ(ursObject* gself, double indata)
{
	BiQuad_Data* self = (BiQuad_Data*)gself->objectdata;
	self->q = indata;
	self->stkobject->setResonance(self->reson, self->q);
}

void BiQuad_SetNotch(ursObject* gself, double indata)
{
	BiQuad_Data* self = (BiQuad_Data*)gself->objectdata;
	self->notch = norm2Freq(indata);
	self->stkobject->setResonance(self->notch, self->nq);
}

void BiQuad_SetNQ(ursObject* gself, double indata)
{
	BiQuad_Data* self = (BiQuad_Data*)gself->objectdata;
	self->nq = indata;
	self->stkobject->setResonance(self->notch, self->nq);
}	

// Import - Blit

void* Blit_Constructor()
{
	Blit* self = new Blit;
	return (void*)self;
}

void Blit_Destructor(ursObject* gself)
{
	Blit* self = (Blit*)gself->objectdata;
	delete (Blit*)self;
}

double Blit_Tick(ursObject* gself)
{
	Blit* self = (Blit*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return gself->CallAllPullIns()+self->tick();
}

double Blit_Out(ursObject* gself)
{
	Blit* self = (Blit*)gself->objectdata;
	return self->lastOut();
}

void Blit_In(ursObject* gself, double indata)
{
	Blit* self = (Blit*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Blit_SetFrequency(ursObject* gself, double indata)
{
	Blit* self = (Blit*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void Blit_SetPhase(ursObject* gself, double indata)
{
	Blit* self = (Blit*)gself->objectdata;
	self->setPhase(indata);
}

void Blit_SetHarmonics(ursObject* gself, double indata)
{
	Blit* self = (Blit*)gself->objectdata;
	self->setHarmonics(indata);
}

// Interface - BlitSaw

void* BlitSaw_Constructor()
{
	BlitSaw* self = new BlitSaw;
	return (void*)self;
}

void BlitSaw_Destructor(ursObject* gself)
{
	BlitSaw* self = (BlitSaw*)gself->objectdata;
	delete (BlitSaw*)self;
}

double BlitSaw_Tick(ursObject* gself)
{
	BlitSaw* self = (BlitSaw*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return gself->CallAllPullIns()+self->tick();
}

double BlitSaw_Out(ursObject* gself)
{
	BlitSaw* self = (BlitSaw*)gself->objectdata;
	return self->lastOut();
}

void BlitSaw_In(ursObject* gself, double indata)
{
	BlitSaw* self = (BlitSaw*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void BlitSaw_SetFrequency(ursObject* gself, double indata)
{
	BlitSaw* self = (BlitSaw*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void BlitSaw_SetHarmonics(ursObject* gself, double indata)
{
	BlitSaw* self = (BlitSaw*)gself->objectdata;
	self->setHarmonics(indata);
}

// Interface - BlitSquare

void* BlitSquare_Constructor()
{
	BlitSquare* self = new BlitSquare;
	return (void*)self;
}

void BlitSquare_Destructor(ursObject* gself)
{
	BlitSquare* self = (BlitSquare*)gself->objectdata;
	delete (BlitSquare*)self;
}

double BlitSquare_Tick(ursObject* gself)
{
	BlitSquare* self = (BlitSquare*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return gself->CallAllPullIns()+self->tick();
}

double BlitSquare_Out(ursObject* gself)
{
	BlitSquare* self = (BlitSquare*)gself->objectdata;
	return self->lastOut();
}

void BlitSquare_In(ursObject* gself, double indata)
{
	BlitSquare* self = (BlitSquare*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void BlitSquare_SetFrequency(ursObject* gself, double indata)
{
	BlitSquare* self = (BlitSquare*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void BlitSquare_SetPhase(ursObject* gself, double indata)
{
	BlitSquare* self = (BlitSquare*)gself->objectdata;
	self->setPhase(indata);
}

void BlitSquare_SetHarmonics(ursObject* gself, double indata)
{
	BlitSquare* self = (BlitSquare*)gself->objectdata;
	self->setHarmonics(indata);
}

// Interface - BlowBotl

void* BlowBotl_Constructor()
{
	BlowBotl* self = new BlowBotl;
	return (void*)self;
}

void BlowBotl_Destructor(ursObject* gself)
{
	BlowBotl* self = (BlowBotl*)gself->objectdata;
	delete (BlowBotl*)self;
}

double BlowBotl_Tick(ursObject* gself)
{
	BlowBotl* self = (BlowBotl*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double BlowBotl_Out(ursObject* gself)
{
	BlowBotl* self = (BlowBotl*)gself->objectdata;
	return self->lastOut();
}

void BlowBotl_In(ursObject* gself, double indata)
{
	BlowBotl* self = (BlowBotl*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI figure out how to blow the bottle
	
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void BlowBotl_SetFrequency(ursObject* gself, double indata)
{
	BlowBotl* self = (BlowBotl*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

// Interface -- BlowHole

void* BlowHole_Constructor()
{
	BlowHole* self = new BlowHole(22.0);
	return (void*)self;
}

void BlowHole_Destructor(ursObject* gself)
{
	BlowHole* self = (BlowHole*)gself->objectdata;
	delete (BlowHole*)self;
}

double BlowHole_Tick(ursObject* gself)
{
	BlowHole* self = (BlowHole*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double BlowHole_Out(ursObject* gself)
{
	BlowHole* self = (BlowHole*)gself->objectdata;
	return self->lastOut();
}

void BlowHole_In(ursObject* gself, double indata)
{
	BlowHole* self = (BlowHole*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI figure out how to blow the bottle
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void BlowHole_SetFrequency(ursObject* gself, double indata)
{
	BlowHole* self = (BlowHole*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

// More parameters here: NYI

// Interface - Bowed



void* Bowed_Constructor()
{
	Bowed* self = new Bowed(22.0);
	self->noteOn(440.0,1.0);
	return (void*)self;
}

void Bowed_Destructor(ursObject* gself)
{
	Bowed* self = (Bowed*)gself->objectdata;
	delete (Bowed*)self;
}

double Bowed_Tick(ursObject* gself)
{
	Bowed* self = (Bowed*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Bowed_Out(ursObject* gself)
{
	Bowed* self = (Bowed*)gself->objectdata;
	return self->lastOut();
}

void Bowed_In(ursObject* gself, double indata)
{
	Bowed* self = (Bowed*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI figure out how to blow the bottle
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Bowed_SetFrequency(ursObject* gself, double indata)
{
	Bowed* self = (Bowed*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void Bowed_SetVibrato(ursObject* gself, double indata)
{
	Bowed* self = (Bowed*)gself->objectdata;
	self->setVibrato(indata);
}


// Interface - BowTable

void* BowTable_Constructor()
{
	BowTable* self = new BowTable();
	return (void*)self;
}

void BowTable_Destructor(ursObject* gself)
{
	BowTable* self = (BowTable*)gself->objectdata;
	delete (BowTable*)self;
}

double BowTable_Tick(ursObject* gself)
{
	BowTable* self = (BowTable*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double BowTable_Out(ursObject* gself)
{
	BowTable* self = (BowTable*)gself->objectdata;
	return self->lastOut();
}

void BowTable_In(ursObject* gself, double indata)
{
	BowTable* self = (BowTable*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void BowTable_SetOffset(ursObject* gself, double indata)
{
	BowTable* self = (BowTable*)gself->objectdata;
	self->setOffset(indata);
}

void BowTable_SetSlope(ursObject* gself, double indata)
{
	BowTable* self = (BowTable*)gself->objectdata;
	self->setSlope(indata);
}

// Interface - Brass

void* Brass_Constructor()
{
	Brass* self = new Brass(22.0);
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Brass_Destructor(ursObject* gself)
{
	Brass* self = (Brass*)gself->objectdata;
	delete (Brass*)self;
}

double Brass_Tick(ursObject* gself)
{
	Brass* self = (Brass*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Brass_Out(ursObject* gself)
{
	Brass* self = (Brass*)gself->objectdata;
	return self->lastOut();
}

void Brass_In(ursObject* gself, double indata)
{
	Brass* self = (Brass*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI figure out how to blow the bottle
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Brass_SetFrequency(ursObject* gself, double indata)
{
	Brass* self = (Brass*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

// Interface - Chorus

void* Chorus_Constructor()
{
	Chorus* self = new Chorus();
	return (void*)self;
}

void Chorus_Destructor(ursObject* gself)
{
	Chorus* self = (Chorus*)gself->objectdata;
	delete (Chorus*)self;
}

double Chorus_Tick(ursObject* gself)
{
	Chorus* self = (Chorus*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Chorus_Out(ursObject* gself)
{
	Chorus* self = (Chorus*)gself->objectdata;
	return self->lastOut();
}

void Chorus_In(ursObject* gself, double indata)
{
	Chorus* self = (Chorus*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void Chorus_SetModDepth(ursObject* gself, double indata)
{
	Chorus* self = (Chorus*)gself->objectdata;
	self->setModDepth(norm2ModIndex(indata));
}

void Chorus_SetModFrequency(ursObject* gself, double indata)
{
	Chorus* self = (Chorus*)gself->objectdata;
	self->setModFrequency(norm2Freq(indata));
}

// Interface - Clarinet

void* Clarinet_Constructor()
{
	Clarinet* self = new Clarinet(22.0);
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Clarinet_Destructor(ursObject* gself)
{
	Clarinet* self = (Clarinet*)gself->objectdata;
	delete (Clarinet*)self;
}

double Clarinet_Tick(ursObject* gself)
{
	Clarinet* self = (Clarinet*)gself->objectdata;

	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate
	
	return self->tick(gself->CallAllPullIns());
}

double Clarinet_Out(ursObject* gself)
{
	Clarinet* self = (Clarinet*)gself->objectdata;
	return self->lastOut();
}

void Clarinet_In(ursObject* gself, double indata)
{
	Clarinet* self = (Clarinet*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI figure out how to blow the bottle
	double res = 0;
	self->startBlowing(indata,0.05);
	res = self->lastOut();
	gself->CallAllPushOuts(res);
}

void Clarinet_SetFrequency(ursObject* gself, double indata)
{
	Clarinet* self = (Clarinet*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

// Interface - Delay

void* Delay_Constructor()
{
	Delay* self = new Delay(22.0);
	return (void*)self;
}

void Delay_Destructor(ursObject* gself)
{
	Delay* self = (Delay*)gself->objectdata;
	delete (Delay*)self;
}

double Delay_Tick(ursObject* gself)
{
	Delay* self = (Delay*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Delay_Out(ursObject* gself)
{
	Delay* self = (Delay*)gself->objectdata;
	return self->lastOut();
}

void Delay_In(ursObject* gself, double indata)
{
	Delay* self = (Delay*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI figure out how to blow the bottle
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void Delay_SetDelay(ursObject* gself, double indata)
{
	Delay* self = (Delay*)gself->objectdata;
	self->setDelay(indata);
}

// Interface - DelayA

void* DelayA_Constructor()
{
	DelayA* self = new DelayA(22.0);
	return (void*)self;
}

void DelayA_Destructor(ursObject* gself)
{
	DelayA* self = (DelayA*)gself->objectdata;
	delete (DelayA*)self;
}

double DelayA_Tick(ursObject* gself)
{
	DelayA* self = (DelayA*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double DelayA_Out(ursObject* gself)
{
	DelayA* self = (DelayA*)gself->objectdata;
	return self->lastOut();
}

void DelayA_In(ursObject* gself, double indata)
{
	DelayA* self = (DelayA*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI figure out how to blow the bottle
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void DelayA_SetDelay(ursObject* gself, double indata)
{
	DelayA* self = (DelayA*)gself->objectdata;
	self->setDelay(indata);
}

// Interface - DelayL

void* DelayL_Constructor()
{
	DelayL* self = new DelayL(22.0);
	return (void*)self;
}

void DelayL_Destructor(ursObject* gself)
{
	DelayL* self = (DelayL*)gself->objectdata;
	delete (DelayL*)self;
}

double DelayL_Tick(ursObject* gself)
{
	DelayL* self = (DelayL*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double DelayL_Out(ursObject* gself)
{
	DelayL* self = (DelayL*)gself->objectdata;
	return self->lastOut();
}

void DelayL_In(ursObject* gself, double indata)
{
	DelayL* self = (DelayL*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI figure out how to blow the bottle
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void DelayL_SetDelay(ursObject* gself, double indata)
{
	DelayL* self = (DelayL*)gself->objectdata;
	self->setDelay(indata);
}

// Interface - Echo

void* Echo_Constructor()
{
	Echo* self = new Echo(48000*4.16);
	return (void*)self;
}

void Echo_Destructor(ursObject* gself)
{
	Echo* self = (Echo*)gself->objectdata;
	delete (Echo*)self;
}

double Echo_Tick(ursObject* gself)
{
	Echo* self = (Echo*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Echo_Out(ursObject* gself)
{
	Echo* self = (Echo*)gself->objectdata;
	return self->lastOut();
}

void Echo_In(ursObject* gself, double indata)
{
	Echo* self = (Echo*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI figure out how to blow the bottle
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void Echo_SetDelay(ursObject* gself, double indata)
{
	Echo* self = (Echo*)gself->objectdata;
	self->setDelay(norm2RevSamples(indata, 48000.0));
}

void Echo_SetEffectMix(ursObject* gself, double indata)
{
	Echo* self = (Echo*)gself->objectdata;
	self->setEffectMix(norm2PositiveLinear(indata));
}

// Interface - Envelope

void* Envelope_Constructor()
{
	Envelope* self = new Envelope();
	return (void*)self;
}

void Envelope_Destructor(ursObject* gself)
{
	Envelope* self = (Envelope*)gself->objectdata;
	delete (Envelope*)self;
}

double Envelope_Tick(ursObject* gself)
{
	Envelope* self = (Envelope*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return gself->CallAllPullIns()*self->tick();
}

double Envelope_Out(ursObject* gself)
{
	Envelope* self = (Envelope*)gself->objectdata;
	return self->lastOut();
}

void Envelope_In(ursObject* gself, double indata)
{
	Envelope* self = (Envelope*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->setTarget(indata); // NYI check if this makes sense
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Envelope_SetTime(ursObject* gself, double indata)
{
	Envelope* self = (Envelope*)gself->objectdata;
	self->setTime(norm2PositiveLinear(indata)*0.25);
}

// Interface - Flute

void* Flute_Constructor()
{
	Flute* self = new Flute(22.0);
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Flute_Destructor(ursObject* gself)
{
	Flute* self = (Flute*)gself->objectdata;
	delete (Flute*)self;
}

double Flute_Tick(ursObject* gself)
{
	Flute* self = (Flute*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Flute_Out(ursObject* gself)
{
	Flute* self = (Flute*)gself->objectdata;
	return self->lastOut();
}

void Flute_In(ursObject* gself, double indata)
{
	Flute* self = (Flute*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI check if this makes sense
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Flute_SetFrequency(ursObject* gself, double indata)
{
	Flute* self = (Flute*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void Flute_SetJetReflection(ursObject* gself, double indata)
{
	Flute* self = (Flute*)gself->objectdata;
	self->setJetReflection(indata);
}

void Flute_SetEndReflection(ursObject* gself, double indata)
{
	Flute* self = (Flute*)gself->objectdata;
	self->setEndReflection(indata);
}

void Flute_SetJetDelay(ursObject* gself, double indata)
{
	Flute* self = (Flute*)gself->objectdata;
	self->setJetDelay(indata);
}

// Interface - FMVoices
#ifdef SAMPLEBASED_STKS
void* FMVoices_Constructor()
{
	FMVoices* self = new FMVoices();
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void FMVoices_Destructor(ursObject* gself)
{
	FMVoices* self = (FMVoices*)gself->objectdata;
	delete (FMVoices*)self;
}

double FMVoices_Tick(ursObject* gself)
{
	FMVoices* self = (FMVoices*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double FMVoices_Out(ursObject* gself)
{
	FMVoices* self = (FMVoices*)gself->objectdata;
	return self->lastOut();
}

void FMVoices_In(ursObject* gself, double indata)
{
	FMVoices* self = (FMVoices*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->noteOn(440.0,indata); // NYI check if this makes sense
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void FMVoices_SetFrequency(ursObject* gself, double indata)
{
	FMVoices* self = (FMVoices*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void FMVoices_SetModulationFrequency(ursObject* gself, double indata)
{
	FMVoices* self = (FMVoices*)gself->objectdata;
	self->setModulationSpeed(indata);
}

void FMVoices_SetModulationDepth(ursObject* gself, double indata)
{
	FMVoices* self = (FMVoices*)gself->objectdata;
	self->setModulationDepth(indata);
}

// Interface - HevyMetl

void* HevyMetl_Constructor()
{
	HevyMetl* self = new HevyMetl();
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void HevyMetl_Destructor(ursObject* gself)
{
	HevyMetl* self = (HevyMetl*)gself->objectdata;
	delete (HevyMetl*)self;
}

double HevyMetl_Tick(ursObject* gself)
{
	HevyMetl* self = (HevyMetl*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double HevyMetl_Out(ursObject* gself)
{
	HevyMetl* self = (HevyMetl*)gself->objectdata;
	return self->lastOut();
}

void HevyMetl_In(ursObject* gself, double indata)
{
	HevyMetl* self = (HevyMetl*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->noteOn(440.0,indata); // NYI check if this makes sense
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void HevyMetl_SetFrequency(ursObject* gself, double indata)
{
	HevyMetl* self = (HevyMetl*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void HevyMetl_SetModulationFrequency(ursObject* gself, double indata)
{
	HevyMetl* self = (HevyMetl*)gself->objectdata;
	self->setModulationSpeed(indata);
}

void HevyMetl_SetModulationDepth(ursObject* gself, double indata)
{
	HevyMetl* self = (HevyMetl*)gself->objectdata;
	self->setModulationDepth(indata);
}
#endif

// Interface - JCRev

void* JCRev_Constructor()
{
	JCRev* self = new JCRev();
	return (void*)self;
}

void JCRev_Destructor(ursObject* gself)
{
	JCRev* self = (JCRev*)gself->objectdata;
	delete (JCRev*)self;
}

double JCRev_Tick(ursObject* gself)
{
	JCRev* self = (JCRev*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double JCRev_Out(ursObject* gself)
{
	JCRev* self = (JCRev*)gself->objectdata;
	return self->lastOut();
}

void JCRev_In(ursObject* gself, double indata)
{
	JCRev* self = (JCRev*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void JCRev_SetT60(ursObject* gself, double indata)
{
	JCRev* self = (JCRev*)gself->objectdata;
	self->setT60(norm2RevTime(indata));
}

// Interface - JetTable

void* JetTable_Constructor()
{
	JetTable* self = new JetTable();
	return (void*)self;
}

void JetTable_Destructor(ursObject* gself)
{
	JetTable* self = (JetTable*)gself->objectdata;
	delete (JetTable*)self;
}

double JetTable_Tick(ursObject* gself)
{
	JetTable* self = (JetTable*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double JetTable_Out(ursObject* gself)
{
	JetTable* self = (JetTable*)gself->objectdata;
	return self->lastOut();
}

void JetTable_In(ursObject* gself, double indata)
{
	JetTable* self = (JetTable*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

// Interface - Mandolin
#ifdef SAMPLEBASED_STKS
void* Mandolin_Constructor()
{
	Mandolin* self = new Mandolin(22.0);
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Mandolin_Destructor(ursObject* gself)
{
	Mandolin* self = (Mandolin*)gself->objectdata;
	delete (Mandolin*)self;
}

double Mandolin_Tick(ursObject* gself)
{
	Mandolin* self = (Mandolin*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Mandolin_Out(ursObject* gself)
{
	Mandolin* self = (Mandolin*)gself->objectdata;
	return self->lastOut();
}

void Mandolin_In(ursObject* gself, double indata)
{
	Mandolin* self = (Mandolin*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->pluck(indata);
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Mandolin_SetFrequency(ursObject* gself, double indata)
{
	Mandolin* self = (Mandolin*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void Mandolin_SetDetune(ursObject* gself, double indata)
{
	Mandolin* self = (Mandolin*)gself->objectdata;
	self->setDetune(indata);
}

void Mandolin_SetLoop(ursObject* gself, double indata)
{
	Mandolin* self = (Mandolin*)gself->objectdata;
	self->setBaseLoopGain(indata);
}

void Mandolin_SetBodySize(ursObject* gself, double indata)
{
	Mandolin* self = (Mandolin*)gself->objectdata;
	self->setBodySize(indata);
}
#endif

// Interface - ModalBar

void* ModalBar_Constructor()
{
	ModalBar* self = new ModalBar();
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void ModalBar_Destructor(ursObject* gself)
{
	ModalBar* self = (ModalBar*)gself->objectdata;
	delete (ModalBar*)self;
}

double ModalBar_Tick(ursObject* gself)
{
	ModalBar* self = (ModalBar*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double ModalBar_Out(ursObject* gself)
{
	ModalBar* self = (ModalBar*)gself->objectdata;
	return self->lastOut();
}

void ModalBar_In(ursObject* gself, double indata)
{
	ModalBar* self = (ModalBar*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void ModalBar_SetFrequency(ursObject* gself, double indata)
{
	ModalBar* self = (ModalBar*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void ModalBar_SetStickHardness(ursObject* gself, double indata)
{
	ModalBar* self = (ModalBar*)gself->objectdata;
	self->setStickHardness(indata);
}

void ModalBar_SetStrikePosition(ursObject* gself, double indata)
{
	ModalBar* self = (ModalBar*)gself->objectdata;
	self->setStrikePosition(norm2PositiveLinear(indata));
}

/*void ModalBar_SetModulationDepth(ursObject* gself, double indata)
{
	ModalBar* self = (ModalBar*)gself->objectdata;
	self->setModulationDepth(indata);
}*/

void ModalBar_SetPreset(ursObject* gself, double indata)
{
	ModalBar* self = (ModalBar*)gself->objectdata;
	self->setPreset(indata);
}

// Interface - Modulate

void* Modulate_Constructor()
{
	Modulate* self = new Modulate();
	return (void*)self;
}

void Modulate_Destructor(ursObject* gself)
{
	Modulate* self = (Modulate*)gself->objectdata;
	delete (Modulate*)self;
}

double Modulate_Tick(ursObject* gself)
{
	Modulate* self = (Modulate*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return gself->CallAllPullIns()*self->tick();
}

double Modulate_Out(ursObject* gself)
{
	Modulate* self = (Modulate*)gself->objectdata;
	return self->lastOut();
}

/*void Modulate_In(ursObject* gself, double indata)
{
	Modulate* self = (Modulate*)gself->objectdata;
	gself->lastindata[0] =indata;
 double res = 0;
 res = self->tick();
 gself->CallAllPushOuts(res);
 }*/

void Modulate_SetVibratoRate(ursObject* gself, double indata)
{
	Modulate* self = (Modulate*)gself->objectdata;
	self->setVibratoRate(indata);
}

void Modulate_SetVibratoGain(ursObject* gself, double indata)
{
	Modulate* self = (Modulate*)gself->objectdata;
	self->setVibratoGain(indata);
}

void Modulate_SetRandomGain(ursObject* gself, double indata)
{
	Modulate* self = (Modulate*)gself->objectdata;
	self->setRandomGain(indata);
}

/*void Modulate_SetModulationDepth(ursObject* gself, double indata)
 {
 Modulate* self = (Modulate*)gself->objectdata;
 self->setModulationDepth(indata);
 }*/

// Interface - Moog

void* Moog_Constructor()
{
	Moog* self = new Moog();
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Moog_Destructor(ursObject* gself)
{
	Moog* self = (Moog*)gself->objectdata;
	delete (Moog*)self;
}

double Moog_Tick(ursObject* gself)
{
	Moog* self = (Moog*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Moog_Out(ursObject* gself)
{
	Moog* self = (Moog*)gself->objectdata;
	return self->lastOut();
}

void Moog_In(ursObject* gself, double indata)
{
	Moog* self = (Moog*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Moog_SetFrequency(ursObject* gself, double indata)
{
	Moog* self = (Moog*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void Moog_SetModulationFrequency(ursObject* gself, double indata)
{
	Moog* self = (Moog*)gself->objectdata;
	self->setModulationSpeed(indata);
}

void Moog_SetModulationDepth(ursObject* gself, double indata)
{
	Moog* self = (Moog*)gself->objectdata;
	self->setModulationDepth(indata);
}

// Interface - Noise

void* Noise_Constructor()
{
	Noise* self = new Noise();
	return (void*)self;
}

void Noise_Destructor(ursObject* gself)
{
	Noise* self = (Noise*)gself->objectdata;
	delete (Noise*)self;
}

double Noise_Tick(ursObject* gself)
{
	Noise* self = (Noise*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return gself->CallAllPullIns()*self->tick();
}

double Noise_Out(ursObject* gself)
{
	Noise* self = (Noise*)gself->objectdata;
	return self->lastOut();
}

// Interface - NRev

void* NRev_Constructor()
{
	NRev* self = new NRev();
	return (void*)self;
}

void NRev_Destructor(ursObject* gself)
{
	NRev* self = (NRev*)gself->objectdata;
	delete (NRev*)self;
}

double NRev_Tick(ursObject* gself)
{
	NRev* self = (NRev*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate
//	gself->CallAllPullIns();
	return self->tick(gself->CallAllPullIns());
}

double NRev_Out(ursObject* gself)
{
	NRev* self = (NRev*)gself->objectdata;
	return self->lastOut();
}

void NRev_In(ursObject* gself, double indata)
{
	NRev* self = (NRev*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void NRev_SetT60(ursObject* gself, double indata)
{
	NRev* self = (NRev*)gself->objectdata;
	self->setT60(norm2RevTime(indata));
}

// Interface - OnePole

void* OnePole_Constructor()
{
	OnePole_Data* self = new OnePole_Data();
	self->stkobject = new OnePole;
	self->stkobject->setPole(self->reson);//, self->q);
	return (void*)self;
}

void OnePole_Destructor(ursObject* gself)
{
	OnePole_Data* self = (OnePole_Data*)gself->objectdata;
	delete self->stkobject;
	delete self;
}

double OnePole_Tick(ursObject* gself)
{
	OnePole* self = ((OnePole_Data*)gself->objectdata)->stkobject;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double OnePole_Out(ursObject* gself)
{
	OnePole* self = ((OnePole_Data*)gself->objectdata)->stkobject;
	return self->lastOut();
}

// NYI Needs split of parameters here. Excite and setFrequency
void OnePole_In(ursObject* gself, double indata)
{
	OnePole* self = ((OnePole_Data*)gself->objectdata)->stkobject;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void OnePole_SetResonance(ursObject* gself, double indata)
{
	OnePole* self = ((OnePole_Data*)gself->objectdata)->stkobject;
	self->setPole(indata);
}

/*
void OnePole_SetQ(ursObject* gself, double indata)
{
	OnePole* self = (OnePole*)gself->objectdata;
	self->setQ(indata);
}
*/

// Interface - OnZero

void* OneZero_Constructor()
{
	OneZero_Data* self = new OneZero_Data();
	self->stkobject = new OneZero;
	self->stkobject->setZero(self->notch);//, self->q);
	return (void*)self;
}

void OneZero_Destructor(ursObject* gself)
{
	OneZero_Data* self = (OneZero_Data*)gself->objectdata;
	delete self->stkobject;
	delete self;
}

double OneZero_Tick(ursObject* gself)
{
	OneZero* self = ((OneZero_Data*)gself->objectdata)->stkobject;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double OneZero_Out(ursObject* gself)
{
	OneZero* self = ((OneZero_Data*)gself->objectdata)->stkobject;
	return self->lastOut();
}

// NYI Needs split of parameters here. Excite and setFrequency
void OneZero_In(ursObject* gself, double indata)
{
	OneZero* self = ((OneZero_Data*)gself->objectdata)->stkobject;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void OneZero_SetNotch(ursObject* gself, double indata)
{
	OneZero* self = ((OneZero_Data*)gself->objectdata)->stkobject;
	self->setZero(indata);
}

/*
 void OneZero_SetQ(ursObject* gself, double indata)
 {
 OneZero* self = (OneZero*)gself->objectdata;
 self->setQ(indata);
 }
 */
/*
void* OneZero_Constructor()
{
	OneZero* self = new OneZero;
	return (void*)self;
}

void OneZero_Destructor(ursObject* gself)
{
	OneZero* self = (OneZero*)gself->objectdata;
	delete (OneZero*)self;
}

double OneZero_Tick(ursObject* gself)
{
	OneZero* self = (OneZero*)gself->objectdata;
	
	return self->tick(gself->CallAllPullIns());
}

double OneZero_Out(ursObject* gself)
{
	OneZero* self = (OneZero*)gself->objectdata;
	return self->lastOut();
}

// NYI Needs split of parameters here. Excite and setFrequency
void OneZero_In(ursObject* gself, double indata)
{
	OneZero* self = (OneZero*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void OneZero_SetB0(ursObject* gself, double indata)
{
	OneZero* self = (OneZero*)gself->objectdata;
	self->setB0(indata);
}

void OneZero_SetB1(ursObject* gself, double indata)
{
	OneZero* self = (OneZero*)gself->objectdata;
	self->setB1(indata);
}
*/
// Interface - PercFlute

void* PercFlut_Constructor()
{
	PercFlut* self = new PercFlut();
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void PercFlut_Destructor(ursObject* gself)
{
	PercFlut* self = (PercFlut*)gself->objectdata;
	delete (PercFlut*)self;
}

double PercFlut_Tick(ursObject* gself)
{
	PercFlut* self = (PercFlut*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double PercFlut_Out(ursObject* gself)
{
	PercFlut* self = (PercFlut*)gself->objectdata;
	return self->lastOut();
}

void PercFlut_In(ursObject* gself, double indata)
{
	PercFlut* self = (PercFlut*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->noteOn(440.0,indata); // NYI check if this makes sense
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void PercFlut_SetFrequency(ursObject* gself, double indata)
{
	PercFlut* self = (PercFlut*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void PercFlut_SetModulationFrequency(ursObject* gself, double indata)
{
	PercFlut* self = (PercFlut*)gself->objectdata;
	self->setModulationSpeed(indata);
}

void PercFlut_SetModulationDepth(ursObject* gself, double indata)
{
	PercFlut* self = (PercFlut*)gself->objectdata;
	self->setModulationDepth(indata);
}

// Interface - PitShift

void* PitShift_Constructor()
{
	PitShift* self = new PitShift();
	return (void*)self;
}

void PitShift_Destructor(ursObject* gself)
{
	PitShift* self = (PitShift*)gself->objectdata;
	delete (PitShift*)self;
}

double PitShift_Tick(ursObject* gself)
{
	PitShift* self = (PitShift*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double PitShift_Out(ursObject* gself)
{
	PitShift* self = (PitShift*)gself->objectdata;
	return self->lastOut();
}

void PitShift_In(ursObject* gself, double indata)
{
	PitShift* self = (PitShift*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void PitShift_SetShift(ursObject* gself, double indata)
{
	PitShift* self = (PitShift*)gself->objectdata;
	self->setShift(norm2PitchShift(indata));
}

// Interface - Plucked

void* Plucked_Constructor()
{
	Plucked* self = new Plucked(22.0);
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Plucked_Destructor(ursObject* gself)
{
	Plucked* self = (Plucked*)gself->objectdata;
	delete (Plucked*)self;
}

double Plucked_Tick(ursObject* gself)
{
	Plucked* self = (Plucked*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Plucked_Out(ursObject* gself)
{
	Plucked* self = (Plucked*)gself->objectdata;
	return self->lastOut();
}

void Plucked_In(ursObject* gself, double indata)
{
	Plucked* self = (Plucked*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->pluck(indata);
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Plucked_SetFrequency(ursObject* gself, double indata)
{
	Plucked* self = (Plucked*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

// Interface - AllPass

void* AllPass_Constructor()
{
	PoleZero* self = new PoleZero;
	self->setAllpass(0.5);
	return (void*)self;
}

void AllPass_Destructor(ursObject* gself)
{
	PoleZero* self = (PoleZero*)gself->objectdata;
	delete (PoleZero*)self;
}

double AllPass_Tick(ursObject* gself)
{
	PoleZero* self = (PoleZero*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double AllPass_Out(ursObject* gself)
{
	PoleZero* self = (PoleZero*)gself->objectdata;
	return self->lastOut();
}

// NYI Needs split of parameters here. Excite and setFrequency
void AllPass_In(ursObject* gself, double indata)
{
	PoleZero* self = (PoleZero*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void AllPass_SetAllpass(ursObject* gself, double indata)
{
	PoleZero* self = (PoleZero*)gself->objectdata;
	self->setAllpass(indata);
}

// Interface - ZeroBlock (PoleZero based)

void* ZeroBlock_Constructor()
{
	PoleZero* self = new PoleZero;
	return (void*)self;
}

void ZeroBlock_Destructor(ursObject* gself)
{
	PoleZero* self = (PoleZero*)gself->objectdata;
	delete (PoleZero*)self;
}

double ZeroBlock_Tick(ursObject* gself)
{
	PoleZero* self = (PoleZero*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double ZeroBlock_Out(ursObject* gself)
{
	PoleZero* self = (PoleZero*)gself->objectdata;
	return self->lastOut();
}

// NYI Needs split of parameters here. Excite and setFrequency
void ZeroBlock_In(ursObject* gself, double indata)
{
	PoleZero* self = (PoleZero*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}


// Interface - PRCRev

void* PRCRev_Constructor()
{
	PRCRev* self = new PRCRev();
	return (void*)self;
}

void PRCRev_Destructor(ursObject* gself)
{
	PRCRev* self = (PRCRev*)gself->objectdata;
	delete (PRCRev*)self;
}

double PRCRev_Tick(ursObject* gself)
{
	PRCRev* self = (PRCRev*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
//	return self->tick(gself->lastindata[0]);
}

double PRCRev_Out(ursObject* gself)
{
	PRCRev* self = (PRCRev*)gself->objectdata;
	return self->lastOut();
}

void PRCRev_In(ursObject* gself, double indata)
{
	PRCRev* self = (PRCRev*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void PRCRev_SetT60(ursObject* gself, double indata)
{
	PRCRev* self = (PRCRev*)gself->objectdata;
	self->setT60(norm2RevTime(indata));
}

// Interface - ReedTable

void* ReedTable_Constructor()
{
	ReedTable* self = new ReedTable();
	return (void*)self;
}

void ReedTable_Destructor(ursObject* gself)
{
	ReedTable* self = (ReedTable*)gself->objectdata;
	delete (ReedTable*)self;
}

double ReedTable_Tick(ursObject* gself)
{
	ReedTable* self = (ReedTable*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double ReedTable_Out(ursObject* gself)
{
	ReedTable* self = (ReedTable*)gself->objectdata;
	return self->lastOut();
}

void ReedTable_In(ursObject* gself, double indata)
{
	ReedTable* self = (ReedTable*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick(indata);
	gself->CallAllPushOuts(res);
}

void ReedTable_SetOffset(ursObject* gself, double indata)
{
	ReedTable* self = (ReedTable*)gself->objectdata;
	self->setOffset(indata);
}

void ReedTable_SetSlope(ursObject* gself, double indata)
{
	ReedTable* self = (ReedTable*)gself->objectdata;
	self->setSlope(indata);
}

// Interface - Rhodey

void* Rhodey_Constructor()
{
	Rhodey* self = new Rhodey();
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Rhodey_Destructor(ursObject* gself)
{
	Rhodey* self = (Rhodey*)gself->objectdata;
	delete (Rhodey*)self;
}

double Rhodey_Tick(ursObject* gself)
{
	Rhodey* self = (Rhodey*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Rhodey_Out(ursObject* gself)
{
	Rhodey* self = (Rhodey*)gself->objectdata;
	return self->lastOut();
}

void Rhodey_In(ursObject* gself, double indata)
{
	Rhodey* self = (Rhodey*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Rhodey_SetFrequency(ursObject* gself, double indata)
{
	Rhodey* self = (Rhodey*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

// Interface - Saxofony

void* Saxofony_Constructor()
{
	Saxofony* self = new Saxofony(22.0);
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Saxofony_Destructor(ursObject* gself)
{
	Saxofony* self = (Saxofony*)gself->objectdata;
	delete (Saxofony*)self;
}

double Saxofony_Tick(ursObject* gself)
{
	Saxofony* self = (Saxofony*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Saxofony_Out(ursObject* gself)
{
	Saxofony* self = (Saxofony*)gself->objectdata;
	return self->lastOut();
}

void Saxofony_In(ursObject* gself, double indata)
{
	Saxofony* self = (Saxofony*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI figure out how to blow the bottle
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Saxofony_SetFrequency(ursObject* gself, double indata)
{
	Saxofony* self = (Saxofony*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void Saxofony_SetBlowPosition(ursObject* gself, double indata)
{
	Saxofony* self = (Saxofony*)gself->objectdata;
	self->setBlowPosition(norm2PositiveLinear(indata));
}

/*// Interface - Shakers

void* Shakers_Constructor()
{
	Shakers* self = new Shakers();
	return (void*)self;
}

void Shakers_Destructor(ursObject* gself)
{
	Shakers* self = (Shakers*)gself->objectdata;
	delete (Shakers*)self;
}

double Shakers_Tick(ursObject* gself)
{
	Shakers* self = (Shakers*)gself->objectdata;
	
	return self->tick(gself->lastindata[0]);
}

double Shakers_Out(ursObject* gself)
{
	Shakers* self = (Shakers*)gself->objectdata;
	return self->lastOut();
}

void Shakers_In(ursObject* gself, double indata)
{
	Shakers* self = (Shakers*)gself->objectdata;
	gself->lastindata[0] =indata;
 double res = 0;
 res = self->tick();
 gself->CallAllPushOuts(res);
 }

void Shakers_SetFrequency(ursObject* gself, double indata)
{
	Shakers* self = (Shakers*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void Shakers_SetStickHardness(ursObject* gself, double indata)
{
	Shakers* self = (Shakers*)gself->objectdata;
	self->setStickHardness(indata);
}

void Shakers_SetStrikePosition(ursObject* gself, double indata)
{
	Shakers* self = (Shakers*)gself->objectdata;
	self->setStrikePosition(norm2PositiveLinear(indata));
}

void Shakers_SetPreset(ursObject* gself, double indata)
{
	Shakers* self = (Shakers*)gself->objectdata;
	self->setPreset(indata);
}*/

// Interface - Sitar

void* Sitar_Constructor()
{
	Sitar* self = new Sitar(22.0);
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Sitar_Destructor(ursObject* gself)
{
	Sitar* self = (Sitar*)gself->objectdata;
	delete (Sitar*)self;
}

double Sitar_Tick(ursObject* gself)
{
	Sitar* self = (Sitar*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Sitar_Out(ursObject* gself)
{
	Sitar* self = (Sitar*)gself->objectdata;
	return self->lastOut();
}

void Sitar_In(ursObject* gself, double indata)
{
	Sitar* self = (Sitar*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->pluck(indata);
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Sitar_SetFrequency(ursObject* gself, double indata)
{
	Sitar* self = (Sitar*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

// Interface - StifKarp

void* StifKarp_Constructor()
{
	StifKarp* self = new StifKarp(22.0);
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void StifKarp_Destructor(ursObject* gself)
{
	StifKarp* self = (StifKarp*)gself->objectdata;
	delete (StifKarp*)self;
}

double StifKarp_Tick(ursObject* gself)
{
	StifKarp* self = (StifKarp*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double StifKarp_Out(ursObject* gself)
{
	StifKarp* self = (StifKarp*)gself->objectdata;
	return self->lastOut();
}

void StifKarp_In(ursObject* gself, double indata)
{
	StifKarp* self = (StifKarp*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->pluck(indata);
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void StifKarp_SetFrequency(ursObject* gself, double indata)
{
	StifKarp* self = (StifKarp*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void StifKarp_SetStretch(ursObject* gself, double indata)
{
	StifKarp* self = (StifKarp*)gself->objectdata;
	self->setStretch(indata);
}

void StifKarp_SetPickupPosition(ursObject* gself, double indata)
{
	StifKarp* self = (StifKarp*)gself->objectdata;
	self->setPickupPosition(norm2PositiveLinear(indata));
}

void StifKarp_SetBaseLoopGain(ursObject* gself, double indata)
{
	StifKarp* self = (StifKarp*)gself->objectdata;
	self->setBaseLoopGain(indata);
}

// Interface - TubeBelle

void* TubeBell_Constructor()
{
	TubeBell* self = new TubeBell();
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void TubeBell_Destructor(ursObject* gself)
{
	TubeBell* self = (TubeBell*)gself->objectdata;
	delete (TubeBell*)self;
}

double TubeBell_Tick(ursObject* gself)
{
	TubeBell* self = (TubeBell*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double TubeBell_Out(ursObject* gself)
{
	TubeBell* self = (TubeBell*)gself->objectdata;
	return self->lastOut();
}

void TubeBell_In(ursObject* gself, double indata)
{
	TubeBell* self = (TubeBell*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->noteOn(440.0,indata); // NYI check if this makes sense
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void TubeBell_SetFrequency(ursObject* gself, double indata)
{
	TubeBell* self = (TubeBell*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

// Interface - VoicForm

void* VoicForm_Constructor()
{
	VoicForm* self = new VoicForm();
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void VoicForm_Destructor(ursObject* gself)
{
	VoicForm* self = (VoicForm*)gself->objectdata;
	delete (VoicForm*)self;
}

double VoicForm_Tick(ursObject* gself)
{
	VoicForm* self = (VoicForm*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double VoicForm_Out(ursObject* gself)
{
	VoicForm* self = (VoicForm*)gself->objectdata;
	return self->lastOut();
}

void VoicForm_In(ursObject* gself, double indata)
{
	VoicForm* self = (VoicForm*)gself->objectdata;
	gself->lastindata[0] =indata;
	self->noteOn(440.0,indata); // NYI check if this makes sense
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void VoicForm_SetFrequency(ursObject* gself, double indata)
{
	VoicForm* self = (VoicForm*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

void VoicForm_SetVoiced(ursObject* gself, double indata)
{
	VoicForm* self = (VoicForm*)gself->objectdata;
	self->setVoiced(indata);
}

void VoicForm_SetUnvoiced(ursObject* gself, double indata)
{
	VoicForm* self = (VoicForm*)gself->objectdata;
	self->setUnVoiced(indata);
}

void VoicForm_SetPitchSweepRate(ursObject* gself, double indata)
{
	VoicForm* self = (VoicForm*)gself->objectdata;
	self->setPitchSweepRate(indata);
}

// Interface - Whistle

void* Whistle_Constructor()
{
	Whistle* self = new Whistle();
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Whistle_Destructor(ursObject* gself)
{
	Whistle* self = (Whistle*)gself->objectdata;
	delete (Whistle*)self;
}

double Whistle_Tick(ursObject* gself)
{
	Whistle* self = (Whistle*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Whistle_Out(ursObject* gself)
{
	Whistle* self = (Whistle*)gself->objectdata;
	return self->lastOut();
}

void Whistle_In(ursObject* gself, double indata)
{
	Whistle* self = (Whistle*)gself->objectdata;
	gself->lastindata[0] =indata;
	// NYI check if this makes sense
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Whistle_SetFrequency(ursObject* gself, double indata)
{
	Whistle* self = (Whistle*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

// Interface - Wurley

void* Wurley_Constructor()
{
	Wurley* self = new Wurley();
	self->noteOn(440.0, 1.0);
	return (void*)self;
}

void Wurley_Destructor(ursObject* gself)
{
	Wurley* self = (Wurley*)gself->objectdata;
	delete (Wurley*)self;
}

double Wurley_Tick(ursObject* gself)
{
	Wurley* self = (Wurley*)gself->objectdata;
	
	gself->FeedAllPullIns(1); // This is decoupled so no forwarding, just pulling to propagate our natural rate

	return self->tick(gself->CallAllPullIns());
}

double Wurley_Out(ursObject* gself)
{
	Wurley* self = (Wurley*)gself->objectdata;
	return self->lastOut();
}

void Wurley_In(ursObject* gself, double indata)
{
	Wurley* self = (Wurley*)gself->objectdata;
	gself->lastindata[0] =indata;
	double res = 0;
	res = self->tick();
	gself->CallAllPushOuts(res);
}

void Wurley_SetFrequency(ursObject* gself, double indata)
{
	Wurley* self = (Wurley*)gself->objectdata;
	self->setFrequency(norm2Freq(indata));
}

// Interface - 








void urSTK_Setup()
{
	ursObject* object;

	object = new ursObject("Plucked", Plucked_Constructor, Plucked_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", Plucked_Tick, Plucked_Out, NULL);
	object->AddIn("In", "Generic", Plucked_In);
	object->AddIn("Freq", "Frequency", Plucked_SetFrequency);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("ADSR", ADSR_Constructor, ADSR_Destructor,5,1);
	object->AddOut("WaveForm", "TimeSeries", ADSR_Tick, ADSR_Out, NULL);
	object->AddIn("In", "Generic", ADSR_In);
	object->AddIn("Attack", "Rate", ADSR_SetAttack);
	object->AddIn("Decay", "Rate", ADSR_SetDecay);
	object->AddIn("Sustain", "Threshold", ADSR_SetSustain);
	object->AddIn("Release", "Rate", ADSR_SetRelease);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("Asymp", Asymp_Constructor, Asymp_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", Asymp_Tick, Asymp_Out, NULL);
	object->AddIn("In", "Generic", Asymp_In);
	object->AddIn("Tau", "Rate", Asymp_SetTau);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
#ifdef INCLUDE_COMPHEAVY_STKS
	object = new ursObject("BandedWG", BandedWG_Constructor, BandedWG_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", BandedWG_Tick, BandedWG_Out, NULL);
	object->AddIn("Pluck", "Generic", BandedWG_Pluck);
	object->AddIn("Freq", "Frequency", BandedWG_SetFrequency);
	object->AddIn("Pos", "Position", BandedWG_SetPosition);
	urmanipulatorobjectlist.Append(object);
#endif

#ifdef SAMPLEBASED_STKS
	object = new ursObject("BeeThree", BeeThree_Constructor, BeeThree_Destructor,1,1);
	object->AddOut("WaveForm", "TimeSeries", BeeThree_Tick, BeeThree_Out, NULL);
	object->AddIn("In", "Generic", BeeThree_In);
	urmanipulatorobjectlist.Append(object);
#endif
	
	object = new ursObject("BiQuad", BiQuad_Constructor, BiQuad_Destructor,5,1);
	object->AddOut("WaveForm", "TimeSeries", BiQuad_Tick, BiQuad_Out, NULL);
	object->AddIn("In", "Generic", BiQuad_In);
	object->AddIn("Reson", "Freq", BiQuad_SetResonance);
	object->AddIn("Q", "Q", BiQuad_SetQ);
	object->AddIn("Notch", "Freq", BiQuad_SetNotch);
	object->AddIn("NQ", "Q", BiQuad_SetNQ);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("Blit", Blit_Constructor, Blit_Destructor,4,1);
	object->AddOut("WaveForm", "TimeSeries", Blit_Tick, Blit_Out, NULL);
	object->AddIn("In", "Generic", Blit_In);
	object->AddIn("Freq", "Frequency", Blit_SetFrequency);
	object->AddIn("Phase", "Phase", Blit_SetPhase);
	object->AddIn("Harms", "Harmonics", Blit_SetHarmonics);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("BlitSaw", BlitSaw_Constructor, BlitSaw_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", BlitSaw_Tick, BlitSaw_Out, NULL);
	object->AddIn("In", "Generic", BlitSaw_In);
	object->AddIn("Freq", "Frequency", BlitSaw_SetFrequency);
	object->AddIn("Harms", "Harmonics", BlitSaw_SetHarmonics);
	urmanipulatorobjectlist.Append(object);

	object = new ursObject("BlitSq", BlitSquare_Constructor, BlitSquare_Destructor,4,1);
	object->AddOut("WaveForm", "TimeSeries", BlitSquare_Tick, BlitSquare_Out, NULL);
	object->AddIn("In", "Generic", BlitSquare_In);
	object->AddIn("Freq", "Frequency", BlitSquare_SetFrequency);
	object->AddIn("Phase", "Phase", BlitSquare_SetPhase);
	object->AddIn("Harms", "Harmonics", BlitSquare_SetHarmonics);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("BlowBotl", BlowBotl_Constructor, BlowBotl_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", BlowBotl_Tick, BlowBotl_Out, NULL);
	object->AddIn("In", "Generic", BlowBotl_In);
	object->AddIn("Freq", "Frequency", BlowBotl_SetFrequency);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("BlowHol", BlowHole_Constructor, BlowHole_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", BlowHole_Tick, BlowHole_Out, NULL);
	object->AddIn("In", "Generic", BlowHole_In);
	object->AddIn("Freq", "Frequency", BlowHole_SetFrequency);
	urmanipulatorobjectlist.Append(object);

	object = new ursObject("Bowed", Bowed_Constructor, Bowed_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", Bowed_Tick, Bowed_Out, NULL);
	object->AddIn("In", "Generic", Bowed_In);
	object->AddIn("Freq", "Frequency", Bowed_SetFrequency);
	object->AddIn("Vibrato", "Generic", Bowed_SetVibrato);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("BowTbl", BowTable_Constructor, BowTable_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", BowTable_Tick, BowTable_Out, NULL);
	object->AddIn("In", "Generic", BowTable_In);
	object->AddIn("Offset", "Generic", BowTable_SetOffset);
	object->AddIn("Slope", "Generic", BowTable_SetSlope);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);

	object = new ursObject("Brass", Brass_Constructor, Brass_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", Brass_Tick, Brass_Out, NULL);
	object->AddIn("In", "Generic", Brass_In);
	object->AddIn("Freq", "Frequency", Brass_SetFrequency);
	urmanipulatorobjectlist.Append(object);
	
#ifdef INCLUDE_COMPHEAVY_STKS
	object = new ursObject("Chorus", Chorus_Constructor, Chorus_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", Chorus_Tick, Chorus_Out, NULL);
	object->AddIn("In", "Generic", Chorus_In);
	object->AddIn("ModDepth", "Generic", Chorus_SetModDepth);
	object->AddIn("ModFreq", "Frequency", Chorus_SetModFrequency);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
#endif
	
	object = new ursObject("Clarinet", Clarinet_Constructor, Clarinet_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", Clarinet_Tick, Clarinet_Out, NULL);
	object->AddIn("In", "Generic", Clarinet_In);
	object->AddIn("Freq", "Frequency", Clarinet_SetFrequency);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("Delay", Delay_Constructor, Delay_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", Delay_Tick, Delay_Out, NULL);
	object->AddIn("In", "Generic", Delay_In);
	object->AddIn("Delay", "Time", Delay_SetDelay);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("DelayA", DelayA_Constructor, DelayA_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", DelayA_Tick, DelayA_Out, NULL);
	object->AddIn("In", "Generic", DelayA_In);
	object->AddIn("Delay", "Time", DelayA_SetDelay);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("DelayL", DelayL_Constructor, DelayL_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", DelayL_Tick, DelayL_Out, NULL);
	object->AddIn("In", "Generic", DelayL_In);
	object->AddIn("Delay", "Time", DelayL_SetDelay);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);

// NYI Skipping Drummer because sample based
	
	object = new ursObject("Echo", Echo_Constructor, Echo_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", Echo_Tick, Echo_Out, NULL);
	object->AddIn("In", "Generic", Echo_In);
	object->AddIn("Echo", "Time", Echo_SetDelay);
	object->AddIn("Mix", "Mix", Echo_SetEffectMix);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("Env", Envelope_Constructor, Envelope_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", Envelope_Tick, Envelope_Out, NULL);
	object->AddIn("In", "Generic", Envelope_In);
	object->AddIn("Time", "Time", Envelope_SetTime);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
// NYI FileLoop, sample based
// NYI FileRead, sample based
// NYI FileWrite, sample based	
// NYI FileWvIn, sample based	
// NYI FileWvOut, sample based
	
// NYI Fir, needs parameter split
	
	object = new ursObject("Flute", Flute_Constructor, Flute_Destructor,5,1);
	object->AddOut("WaveForm", "TimeSeries", Flute_Tick, Flute_Out, NULL);
	object->AddIn("In", "Generic", Flute_In);
	object->AddIn("Freq", "Frequency", Flute_SetFrequency);
	object->AddIn("JetRefl", "Generic", Flute_SetJetReflection);
	object->AddIn("EndRefl", "Generic", Flute_SetEndReflection);
	object->AddIn("JetDelay", "Time", Flute_SetJetDelay);
	urmanipulatorobjectlist.Append(object);
	
// NYI FM
	
	// NYI: FMVoices: sample based
#ifdef SAMPLEBASED_STKS
	object = new ursObject("FMVoices", FMVoices_Constructor, FMVoices_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", FMVoices_Tick, FMVoices_Out, NULL);
	object->AddIn("In", "Generic", FMVoices_In);
	object->AddIn("Freq", "Frequency", FMVoices_SetFrequency);
	urmanipulatorobjectlist.Append(object);
	
	
// NYI FormSwep, needs argument splitting again

// NYI Granulate, sample based	
	
	object = new ursObject("HevyMetl", HevyMetl_Constructor, HevyMetl_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", HevyMetl_Tick, HevyMetl_Out, NULL);
	object->AddIn("In", "Generic", HevyMetl_In);
	object->AddIn("Freq", "Frequency", HevyMetl_SetFrequency);
	object->AddIn("ModFreq", "Frequency", HevyMetl_SetModulationFrequency);
	object->AddIn("ModIdx", "Generic", HevyMetl_SetModulationDepth);
	urmanipulatorobjectlist.Append(object);
#endif
	
// NYI IIR
	
	object = new ursObject("JCRev", JCRev_Constructor, JCRev_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", JCRev_Tick, JCRev_Out, NULL);
	object->AddIn("In", "Generic", JCRev_In);
	object->AddIn("T60", "Time", JCRev_SetT60);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);

	object = new ursObject("JetTbl", JetTable_Constructor, JetTable_Destructor,1,1);
	object->AddOut("WaveForm", "TimeSeries", JetTable_Tick, JetTable_Out, NULL);
	object->AddIn("In", "Generic", JetTable_In);
	urmanipulatorobjectlist.Append(object);

#ifdef SAMPLEBASED_STKS	
	object = new ursObject("Mandolin", Mandolin_Constructor, Mandolin_Destructor,5,1);
	object->AddOut("WaveForm", "TimeSeries", Mandolin_Tick, Mandolin_Out, NULL);
	object->AddIn("In", "Generic", Mandolin_In);
	object->AddIn("Freq", "Frequency", Mandolin_SetFrequency);
	object->AddIn("Detune", "Generic", Mandolin_SetDetune);
	object->AddIn("Loop", "Gain", Mandolin_SetLoop);
	object->AddIn("Body", "Generic", Mandolin_SetBodySize);
	urmanipulatorobjectlist.Append(object);
	
// NYI Mesh2D
	
	object = new ursObject("ModalBar", ModalBar_Constructor, ModalBar_Destructor,5,1);
	object->AddOut("WaveForm", "TimeSeries", ModalBar_Tick, ModalBar_Out, NULL);
	object->AddIn("In", "Generic", ModalBar_In);
	object->AddIn("Freq", "Frequency", ModalBar_SetFrequency);
	object->AddIn("Hard", "Gain", ModalBar_SetStickHardness);
	object->AddIn("Pos", "Position", ModalBar_SetStrikePosition);
//	object->AddIn("Mod", "Generic", ModalBar_SetModulationDepth);
	object->AddIn("Preset", "Discrete", ModalBar_SetPreset);
	urmanipulatorobjectlist.Append(object);
#endif

	object = new ursObject("Mod", Modulate_Constructor, Modulate_Destructor,5,1);
	object->AddOut("WaveForm", "TimeSeries", Modulate_Tick, Modulate_Out, NULL);
//	object->AddIn("In", "Generic", Modulate_In);
	object->AddIn("VibRate", "Rate", Modulate_SetVibratoRate);
	object->AddIn("VibGain", "Gain", Modulate_SetVibratoGain);
	object->AddIn("RandGain", "Gain", Modulate_SetRandomGain);
	urmanipulatorobjectlist.Append(object);
	

#ifdef SAMPLEBASED_STKS	
	object = new ursObject("Moog", Moog_Constructor, Moog_Destructor,4,1);
	object->AddOut("WaveForm", "TimeSeries", Moog_Tick, Moog_Out, NULL);
	object->AddIn("In", "Generic", Moog_In);
	object->AddIn("Freq", "Frequency", Moog_SetFrequency);
	object->AddIn("ModFreq", "Frequency", Moog_SetModulationFrequency);
	object->AddIn("ModIdx", "Generic", Moog_SetModulationDepth);
	urmanipulatorobjectlist.Append(object);
#endif

	object = new ursObject("NRev", NRev_Constructor, NRev_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", NRev_Tick, NRev_Out, NULL);
	object->AddIn("In", "Generic", NRev_In);
	object->AddIn("T60", "Time", NRev_SetT60);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("OnePole", OnePole_Constructor, OnePole_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", OnePole_Tick, OnePole_Out, NULL);
	object->AddIn("In", "Generic", OnePole_In);
	object->AddIn("Reson", "Frequency", OnePole_SetResonance);
//	object->AddIn("Q", "Q", OnePole_SetQ);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("OneZero", OneZero_Constructor, OneZero_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", OneZero_Tick, OneZero_Out, NULL);
	object->AddIn("In", "Generic", OneZero_In);
	object->AddIn("Notch", "Frequency", OneZero_SetNotch);
//	object->AddIn("B1", "Generic", OneZero_SetB1);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
#ifdef SAMPLEBASED_STKS	
	object = new ursObject("PercFlut", PercFlut_Constructor, PercFlut_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", PercFlut_Tick, PercFlut_Out, NULL);
	object->AddIn("In", "Generic", PercFlut_In);
	object->AddIn("Frequency", "Frequency", PercFlut_SetFrequency);
	urmanipulatorobjectlist.Append(object);
#endif
	
// NYI Phonemes, needs multiple through handling

	object = new ursObject("PitShift", PitShift_Constructor, PitShift_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", PitShift_Tick, PitShift_Out, NULL);
	object->AddIn("In", "Generic", PitShift_In);
	object->AddIn("Shift", "Generic", PitShift_SetShift);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("AllPass", AllPass_Constructor, AllPass_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", AllPass_Tick, AllPass_Out, NULL);
	object->AddIn("In", "Generic", AllPass_In);
	object->AddIn("Coeff", "Generic", AllPass_SetAllpass);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("ZeroBlk", ZeroBlock_Constructor, ZeroBlock_Destructor,1,1);
	object->AddOut("WaveForm", "TimeSeries", ZeroBlock_Tick, ZeroBlock_Out, NULL);
	object->AddIn("In", "Generic", ZeroBlock_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("PRCRev", PRCRev_Constructor, PRCRev_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", PRCRev_Tick, PRCRev_Out, NULL);
	object->AddIn("In", "Generic", PRCRev_In);
	object->AddIn("T60", "Time", PRCRev_SetT60);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("ReedTbl", ReedTable_Constructor, ReedTable_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", ReedTable_Tick, ReedTable_Out, NULL);
	object->AddIn("In", "Generic", ReedTable_In);
	object->AddIn("Offset", "Generic", ReedTable_SetOffset);
	object->AddIn("Slope", "Generic", ReedTable_SetSlope);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
// NYI Resonate, has mixed params

#ifdef SAMPLEBASED_STKS	
	object = new ursObject("Rhodey", Rhodey_Constructor, Rhodey_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", Rhodey_Tick, Rhodey_Out, NULL);
	object->AddIn("In", "Generic", Rhodey_In);
	object->AddIn("Freq", "Frequency", Rhodey_SetFrequency);
	urmanipulatorobjectlist.Append(object);
#endif
	
// NYI Sampler, sample based

	object = new ursObject("Saxofony", Saxofony_Constructor, Saxofony_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", Saxofony_Tick, Saxofony_Out, NULL);
	object->AddIn("In", "Generic", Saxofony_In);
	object->AddIn("Freq", "Frequency", Saxofony_SetFrequency);
	object->AddIn("Pos", "Position", Saxofony_SetBlowPosition);
	urmanipulatorobjectlist.Append(object);
	
/*	object = new ursObject("Shakers", Shakers_Constructor, Shakers_Destructor,5,1);
	object->AddOut("WaveForm", "TimeSeries", Shakers_Tick, Shakers_Out, NULL);
	object->AddIn("In", "Generic", Shakers_In);
	object->AddIn("Frequency", "Frequency", Shakers_SetFrequency);
	object->AddIn("Hard", "Gain", Shakers_SetStickHardness);
	object->AddIn("Pos", "Position", Shakers_SetStrikePosition);
	//	object->AddIn("Mod", "Generic", Shakers_SetModulationDepth);
	object->AddIn("Preset", "Discrete", Shakers_SetPreset);
	urmanipulatorobjectlist.Append(object);*/
	
	// NYI Shakers: Again a split case... probably one per shaker :P
	// NYI Simple: Sample based
	
	// NYI SineWave: Redundancy with our SinOsc

	// NYI SingWave: Sample based
	
	object = new ursObject("Sitar", Sitar_Constructor, Sitar_Destructor,3,1);
	object->AddOut("WaveForm", "TimeSeries", Sitar_Tick, Sitar_Out, NULL);
	object->AddIn("In", "Generic", Sitar_In);
	object->AddIn("Freq", "Frequency", Sitar_SetFrequency);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("StifKarp", StifKarp_Constructor, StifKarp_Destructor,5,1);
	object->AddOut("WaveForm", "TimeSeries", StifKarp_Tick, StifKarp_Out, NULL);
	object->AddIn("In", "Generic", StifKarp_In);
	object->AddIn("Freq", "Frequency", StifKarp_SetFrequency);
	object->AddIn("Stretch", "Generic", StifKarp_SetStretch);
	object->AddIn("Pos", "Position", StifKarp_SetPickupPosition);
	object->AddIn("Loop", "Gain", StifKarp_SetBaseLoopGain);
	urmanipulatorobjectlist.Append(object);
	
	// NYI TapDelay: Is cool but needs splitting

#ifdef SAMPLEBASED_STKS	
	object = new ursObject("TubeBell", TubeBell_Constructor, TubeBell_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", TubeBell_Tick, TubeBell_Out, NULL);
	object->AddIn("In", "Generic", TubeBell_In);
	object->AddIn("Freq", "Frequency", TubeBell_SetFrequency);
	urmanipulatorobjectlist.Append(object);
	
	// NYI skipping twopole (see BiQuad) and TwoZero (may come later for now)

	object = new ursObject("VoicForm", VoicForm_Constructor, VoicForm_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", VoicForm_Tick, VoicForm_Out, NULL);
	object->AddIn("In", "Generic", VoicForm_In);
	object->AddIn("Freq", "Frequency", VoicForm_SetFrequency);
	object->AddIn("Voiced", "Gain", VoicForm_SetVoiced);
	object->AddIn("Unvoiced", "Gain", VoicForm_SetUnvoiced);
	object->AddIn("Sweep", "Rate", VoicForm_SetPitchSweepRate);
	urmanipulatorobjectlist.Append(object);
#endif
	
#ifdef INCLUDE_COMPHEAVY_STKS
	object = new ursObject("Whistle", Whistle_Constructor, Whistle_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", Whistle_Tick, Whistle_Out, NULL);
	object->AddIn("In", "Generic", Whistle_In);
	object->AddIn("Freq", "Frequency", Whistle_SetFrequency);
	urmanipulatorobjectlist.Append(object);
#endif
	
#ifdef SAMPLEBASED_STKS	
	object = new ursObject("Wurley", Wurley_Constructor, Wurley_Destructor,2,1);
	object->AddOut("WaveForm", "TimeSeries", Wurley_Tick, Wurley_Out, NULL);
	object->AddIn("In", "Generic", Wurley_In);
	object->AddIn("Freq", "Frequency", Wurley_SetFrequency);
	urmanipulatorobjectlist.Append(object);
#endif
	
	// NYI WvIn and WvOut: sample based
	
	// Sources
	
//	object = new ursObject("Noise", Noise_Constructor, Noise_Destructor,0,1);
//	object->AddOut("Out", "TimeSeries", Noise_Tick, Noise_Out, NULL);
//	ursourceobjectlist.Append(object);


}



