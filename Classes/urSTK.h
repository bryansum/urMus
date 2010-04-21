/*
 *  urSTK.h
 *  urMus
 *
 *  Created by gessl on 10/16/09.
 *  Copyright 2009 Georg Essl. All rights reserved.
 *
 */

#ifndef __URSTK_H__
#define __URSTK_H__

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

using namespace stk;

void urSTK_Setup();

struct BiQuad_Data
{
	double reson;
	double q;
	double notch;
	double nq;
	BiQuad* stkobject;
	BiQuad_Data() { reson = 0.2; q = 0.995; notch = 0; nq = 0.995; }
};

struct OnePole_Data
{
	double reson;
//	double q;
	OnePole* stkobject;
	OnePole_Data() { reson = 0.2; /*q = 0.995;*/ }
};

struct OneZero_Data
{
	double notch;
//	double nq;
	OneZero* stkobject;
	OneZero_Data() { notch = 0; /*nq = 0.995;*/ }
};



#endif /* __URSTK_H__ */