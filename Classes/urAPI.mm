/*
 *  urAPI.c
 *  urMus
 *
 *  Created by Georg Essl on 6/20/09.
 *  Copyright 2009 Georg Essl. All rights reserved. See LICENSE.txt for license details.
 *
 */

#include "urAPI.h"
#import "EAGLView.h"
#import "MachTimer.h"
#include "RIOAudioUnitLayer.h"
#include "urSound.h"
#include "httpServer.h"

// Make EAGLview global so lua interface can grab it without breaking a leg over IMP
extern EAGLView* g_glView;
// This is to transport error and print messages to EAGLview
extern NSString * errorstr;
extern bool newerror;

// Global lua state
lua_State *lua;

// Region based API below, this is inspired by WoW's frame API with many modifications and expansions.
// Our engine supports paging, region horizontal and vertical scrolling, full multi-touch and more.

// Hardcoded for now... lazy me
#define MAX_PAGES 30

int currentPage;
urAPI_Region_t* firstRegion[MAX_PAGES] = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil};
urAPI_Region_t* lastRegion[MAX_PAGES] = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil};
int numRegions[MAX_PAGES] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

urAPI_Region_t* UIParent = nil;

ursAPI_FlowBox_t* FBNope = nil;

MachTimer* systimer;

const char DEFAULT_RPOINT[] = "BOTTOMLEFT";

#define STRATA_PARENT 0
#define STRATA_BACKGROUND 1
#define STRATA_LOW 2
#define STRATA_MEDIUM 3
#define STRATA_HIGH 4
#define STRATA_DIALOG 5
#define STRATA_FULLSCREEN 6
#define STRATA_FULLSCREEN_DIALOG 7
#define STRATA_TOOLTIP 8

#define LAYER_BACKGROUND 1
#define LAYER_BORDER 2
#define LAYER_ARTWORK 3
#define LAYER_OVERLAY 4
#define LAYER_HIGHLIGHT 5

urAPI_Region_t* findRegionHit(float x, float y)
{
	for(urAPI_Region_t* t=lastRegion[currentPage]; t != nil /* && t != firstRegion[currentPage] */; t=t->prev)
	{
		if(x >= t->left && x <= t->left+t->width &&
		   y >= t->bottom && y <= t->bottom+t->height && t->isTouchEnabled)
			if(t->isClipping==false || (x >= t->clipleft && x <= t->clipleft+t->clipwidth &&
										y >= t->clipbottom && y <= t->clipbottom+t->clipheight))
				return t;
	}
	return nil;
}

void callAllOnLeaveRegions(float x, float y)
{
	for(urAPI_Region_t* t=lastRegion[currentPage]; t != nil ; t=t->prev)
	{
		if(x >= t->left && x <= t->left+t->width &&
			 y >= t->bottom && y <= t->bottom+t->height
		   && t->OnLeave != 0)
			if(t->isClipping==false || (x >= t->clipleft && x <= t->clipleft+t->clipwidth &&
								  y >= t->clipbottom && y <= t->clipbottom+t->clipheight))
			{
				t->entered = false;
				callScript(t->OnLeave, t);
			}
	}
}

void callAllOnEnterLeaveRegions(int nr, float* x, float* y, float* ox, float* oy)
{
	bool didenter;
	for(urAPI_Region_t* t=lastRegion[currentPage]; t != nil /* && t != firstRegion[currentPage] */; t=t->prev)
	{
		for(int i=0; i<nr; i++)
		{
			if(!(x[i] >= t->left && x[i] <= t->left+t->width &&
			   y[i] >= t->bottom && y[i] <= t->bottom+t->height) && 
			   ox[i] >= t->left && ox[i] <= t->left+t->width &&
				 oy[i] >= t->bottom && oy[i] <= t->bottom+t->height			   
			   && t->OnLeave != 0)
			{
//				if(t->entered)
//				{
					t->entered = false;
					callScript(t->OnLeave, t);
//				}
//				else
//				{
//					int a=0;
//				}
			}
			else if(x[i] >= t->left && x[i] <= t->left+t->width &&
			   y[i] >= t->bottom && y[i] <= t->bottom+t->height &&
			   (!(ox[i] >= t->left && ox[i] <= t->left+t->width &&
			   oy[i] >= t->bottom && oy[i] <= t->bottom+t->height) || !t->entered)			   
			   && t->OnEnter != 0)
			{
//				didenter = true;
//				if(!t->entered)
//				{
					t->entered = true;
					callScript(t->OnEnter, t);
//				}
//				else
//				{
//					int a=0;
//				}
			}
		}
//		if(t->entered && !didenter)
//		{
//			t->entered = false;
//			callScript(t->OnLeave, t);
//		}
//		didenter = false;
	}
}

urAPI_Region_t* findRegionDraggable(float x, float y)
{
	for(urAPI_Region_t* t=lastRegion[currentPage]; t != nil /* && t != firstRegion[currentPage]*/; t=t->prev)
	{
		if(x >= t->left && x <= t->left+t->width &&
		   y >= t->bottom && y <= t->bottom+t->height && t->isMovable && t->isTouchEnabled)
			if(t->isClipping==false || (x >= t->clipleft && x <= t->clipleft+t->clipwidth &&
								  y >= t->clipbottom && y <= t->clipbottom+t->clipheight))
				return t;
	}
	return nil;
}

urAPI_Region_t* findRegionXScrolled(float x, float y, float dx)
{
	if(fabs(dx) > 0.9)
	{
		for(urAPI_Region_t* t=lastRegion[currentPage]; t != nil /* && t != firstRegion[currentPage]*/; t=t->prev)
		{
			if(x >= t->left && x <= t->left+t->width &&
			   y >= t->bottom && y <= t->bottom+t->height && t->isScrollXEnabled && t->isTouchEnabled)
				if(t->isClipping==false || (x >= t->clipleft && x <= t->clipleft+t->clipwidth &&
									  y >= t->clipbottom && y <= t->clipbottom+t->clipheight))
				return t;
		}
	}
	return nil;
}

urAPI_Region_t* findRegionYScrolled(float x, float y, float dy)
{
	if(fabs(dy) > 0.9*3)
	{
		for(urAPI_Region_t* t=lastRegion[currentPage]; t != nil /* && t != firstRegion[currentPage]*/; t=t->prev)
		{
			if(x >= t->left && x <= t->left+t->width &&
			   y >= t->bottom && y <= t->bottom+t->height && t->isScrollYEnabled && t->isTouchEnabled)
				if(t->isClipping==false || (x >= t->clipleft && x <= t->clipleft+t->clipwidth &&
									  y >= t->clipbottom && y <= t->clipbottom+t->clipheight))
				return t;
		}
	}
	return nil;
}


void layoutchildren(urAPI_Region_t* region)
{
	urAPI_Region_t* child = region->firstchild;
	while(child!=NULL)
	{
		child->update = true;
		layout(child);
		child = child->nextchild;
	}
}

bool visibleparent(urAPI_Region_t* region)
{
	if(region == UIParent)
		return true;

	urAPI_Region_t* parent = region->parent;
	
	while(parent != UIParent && parent->isVisible == true)
	{
		parent = parent->parent;
	}
	
	if(parent == UIParent)
		return true;
	else
		return false;
}

void showchildren(urAPI_Region_t* region)
{
	urAPI_Region_t* child = region->firstchild;
	while(child!=NULL)
	{
		if(child->isShown)
		{
			child->isVisible = true;
			if(region->OnShow != 0)
				callScript(region->OnShow, region);
			showchildren(child);
		}
		child = child->nextchild;
	}
}

void hidechildren(urAPI_Region_t* region)
{
	urAPI_Region_t* child = region->firstchild;
	while(child!=NULL)
	{
		if(child->isVisible)
		{
			child->isVisible = false;
			if(region->OnHide != 0)
				callScript(region->OnHide, region);
			hidechildren(child);
		}
		child = child->nextchild;
	}
}

// This function is heavily informed by Jerry's base.lua in wowsim function, which is covered by a BSD-style (open) license.
// (EDIT) Fixed it up. Was buggy as is and didn't properly align for most anchor sides.

bool layout(urAPI_Region_t* region)
{
	if(region == nil) return false;
	
	bool update = region->update;

	if(!update)
	{
		if(region->relativeRegion)
			update = layout(region->relativeRegion);
		else
			update = layout(region->parent);
	}
		
	if(!update) return false;

	float left, right, top, bottom, width, height, cx, cy,x,y;

	left = right = top = bottom = width = height = cx = cy = x = y = -1000000;
	
	
	const char* point = region->point;
	if(point == nil)
		point = DEFAULT_RPOINT;
	
	urAPI_Region_t* relativeRegion = region->relativeRegion;
	if(relativeRegion == nil)
		relativeRegion = region->parent;
	if(relativeRegion == nil)
		relativeRegion = UIParent; // This should be another layer but we don't care for now

	const char* relativePoint = region->relativePoint;
	if(relativePoint == nil)
		relativePoint = DEFAULT_RPOINT;

	if(!strcmp(relativePoint, "ALL"))
	{
		left = relativeRegion->left;
		bottom = relativeRegion->bottom;
		width = relativeRegion->width;
		height = relativeRegion->height;
	}
	else if(!strcmp(relativePoint,"TOPLEFT"))
	{
		x = relativeRegion->left;
		y = relativeRegion->top;
	}
	else if(!strcmp(relativePoint,"TOPRIGHT"))
	{
		x = relativeRegion->right;
		y = relativeRegion->top;
	}
	else if(!strcmp(relativePoint,"TOP"))
	{
		x = relativeRegion->cx;
		y = relativeRegion->top;
	}
	else if(!strcmp(relativePoint,"LEFT"))
	{
		x = relativeRegion->left;
		y = relativeRegion->cy;
	}
	else if(!strcmp(relativePoint,"RIGHT"))
	{
		x = relativeRegion->right;
		y = relativeRegion->cy;
	}
	else if(!strcmp(relativePoint,"CENTER"))
	{
		x = relativeRegion->cx;
		y = relativeRegion->cy;
	}
	else if(!strcmp(relativePoint,"BOTTOMLEFT"))
	{
		x = relativeRegion->left;
		y = relativeRegion->bottom;
	}
	else if(!strcmp(relativePoint,"BOTTOMRIGHT"))
	{
		x = relativeRegion->right;
		y = relativeRegion->bottom;
	}
	else if(!strcmp(relativePoint,"BOTTOM"))
	{
		x = relativeRegion->cx;
		y = relativeRegion->bottom;
	}
	else
	{
		// Error!!
		luaL_error(lua, "Unknown relativePoint when layouting regions.");
		return false;
	}
	
	x = x+region->ofsx;
	y = y+region->ofsy;

	if(!strcmp(point,"TOPLEFT"))
	{
		left = x;
		top = y;
	}
	else if(!strcmp(point,"TOPRIGHT"))
	{
		right = x;
		top = y;
	}
	else if(!strcmp(point,"TOP"))
	{
		cx = x;
		top = y;
	}
	else if(!strcmp(point,"LEFT"))
	{
		left = x;
		cy = y; // Another typo here
	}
	else if(!strcmp(point,"RIGHT"))
	{
		right = x;
		cy = y;
	}
	else if(!strcmp(point,"CENTER"))
	{
		cx = x;
		cy = y;
	}
	else if(!strcmp(point,"BOTTOMLEFT"))
	{
		left = x;
		bottom = y;
	}
	else if(!strcmp(point,"BOTTOMRIGHT"))
	{
		right = x;
		bottom = y;
	}
	else if(!strcmp(point,"BOTTOM"))
	{
		cx = x;
		bottom = y;
	}
	else
	{
		// Error!!
		luaL_error(lua, "Unknown relativePoint when layouting regions.");
		return false;
	}
	
	if(left > 0 && right > 0)
	{
		width = right - left;
	}
	if(top > 0 && bottom > 0)
	{
		height = top - bottom;
	}
	
	if(width == -1000000 && region->width > 0) width = region->width;
	if(height == -1000000 && region->height > 0) height = region->height;
	
	if(left == -1000000 && width > 0)
	{
		if(right>0) left = right - width;
		else if(cx>0)
		{
			left = cx - width/2; // This was buggy. Fixing it up.
			right = cx + width/2;
		} 
	}
	if(bottom == -1000000 && height > 0)
	{
		if(top>0) bottom = top - height;
		if(cy>0) 
		{
			bottom = cy - height/2; // This was buggy. Fixing it up.
			top = cy + height/2;
		}
	}
	
	update = false;
	
	if(left != region->left || bottom != region->bottom || width != region->width || height != region->height)
		update = true;
	
	region->left = left;
	region->bottom = bottom;
	region->width = width;
	region->height = height;
	region->cx = left + width/2;
	region->cy = bottom + height/2;
	top = bottom + height; // All this was missing with bad effects
	region->top = top;
	right = left + width;
	region->right = right;
	
	region->update = false;
	
	if(update)
	{
		layoutchildren(region);
		// callScript("OnSizeChanged", width, height)
	}
	return update;
	
}


//------------------------------------------------------------------------------
// Our custom lua API
//------------------------------------------------------------------------------



static urAPI_Region_t *checkregion(lua_State *lua, int nr)
{
//	void *region = luaL_checkudata(lua, nr, "URAPI.region");
	luaL_checktype(lua, nr, LUA_TTABLE);
	lua_rawgeti(lua, nr, 0);
	void *region = lua_touserdata(lua, -1);
	lua_pop(lua,1);
	luaL_argcheck(lua, region!= NULL, nr, "'region' expected");
	return (urAPI_Region_t*)region;
}

static urAPI_Texture_t *checktexture(lua_State *lua, int nr)
{
	void *texture = luaL_checkudata(lua, nr, "URAPI.texture");
	luaL_argcheck(lua, texture!= NULL, nr, "'texture' expected");
	return (urAPI_Texture_t*)texture;
}

static urAPI_TextLabel_t *checktextlabel(lua_State *lua, int nr)
{
	void *textlabel = luaL_checkudata(lua, nr, "URAPI.textlabel");
	luaL_argcheck(lua, textlabel!= NULL, nr, "'textlabel' expected");
	return (urAPI_TextLabel_t*)textlabel;
}

