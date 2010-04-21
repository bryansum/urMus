/*
 *  urSoundAtoms.h
 *  urMus
 *
 *  Created by gessl on 10/30/09.
 *  Copyright 2009 Georg Essl. All rights reserved.
 *
 */
#ifndef __URSOUNDATOMS_H__
#define __URSOUNDATOMS_H__

double capNorm(double norm);

double oddPolySlope(double norm, int n);
double oddPolyOriented(double norm, int n);
double evenPolyOriented(double norm, int n);
double evenPolyFull(double norm, int n);
double norm2UpWedge(double norm);
double norm2FullUpWedge(double norm);
double norm2DownWedge(double norm);
double norm2FullDownWedge(double norm);
double norm2CenterJump(double norm);
double norm2Square(double norm);
double gatePositives(double norm);
double gateNegatives(double norm);
double norm2PositiveLinear(double norm);
double norm2NegativeLinear(double norm);

void urSoundAtoms_Setup();

#endif /* __URSOUNDATOMS_H__ */
