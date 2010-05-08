/*
 *  urAPI.h
 *  urMus
 *
 *  Created by Georg Essl on 6/20/09.
 *  Copyright 2009 Georg Essl. All rights reserved. See LICENSE.txt for license details.
 *
 */
#ifndef __URAPI_H__
#define __URAPI_H__
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "urSound.h"

#import "Texture2d.h"

#undef SANDWICH_SUPPORT

#define BLEND_DISABLED 0
#define BLEND_BLEND 1
#define BLEND_ALPHAKEY 2
#define BLEND_ADD 3
#define BLEND_MOD 4
#define BLEND_SUB 5

#define JUSTIFYH_CENTER 0
#define JUSTIFYH_LEFT 1
#define JUSTIFYH_RIGHT 2

#define JUSTIFYV_MIDDLE 0
#define JUSTIFYV_TOP 1
#define JUSTIFYV_BOTTOM 2

#define WRAP_WORD 0
#define WRAP_CHAR 1
#define WRAP_CLIP 2

extern char TEXTURE_SOLID[];

extern lua_State *lua;

// TextLabel user data
typedef struct urAPI_TextLabel
{
	char* text;
	const char* font;
	int	justifyh;
	int justifyv;
	float shadowcolor[4];
	float shadowoffset[2];
	float shadowblur;
	bool drawshadow;
	float linespacing;
	float textcolor[4];
	float textheight;
	float stringheight;
	float stringwidth;
	int wrap;
	bool updatestring;
	
	// Private
	Texture2D		*textlabelTex;
} urAPI_TextLabel_t;

typedef struct urAPI_Region urAPI_Region_t;

// Texture user data
typedef struct urAPI_Texture
	{
		int blendmode;
		float texcoords[8];
		char* texturepath;
		bool modifyRect;
		bool isDesaturated;
		bool fill;
		float gradientUL[4]; // RGBA
		float gradientUR[4]; // RGBA
		float gradientBL[4]; // RGB for 4 corner color magic
		float gradientBR[4]; // RGB for 4 corner color magic		
		float texturesolidcolor[4]; // for solid
		float texturebrushcolor[4]; // for brushes
		// Private
		Texture2D	*backgroundTex;
		urAPI_Region_t *region;
	} urAPI_Texture_t;

// FlowBox user data

typedef struct ursAPI_FlowBox
	{
		int tableref; // table reference which contains this flowbox
		ursObject* object;
	} ursAPI_FlowBox_t;

// Region user data

typedef struct urAPI_Region
	{
		// internals
		struct urAPI_Region* prev; // Chained list of Regions
		struct urAPI_Region* next;
		// actual data
		struct urAPI_Region* parent;
		struct urAPI_Region* firstchild;
		struct urAPI_Region* nextchild;
		const char* name;
		const char* type;
		urAPI_Texture_t* texture;
		urAPI_TextLabel_t* textlabel;
		
		int tableref; // table reference which contains this Region
		
		bool isMovable;
		bool isResizable;
		bool isTouchEnabled;
		bool isScrollXEnabled;
		bool isScrollYEnabled;
		bool isVisible;
		bool isShown;
		bool isDragged;
		bool isResized;
		bool isClamped;
		bool isClipping;
		
		float cx;
		float cy;
		float top;
		float bottom;
		float left;
		float right;
		float width;
		float height;

		float clipleft;
		float clipbottom;
		float clipwidth;
		float clipheight;
		
		float alpha;
		
		struct urAPI_Region* relativeRegion;
		char* relativePoint;
		char* point;
		lua_Number ofsx;
		lua_Number ofsy;
		
		bool update;
		
		bool entered;
		
		int strata;
		
		int OnDragStart;
		int OnDragStop;
		int OnEnter;
		int OnEvent;
		int OnHide;
		int OnLeave;
		int OnTouchDown;
		int OnTouchUp;
		int OnShow;
		int OnSizeChanged; // needs args (NYI)
		int OnUpdate;
		int OnDoubleTap; // (UR!)
		// All UR!
		int OnAccelerate;
		int OnNetIn;
#ifdef SANDWICH_SUPPORT
		int OnPressure;
#endif
		int OnHeading;
		int OnLocation;
		int OnMicrophone;
		int OnHorizontalScroll;
		int OnVerticalScroll;
		int OnPageEntered;
		int OnPageLeft;
		
	}urAPI_Region_t;

/*static int l_setanimspeed(lua_State *lua);
static int l_Region(lua_State *lua);*/

void l_setupAPI(lua_State *lua);
void l_setstrataindex(urAPI_Region_t* region , int strataindex);
bool callScript(int func_ref, urAPI_Region_t* region);
urAPI_Region_t* findRegionDraggable(float x, float y);
urAPI_Region_t* findRegionHit(float x, float y);
urAPI_Region_t* findRegionXScrolled(float x, float y, float dx);
urAPI_Region_t* findRegionYScrolled(float x, float y, float dy);
bool callAllOnUpdate(float time);
bool callAllOnAccelerate(float x, float y, float z);
bool callAllOnNetIn(float a);
#ifdef SANDWICH_SUPPORT
bool callAllOnPressure(float p);
#endif
bool callAllOnHeading(float x, float y, float z, float north);
bool callAllOnLocation(float latitude, float longitude);
bool callAllOnMicrophone(SInt16* mic_buffer, UInt32 bufferlen);
void callAllOnLeaveRegions(float x, float y);
void callAllOnEnterLeaveRegions(int nr, float* x, float* y, float* ox, float* oy);
bool callScriptWith4Args(int func_ref, urAPI_Region_t* region ,float a, float b, float c, float d);
bool callScriptWith3Args(int func_ref, urAPI_Region_t* region ,float a, float b, float c);
bool callScriptWith2Args(int func_ref, urAPI_Region_t* region ,float a, float b);
bool callScriptWith1Args(int func_ref, urAPI_Region_t* region ,float a);
bool callScriptWith1Global(int func_ref, urAPI_Region_t* region, const char* globaldata);

void addChild(urAPI_Region_t *parent, urAPI_Region_t *child);
void removeChild(urAPI_Region_t *parent, urAPI_Region_t *child);
bool layout(urAPI_Region_t* region);

void ur_GetSoundBuffer(SInt16* buffer, int channel, int size);


#endif /* __URAPI_H__ */