static ursAPI_FlowBox_t *checkflowbox(lua_State *lua, int nr)
{
	luaL_checktype(lua, nr, LUA_TTABLE);
	lua_rawgeti(lua, nr, 0);
	void *flowbox = lua_touserdata(lua, -1);
	lua_pop(lua,1);
	luaL_argcheck(lua, flowbox!= NULL, nr, "'flowbox' expected");
	return (ursAPI_FlowBox_t*)flowbox;
}

// NEW!!
static int l_NumRegions(lua_State *lua)
{
	lua_pushnumber(lua, numRegions[currentPage]);
	return 1;
}

static int l_EnumerateRegions(lua_State *lua)
{
	urAPI_Region_t* region;

	if(lua_isnil(lua,1))
	{
		region = UIParent->next;
	}
	else
	{
		region = checkregion(lua,1);
		if(region!=nil)
			region = region->next;
	}
	
	lua_rawgeti(lua,LUA_REGISTRYINDEX, region->tableref);
	
	return 1;
}

// Region events to support
// OnDragStart
// OnDragStop
// OnEnter
// OnEvent
// OnHide
// OnLeave
// OnTouchDown
// OnTouchUp
// OnReceiveDrag (NYI)
// OnShow
// OnSizeChanged
// OnUpdate
// OnDoubleTap (UR!)

bool callAllOnUpdate(float time)
{
	for(urAPI_Region_t* t=firstRegion[currentPage]; t != nil; t=t->next)
	{
		if(t->OnUpdate != 0)
			callScriptWith1Args(t->OnUpdate, t,time);
	}	
	return true;
}

bool callAllOnPageEntered(float page)
{
	for(urAPI_Region_t* t=firstRegion[currentPage]; t != nil; t=t->next)
	{
		if(t->OnPageEntered != 0)
			callScriptWith1Args(t->OnPageEntered, t,page);
	}	
	return true;
}

bool callAllOnPageLeft(float page)
{
	for(urAPI_Region_t* t=firstRegion[currentPage]; t != nil; t=t->next)
	{
		if(t->OnPageLeft != 0)
			callScriptWith1Args(t->OnPageLeft, t,page);
	}	
	return true;
}

bool callAllOnLocation(float latitude, float longitude)
{
	for(urAPI_Region_t* t=firstRegion[currentPage]; t != nil; t=t->next)
	{
		if(t->OnLocation != 0)
			callScriptWith2Args(t->OnLocation,t,latitude, longitude);
	}	
	return true;
}

bool callAllOnHeading(float x, float y, float z, float north)
{
	for(urAPI_Region_t* t=firstRegion[currentPage]; t != nil; t=t->next)
	{
		if(t->OnHeading != 0)
			callScriptWith4Args(t->OnHeading,t,x,y,z,north);
	}	
	return true;
}

bool callAllOnAccelerate(float x, float y, float z)
{
	for(urAPI_Region_t* t=firstRegion[currentPage]; t != nil; t=t->next)
	{
		if(t->OnAccelerate != 0)
			callScriptWith3Args(t->OnAccelerate,t,x,y,z);
	}	
	return true;
}

bool callAllOnNetIn(float a)
{
	for(urAPI_Region_t* t=firstRegion[currentPage]; t != nil; t=t->next)
	{
		if(t->OnNetIn != 0)
			callScriptWith1Args(t->OnNetIn,t,a);
	}
}

#ifdef SANDWICH_SUPPORT
bool callAllOnPressure(float p)
{
	for(urAPI_Region_t* t=firstRegion[currentPage]; t != nil; t=t->next)
	{
		if(t->OnPressure != 0)
			callScriptWith1Args(t->OnPressure,t,p);
	}	
	return true;
}
#endif


bool callAllOnMicrophone(SInt32* mic_buffer, UInt32 bufferlen)
{
	lua_getglobal(lua, "urMicData");
	if(lua_isnil(lua, -1) || !lua_istable(lua,-1)) // Channel doesn't exist or is falsely set up
	{
		lua_pop(lua,1);
		return false;
	}
	
	for(UInt32 i=0;i<bufferlen; i++)
	{
		lua_pushnumber(lua, mic_buffer[i]);
		lua_rawseti(lua, -2, i+1);
	}	
	lua_setglobal(lua, "urMicData");

	for(urAPI_Region_t* t=firstRegion[currentPage]; t != nil; t=t->next)
	{
		if(t->OnMicrophone != 0)
			callScriptWith1Global(t->OnMicrophone, t, "urMicData");
	}
	return true;
}

bool callScriptWith4Args(int func_ref, urAPI_Region_t* region, float a, float b, float c, float d)
{
	if(func_ref == 0) return false;

	// Call lua function by stored Reference
	lua_rawgeti(lua,LUA_REGISTRYINDEX, func_ref);
	lua_rawgeti(lua,LUA_REGISTRYINDEX, region->tableref);
	lua_pushnumber(lua,a);
	lua_pushnumber(lua,b);
	lua_pushnumber(lua,c);
	lua_pushnumber(lua,d);
	if(lua_pcall(lua,5,0,0) != 0)
	{
		// Error!!
		const char* error = lua_tostring(lua, -1);
		errorstr = [[NSString alloc] initWithCString:error ]; // DPrinting errors for now
		newerror = true;
		return false;
	}
	
	// OK!
	return true;
}

bool callScriptWith3Args(int func_ref, urAPI_Region_t* region, float a, float b, float c)
{
	if(func_ref == 0) return false;
	
	// Call lua function by stored Reference
	lua_rawgeti(lua,LUA_REGISTRYINDEX, func_ref);
	lua_rawgeti(lua,LUA_REGISTRYINDEX, region->tableref);
	lua_pushnumber(lua,a);
	lua_pushnumber(lua,b);
	lua_pushnumber(lua,c);
	if(lua_pcall(lua,4,0,0) != 0)
	{
		// Error!!
		const char* error = lua_tostring(lua, -1);
		errorstr = [[NSString alloc] initWithCString:error ]; // DPrinting errors for now
		newerror = true;
		return false;
	}
	
	// OK!
	return true;
}

bool callScriptWith2Args(int func_ref, urAPI_Region_t* region, float a, float b)
{
	if(func_ref == 0) return false;
	
	// Call lua function by stored Reference
	lua_rawgeti(lua,LUA_REGISTRYINDEX, func_ref);
	lua_rawgeti(lua,LUA_REGISTRYINDEX, region->tableref);
	lua_pushnumber(lua,a);
	lua_pushnumber(lua,b);
	if(lua_pcall(lua,3,0,0) != 0)
	{
		//<return Error>
		const char* error = lua_tostring(lua, -1);
		errorstr = [[NSString alloc] initWithCString:error ]; // DPrinting errors for now
		newerror = true;
		return false;
	}
	
	// OK!
	return true;
}

bool callScriptWith1Args(int func_ref, urAPI_Region_t* region, float a)
{
	if(func_ref == 0) return false;
	
	//		int func_ref = region->OnDragging;
	// Call lua function by stored Reference
	lua_rawgeti(lua,LUA_REGISTRYINDEX, func_ref);
	lua_rawgeti(lua,LUA_REGISTRYINDEX, region->tableref);
	lua_pushnumber(lua,a);
	if(lua_pcall(lua,2,0,0) != 0)
	{
		//<return Error>
		const char* error = lua_tostring(lua, -1);
		errorstr = [[NSString alloc] initWithCString:error ]; // DPrinting errors for now
		newerror = true;
		return false;
	}
		
	// OK!
	return true;
}

bool callScriptWith1Global(int func_ref, urAPI_Region_t* region, const char* globaldata)
{
	if(func_ref == 0) return false;
	
	//		int func_ref = region->OnDragging;
	// Call lua function by stored Reference
	lua_rawgeti(lua,LUA_REGISTRYINDEX, func_ref);
	lua_rawgeti(lua,LUA_REGISTRYINDEX, region->tableref);
	lua_getglobal(lua, globaldata);
	if(lua_pcall(lua,2,0,0) != 0)
	{
		//<return Error>
		const char* error = lua_tostring(lua, -1);
		errorstr = [[NSString alloc] initWithCString:error ]; // DPrinting errors for now
		newerror = true;
		return false;
	}
	
	// OK!
	return true;
}

bool callScript(int func_ref, urAPI_Region_t* region)
{
	if(func_ref == 0) return false;
	
	// Call lua function by stored Reference
	lua_rawgeti(lua,LUA_REGISTRYINDEX, func_ref);
	lua_rawgeti(lua,LUA_REGISTRYINDEX, region->tableref);
	if(lua_pcall(lua,1,0,0) != 0) // find table of udata here!!
	{
		//<return Error>
		const char* error = lua_tostring(lua, -1);
		errorstr = [[NSString alloc] initWithCString:error ]; // DPrinting errors for now
		newerror = true;
		return false;
	}

	// OK!
	return true;
}

int region_Handle(lua_State* lua)
{
	urAPI_Region_t* region 
	= checkregion(lua,1);
	//get parameter
	const char* handler = luaL_checkstring(lua, 2);
	
	if(lua_isnil(lua,3))
	{
		if(!strcmp(handler, "OnDragStart"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnDragStart);
			region->OnDragStart = 0;
		}
		else if(!strcmp(handler, "OnDragStop"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnDragStop);
			region->OnDragStop = 0;
		}
		else if(!strcmp(handler, "OnEnter"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnEnter);
			region->OnEnter = 0;
		}
		else if(!strcmp(handler, "OnEvent"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnEvent);
			region->OnEvent = 0;
		}
		else if(!strcmp(handler, "OnHide"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnHide);
			region->OnHide = 0;
		}
		else if(!strcmp(handler, "OnLeave"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnLeave);
			region->OnLeave = 0;
		}
		else if(!strcmp(handler, "OnTouchDown"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnTouchDown);
			region->OnTouchDown = 0;
		}
		else if(!strcmp(handler, "OnTouchUp"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnTouchUp);
			region->OnTouchUp = 0;
		}
		else if(!strcmp(handler, "OnShow"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnShow);
			region->OnShow = 0;
		}
		else if(!strcmp(handler, "OnSizeChanged"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnSizeChanged);
			region->OnSizeChanged = 0;
		}
		else if(!strcmp(handler, "OnUpdate"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnUpdate);
			region->OnUpdate = 0;
		}
		else if(!strcmp(handler, "OnDoubleTap"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnDoubleTap);
			region->OnDoubleTap = 0;
		}
		else if(!strcmp(handler, "OnAccelerate"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnAccelerate);
			region->OnAccelerate = 0;
		}
		else if(!strcmp(handler, "OnNetIn"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnNetIn);
			region->OnNetIn = 0;
		}
#ifdef SANDWICH_SUPPORT
		else if(!strcmp(handler, "OnPressure"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnPressure);
			region->OnPressure = 0;
		}
#endif
		else if(!strcmp(handler, "OnHeading"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnHeading);
			region->OnHeading = 0;
		}
		else if(!strcmp(handler, "OnLocation"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnLocation);
			region->OnLocation = 0;
		}
		else if(!strcmp(handler, "OnMicrophone"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnMicrophone);
			region->OnMicrophone = 0;
		}
		else if(!strcmp(handler, "OnHorizontalScroll"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnHorizontalScroll);
			region->OnHorizontalScroll = 0;
		}
		else if(!strcmp(handler, "OnVerticalScroll"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnVerticalScroll);
			region->OnVerticalScroll = 0;
		}
		else if(!strcmp(handler, "OnPageEntered"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnPageEntered);
			region->OnPageEntered = 0;
		}
		else if(!strcmp(handler, "OnPageLeft"))
		{
			luaL_unref(lua, LUA_REGISTRYINDEX, region->OnPageLeft);
			region->OnPageLeft = 0;
		}
		else
			luaL_error(lua, "Trying to set a script for an unknown event: %s",handler);
			return 0; // Error, unknown event
		return 1;
	}
	else
	{
	luaL_argcheck(lua, lua_isfunction(lua,3), 3, "'function' expected");
		if(lua_isfunction(lua,3))
		{
/*			char* func     = (char*)lua_topointer(lua,3);
			// <Also get some other info like function name, argument count>
	
			// Load the function to memory
			luaL_loadbuffer(lua,func,strlen(func),"LuaFunction");
			lua_pop(lua,1);
*/	
			// Store funtion reference
			lua_pushvalue(lua, 3);
			int func_ref = luaL_ref(lua, LUA_REGISTRYINDEX);
			
			// OnDragStart
			// OnDragStop
			// OnEnter
			// OnEvent
			// OnHide
			// OnLeave
			// OnTouchDown
			// OnTouchUp
			// OnReceiveDrag (NYI)
			// OnShow
			// OnSizeChanged
			// OnUpdate
			// OnDoubleTap (UR!)
			if(!strcmp(handler, "OnDragStart"))
				region->OnDragStart = func_ref;
			else if(!strcmp(handler, "OnDragStop"))
				region->OnDragStop = func_ref;
			else if(!strcmp(handler, "OnEnter"))
				region->OnEnter = func_ref;
			else if(!strcmp(handler, "OnEvent"))
				region->OnEvent = func_ref;
			else if(!strcmp(handler, "OnHide"))
				region->OnHide = func_ref;
			else if(!strcmp(handler, "OnLeave"))
				region->OnLeave = func_ref;
			else if(!strcmp(handler, "OnTouchDown"))
				region->OnTouchDown = func_ref;
			else if(!strcmp(handler, "OnTouchUp"))
				region->OnTouchUp = func_ref;
			else if(!strcmp(handler, "OnShow"))
				region->OnShow = func_ref;
			else if(!strcmp(handler, "OnSizeChanged"))
				region->OnSizeChanged = func_ref;
			else if(!strcmp(handler, "OnUpdate"))
				region->OnUpdate = func_ref;
			else if(!strcmp(handler, "OnDoubleTap"))
				region->OnDoubleTap = func_ref;
			else if(!strcmp(handler, "OnAccelerate"))
				region->OnAccelerate = func_ref;
			else if(!strcmp(handler, "OnNetIn"))
				region->OnNetIn = func_ref;
#ifdef SANDWICH_SUPPORT
			else if(!strcmp(handler, "OnPressure"))
				region->OnPressure = func_ref;
#endif
			else if(!strcmp(handler, "OnHeading"))
				region->OnHeading = func_ref;
			else if(!strcmp(handler, "OnLocation"))
				region->OnLocation = func_ref;
			else if(!strcmp(handler, "OnMicrophone"))
				region->OnMicrophone = func_ref;
			else if(!strcmp(handler, "OnHorizontalScroll"))
				region->OnHorizontalScroll = func_ref;
			else if(!strcmp(handler, "OnVerticalScroll"))
				region->OnVerticalScroll = func_ref;
			else if(!strcmp(handler, "OnPageEntered"))
				region->OnPageEntered = func_ref;
			else if(!strcmp(handler, "OnPageLeft"))
				region->OnPageLeft = func_ref;
			else
				luaL_unref(lua, LUA_REGISTRYINDEX, func_ref);
			
			// OK! 
			return 1;
		}
		return 0;
	}
}

