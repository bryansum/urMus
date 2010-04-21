//
//  RearTouchController.h
//  GLGravity
//
//  Created by Sven Kratz on 6/7/09.
//  Copyright 2009 Deutsche Telekom Laboratories. All rights reserved.
//
//  Manages all Sandwich Rear events and pressure updates
//  Notifies delegate(s) of pressure updates
//
//


#import <UIKit/UIKit.h>
#import "SandwichTypes.h"

#define K_MAX_TOUCHES 5

@interface SandwichEventManager : NSObject {
	rear_touch_t * rTouches;
	rear_touch_t * iPreviousTouches;
	int _pressureValues[4];
	NSMutableArray * iDelegates;
}

@property(assign) rear_touch_t * rTouches;
@property(assign) rear_touch_t * iPreviousTouches;
@property(readonly) int * pressureValues;





- (void) updateTouchEvents: (rear_touch_t*) touches eventCount: (int) count;
- (void) updatePressure: (int *) pressure;
- (BOOL) rearTouchesActive;
- (CGPoint) touchCoordsForTouchAtIndex: (int) index;
- (CGPoint) previousTouchCoordsForTouchAtIndex: (int) index;
- (void) addDelegate: (id<SandwichUpdateDelegate>) delegate;


@end
