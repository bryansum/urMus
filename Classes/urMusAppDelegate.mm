//
//  urMusAppDelegate.m
//  urMus
//
//  Created by Georg Essl on 6/20/09.
//  Copyright Georg Essl 2009. All rights reserved. See LICENSE.txt for license conditions.
//

#import "urMusAppDelegate.h"
#import "EAGLView.h"
#include "urAPI.h"
#include "RIOAudioUnitLayer.h"
#include "lfs.h"
#include "luasocket.h"
#include "mime.h"

// This enables video projector output. It's not official API hence not safe for app store.
//#define PROJECTOR_VIDEO

#ifdef SANDWICH_SUPPORT
#import "SandwichUpdateListener.h"
#endif

@implementation urMusAppDelegate

@synthesize window;
@synthesize glView;

// Make EAGLview global so lua interface can grab it without breaking a leg over IMP
EAGLView* g_glView;

extern NSString* errorstr;
extern bool newerror;
extern int luaopen_rings (lua_State *L);

//------------------------------------------------------------------------------
// Application controls
//------------------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
	g_glView = glView;
	/* Declare a Lua State, open the Lua State and load the libraries (see above). */
	lua = lua_open();
	luaL_openlibs(lua);
	luaopen_rings(lua);
	luaopen_lfs(lua); // Added external luafilesystem, runs under lua's open license	
	luaopen_socket_core(lua); // Adding luasocket support
	luaopen_mime_core(lua);
	l_setupAPI(lua);
	

//	[[UIApplication] sharedApplication] startTVOut]; // This enables that the video data is send to the AV out for projection (it's a mirror)
#ifdef PROJECTOR_VIDEO
	[application startTVOut]; // This enables that the video data is send to the AV out for projection (it's a mirror)
#endif
	
#ifdef SANDWICH_SUPPORT
	// init SandwichUpdateListener
//	NSLog(@"Delegate: Starting Listener...");
	[SandwichUpdateListener initializeWithServerPort:4555 andDelegate:glView];
	[SandwichUpdateListener addDelegate: self];
	
	if([SandwichUpdateListener startListening])
	{
//		NSLog(@"Success!");  
	}
	else
	{
//		NSLog(@"Fail :(");  
	};
#endif
	
	[glView startAnimation];

	NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"urMus.lua"];
	const char* filestr = [filePath UTF8String];
	
	if(luaL_dofile(lua, filestr)!=0)
	{
		const char* error = lua_tostring(lua, -1);
		errorstr = [[NSString alloc] initWithCString:error ]; // DPrinting errors for now
		newerror = true;
	}
}

#ifdef SANDWICH_SUPPORT
- (void) rearTouchUpdate: (SandwichEventManager * ) sender;
{
	
}
- (void) pressureUpdate: (SandwichEventManager * ) sender;
{
	NSLog(@"Appdelegate - PressureUpate");
	int pressure[4];
	
	pressure[0] = sender.pressureValues[0];
	pressure[1] = sender.pressureValues[1];
	pressure[2] = sender.pressureValues[2];
	pressure[3] = sender.pressureValues[3];
}
#endif

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}


- (void)dealloc {
	/* Remember to destroy the Lua State */
	lua_close(lua);
	
	[window release];
	[glView release];
	[super dealloc];
}

@end