int region_SetHeight(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_Number height = luaL_checknumber(lua,2);
	region->height=height;
	region->update = true;
	if(!layout(region)) // Change may not have had a layouting effect on parent, but still could affect children that are anchored to Y
		layoutchildren(region);
	return 0;
}

int region_SetWidth(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_Number width = luaL_checknumber(lua,2);
	region->width=width;
	region->update = true;
	if(!layout(region)) // Change may not have had a layouting effect on parent, but still could affect children that are anchored to X
		layoutchildren(region);
	return 0;
}

int region_EnableInput(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	bool enableinput = lua_toboolean(lua,2); //!lua_isnil(lua,2);
	region->isTouchEnabled = enableinput;
	return 0;
}

int region_EnableHorizontalScroll(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	bool enablescrollx = lua_toboolean(lua,2); //!lua_isnil(lua,2);
	region->isScrollXEnabled = enablescrollx;
	return 0;
}

int region_EnableVerticalScroll(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	bool enablescrolly = lua_toboolean(lua,2); //!lua_isnil(lua,2);
	region->isScrollYEnabled = enablescrolly;
	return 0;
}

int region_EnableClipping(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	
	bool enableclipping = lua_toboolean(lua,2); //!lua_isnil(lua,2);
	region->isClipping = enableclipping;
	return 0;
}

int region_SetClipRegion(lua_State* lua)
{
	urAPI_Region_t* t = checkregion(lua, 1);
	t->clipleft = luaL_checknumber(lua, 2);
	t->clipbottom = luaL_checknumber(lua, 3);
	t->clipwidth = luaL_checknumber(lua, 4);
	t->clipheight = luaL_checknumber(lua, 5);
	return 0;
}

int region_ClipRegion(lua_State* lua)
{
	urAPI_Region_t* t = checkregion(lua, 1);
	lua_pushnumber(lua, t->clipleft);
	lua_pushnumber(lua, t->clipbottom);
	lua_pushnumber(lua, t->clipwidth);
	lua_pushnumber(lua, t->clipheight);
	return 4;
}

int region_EnableMoving(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	bool setmovable = lua_toboolean(lua,2);//!lua_isnil(lua,2);
	region->isMovable = setmovable;
	return 0;
}

int region_EnableResizing(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	bool setresizable = lua_toboolean(lua,2);//!lua_isnil(lua,2);
	region->isResizable = setresizable;
	return 0;
}

void ClampRegion(urAPI_Region_t* region);

int region_SetAnchor(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	if(region==UIParent) return 0;
	lua_Number ofsx;
	lua_Number ofsy;
	urAPI_Region_t* relativeRegion = UIParent; 
	
	const char* point = luaL_checkstring(lua, 2);
	const char* relativePoint = DEFAULT_RPOINT;
	if(lua_isnil(lua,3)) // SetAnchor(point);
	{
		
	}
	else
	{
		if(lua_isnumber(lua, 3) && lua_isnumber(lua, 4)) // SetAnchor(point, x,y);
		{
			ofsx = luaL_checknumber(lua, 3);
			ofsy = luaL_checknumber(lua, 4);
		}
		else
		{
			if(lua_isstring(lua, 3)) // SetAnchor(point, "relativeRegion")
			{
				// find parent here
			}
			else // SetAnchor(point, relativeRegion)
				relativeRegion = checkregion(lua, 3);
			
			if(lua_isstring(lua, 4))
				relativePoint = luaL_checkstring(lua, 4);
			
			if(lua_isnumber(lua, 5) && lua_isnumber(lua, 6)) // SetAnchor(point, x,y);
			{
				ofsx = luaL_checknumber(lua, 5);
				ofsy = luaL_checknumber(lua, 6);
			}
		}
			
	}
	
	if(region->point != NULL)
		free(region->point);
	region->point = (char*)malloc(strlen(point)+1);
	strcpy(region->point, point);
	region->relativeRegion = relativeRegion;

	if(relativeRegion != region->parent)
	{
		removeChild(region->parent, region);
 		region->parent = relativeRegion;
		addChild(relativeRegion, region);
	}

	if(region->relativePoint != NULL)
		free(region->relativePoint);
	region->relativePoint = (char*)malloc(strlen(relativePoint)+1);
	strcpy(region->relativePoint, relativePoint);

	region->ofsx = ofsx;
	region->ofsy = ofsy;
	region->update = true;
	layout(region);
	if(region->isClamped)
		ClampRegion(region);
	return true;
}

int region_Show(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	region->isShown = true;
	if(visibleparent(region)) // Check visibility change for children
	{
		region->isVisible = true;
		if(region->OnShow != 0)
			callScript(region->OnShow, region);
		showchildren(region);
	}
	return 0;
}

int region_Hide(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	region->isVisible = false;
	region->isShown = false;
	if(region->OnHide != 0)
		callScript(region->OnHide, region);
	hidechildren(region); // parent got hidden so hide children too.
	return 0;
}

const char STRATASTRING_PARENT[] = "PARENT";
const char STRATASTRING_BACKGROUND[] = "BACKGROUND";
const char STRATASTRING_LOW[] = "LOW";
const char STRATASTRING_MEDIUM[] = "MEDIUM";
const char STRATASTRING_HIGH[] = "HIGH";
const char STRATASTRING_DIALOG[] = "DIALOG";
const char STRATASTRING_FULLSCREEN[] = "FULLSCREEN";
const char STRATASTRING_FULLSCREEN_DIALOG[] = "FULLSCREEN_DIALOG";
const char STRATASTRING_TOOLTIP[] = "TOOLTIP";

const char* region_strataindex2str(int strataidx)
{
	switch(strataidx)
	{
		case STRATA_PARENT:
			return STRATASTRING_PARENT;
		case STRATA_BACKGROUND:
			return STRATASTRING_BACKGROUND;
		case STRATA_LOW:
			return STRATASTRING_LOW;
		case STRATA_MEDIUM:
			return STRATASTRING_MEDIUM;
		case STRATA_HIGH:
			return STRATASTRING_HIGH;
		case STRATA_FULLSCREEN:
			return STRATASTRING_FULLSCREEN;
		case STRATA_FULLSCREEN_DIALOG:
			return STRATASTRING_FULLSCREEN_DIALOG;
		case STRATA_TOOLTIP:
			return STRATASTRING_TOOLTIP;
		default:
			return nil;
	}
}

int region_strata2index(const char* strata)
{

	if(!strcmp(strata, "PARENT"))
		return STRATA_PARENT;
	else if(!strcmp(strata, "BACKGROUND"))
		return STRATA_BACKGROUND;
	else if(!strcmp(strata, "LOW"))
		return STRATA_LOW;
	else if(!strcmp(strata, "MEDIUM"))
		return STRATA_MEDIUM;
	else if(!strcmp(strata, "HIGH"))
		return STRATA_HIGH;
	else if(!strcmp(strata, "DIALOG"))
		return STRATA_DIALOG;
	else if(!strcmp(strata, "FULLSCREEN"))
		return STRATA_FULLSCREEN;
	else if(!strcmp(strata, "FULLSCREEN_DIALOG"))
		return STRATA_FULLSCREEN_DIALOG;
	else if(!strcmp(strata, "TOOLTIP"))
		return STRATA_TOOLTIP;
	else
	{
		return -1; // unknown strata
	}
	
}

const char LAYERSTRING_BACKGROUND[] = "BACKGROUND";
const char LAYERSTRING_BORDER[] = "BORDER";
const char LAYERSTRING_ARTWORK[] = "ARTWORK";
const char LAYERSTRING_OVERLAY[] = "OVERLAY";
const char LAYERSTRING_HIGHLIGHT[] = "HIGHLIGHT";

const char* region_layerindex2str(int layeridx)
{
	switch(layeridx)
	{
		case LAYER_BACKGROUND:
			return LAYERSTRING_BACKGROUND;
		case LAYER_BORDER:
			return LAYERSTRING_BORDER;
		case LAYER_ARTWORK:
			return LAYERSTRING_ARTWORK;
		case LAYER_OVERLAY:
			return LAYERSTRING_OVERLAY;
		case LAYER_HIGHLIGHT:
			return LAYERSTRING_HIGHLIGHT;
		default:
			return nil;
	}
}

int region_layer2index(const char* layer)
{
	
	if(!strcmp(layer, "BACKGROUND"))
		return LAYER_BACKGROUND;
	else if(!strcmp(layer, "BORDER"))
		return LAYER_BORDER;
	else if(!strcmp(layer, "ARTWORK"))
		return LAYER_ARTWORK;
	else if(!strcmp(layer, "OVERLAY"))
		return LAYER_OVERLAY;
	else if(!strcmp(layer, "HIGHLIGHT"))
		return LAYER_HIGHLIGHT;
	else
	{
		return -1; // unknown layer
	}
	
}

const char WRAPSTRING_WORD[] = "WORD";
const char WRAPSTRING_CHAR[] = "CHAR";
const char WRAPSTRING_CLIP[] = "CLIP";

const char* textlabel_wrapindex2str(int wrapidx)
{
	switch(wrapidx)
	{
		case WRAP_WORD:
			return WRAPSTRING_WORD;
		case WRAP_CHAR:
			return WRAPSTRING_CHAR;
		case WRAP_CLIP:
			return WRAPSTRING_CLIP;
		default:
			return nil;
	}
}

int textlabel_wrap2index(const char* wrap)
{
	if(!strcmp(wrap, "WORD"))
		return WRAP_WORD;
	else if(!strcmp(wrap, "CHAR"))
		return WRAP_CHAR;
	else if(!strcmp(wrap, "CLIP"))
		return WRAP_CLIP;
	else
	{
		return -1; // unknown wrap
	}
}

void l_SortStrata(urAPI_Region_t* region, int strata)
{
	if(region->prev == nil && firstRegion[currentPage] == region) // first region!
	{
		firstRegion[currentPage] = region->next; // unlink!
		firstRegion[currentPage]->prev = nil;
	}
	else if(region->next == nil && lastRegion[currentPage] == region) // last region!
	{
		lastRegion[currentPage] = region->prev; // unlink!
		lastRegion[currentPage]->next = nil;
	}
	else if(region->prev != NULL && region->next !=NULL)
	{
		region->prev->next = region->next; // unlink!
		region->next->prev = region->prev;
	}
	for(urAPI_Region_t* t=firstRegion[currentPage]; t!=NULL; t=t->next)
	{
		if(t->strata!=STRATA_PARENT) // ignoring PARENT strata regions.
		{
			if(t->strata > strata) // insert here!
			{
				if(t == firstRegion[currentPage])
					firstRegion[currentPage] = region;
				region->prev = t->prev;
				if(t->prev != NULL) // Again, may be the first.
					t->prev->next = region;
				region->next = t; // Link in

				t->prev = region; // fix links
				region->strata = strata;
//				region->prev->next = region;
				return; // Done.
			}
		}
	}
	
	if(region!=lastRegion[currentPage])
	{
		region->prev = lastRegion[currentPage];
		region->next = nil;
		lastRegion[currentPage]->next = region;
		lastRegion[currentPage] = region;
	}
	else
	{
		lastRegion[currentPage] = nil;
	}
}

void l_setstrataindex(urAPI_Region_t* region , int strataindex)
{
	if(strataindex == STRATA_PARENT)
	{
		region->strata = strataindex;
		urAPI_Region_t* p = region->parent;
		int newstrataindex = 1;
		do
		{
			if (p->strata != STRATA_PARENT) newstrataindex = p->strata;
			p = p->parent;
		}
		while(p!=NULL && p->strata == 0);
		
		l_SortStrata(region, newstrataindex);
	}
	if (strataindex > 0 && strataindex != region->strata)
	{
		region->strata = strataindex;
		l_SortStrata(region, strataindex);
	}
}

int region_SetLayer(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	const char* strata = luaL_checkstring(lua,2);
	if(strata)
	{
		int strataindex = region_strata2index(strata);
		if( region == firstRegion[currentPage] && region == lastRegion[currentPage])
		{
			// This is a sole region, no need to stratify
		}
		else
			l_setstrataindex(region , strataindex);
		region->strata = strataindex;
	}
	return 0;
}

int region_Parent(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	if(region != nil)
	{
		region = region->parent;
		lua_rawgeti(lua,LUA_REGISTRYINDEX, region->tableref);

		return 1;
	}
	else
		return 0;
}

int region_Children(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	urAPI_Region_t* child = region->firstchild;
	
	int childcount = 0;
	while(child!=NULL)
	{
		childcount++;
		lua_rawgeti(lua,LUA_REGISTRYINDEX, child->tableref);
		child = child->nextchild;
	}
	return childcount;
}

int region_Alpha(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushnumber(lua, region->alpha);
	return 1;
}

int region_SetAlpha(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	
	lua_Number alpha = luaL_checknumber(lua,2);
	if(alpha > 1.0) alpha = 1.0;
	else if(alpha < 0.0) alpha = 0.0;
	region->alpha=alpha;
	return 0;
}

int region_Name(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushstring(lua, region->name);
	return 1;
}

