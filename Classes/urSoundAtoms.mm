/*
 *  urSoundAtoms.mm
 *  urMus
 *
 *  Created by gessl on 10/30/09.
 *  Copyright 2009 Georg Essl. All rights reserved. See LICENSE.txt for license conditions.
 *
 */



#include "urSoundAtoms.h"
#include "urSound.h"


#define sgn(norm) (norm<0.0?-1.0:1.0)

// This converts a normed value to a frequency range. This is a continuous form of octave (just/natural) temperment. Center of gravity is 55.0 @ 0 normed.
double norm2Freq(double norm)
{
	return 55.0*pow(2.0,96*norm/12.0);
}

// This converts a normed value into a canonical reverberation time. We range it to up to 4 seconds. 150ms minimum.
double norm2RevTime(double norm)
{
	return (norm+1.0)*2.0+0.15;
}

// Same as above but taking time in samples
double norm2RevSamples(double norm, double SR)
{
	return norm2RevTime(norm)*SR;
}

// This converts a normed value into something that is a sensible FM modulation index (0-12)
double norm2ModIndex(double norm)
{
	return (norm+1.0)*6.0;
}

// This is a normed value to pitchshift. Allowing a range of 0-2. We offset by 1.0 to make 0 be neutral (no pitch change). Quadratic relationship.
double norm2PitchShift(double norm)
{
	return (norm+1.0)*(norm+1.0);
}

// This clips over-reaching arguments.
double capNorm(double norm)
{
	if(norm<-1.0) return -1.0;
	if(norm>1.0) return 1.0;
	return norm;
}

#define modNorm(norm) (norm%1.0)

// This is rising slope only polynomial, it will be more edgy with increased order n
inline double oddPolySlope(double norm, int n)
{
	return capNorm(2.0*pow(norm,n)-1);
}

// This is the normed n-th order polynomial. For odd this this covers the full range
inline double oddPolyOriented(double norm, int n)
{
	return pow(norm,n);
}

// This is the normed n-th order polynomial. For evens this only covers half the range
inline double evenPolyOriented(double norm, int n)
{
	return pow(norm,n);
}

// This is a full ranged smooth n-th order polynomial, with a minimum of -1 at 0. Covers full range.
inline double evenPolyFull(double norm, int n)
{
	return 2.0*pow(norm,n)-1.0;
}

// This is a center-symmetric upward wedge. Maximum of 1 at 0. Sides at 0. Covers half range. /\

inline double norm2UpWedge(double norm)
{
	return 1.0-fabs(norm);
}

// This is a center-symmetric upward wedge. Maximum of 1 at 0. Sides at -1. Covers full range. /\

inline double norm2FullUpWedge(double norm)
{
	return 1.0-2.0*fabs(norm);
}

// This is a center-symmetric down wedge. Minimum of 0 at 0. Sides at 1. Covers half range. \/

inline double norm2DownWedge(double norm)
{
	return fabs(norm);
}

// This is a center-symmetric down wedge. Minimum of -1 at 0. Sides at 1. Covers full range. \/
double norm2FullDownWedge(double norm)
{
	return 2.0*fabs(norm)-1.0;
}

// This is a shifted linear function. It has max/min of 1/-1 at 0 and 0 at the sides. //
inline double norm2CenterJump(double norm)
{
	return norm-sgn(norm);
}

// This returns a normed square from a linear function via sgn. _-
inline double norm2Square(double norm)
{
	return sgn(norm);
}

// This gates positives values
inline double gatePositives(double norm)
{
	return norm>0.0?norm:0.0;
}

// This gates negative values
inline double gateNegatives(double norm)
{
	return norm<0.0?norm:-0.0;
}

// This make a positive linear functions from a normed one. Slope becomes half as steep (0.5).
double norm2PositiveLinear(double norm)
{
	return norm/2.0+0.5;
}

inline double norm2NegativeLinear(double norm)
{
	return norm/2.0-0.5;
}



double Nope_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
/*	if(gself->firstpullin[0]!=NULL)
	{
		ursObject* outobject;
		//		Nope_In(gself);
		urSoundPullIn* pullfrom = gself->firstpullin[0];
		for(; pullfrom != NULL; pullfrom = pullfrom->next)
		{	
			urSoundOut* out = pullfrom->out;
			outobject = out->object;
			res = res + out->outFuncTick(outobject);
		}
	}*/
	res += gself->CallAllPullIns();
	return res;
}

double Nope_Out(ursObject* gself)
{
	return gself->CallAllPullIns();
	//	return gself->lastindata[0];
}


void Nope_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(in);
	/*	gself->lastindata[0] = in;
	 double res = 0;
	 res = Nope_Tick(gself);
	 gself->CallAllPushOuts(res);*/
}

double Inv_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return -res;
}

double Inv_Out(ursObject* gself)
{
	return -gself->CallAllPullIns();
}


void Inv_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(-in);
}

double V_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return norm2DownWedge(res);
}

double V_Out(ursObject* gself)
{
	return norm2DownWedge(gself->CallAllPullIns());
}


void V_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(norm2DownWedge(in));
}

double FullV_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return norm2FullDownWedge(res);
}

double FullV_Out(ursObject* gself)
{
	return norm2FullDownWedge(gself->CallAllPullIns());
}


void FullV_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(norm2FullDownWedge(in));
}

double DV_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return norm2UpWedge(res);
}

double DV_Out(ursObject* gself)
{
	return norm2UpWedge(gself->CallAllPullIns());
}


void DV_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(norm2UpWedge(in));
}

double FullDV_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return norm2FullUpWedge(res);
}

