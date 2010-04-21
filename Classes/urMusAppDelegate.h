//
//  urMusAppDelegate.h
//  urMus
//
//  Created by Georg Essl on 6/20/09.
//  Copyright Georg Essl 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "urAPI.h"

#ifdef SANDWICH_SUPPORT
#import "SandwichTypes.h"
#endif

@class EAGLView;

#ifdef SANDWICH_SUPPORT
@interface urMusAppDelegate : NSObject <UIApplicationDelegate,SandwichUpdateDelegate> {
#else
@interface urMusAppDelegate : NSObject <UIApplicationDelegate> {
#endif
	lua_State *lua;
    UIWindow *window;
    EAGLView *glView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

#ifdef SANDWICH_SUPPORT
- (void) rearTouchUpdate: (SandwichEventManager * ) sender;
- (void) pressureUpdate: (SandwichEventManager * ) sender;
#endif
	
@end