int region_Bottom(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushnumber(lua, region->bottom);
	return 1;
}

int region_Center(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushnumber(lua, region->cx);
	lua_pushnumber(lua, region->cy);
	return 2;
}

int region_Height(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushnumber(lua, region->height);
	return 1;
}

int region_Left(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushnumber(lua, region->left);
	return 1;
}

int region_Right(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushnumber(lua, region->right);
	return 1;
}

int region_Top(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushnumber(lua, region->top);
	return 1;
}

int region_Width(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushnumber(lua, region->width);
	return 1;
}

int region_NumAnchors(lua_State* lua)
{
//	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushnumber(lua, 1); // NYI always 1 point for now
	return 1;
}

int region_Anchor(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);

	lua_pushstring(lua, region->point);
	if(region->relativeRegion)
	{
		lua_rawgeti(lua, LUA_REGISTRYINDEX, region->relativeRegion->tableref);
	}
	else
		lua_pushnil(lua);
	lua_pushstring(lua, region->relativePoint);
	lua_pushnumber(lua, region->ofsx);
	lua_pushnumber(lua, region->ofsy);
	
	return 5;
}

int region_IsShown(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushboolean(lua, region->isVisible);
	return 1;
}

int region_IsVisible(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	bool visible = false;
	if(region->parent!=NULL)
		visible = region->isVisible && region->parent->isVisible;
	else
		visible = region->isVisible;
	lua_pushboolean(lua, visible );
	return 1;
}

void setParent(urAPI_Region_t* region, urAPI_Region_t* parent)
{
	if(region!= NULL && parent!= NULL && region != parent)
	{
		removeChild(region->parent, region);
		if(parent == UIParent)
			region->parent = UIParent;
		else
		{
			region->parent = parent;
			addChild(parent, region);
		}
	}
}

int region_SetParent(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	urAPI_Region_t* parent = checkregion(lua, 2);

	setParent(region, parent);
	return 0;
}

int region_Layer(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	lua_pushstring(lua, region_strataindex2str(region->strata));
	return 1;
}

// NEW!!
int region_Lower(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	if(region->prev != nil)
	{
		urAPI_Region_t* temp = region->prev;
		region->prev = temp->prev;
		temp->next = region->next;
		temp->prev = region;
		region->next = temp;
	}
	return 0;
}

int region_Raise(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	if(region->next != nil)
	{
		urAPI_Region_t* temp = region->next;
		region->next = temp->next;
		temp->prev = region->prev;
		temp->next = region;
		region->prev = temp;
	}
	return 0;
}

int region_IsToplevel(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);

	bool istop = false;
	
	if(region == lastRegion[currentPage])
	{
		istop = true;
	}

	lua_pushboolean(lua, istop);
	return 1;
}

int region_MoveToTop(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	
	if(region != lastRegion[currentPage]) 
	{
		if(region->prev != nil) // Could be first region!
			region->prev->next = region->next; // unlink!
		region->next->prev = region->prev;
		// and make last
		lastRegion[currentPage]->next = region;
		region->next = nil;
		lastRegion[currentPage] = region;
	}
	return 0;
}

// ENDNEW!!

void instantiateTexture(urAPI_Region_t* t);

char TEXTURE_SOLID[] = "Solid Texture";

#define GRADIENT_ORIENTATION_VERTICAL 0
#define GRADIENT_ORIENTATION_HORIZONTAL 1
#define GRADIENT_ORIENTATION_DOWNWARD 2
#define GRADIENT_ORIENTATION_UPWARD 3

int region_Texture(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	const char* texturename;
	const char* texturelayer;
	int texturelayerindex=1;
	
	if(lua_gettop(lua)<2 || lua_isnil(lua,2)) // this can legitimately be nil.
		texturename = nil;
	else
	{
		texturename = luaL_checkstring(lua,2);
		if(lua_gettop(lua)==3 && !lua_isnil(lua,3)) // this should be set.
		{
			texturelayer = luaL_checkstring(lua,3);
			texturelayerindex = region_layer2index(texturelayer);
		}
		// NYI arg3.. are inheritsFrom regions
	}
	urAPI_Texture_t* mytexture = (urAPI_Texture_t*)lua_newuserdata(lua, sizeof(urAPI_Texture_t));
	mytexture->blendmode = BLEND_DISABLED;
	mytexture->texcoords[0] = 0.0;
	mytexture->texcoords[1] = 1.0;
	mytexture->texcoords[2] = 1.0;
	mytexture->texcoords[3] = 1.0;
	mytexture->texcoords[4] = 0.0;
	mytexture->texcoords[5] = 0.0;
	mytexture->texcoords[6] = 1.0;
	mytexture->texcoords[7] = 0.0;
	if(texturename == NULL)
		mytexture->texturepath = TEXTURE_SOLID;
	else
	{
		mytexture->texturepath = (char*)malloc(strlen(texturename)+1);
		strcpy(mytexture->texturepath, texturename);
//		mytexture->texturepath = texturename;
	}
	mytexture->modifyRect = false;
	mytexture->isDesaturated = false;
	mytexture->fill = false;
//	mytexture->gradientOrientation = GRADIENT_ORIENTATION_VERTICAL; OBSOLETE
	mytexture->gradientUL[0] = 255; // R
	mytexture->gradientUL[1] = 255; // G
	mytexture->gradientUL[2] = 255; // B
	mytexture->gradientUL[3] = 255; // A
	mytexture->gradientUR[0] = 255; // R
	mytexture->gradientUR[1] = 255; // G
	mytexture->gradientUR[2] = 255; // B
	mytexture->gradientUR[3] = 255; // A
	mytexture->gradientBL[0] = 255; // R
	mytexture->gradientBL[1] = 255; // G
	mytexture->gradientBL[2] = 255; // B
	mytexture->gradientBL[3] = 255; // A
	mytexture->gradientBR[0] = 255; // R
	mytexture->gradientBR[1] = 255; // G
	mytexture->gradientBR[2] = 255; // B
	mytexture->gradientBR[3] = 255; // A
	mytexture->texturesolidcolor[0] = 255; // R for solid
	mytexture->texturesolidcolor[1] = 255; // G
	mytexture->texturesolidcolor[2] = 255; // B
	mytexture->texturesolidcolor[3] = 255; // A

	mytexture->backgroundTex = NULL;
	
	region->texture = mytexture; // HACK
	mytexture->region = region;
	
	luaL_getmetatable(lua, "URAPI.texture");
	lua_setmetatable(lua, -2);

	if(mytexture->backgroundTex == nil && mytexture->texturepath != TEXTURE_SOLID)
	{
		instantiateTexture(mytexture->region);
	}
	return 1;
}

char textlabel_empty[] = "";
const char textlabel_defaultfont[] = "Helvetica";

int region_TextLabel(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	const char* texturename;
	const char* texturelayer;
	int texturelayerindex=1;
	
	if(lua_gettop(lua)<2 || lua_isnil(lua,2)) // this can legitimately be nil.
		texturename = nil;
	else
		if(!lua_isnil(lua,3)) // this should be set.
		{
			texturelayer = luaL_checkstring(lua,3);
			texturelayerindex = region_layer2index(texturelayer);
		}
	// NYI arg3.. are inheritsFrom regions
	
	urAPI_TextLabel_t* mytextlabel = (urAPI_TextLabel_t*)lua_newuserdata(lua, sizeof(urAPI_TextLabel_t));
	
	region->textlabel = mytextlabel; // HACK
	
	mytextlabel->text = textlabel_empty;
	mytextlabel->updatestring = true;
	mytextlabel->font = textlabel_defaultfont;
	mytextlabel->justifyh = JUSTIFYH_CENTER;
	mytextlabel->justifyv = JUSTIFYV_MIDDLE;
	mytextlabel->shadowcolor[0] = 0.0;
	mytextlabel->shadowcolor[1] = 0.0;
	mytextlabel->shadowcolor[2] = 0.0;
	mytextlabel->shadowcolor[3] = 128.0;
	mytextlabel->shadowoffset[0] = 0.0;
	mytextlabel->shadowoffset[1] = 0.0;
	mytextlabel->shadowblur = 0.0;
	mytextlabel->drawshadow = false;
	mytextlabel->linespacing = 2;
	mytextlabel->textcolor[0] = 255.0;
	mytextlabel->textcolor[1] = 255.0;
	mytextlabel->textcolor[2] = 255.0;
	mytextlabel->textcolor[3] = 255.0;
	mytextlabel->textheight = 12;
	mytextlabel->wrap = WRAP_WORD;
	
	mytextlabel->textlabelTex = nil;
	
	luaL_getmetatable(lua, "URAPI.textlabel");
	lua_setmetatable(lua, -2);

	return 1;
}

int l_DPrint(lua_State* lua)
{
	const char* str = luaL_checkstring(lua,1);
	if(str!=nil)
	{
		errorstr = [[NSString alloc] initWithCString:str ];
		newerror = true;
	}
	return 0;
}

int l_InputFocus(lua_State* lua)
{
	// NYI
	return 0;
}

int l_HasInput(lua_State* lua)
{
	urAPI_Region_t* t = checkregion(lua, 1);
	bool isover = false;
	
	float x,y;

	// NYI
	
	if(x >= t->left && x <= t->left+t->width &&
	   y >= t->bottom && y <= t->bottom+t->height /*&& t->isTouchEnabled*/)
		isover = true;
	lua_pushboolean(lua, isover);
	return 1;
}

extern int SCREEN_WIDTH;
extern int SCREEN_HEIGHT;

int l_ScreenHeight(lua_State* lua)
{
	lua_pushnumber(lua, SCREEN_HEIGHT);
	return 1;
}

int l_ScreenWidth(lua_State* lua)
{
	lua_pushnumber(lua, SCREEN_WIDTH);
	return 1;
}

extern float cursorpositionx[MAX_FINGERS];
extern float cursorpositiony[MAX_FINGERS];

// UR: New arg "finger" allows to specify which finger to get position for. nil defaults to 0.
int l_InputPosition(lua_State* lua)
{
	int finger = 0;
	if(lua_gettop(lua) > 0 && !lua_isnil(lua, 1))
		finger = luaL_checknumber(lua, 1);
	lua_pushnumber(lua, cursorpositionx[finger]);
	lua_pushnumber(lua, SCREEN_HEIGHT-cursorpositiony[finger]);
	return 2;
}

int l_Time(lua_State* lua)
{
	lua_pushnumber(lua, [systimer elapsedSec]);
	return 1;
}

int l_RunScript(lua_State* lua)
{
	const char* script = luaL_checkstring(lua,1);
	if(script != NULL)
		luaL_dostring(lua,script);
	return 0;
}

int l_StartHTTPServer(lua_State *lua)
{
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	// start off http server
	http_start([[resourcePath stringByAppendingPathComponent:@"html"] UTF8String],
			   [resourcePath UTF8String]);
	return 0;
}

int l_StopHTTPServer(lua_State *lua)
{
	http_stop();
	return 0;
}

int l_HTTPServer(lua_State *lua)
{
	const char *ip = http_ip_address();
	if (ip) {
		lua_pushstring(lua, ip);
		lua_pushstring(lua, http_ip_port());
		return 2;
	} else {
		return 0;
	}
}

static int audio_initialized = false;

int l_StartAudio(lua_State* lua)
{
	if(!audio_initialized)
	{
		initializeRIOAudioLayer();
	}
	else
		playRIOAudioLayer();

	return 0;
}

int l_PauseAudio(lua_State* lua)
{
	stopRIOAudioLayer();

	return 0;
}

static int l_setanimspeed(lua_State *lua)
{
	double ds = luaL_checknumber(lua, 1);
	g_glView.animationInterval = ds;
	return 0;
}

int texture_SetTexture(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	if(lua_isnumber(lua,2) && lua_isnumber(lua,3) && lua_isnumber(lua,4))
	{
		t->texturepath = TEXTURE_SOLID;
		t->texturesolidcolor[0] = luaL_checknumber(lua, 2); 
		t->texturesolidcolor[1] = luaL_checknumber(lua, 3); 
		t->texturesolidcolor[2] = luaL_checknumber(lua, 4); 
		if(lua_isnumber(lua, 5))
			t->texturesolidcolor[3] = luaL_checknumber(lua, 5);
		else
			t->texturesolidcolor[3] = 255;
	}
	else
	{
		const char* texturename = luaL_checkstring(lua,2);
		if(t->texturepath != TEXTURE_SOLID && t->texturepath != NULL)
			free(t->texturepath);
		t->texturepath = (char*)malloc(strlen(texturename)+1);
		strcpy(t->texturepath, texturename);
		if(t->backgroundTex != NULL) [t->backgroundTex release]; // Antileak
		t->backgroundTex = nil;
    instantiateTexture(t->region);
	}
	
	return 0;
}