double FullDV_Out(ursObject* gself)
{
	return norm2FullUpWedge(gself->CallAllPullIns());
}


void FullDV_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(norm2FullUpWedge(in));
}

double CJ_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return norm2CenterJump(res);
}

double CJ_Out(ursObject* gself)
{
	return norm2CenterJump(gself->CallAllPullIns());
}


void CJ_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(norm2CenterJump(in));
}

double SQ_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return norm2Square(res);
}

double SQ_Out(ursObject* gself)
{
	return norm2Square(gself->CallAllPullIns());
}


void SQ_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(norm2Square(in));
}

double PGate_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return gatePositives(res);
}

double PGate_Out(ursObject* gself)
{
	return gatePositives(gself->CallAllPullIns());
}


void PGate_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(gatePositives(in));
}

double NGate_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return gateNegatives(res);
}

double NGate_Out(ursObject* gself)
{
	return gateNegatives(gself->CallAllPullIns());
}


void NGate_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(gateNegatives(in));
}

double Pos_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return norm2PositiveLinear(res);
}

double Pos_Out(ursObject* gself)
{
	return norm2PositiveLinear(gself->CallAllPullIns());
}


void Pos_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(norm2PositiveLinear(in));
}

double Neg_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return norm2NegativeLinear(res);
}

double Neg_Out(ursObject* gself)
{
	return norm2NegativeLinear(gself->CallAllPullIns());
}


void Neg_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(norm2NegativeLinear(in));
}

double ZPulse_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	if(sgn(gself->lastindata[0]) != sgn(res))
		return 1.0;
	else
		return 0.0;
}

double ZPulse_Out(ursObject* gself)
{
	return 0.0; //norm2NegativeLinear(gself->CallAllPullIns());
}


void ZPulse_In(ursObject* gself, double in)
{
	float out = 0.0;
	if(sgn(in) != sgn(gself->lastindata[0]))
		out = 1.0;
	gself->lastindata[0] = in;
	
	gself->CallAllPushOuts(out);
}

double Hold_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return res;
}

double Hold_Out(ursObject* gself)
{
	return gself->lastindata[0]; //norm2NegativeLinear(gself->CallAllPullIns());
}


void Hold_In(ursObject* gself, double in)
{
	gself->lastindata[0] = in;
	
	gself->CallAllPushOuts(in);
}

static float lastslp;
double SLP_Tick(ursObject* gself)
{
	double res;
	
	res = (gself->CallAllPullIns()+lastslp)/2.0;
	lastslp = res;
	return res;
}

double SLP_Out(ursObject* gself)
{
	return gself->lastindata[0]; //norm2NegativeLinear(gself->CallAllPullIns());
}


void SLP_In(ursObject* gself, double in)
{
	gself->lastindata[0] = in;
	
	gself->CallAllPushOuts((in+lastslp)/2.0);
	lastslp = (in+lastslp)/2.0;
}

double PosSqr_Tick(ursObject* gself)
{
	double res;
	res = gself->lastindata[0];
	
	res += gself->CallAllPullIns();
	return evenPolyOriented(res,2);
}

double PosSqr_Out(ursObject* gself)
{
	
	return evenPolyOriented(gself->CallAllPullIns(),2);
}


void PosSqr_In(ursObject* gself, double in)
{
	gself->CallAllPushOuts(evenPolyOriented(in,2));
}



void urSoundAtoms_Setup()
{
	ursObject* object;
	
	object = new ursObject("Nope", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", Nope_Out, Nope_Tick, NULL);
	object->AddIn("In", "Generic", Nope_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);

	object = new ursObject("Inv", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", Inv_Out, Inv_Tick, NULL);
	object->AddIn("In", "Generic", Inv_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("V", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", V_Out, V_Tick, NULL);
	object->AddIn("In", "Generic", V_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("FullV", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", FullV_Out, FullV_Tick, NULL);
	object->AddIn("In", "Generic", FullV_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("DV", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", DV_Out, DV_Tick, NULL);
	object->AddIn("In", "Generic", DV_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("FullDV", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", FullDV_Out, FullDV_Tick, NULL);
	object->AddIn("In", "Generic", FullDV_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("CJ", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", CJ_Out, CJ_Tick, NULL);
	object->AddIn("In", "Generic", CJ_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("SQ", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", SQ_Out, SQ_Tick, NULL);
	object->AddIn("In", "Generic", SQ_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("PGate", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", PGate_Out, PGate_Tick, NULL);
	object->AddIn("In", "Generic", PGate_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("NGate", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", NGate_Out, NGate_Tick, NULL);
	object->AddIn("In", "Generic", NGate_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("Pos", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", Pos_Out, Pos_Tick, NULL);
	object->AddIn("In", "Generic", Pos_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("Neg", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", Neg_Out, Neg_Tick, NULL);
	object->AddIn("In", "Generic", Neg_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);

	object = new ursObject("ZPuls", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", ZPulse_Tick, ZPulse_Out, NULL);
	object->AddIn("In", "Generic", ZPulse_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);

	object = new ursObject("Hold", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", Hold_Tick, Hold_Out, NULL);
	object->AddIn("In", "Generic", Hold_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("SLP", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", SLP_Tick, SLP_Out, NULL);
	object->AddIn("In", "Generic", SLP_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
	
	object = new ursObject("PosSqr", NULL, NULL,1,1);
	object->AddOut("Out", "Generic", PosSqr_Tick, PosSqr_Out, NULL);
	object->AddIn("In", "Generic", PosSqr_In);
	object->SetCouple(0,0);
	urmanipulatorobjectlist.Append(object);
}