int texture_SetGradientColor(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	const char* orientation = luaL_checkstring(lua, 2);
	float minR = luaL_checknumber(lua, 3);
	float minG = luaL_checknumber(lua, 4);
	float minB = luaL_checknumber(lua, 5);
	float minA = luaL_checknumber(lua, 6);
	float maxR = luaL_checknumber(lua, 7);
	float maxG = luaL_checknumber(lua, 8);
	float maxB = luaL_checknumber(lua, 9);
	float maxA = luaL_checknumber(lua, 10);
	
	if(!strcmp(orientation, "HORIZONTAL"))
	{
		t->gradientUL[0] = minR;
		t->gradientUL[1] = minG;
		t->gradientUL[2] = minB;
		t->gradientUL[3] = minA;
		t->gradientBL[0] = minR;
		t->gradientBL[1] = minG;
		t->gradientBL[2] = minB;
		t->gradientBL[3] = minA;
		t->gradientUR[0] = maxR;
		t->gradientUL[1] = maxG;
		t->gradientUR[2] = maxB;
		t->gradientUR[3] = maxA;
		t->gradientBR[0] = maxR;
		t->gradientBR[1] = maxG;
		t->gradientBR[2] = maxB;
		t->gradientBR[3] = maxA;
	}
	else if(!strcmp(orientation, "VERTICAL"))
	{
		t->gradientUL[0] = minR;
		t->gradientUL[1] = minG;
		t->gradientUL[2] = minB;
		t->gradientUL[3] = minA;
		t->gradientUR[0] = minR;
		t->gradientUR[1] = minG;
		t->gradientUR[2] = minB;
		t->gradientUR[3] = minA;
		t->gradientBL[0] = maxR;
		t->gradientBL[1] = maxG;
		t->gradientBL[2] = maxB;
		t->gradientBL[3] = maxA;
		t->gradientBR[0] = maxR;
		t->gradientBR[1] = maxG;
		t->gradientBR[2] = maxB;
		t->gradientBR[3] = maxA;
		
	} 
	else if(!strcmp(orientation, "TOP")) // UR! Allows to set the full gradient in 2 calls.
	{
		t->gradientUL[0] = minR;
		t->gradientUL[1] = minG;
		t->gradientUL[2] = minB;
		t->gradientUL[3] = minA;
		t->gradientUR[0] = maxR;
		t->gradientUR[1] = maxG;
		t->gradientUR[2] = maxB;
		t->gradientUR[3] = maxA;
		
	} 
	else if(!strcmp(orientation, "BOTTOM")) // UR!
	{
		t->gradientBL[0] = minR;
		t->gradientBL[1] = minG;
		t->gradientBL[2] = minB;
		t->gradientBL[3] = minA;
		t->gradientBR[0] = maxR;
		t->gradientBR[1] = maxG;
		t->gradientBR[2] = maxB;
		t->gradientBR[3] = maxA;
		
	}	
	
	return 0;	
}

int texture_Texture(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	// NYI still don't know how to return user values
	return 0;
}

int texture_SetSolidColor(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float vertR = luaL_checknumber(lua, 2);
	float vertG = luaL_checknumber(lua, 3);
	float vertB = luaL_checknumber(lua, 4);
	float vertA = 255;
	if(lua_gettop(lua)==5)
		vertA = luaL_checknumber(lua, 5);
	t->texturesolidcolor[0] = vertR;
	t->texturesolidcolor[1] = vertG;
	t->texturesolidcolor[2] = vertB;
	t->texturesolidcolor[3] = vertA;
	return 0;
}

int texture_SolidColor(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	lua_pushnumber(lua, t->texturesolidcolor[0]);
	lua_pushnumber(lua, t->texturesolidcolor[1]);
	lua_pushnumber(lua, t->texturesolidcolor[2]);
	lua_pushnumber(lua, t->texturesolidcolor[3]);
	return 4;
}

int texture_SetTexCoord(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	if(lua_gettop(lua)==5)
	{
		float left = luaL_checknumber(lua, 2);
		float right = luaL_checknumber(lua, 3);
		float top = luaL_checknumber(lua, 4);
		float bottom = luaL_checknumber(lua, 5);
		t->texcoords[0] = left; //ULx
		t->texcoords[1] = top;  // ULy
		t->texcoords[2] = right; // URx
		t->texcoords[3] = top;   // URy
		t->texcoords[4] = left; // BLx 
		t->texcoords[5] = bottom; // BLy
		t->texcoords[6] = right; // BRx
		t->texcoords[7] = bottom; // BRy
		
	}
	else if(lua_gettop(lua)==9)
	{
		t->texcoords[0] = luaL_checknumber(lua, 2);
		t->texcoords[1] = luaL_checknumber(lua, 3);
		t->texcoords[2] = luaL_checknumber(lua, 4);
		t->texcoords[3] = luaL_checknumber(lua, 5);
		t->texcoords[4] = luaL_checknumber(lua, 6);
		t->texcoords[5] = luaL_checknumber(lua, 7);
		t->texcoords[6] = luaL_checknumber(lua, 8);
		t->texcoords[7] = luaL_checknumber(lua, 9);
	}
	return 0;
}

int texture_TexCoord(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	lua_pushnumber(lua, t->texcoords[0]);
	lua_pushnumber(lua, t->texcoords[1]);
	lua_pushnumber(lua, t->texcoords[2]);
	lua_pushnumber(lua, t->texcoords[3]);
	lua_pushnumber(lua, t->texcoords[4]);
	lua_pushnumber(lua, t->texcoords[5]);
	lua_pushnumber(lua, t->texcoords[6]);
	lua_pushnumber(lua, t->texcoords[7]);
	return 8;
}

int texture_SetRotation(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float angle = luaL_checknumber(lua, 2);
	float s = sin(angle);
	float c = cos(angle);
	
	t->texcoords[0] = 0.5-s;
	t->texcoords[1] = 0.5+c;
	t->texcoords[2] = 0.5+c;
	t->texcoords[3] = 0.5+s;
	t->texcoords[4] = 0.5-c;
	t->texcoords[5] = 0.5-s;
	t->texcoords[6] = 0.5+s;
	t->texcoords[7] = 0.5-c;
	return 0;
}
int region_EnableClamping(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	bool clamped = lua_toboolean(lua,2); //!lua_isnil(lua,2);
	region->isClamped = clamped;
	return 0;
}

int region_RegionOverlap(lua_State* lua)
{
	urAPI_Region_t* region = checkregion(lua,1);
	urAPI_Region_t* region2 = checkregion(lua,2);
	if( region->left < region2->right &&
		region2->left < region->right &&
		region->bottom < region2->top &&
		region2->bottom < region->top)
	{
		lua_pushboolean(lua, true);
		return 1;
	}
	return 0;
}

int texture_SetTexCoordModifiesRect(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	bool modifyrect = lua_toboolean(lua,2); //!lua_isnil(lua,2);
	t->modifyRect = modifyrect;
	return 0;
}

int texture_TexCoordModifiesRect(lua_State* lua)
{
	urAPI_Texture_t* t= checktexture(lua, 1);
	lua_pushboolean(lua, t->modifyRect);
	return 1;
}

int texture_SetDesaturated(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	bool isDesaturated = lua_toboolean(lua,2); //!lua_isnil(lua,2);
	t->isDesaturated = isDesaturated;
	return 0;
}

int texture_IsDesaturated(lua_State* lua)
{
	urAPI_Texture_t* t= checktexture(lua, 1);
	lua_pushboolean(lua, t->isDesaturated);
	return 1;
}

const char BLENDSTR_DISABLED[] = "DISABLED";
const char BLENDSTR_BLEND[] = "BLEND";
const char BLENDSTR_ALPHAKEY[] = "ALPHAKEY";
const char BLENDSTR_ADD[] = "ADD";
const char BLENDSTR_MOD[] = "MOD";
const char BLENDSTR_SUB[] = "SUB";

int texture_SetBlendMode(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	const char* blendmode = luaL_checkstring(lua, 2);
		if(!strcmp(blendmode, BLENDSTR_DISABLED))
		   t->blendmode = BLEND_DISABLED;
		else if(!strcmp(blendmode, BLENDSTR_BLEND))
		   t->blendmode = BLEND_BLEND;
		else if(!strcmp(blendmode, BLENDSTR_ALPHAKEY))
			t->blendmode = BLEND_ALPHAKEY;
		else if(!strcmp(blendmode, BLENDSTR_ADD))
			t->blendmode = BLEND_ADD;
		else if(!strcmp(blendmode, BLENDSTR_MOD))
			t->blendmode = BLEND_MOD;
		else if(!strcmp(blendmode, BLENDSTR_SUB))
			t->blendmode = BLEND_SUB;
		else
		{
			// NYI unknown blend
		}
		   
	return 0;
}

int texture_BlendMode(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	const char* returnstr;
	switch(t->blendmode)
	{
		case BLEND_DISABLED:
			returnstr = BLENDSTR_DISABLED;
			break;
		case BLEND_BLEND:
			returnstr = BLENDSTR_BLEND;
			break;
		case BLEND_ALPHAKEY:
			returnstr = BLENDSTR_ALPHAKEY;
			break;
		case BLEND_ADD:
			returnstr = BLENDSTR_ADD;
			break;
		case BLEND_MOD:
			returnstr = BLENDSTR_MOD;
			break;
		case BLEND_SUB:
			returnstr = BLENDSTR_SUB;
			break;
		default:
			luaL_error(lua, "Bogus blend mode found! Please report.");
			return 0; // Error, unknown event
//			returnstr = BLENDSTR_DISABLED; // This should never happen!! Error case NYI
			break;
	}
	lua_pushstring(lua, returnstr);
	return 1;
}


void drawLineToTexture(urAPI_Texture_t *texture, float startx, float starty, float endx, float endy);

int texture_Line(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float startx = luaL_checknumber(lua, 2);
	float starty = luaL_checknumber(lua, 3);
	float endx = luaL_checknumber(lua, 4);
	float endy = luaL_checknumber(lua, 5);

	if(t->backgroundTex != nil)
		drawLineToTexture(t, startx, starty, endx, endy);
	return 0;
}

void drawEllipseToTexture(urAPI_Texture_t *texture, float x, float y, float w, float h);

int texture_Ellipse(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float x = luaL_checknumber(lua, 2);
	float y = luaL_checknumber(lua, 3);
	float w = luaL_checknumber(lua, 4);
	float h = luaL_checknumber(lua, 5);
	
	if(t->backgroundTex != nil)
		drawEllipseToTexture(t, x, y, w, h);
	return 0;
}

void drawQuadToTexture(urAPI_Texture_t *texture, float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4);

int texture_Quad(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float x1 = luaL_checknumber(lua, 2);
	float y1 = luaL_checknumber(lua, 3);
	float x2 = luaL_checknumber(lua, 4);
	float y2 = luaL_checknumber(lua, 5);
	float x3 = luaL_checknumber(lua, 6);
	float y3 = luaL_checknumber(lua, 7);
	float x4 = luaL_checknumber(lua, 8);
	float y4 = luaL_checknumber(lua, 9);
	
	if(t->backgroundTex != nil)
		drawQuadToTexture(t, x1, y1, x2, y2, x3, y3, x4, y4);
	return 0;
}

int texture_Rect(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float x = luaL_checknumber(lua, 2);
	float y = luaL_checknumber(lua, 3);
	float w = luaL_checknumber(lua, 4);
	float h = luaL_checknumber(lua, 5);
	
	if(t->backgroundTex != nil)
		drawQuadToTexture(t, x, y, x+w, y, x+w, y+h, x, y+h);
	return 0;
}

int texture_SetFill(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	bool fill = lua_toboolean(lua,2); //!lua_isnil(lua,2);
	t->fill = fill;
	return 0;
}

void clearTexture(Texture2D* t, float r, float g, float b);

int texture_Clear(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float r = 0.0;
	float g = 0.0;
	float b = 0.0;
	if(lua_gettop(lua)==4)
	{
		r = luaL_checknumber(lua, 2);
		g = luaL_checknumber(lua, 3);
		b = luaL_checknumber(lua, 4);
	}	

	if(t->backgroundTex == nil && t->texturepath != TEXTURE_SOLID)
		instantiateTexture(t->region);

	if(t->backgroundTex != nil)
		clearTexture(t->backgroundTex,r,g,b);
	return 0;
}

void ClearBrushTexture();

int texture_ClearBrush(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	[t->backgroundTex release];
	t->backgroundTex = nil;
	ClearBrushTexture();
}

void drawPointToTexture(urAPI_Texture_t *texture, float x, float y);

int texture_Point(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float x = luaL_checknumber(lua, 2);
	float y = luaL_checknumber(lua, 3);
	
	if(t->backgroundTex != nil)
		drawPointToTexture(t, x, y);
	return 0;
}

void SetBrushSize(float size);

int texture_SetBrushSize(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float size = luaL_checknumber(lua, 2);
	SetBrushSize(size);
	return 0;
}


int texture_SetBrushColor(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float vertR = luaL_checknumber(lua, 2);
	float vertG = luaL_checknumber(lua, 3);
	float vertB = luaL_checknumber(lua, 4);
	float vertA = 255;
	if(lua_gettop(lua)==5)
		vertA = luaL_checknumber(lua, 5);
	t->texturebrushcolor[0] = vertR;
	t->texturebrushcolor[1] = vertG;
	t->texturebrushcolor[2] = vertB;
	t->texturebrushcolor[3] = vertA;
	return 0;
}

float BrushSize();

int texture_BrushSize(lua_State* lua)
{
	urAPI_Texture_t* t = checktexture(lua, 1);
	float size = BrushSize();
	lua_pushnumber(lua, size);
	return 1;
}

void SetBrushTexture(Texture2D* t);

int region_UseAsBrush(lua_State* lua)
{
	urAPI_Region_t* t = checkregion(lua, 1);

	if(t->texture->backgroundTex == nil && t->texture->texturepath != TEXTURE_SOLID)
		instantiateTexture(t);
	SetBrushTexture(t->texture->backgroundTex);

	return 0;
}

int textlabel_Font(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	lua_pushstring(lua, t->font);
	return 1;
}

int textlabel_SetFont(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	t->font = luaL_checkstring(lua,2); // NYI
	return 0;
}


const char JUSTIFYH_STRING_CENTER[] = "CENTER";
const char JUSTIFYH_STRING_LEFT[] = "LEFT";
const char JUSTIFYH_STRING_RIGHT[] = "RIGHT";

const char JUSTIFYV_STRING_MIDDLE[] = "MIDDLE";
const char JUSTIFYV_STRING_TOP[] = "TOP";
const char JUSTIFYV_STRING_BOTTOM[] = "BOTTOM";


int textlabel_HorizontalAlign(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	const char* justifyh;
	switch(t->justifyh)
	{
		case JUSTIFYH_CENTER:
			justifyh = JUSTIFYH_STRING_CENTER;
			break;
		case JUSTIFYH_LEFT:
			justifyh = JUSTIFYH_STRING_LEFT;
			break;
		case JUSTIFYH_RIGHT:
			justifyh = JUSTIFYH_STRING_RIGHT;
			break;
	}
	lua_pushstring(lua, justifyh);
	return 1;
}


int textlabel_SetHorizontalAlign(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	const char* justifyh = luaL_checkstring(lua, 2);
	
	if(!strcmp(justifyh, JUSTIFYH_STRING_CENTER))
		t->justifyh = JUSTIFYH_CENTER;
	else if(!strcmp(justifyh, JUSTIFYH_STRING_LEFT))
		t->justifyh = JUSTIFYH_LEFT;
	else if(!strcmp(justifyh, JUSTIFYH_STRING_RIGHT))
		t->justifyh = JUSTIFYH_RIGHT;
	return 0;
}

int textlabel_VerticalAlign(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	const char* justifyv;
	switch(t->justifyv)
	{
		case JUSTIFYV_MIDDLE:
			justifyv = JUSTIFYV_STRING_MIDDLE;
			break;
		case JUSTIFYV_TOP:
			justifyv = JUSTIFYV_STRING_TOP;
			break;
		case JUSTIFYV_BOTTOM:
			justifyv = JUSTIFYV_STRING_BOTTOM;
			break;
	}
	lua_pushstring(lua, justifyv);
	return 1;
}

int textlabel_SetVerticalAlign(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	const char* justifyv = luaL_checkstring(lua, 2);
	
	if(!strcmp(justifyv, JUSTIFYV_STRING_MIDDLE))
		t->justifyv = JUSTIFYV_MIDDLE;
	else if(!strcmp(justifyv, JUSTIFYV_STRING_TOP))
		t->justifyv = JUSTIFYV_TOP;
	else if(!strcmp(justifyv, JUSTIFYV_STRING_BOTTOM))
		t->justifyv = JUSTIFYV_BOTTOM;
	return 0;
}

int textlabel_SetWrap(lua_State* lua)
{
	urAPI_TextLabel_t* textlabel = checktextlabel(lua,1);
	const char* wrap = luaL_checkstring(lua,2);
	if(wrap)
	{
		textlabel->wrap = textlabel_wrap2index(wrap);
	}
	return 0;
}


int textlabel_Wrap(lua_State* lua)
{
	urAPI_TextLabel_t* textlabel = checktextlabel(lua,1);
	lua_pushstring(lua, textlabel_wrapindex2str(textlabel->wrap));
	return 1;
}

int textlabel_ShadowColor(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	lua_pushnumber(lua, t->shadowcolor[0]);
	lua_pushnumber(lua, t->shadowcolor[1]);
	lua_pushnumber(lua, t->shadowcolor[2]);
	lua_pushnumber(lua, t->shadowcolor[3]);
	return 4;
}

int textlabel_SetShadowColor(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	t->shadowcolor[0] = luaL_checknumber(lua,2);
	t->shadowcolor[1] = luaL_checknumber(lua,3);
	t->shadowcolor[2] = luaL_checknumber(lua,4);
	t->shadowcolor[3] = luaL_checknumber(lua,5);
	t->drawshadow = true;
	t->updatestring = true;
	return 0;
}

int textlabel_ShadowOffset(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	lua_pushnumber(lua, t->shadowoffset[0]);
	lua_pushnumber(lua, t->shadowoffset[1]);
	return 2;
}

int textlabel_SetShadowOffset(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	t->shadowoffset[0] = luaL_checknumber(lua,2);
	t->shadowoffset[1] = luaL_checknumber(lua,3);
	t->updatestring = true;
	return 0;
}

int textlabel_ShadowBlur(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	lua_pushnumber(lua, t->shadowblur);
	return 1;
}

int textlabel_SetShadowBlur(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	t->shadowblur = luaL_checknumber(lua,2);
	t->updatestring = true;
	return 0;
}

int textlabel_Spacing(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	lua_pushnumber(lua, t->linespacing);
	return 1;
}

int textlabel_SetSpacing(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	t->linespacing = luaL_checknumber(lua,2);
	return 0;
}

int textlabel_Color(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	lua_pushnumber(lua, t->textcolor[0]);
	lua_pushnumber(lua, t->textcolor[1]);
	lua_pushnumber(lua, t->textcolor[2]);
	lua_pushnumber(lua, t->textcolor[3]);
	return 4;
}

int textlabel_SetColor(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	t->textcolor[0] = luaL_checknumber(lua,2);
	t->textcolor[1] = luaL_checknumber(lua,3);
	t->textcolor[2] = luaL_checknumber(lua,4);
	t->textcolor[3] = luaL_checknumber(lua,5);
	return 0;
}

int textlabel_Height(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	lua_pushnumber(lua, t->stringheight); // NYI
	return 1;
}

int textlabel_Width(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	lua_pushnumber(lua, t->stringwidth); // NYI
	return 1;
}

int textlabel_SetLabelHeight(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	t->textheight = luaL_checknumber(lua,2);
	return 0;
}

int textlabel_Label(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	lua_pushstring(lua, t->text);
	return 1;
}

int textlabel_SetLabel(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	const char* text = luaL_checkstring(lua,2);
	
	if(t->text != NULL && t->text != textlabel_empty)
		free(t->text);
	t->text = (char*)malloc(strlen(text)+1);
	strcpy(t->text, text);

	t->updatestring = true;
	return 0;
}

int textlabel_SetFormattedText(lua_State* lua)
{
	urAPI_TextLabel_t* t = checktextlabel(lua, 1);
	const char* text = luaL_checkstring(lua,2);
	
	if(t->text != NULL && t->text != textlabel_empty)
		free(t->text);
	t->text = (char*)malloc(strlen(text)+1);
	strcpy(t->text, text);

	// NYI
	
	return 0;
}


static const struct luaL_reg textlabelfuncs [] =
{
	{"Font", textlabel_Font},
	{"HorizontalAlign", textlabel_HorizontalAlign},
	{"VerticalAlign", textlabel_VerticalAlign},
	{"ShadowColor", textlabel_ShadowColor},
	{"ShadowOffset", textlabel_ShadowOffset},
	{"ShadowBlur", textlabel_ShadowBlur},
	{"Spacing", textlabel_Spacing},
	{"Color", textlabel_Color},
	{"SetFont", textlabel_SetFont},
	{"SetHorizontalAlign", textlabel_SetHorizontalAlign},
	{"SetVerticalAlign", textlabel_SetVerticalAlign},
	{"SetShadowColor", textlabel_SetShadowColor},
	{"SetShadowOffset", textlabel_SetShadowOffset},
	{"SetShadowBlur", textlabel_SetShadowBlur},
	{"SetSpacing", textlabel_SetSpacing},
	{"SetColor", textlabel_SetColor},
	{"Height", textlabel_Height},
	{"Width", textlabel_Width},
	{"Label", textlabel_Label},
	{"SetFormattedText", textlabel_SetFormattedText},
	{"SetWrap", textlabel_SetWrap},
	{"Wrap", textlabel_Wrap},
	{"SetLabel", textlabel_SetLabel},
	{"SetLabelHeight", textlabel_SetLabelHeight},
	{NULL, NULL}
};

static const struct luaL_reg texturefuncs [] =
{
	{"SetTexture", texture_SetTexture},
//	{"SetGradient", texture_SetGradient},
	{"SetGradientColor", texture_SetGradientColor},
	{"Texture", texture_Texture},
	{"SetSolidColor", texture_SetSolidColor},
	{"SolidColor", texture_SolidColor},
	{"SetTexCoord", texture_SetTexCoord},
	{"TexCoord", texture_TexCoord},
	{"SetRotation", texture_SetRotation},
	{"SetTexCoordModifiesRect", texture_SetTexCoordModifiesRect},
	{"TexCoordModifiesRect", texture_TexCoordModifiesRect},
	{"SetDesaturated", texture_SetDesaturated},
	{"IsDesaturated", texture_IsDesaturated},
	{"SetBlendMode", texture_SetBlendMode},
	{"BlendMode", texture_BlendMode},
	{"Line", texture_Line},
	{"Point", texture_Point},
	{"Ellipse", texture_Ellipse},
	{"Quad", texture_Quad},
	{"Rect", texture_Rect},
	{"Clear", texture_Clear},
	{"ClearBrush", texture_ClearBrush},
	{"SetFill", texture_SetFill},
	{"SetBrushSize", texture_SetBrushSize},
	{"BrushSize", texture_BrushSize},
	{"SetBrushColor", texture_SetBrushColor},
	{NULL, NULL}
};

static const struct luaL_reg regionfuncs [] = 
{
	{"EnableMoving", region_EnableMoving},
	{"EnableResizing", region_EnableResizing},
	{"Handle", region_Handle},
	{"SetHeight", region_SetHeight},
	{"SetWidth", region_SetWidth},
	{"Show", region_Show},
	{"Hide", region_Hide},
	{"EnableInput", region_EnableInput},
	{"EnableHorizontalScroll", region_EnableHorizontalScroll},
	{"EnableVerticalScroll", region_EnableVerticalScroll},
	{"SetAnchor", region_SetAnchor},
	{"SetLayer", region_SetLayer},
	{"Parent", region_Parent},
	{"Children", region_Children},
	{"Name", region_Name},
	{"Bottom", region_Bottom},
	{"Center", region_Center},
	{"Height", region_Height},
	{"Left", region_Left},
	{"NumAnchors", region_NumAnchors},
	{"Anchor", region_Anchor},
	{"Right", region_Right},
	{"Top", region_Top},
	{"Width", region_Width},
	{"IsShown", region_IsShown},
	{"IsVisible", region_IsVisible},
	{"SetParent", region_SetParent},
	{"SetAlpha", region_SetAlpha},
	{"Alpha", region_Alpha},
	{"Layer", region_Layer},
	{"Texture", region_Texture},
	{"TextLabel", region_TextLabel},
	// NEW!!
	{"Lower", region_Lower},
	{"Raise", region_Raise},
	{"IsToplevel", region_IsToplevel},
	{"MoveToTop", region_MoveToTop},
	{"EnableClamping", region_EnableClamping},
	// ENDNEW!!
	{"RegionOverlap", region_RegionOverlap},
	{"UseAsBrush", region_UseAsBrush},
	{"EnableClipping", region_EnableClipping},
	{"SetClipRegion", region_SetClipRegion},
	{"ClipRegion", region_ClipRegion},
	{NULL, NULL}
};

void addChild(urAPI_Region_t *parent, urAPI_Region_t *child)
{
	if(parent->firstchild == NULL)
		parent->firstchild = child;
	else
	{
		urAPI_Region_t *findlast = parent->firstchild;
		while(findlast->nextchild != NULL)
		{
			findlast = findlast->nextchild;
		}
		if(findlast->nextchild != child)
			findlast->nextchild = child;
	}
}

void removeChild(urAPI_Region_t *parent, urAPI_Region_t *child)
{
	if(parent->firstchild != NULL)
	{
		if(parent->firstchild == child)
		{
			parent->firstchild = parent->firstchild->nextchild;
		}
		else
		{
			urAPI_Region_t *findlast = parent->firstchild;
			while(findlast->nextchild != NULL && findlast->nextchild != child)
			{
				findlast = findlast->nextchild;
			}
			if(findlast->nextchild == child)
			{
				findlast->nextchild = findlast->nextchild->nextchild;	
				child->nextchild = NULL;
			}
			else
			{
				int a = 0;
			}
		}
	}
}

static int l_Region(lua_State *lua)
{
	const char *regiontype = NULL;
	const char *regionName = NULL;
	urAPI_Region_t *parentRegion = NULL;

	if(lua_gettop(lua)>0) // Allow for no arg construction
	{
	
		regiontype = luaL_checkstring(lua, 1);
		regionName = luaL_checkstring(lua, 2);
	
		//	urAPI_Region_t *parentRegion = (urAPI_Region_t*)luaL_checkudata(lua, 4, "URAPI.region");
		luaL_checktype(lua, 3, LUA_TTABLE);
		lua_rawgeti(lua, 3, 0);
		parentRegion = (urAPI_Region_t*)lua_touserdata(lua,4);
		luaL_argcheck(lua, parentRegion!= NULL, 4, "'region' expected");
		//	const char *inheritsRegion = luaL_checkstring(lua, 1); //NYI
	}
	else
	{
		parentRegion = UIParent;
	}
		
	// NEW!! Return region in a table at index 0
	
	lua_newtable(lua);
	luaL_register(lua, NULL, regionfuncs);
	//	urAPI_Region_t *myregion = (urAPI_Region_t*)lua_newuserdata(lua, sizeof(urAPI_Region_t)); // User data is our value
	urAPI_Region_t *myregion = (urAPI_Region_t*)malloc(sizeof(urAPI_Region_t)); // User data is our value
	lua_pushlightuserdata(lua, myregion);
	lua_rawseti(lua, -2, 0); // Set this to index 0
	myregion->tableref = luaL_ref(lua, LUA_REGISTRYINDEX);
	lua_rawgeti(lua, LUA_REGISTRYINDEX, myregion->tableref);
	
	// ENDNEW!!
//	luaL_getmetatable(lua, "URAPI.region");
//	lua_setmetatable(lua, -2);
	
	
	myregion->next = nil;
	myregion->parent = parentRegion;
	myregion->firstchild = NULL;
	myregion->nextchild = NULL;
//	addChild(parentRegion, myregion);
	//	myregion->name = regionName; // NYI
	
	// Link it into the global region list
	
	myregion->name = regionName;
	myregion->type = regiontype;
	myregion->ofsx = 0.0;
	myregion->ofsy = 0.0;
	myregion->width = 160.0;
	myregion->height = 160.0;
	myregion->bottom = 1.0;
	myregion->left = 1.0;
	myregion->top = myregion->bottom + myregion->height;
	myregion->right = myregion->left + myregion->width;
	myregion->cx = 80.0;
	myregion->cy = 80.0;
	myregion->ofsx = 0.0;
	myregion->ofsy = 0.0;
	
	myregion->clipleft = 0.0;
	myregion->clipbottom = 0.0;
	myregion->clipwidth = SCREEN_WIDTH;
	myregion->clipheight = SCREEN_HEIGHT;
	
	myregion->alpha = 1.0;
	
	myregion->isMovable = false;
	myregion->isResizable = false;
	myregion->isTouchEnabled = false;
	myregion->isScrollXEnabled = false;
	myregion->isScrollYEnabled = false;
	myregion->isVisible = false;
	myregion->isDragged = false;
	myregion->isClamped = false;
	myregion->isClipping = false;
	
	myregion->entered = false;
	
	myregion->strata = STRATA_PARENT;
	
	myregion->OnDragStart = 0;
	myregion->OnDragStop = 0;
	myregion->OnEnter = 0;
	myregion->OnEvent = 0;
	myregion->OnHide = 0;
	myregion->OnLeave = 0;
	myregion->OnTouchDown = 0;
	myregion->OnTouchUp = 0;
	myregion->OnShow = 0;
	myregion->OnShow = 0;
	myregion->OnSizeChanged = 0; // needs args (NYI)
	myregion->OnUpdate = 0;
	myregion->OnDoubleTap = 0; // (UR!)
	// All UR!
	myregion->OnAccelerate = 0;
	myregion->OnNetIn = 0;
#ifdef SANDWICH_SUPPORT
	myregion->OnPressure = 0;
#endif
	myregion->OnHeading = 0;
	myregion->OnLocation = 0;
	myregion->OnMicrophone = 0;
	myregion->OnHorizontalScroll = 0;
	myregion->OnVerticalScroll = 0;
	myregion->OnPageEntered = 0;
	myregion->OnPageLeft = 0;
	
	myregion->texture = NULL;
	myregion->textlabel = NULL;
	
	myregion->point = NULL;
	myregion->relativePoint = NULL;
	myregion->relativeRegion = NULL;
	
	if(firstRegion[currentPage] == nil) // first region ever
	{
		firstRegion[currentPage] = myregion;
		lastRegion[currentPage] = myregion;
		myregion->next = NULL;
		myregion->prev = NULL;
	}
	else
	{
		myregion->prev = lastRegion[currentPage];
		lastRegion[currentPage]->next = myregion;
		lastRegion[currentPage] = myregion;
		l_setstrataindex(myregion , myregion->strata);
	}
	// NEW!!
	numRegions[currentPage] ++;
	// ENDNEW!!

	setParent(myregion, parentRegion);
	
	return 1;
}

int flowbox_Name(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	lua_pushstring(lua, fb->object->name);
	return 1;
}

// Object to to PushOut from.
// In to PushOut into.
// Needs ID on specific IN
int flowbox_SetPushLink(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);

	int outindex = luaL_checknumber(lua,2);
	ursAPI_FlowBox_t* target = checkflowbox(lua, 3);
	int inindex = luaL_checknumber(lua, 4);
	
	if(outindex >= fb->object->nr_outs || inindex >= target->object->nr_ins)
	{
		return 0;
	}
	
	fb->object->AddPushOut(outindex, &target->object->ins[inindex]);

    lua_pushboolean(lua, 1);
	return 1;
}

int flowbox_SetPullLink(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	
	int inindex = luaL_checknumber(lua,2);
	ursAPI_FlowBox_t* target = checkflowbox(lua, 3);
	int outindex = luaL_checknumber(lua, 4);
	
	if(inindex >= fb->object->nr_ins || outindex >= target->object->nr_outs)
	{
		return 0;
	}
	
	fb->object->AddPullIn(inindex, &target->object->outs[outindex]);

	if(!strcmp(fb->object->name,dacobject->name)) // This is hacky and should be done differently. Namely in the sink pulling
		urActiveDacTickSinkList.AddSink(&target->object->outs[outindex]);
	
	if(!strcmp(fb->object->name,visobject->name)) // This is hacky and should be done differently. Namely in the sink pulling
		urActiveVisTickSinkList.AddSink(&target->object->outs[outindex]);

	if(!strcmp(fb->object->name,netobject->name)) // This is hacky and should be done differently. Namely in the sink pulling
		urActiveNetTickSinkList.AddSink(&target->object->outs[outindex]);
    
	lua_pushboolean(lua, 1);
	return 1;
}

int flowbox_IsPushed(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	
	int outindex = luaL_checknumber(lua,2);
	ursAPI_FlowBox_t* target = checkflowbox(lua, 3);
	int inindex = luaL_checknumber(lua, 4);

	if(outindex >= fb->object->nr_outs || inindex >= target->object->nr_ins)
	{
		return 0;
	}
	
	if(fb->object->IsPushedOut(outindex, &target->object->ins[inindex]))
	{
		lua_pushboolean(lua,1);
		return 1;
	}
	else
		return 0;
}

int flowbox_IsPulled(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	
	int inindex = luaL_checknumber(lua,2);
	ursAPI_FlowBox_t* target = checkflowbox(lua, 3);
	int outindex = luaL_checknumber(lua, 4);
	
	if(inindex >= fb->object->nr_ins || outindex >= target->object->nr_outs)
	{
		return 0;
	}
	
	if(fb->object->IsPulledIn(inindex, &target->object->outs[outindex]))
	{
	    lua_pushboolean(lua, 1);
		return 1;
	}
	else
		return 0;
}

int flowbox_RemovePushLink(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	
	int outindex = luaL_checknumber(lua,2);
	ursAPI_FlowBox_t* target = checkflowbox(lua, 3);
	int inindex = luaL_checknumber(lua, 4);
	
	if(outindex >= fb->object->nr_outs || inindex >= target->object->nr_ins)
	{
		return 0;
	}
	
	fb->object->RemovePushOut(outindex, &target->object->ins[inindex]);

    lua_pushboolean(lua, 1);
	return 1;
}

int flowbox_RemovePullLink(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	
	int inindex = luaL_checknumber(lua,2);
	ursAPI_FlowBox_t* target = checkflowbox(lua, 3);
	int outindex = luaL_checknumber(lua, 4);
	
	if(inindex >= fb->object->nr_ins || outindex >= target->object->nr_outs)
	{
		return 0;
	}
	
	fb->object->RemovePullIn(inindex, &target->object->outs[outindex]);
	
	if(!strcmp(fb->object->name,dacobject->name)) // This is hacky and should be done differently. Namely in the sink pulling
		urActiveDacTickSinkList.RemoveSink(&target->object->outs[outindex]);
	
	if(!strcmp(fb->object->name,visobject->name)) // This is hacky and should be done differently. Namely in the sink pulling
		urActiveVisTickSinkList.RemoveSink(&target->object->outs[outindex]);

	if(!strcmp(fb->object->name,netobject->name)) // This is hacky and should be done differently. Namely in the sink pulling
		urActiveNetTickSinkList.RemoveSink(&target->object->outs[outindex]);
	
    lua_pushboolean(lua, 1);
	return 1;
}

int flowbox_IsPushing(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	int index = luaL_checknumber(lua,2);
	lua_pushboolean(lua, fb->object->firstpullin[index]!=NULL);
	return 1;
}

int flowbox_IsPulling(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	int index = luaL_checknumber(lua,2);
	lua_pushboolean(lua, fb->object->firstpushout[index]!=NULL);
	return 1;
}

int flowbox_IsPlaced(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	int index = luaL_checknumber(lua,2);
	lua_pushboolean(lua, fb->object->ins[index].isplaced);
	return 1;
}

int flowbox_NumIns(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);

	lua_pushnumber(lua, fb->object->nr_ins);
	return 1;
}

int flowbox_NumOuts(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	
	lua_pushnumber(lua, fb->object->nr_outs);
	return 1;
}

int flowbox_Ins(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	
	int nrins = fb->object->nr_ins;
	for(int j=0; j< nrins; j++)
//		if(fb->object->ins[j].name!=(void*)0x1)
			lua_pushstring(lua, fb->object->ins[j].name);
//		else {
//			int a=2;
//		}

	return nrins;
}

int flowbox_Outs(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	
	int nrouts = fb->object->nr_outs;
	for(int j=0; j< nrouts; j++)
		lua_pushstring(lua, fb->object->outs[j].name);
	return nrouts;
}

int flowbox_Push(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	float indata = luaL_checknumber(lua, 2);

	fb->object->CallAllPushOuts(indata);
/*	if(fb->object->firstpushout[0]!=NULL)
	{
		ursObject* inobject;
		urSoundPushOut* pushto = fb->object->firstpushout[0];
		for(;pushto!=NULL; pushto = pushto->next)
		{	
			urSoundIn* in = pushto->in;
			inobject = in->object;
			in->inFuncTick(inobject, indata);
		}
	}*/
//	callAllPushSources(indata);

	return 0;
}

int flowbox_Pull(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	float indata = luaL_checknumber(lua, 2);
	
	fb->object->CallAllPushOuts(indata);
	
	return 0;
}

extern double visoutdata;

int flowbox_Get(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
//	float indata = luaL_checknumber(lua, 2);
	
	lua_pushnumber(lua, visoutdata);
	
	return 1;
}

int flowbox_AddFile(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	const char* filename = luaL_checkstring(lua, 2);

	if(!strcmp(fb->object->name, "Sample"))
	{
		Sample_AddFile(fb->object, filename);
	}
}

int flowbox_IsInstantiable(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	lua_pushboolean(lua, !fb->object->noninstantiable);
	return 1;
}

int flowbox_InstanceNumber(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	lua_pushnumber(lua, fb->object->instancenumber);
	return 1;
}

int flowbox_NumberInstances(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	lua_pushnumber(lua, fb->object->instancelist->Last());
	return 1;
}

int flowbox_Couple(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	if(fb->object->iscoupled)
	{
		lua_pushnumber(lua, fb->object->couple_in);
		lua_pushnumber(lua, fb->object->couple_out);
		return 2;
	}
	else
		return 0;
}

int flowbox_IsCoupled(lua_State *lua)
{
	ursAPI_FlowBox_t* fb = checkflowbox(lua, 1);
	lua_pushboolean(lua, fb->object->iscoupled);
	return 1;
}

// Methods table for the flowbox API

static const struct luaL_reg flowboxfuncs [] = 
{
{"Name", flowbox_Name},
{"NumIns", flowbox_NumIns},
{"NumOuts", flowbox_NumOuts},
{"Ins", flowbox_Ins},
{"Outs", flowbox_Outs},
{"SetPushLink", flowbox_SetPushLink},
{"SetPullLink", flowbox_SetPullLink},
{"RemovePushLink", flowbox_RemovePushLink},
{"RemovePullLink", flowbox_RemovePullLink},
{"IsPushed", flowbox_IsPushed},
{"IsPulled", flowbox_IsPulled},
{"Push", flowbox_Push},
{"Pull", flowbox_Pull},
{"Get", flowbox_Get},
{"AddFile", flowbox_AddFile},
{"IsInstantiable", flowbox_IsInstantiable},
{"InstanceNumber", flowbox_InstanceNumber},
{"NumberInstances", flowbox_NumberInstances},
{"Couple", flowbox_Couple},
{"IsCoupled", flowbox_IsCoupled},
{NULL, NULL}
};

static int l_FlowBox(lua_State* lua)
{
	const char *flowboxtype = luaL_checkstring(lua, 1);
	const char *flowboxName = luaL_checkstring(lua, 2);

	//	urAPI_flowbox_t *parentflowbox = (urAPI_flowbox_t*)luaL_checkudata(lua, 4, "URAPI.flowbox");
	luaL_checktype(lua, 3, LUA_TTABLE);
	lua_rawgeti(lua, 3, 0);
	ursAPI_FlowBox_t *parentFlowBox = (ursAPI_FlowBox_t*)lua_touserdata(lua,4);
	luaL_argcheck(lua, parentFlowBox!= NULL, 4, "'flowbox' expected");
	//	const char *inheritsflowbox = luaL_checkstring(lua, 1); //NYI

	// NEW!! Return flowbox in a table at index 0

	lua_newtable(lua);
	luaL_register(lua, NULL, flowboxfuncs);
	ursAPI_FlowBox_t *myflowbox = (ursAPI_FlowBox_t*)malloc(sizeof(ursAPI_FlowBox_t)); // User data is our value
	lua_pushlightuserdata(lua, myflowbox);
	lua_rawseti(lua, -2, 0); // Set this to index 0
	myflowbox->tableref = luaL_ref(lua, LUA_REGISTRYINDEX);
	lua_rawgeti(lua, LUA_REGISTRYINDEX, myflowbox->tableref);

	myflowbox->object = parentFlowBox->object->Clone();
//	myflowbox->object->instancenumber = parentFlowBox->object->instancenumber + 1;
	
	// ENDNEW!!
	//	luaL_getmetatable(lua, "URAPI.flowbox");
	//	lua_setmetatable(lua, -2);

	return 1;

}

void ur_GetSoundBuffer(SInt32* buffer, int channel, int size)
{
	lua_getglobal(lua,"urSoundData");
	lua_rawgeti(lua, -1, channel);
	if(lua_isnil(lua, -1) || !lua_istable(lua,-1)) // Channel doesn't exist or is falsely set up
	{
		lua_pop(lua,1);
		return;
	}
	
	for(int i=0; i<size; i++)
	{
		lua_rawgeti(lua, -1, i+1);
		if(lua_isnumber(lua, -1))
			buffer[i] = lua_tonumber(lua, -1);
		
		lua_pop(lua,1);	
	}
	
	lua_pop(lua, 2);
}



int l_SourceNames(lua_State *lua)
{
	int nr = urs_NumUrSourceObjects();
	for(int i=0; i<nr; i++)
	{
		lua_pushstring(lua, urs_GetSourceObjectName(i));
	}
	return nr;	
}

int l_ManipulatorNames(lua_State *lua)
{
	int nr = urs_NumUrManipulatorObjects();
	for(int i=0; i<nr; i++)
	{
		lua_pushstring(lua, urs_GetManipulatorObjectName(i));
	}
	return nr;
}

int l_SinkNames(lua_State *lua)
{
	int nr = urs_NumUrSinkObjects();
	for(int i=0; i<nr; i++)
	{
		lua_pushstring(lua, urs_GetSinkObjectName(i));
	}
	return nr;
}

#ifdef ALLOW_DEFUNCT
int l_NumUrIns(lua_State *lua)
{
	const char* obj = luaL_checkstring(lua, 1);
	int nr = urs_NumUrManipulatorObjects();
	for(int i=0; i<nr; i++)
	{
		if(!strcmp(obj, urs_GetManipulatorObjectName(i)))
		{
			lua_pushnumber(lua, urs_NumUrManipulatorIns(i));
			return 1;
		}
	}	
	nr = urs_NumUrSinkObjects();
	for(int i=0; i<nr; i++)
	{
		if(!strcmp(obj, urs_GetSinkObjectName(i)))
		{
			lua_pushnumber(lua, urs_NumUrSinkIns(i));
			return 1;
		}
	}
	return 0;
}

int l_NumUrOuts(lua_State *lua)
{
	const char* obj = luaL_checkstring(lua, 1);
	int nr = urs_NumUrSourceObjects();
	for(int i=0; i<nr; i++)
	{
		if(!strcmp(obj, urs_GetSourceObjectName(i)))
		{
			lua_pushnumber(lua, urs_NumUrSourceOuts(i));
			return 1;
		}
	}	
	nr = urs_NumUrManipulatorObjects();
	for(int i=0; i<nr; i++)
	{
		if(!strcmp(obj, urs_GetManipulatorObjectName(i)))
		{
			lua_pushnumber(lua, urs_NumUrManipulatorOuts(i));
			return 1;
		}
	}
	return 0;
}

int l_GetUrIns(lua_State *lua)
{
	const char* obj = luaL_checkstring(lua, 1);
	int nr = urs_NumUrManipulatorObjects();
	for(int i=0; i<nr; i++)
	{
		if(!strcmp(obj, urs_GetManipulatorObjectName(i)))
		{
			int nrins = urs_NumUrManipulatorIns(i);
			for(int j=0; j< nrins; j++)
				lua_pushstring(lua, urs_GetManipulatorIn(i, j));
			return nrins;
		}
	}	
	nr = urs_NumUrSinkObjects();
	for(int i=0; i<nr; i++)
	{
		if(!strcmp(obj, urs_GetSinkObjectName(i)))
		{
			int nrins = urs_NumUrSinkIns(i);
			for(int j=0; j< nrins; j++)
				lua_pushstring(lua, urs_GetSinkIn(i, j));
			return nrins;
		}
	}
	return 0;
}

int l_GetUrOuts(lua_State *lua)
{
	const char* obj = luaL_checkstring(lua, 1);
	int nr = urs_NumUrSourceObjects();
	for(int i=0; i<nr; i++)
	{
		if(!strcmp(obj, urs_GetSourceObjectName(i)))
		{
			int nrouts = urs_NumUrSourceOuts(i);
			for(int j=0; j< nrouts; j++)
				lua_pushstring(lua, urs_GetSourceOut(i, j));
			return nrouts;
		}
	}
	nr = urs_NumUrManipulatorObjects();
	for(int i=0; i<nr; i++)
	{
		if(!strcmp(obj, urs_GetManipulatorObjectName(i)))
		{
			int nrouts = urs_NumUrManipulatorOuts(i);
			for(int j=0; j< nrouts; j++)
				lua_pushstring(lua, urs_GetManipulatorOut(i, j));
			return nrouts;
		}
	}	
	return 0;
}
#endif

int l_SystemPath(lua_State *lua)
{
	const char* filename = luaL_checkstring(lua,1);
	NSString *filename2 = [[NSString alloc] initWithCString:filename]; 
	NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename2];
	const char* filestr = [filePath UTF8String];
	lua_pushstring(lua, filestr);
	return 1;
}

int l_DocumentPath(lua_State *lua)
{
	const char* filename = luaL_checkstring(lua,1);
	NSString *filename2 = [[NSString alloc] initWithCString:filename]; 
	NSArray *paths;
	paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	if ([paths count] > 0) {
		NSString *filePath = [paths objectAtIndex:0];
		NSString *resultPath = [NSString stringWithFormat:@"%@/%@", filePath, filename2];
		const char* filestr = [resultPath UTF8String];
		lua_pushstring(lua, filestr);
	}
	else
	{
		luaL_error(lua, "Cannot find the Document path.");
	}
	return 1;
}

int l_NumMaxPages(lua_State *lua)
{
	int max = MAX_PAGES;
	lua_pushnumber(lua, max);
	return 1;
}

int l_Page(lua_State *lua)
{
	lua_pushnumber(lua, currentPage+1);
	return 1;
}

int l_SetPage(lua_State *lua)
{
	int oldcurrent;
	int num = luaL_checknumber(lua,1);
	if(num >= 1 and num <= MAX_PAGES)
	{
		callAllOnPageLeft(num-1);
		oldcurrent = currentPage;
		currentPage = num-1;
		callAllOnPageEntered(oldcurrent);
	}
	else
	{
		// Error!!
		luaL_error(lua, "Invalid page number: %d",num);
	}
	return 0;
}

//------------------------------------------------------------------------------
// Register our API
//------------------------------------------------------------------------------

void l_setupAPI(lua_State *lua)
{
	CGRect screendimensions = [[UIScreen mainScreen] bounds];
    
	SCREEN_WIDTH = screendimensions.size.width;
	SCREEN_HEIGHT = screendimensions.size.height;
	// Set global userdata
	// Create UIParent
//	luaL_newmetatable(lua, "URAPI.region");
//	lua_pushstring(lua, "__index");
//	lua_pushvalue(lua, -2);
//	lua_settable(lua, -3);
//	luaL_openlib(lua, NULL, regionfuncs, 0);
	lua_newtable(lua);
	luaL_register(lua, NULL, regionfuncs);
//	urAPI_Region_t *myregion = (urAPI_Region_t*)lua_newuserdata(lua, sizeof(urAPI_Region_t)); // User data is our value
	urAPI_Region_t *myregion = (urAPI_Region_t*)malloc(sizeof(urAPI_Region_t)); // User data is our value
	lua_pushlightuserdata(lua, myregion);
	lua_rawseti(lua, -2, 0); // Set this to index 0
	myregion->tableref = luaL_ref(lua, LUA_REGISTRYINDEX);
	lua_rawgeti(lua, LUA_REGISTRYINDEX, myregion->tableref);
//	luaL_getmetatable(lua, "URAPI.region");
//	lua_setmetatable(lua, -2);
	myregion->strata = STRATA_BACKGROUND;
	myregion->parent = NULL;
	myregion->top = SCREEN_HEIGHT;
	myregion->bottom = 0;
	myregion->left = 0;
	myregion->right = SCREEN_WIDTH;
	myregion->firstchild = NULL;
	myregion->point = NULL;
	myregion->relativePoint = NULL;
	UIParent = myregion;
	lua_setglobal(lua, "UIParent");

	urs_SetupObjects();
	
	char fbname[255];
	for(int source=0; source<ursourceobjectlist.Last(); source++)
	{
		lua_newtable(lua);
		luaL_register(lua, NULL, flowboxfuncs);
		ursAPI_FlowBox_t *myflowbox = (ursAPI_FlowBox_t*)malloc(sizeof(ursAPI_FlowBox_t)); // User data is our value
		lua_pushlightuserdata(lua, myflowbox);
		lua_rawseti(lua, -2, 0); // Set this to index 0
		myflowbox->tableref = luaL_ref(lua, LUA_REGISTRYINDEX);
		lua_rawgeti(lua, LUA_REGISTRYINDEX, myflowbox->tableref);
		//	luaL_getmetatable(lua, "URAPI.region");
		//	lua_setmetatable(lua, -2);
		myflowbox->object = ursourceobjectlist[source];
		FBNope = myflowbox;
		strcpy(fbname, "FB");
		strcat(fbname, myflowbox->object->name);
		lua_setglobal(lua, fbname);
	}
	for(int manipulator=0; manipulator<urmanipulatorobjectlist.Last(); manipulator++)
	{
		lua_newtable(lua);
		luaL_register(lua, NULL, flowboxfuncs);
		ursAPI_FlowBox_t *myflowbox = (ursAPI_FlowBox_t*)malloc(sizeof(ursAPI_FlowBox_t)); // User data is our value
		lua_pushlightuserdata(lua, myflowbox);
		lua_rawseti(lua, -2, 0); // Set this to index 0
		myflowbox->tableref = luaL_ref(lua, LUA_REGISTRYINDEX);
		lua_rawgeti(lua, LUA_REGISTRYINDEX, myflowbox->tableref);
		//	luaL_getmetatable(lua, "URAPI.region");
		//	lua_setmetatable(lua, -2);
		myflowbox->object = urmanipulatorobjectlist[manipulator];
		FBNope = myflowbox;
		strcpy(fbname, "FB");
		strcat(fbname, myflowbox->object->name);
		lua_setglobal(lua, fbname);
	}
	for(int sink=0; sink<ursinkobjectlist.Last(); sink++)
	{
		lua_newtable(lua);
		luaL_register(lua, NULL, flowboxfuncs);
		ursAPI_FlowBox_t *myflowbox = (ursAPI_FlowBox_t*)malloc(sizeof(ursAPI_FlowBox_t)); // User data is our value
		lua_pushlightuserdata(lua, myflowbox);
		lua_rawseti(lua, -2, 0); // Set this to index 0
		myflowbox->tableref = luaL_ref(lua, LUA_REGISTRYINDEX);
		lua_rawgeti(lua, LUA_REGISTRYINDEX, myflowbox->tableref);
		//	luaL_getmetatable(lua, "URAPI.region");
		//	lua_setmetatable(lua, -2);
		myflowbox->object = ursinkobjectlist[sink];
		FBNope = myflowbox;
		strcpy(fbname, "FB");
		strcat(fbname, myflowbox->object->name);
		lua_setglobal(lua, fbname);
	}
	
	luaL_newmetatable(lua, "URAPI.texture");
	lua_pushstring(lua, "__index");
	lua_pushvalue(lua, -2);
	lua_settable(lua, -3);
//	luaL_openlib(lua, NULL, texturefuncs, 0);
	luaL_register(lua, NULL, texturefuncs);
	
	luaL_newmetatable(lua, "URAPI.textlabel");
	lua_pushstring(lua, "__index");
	lua_pushvalue(lua, -2);
	lua_settable(lua, -3);
//	luaL_openlib(lua, NULL, textlabelfuncs, 0);
	luaL_register(lua, NULL, textlabelfuncs);
	
	
	// Compats
	lua_pushcfunction(lua, l_Region);
	lua_setglobal(lua, "Region");
	// NEW!!
	lua_pushcfunction(lua, l_NumRegions);
	lua_setglobal(lua, "NumRegions");
	// ENDNEW!!
	lua_pushcfunction(lua, l_InputFocus);
	lua_setglobal(lua, "InputFocus");
	lua_pushcfunction(lua, l_HasInput);
	lua_setglobal(lua, "HasInput");
	lua_pushcfunction(lua, l_InputPosition);
	lua_setglobal(lua, "InputPosition");
	lua_pushcfunction(lua, l_ScreenHeight);
	lua_setglobal(lua, "ScreenHeight");
	lua_pushcfunction(lua, l_ScreenWidth);
	lua_setglobal(lua, "ScreenWidth");
	lua_pushcfunction(lua, l_Time);
	lua_setglobal(lua, "Time");
	lua_pushcfunction(lua, l_RunScript);
	lua_setglobal(lua, "RunScript");
	lua_pushcfunction(lua,l_StartAudio);
	lua_setglobal(lua,"StartAudio");
	lua_pushcfunction(lua,l_PauseAudio);
	lua_setglobal(lua,"PauseAudio");
	
	// HTTP
	lua_pushcfunction(lua,l_StartHTTPServer);
	lua_setglobal(lua,"StartHTTPServer");
	lua_pushcfunction(lua,l_StopHTTPServer);
	lua_setglobal(lua,"StopHTTPServer");
	lua_pushcfunction(lua,l_HTTPServer);
	lua_setglobal(lua,"HTTPServer");


	
	// UR!
	lua_pushcfunction(lua, l_setanimspeed);
	lua_setglobal(lua, "SetFrameRate");
	lua_pushcfunction(lua, l_DPrint);
	lua_setglobal(lua, "DPrint");
	// URSound!
	lua_pushcfunction(lua, l_SourceNames);
	lua_setglobal(lua, "SourceNames");
	lua_pushcfunction(lua, l_ManipulatorNames);
	lua_setglobal(lua, "ManipulatorNames");
	lua_pushcfunction(lua, l_SinkNames);
	lua_setglobal(lua, "SinkNames");
#ifdef ALLOW_DEFUNCT
	lua_pushcfunction(lua, l_NumUrIns);
	lua_setglobal(lua, "NumUrIns");
	lua_pushcfunction(lua, l_NumUrOuts);
	lua_setglobal(lua, "NumUrOuts");
	lua_pushcfunction(lua, l_GetUrIns);
	lua_setglobal(lua, "GetUrIns");
	lua_pushcfunction(lua, l_GetUrOuts);
	lua_setglobal(lua, "GetUrOuts");
#endif
	lua_pushcfunction(lua, l_FlowBox);
	lua_setglobal(lua, "FlowBox");
	
	lua_pushcfunction(lua, l_SystemPath);
	lua_setglobal(lua, "SystemPath");
	lua_pushcfunction(lua, l_DocumentPath);
	lua_setglobal(lua, "DocumentPath");

	lua_pushcfunction(lua, l_NumMaxPages);
	lua_setglobal(lua, "NumMaxPages");
	lua_pushcfunction(lua, l_Page);
	lua_setglobal(lua, "Page");
	lua_pushcfunction(lua, l_SetPage);
	lua_setglobal(lua, "SetPage");
	
	
	// Initialize the global mic buffer table
#ifdef MIC_ARRAY
	lua_newtable(lua);
	lua_setglobal(lua, "urMicData");
#endif	
	
#ifdef SOUND_ARRAY
	// NOTE: SOMETHING IS WEIRD HERE. CAUSES VARIOUS BUGS IF ONE WRITES TO THIS TABLE
	lua_newtable(lua);
	lua_newtable(lua);
	lua_rawseti(lua, -2, 1); // Setting up for stereo for now
	lua_newtable(lua);
	lua_rawseti(lua, -2, 2); // Can be extended to any number of channels here
	lua_setglobal(lua,"urSoundData");
#endif
	systimer = [MachTimer alloc];
	[systimer start];
}
