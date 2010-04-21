//
//  RearTouchController.m
//  GLGravity
//
//  Created by Sven Kratz on 6/7/09.
//  Copyright 2009 Deutsche Telekom Laboratories. All rights reserved.
//

#import "SandwichEventManager.h"


@implementation SandwichEventManager
@synthesize rTouches;
@synthesize iPreviousTouches;

// hack to be able to acces the array
@dynamic pressureValues;
- (int *) pressureValues {return _pressureValues;}

-(id) init;
{
		if (self = [super init])
		  {
			  iDelegates = [[NSMutableArray alloc] initWithCapacity:10];
			  // allocate memory for touch events
			rTouches = (rear_touch_t*) malloc(sizeof(rear_touch_t) * K_MAX_TOUCHES);
			iPreviousTouches = (rear_touch_t*) malloc(sizeof(rear_touch_t) * K_MAX_TOUCHES);
			  
  
			bzero(_pressureValues, sizeof(_pressureValues));
			  
			int i = 0;
			for (i = 0; i < K_MAX_TOUCHES; i++)
				{
					rear_touch_t touch;
					touch.x = 0;
					touch.y = 0;
					// this touch is inactive
					touch.phase = UITouchPhaseEnded;
					rTouches[i] = touch;
				}
			 
		  }
	return self;
}

- (void) addDelegate: (id<SandwichUpdateDelegate>) aDelegate;
{
		// add a delegate to the update manager
	[iDelegates addObject: aDelegate];
	
}

- (void) updateTouchEvents: (rear_touch_t*) touches eventCount: (int) count;
{
	// update rear touches list
	rear_touch_t * bufferPtr;
	// overwrite <count> previous touches
	memcpy(iPreviousTouches, touches, sizeof(rear_touch_t)*count);
	// swap buffer pointers
	bufferPtr = rTouches;
	rTouches = iPreviousTouches;
	iPreviousTouches = bufferPtr;
	free(touches);
	
	// DEBUG
#undef DEBUG_PLUS
#ifdef DEBUG_PLUS
	int i = 0;
	// update touches that changed
	for (i = 0; i < count; i++)
	  {
		  touch_t touch = iTouches[i];
		  if (touch.phase != UITouchPhaseEnded)
			{
				NSLog(@"<reartouchmanager> Touch %d x: %f y: %f phase: %d", i, touch.x, touch.y, touch.phase);
			}
	  }
	// null touches that don't exist anymore
	
#endif
	for (id<SandwichUpdateDelegate> d in iDelegates)
	  {
		  [d rearTouchUpdate:self];
	  }
	
	// END DEBUG
	  
}

- (void) updatePressure: (int *) pressure;
{
		if (pressure != nil)
		  {
			  // copy values
			  _pressureValues[0] = pressure[0];
			  _pressureValues[1] = pressure[1];
			  _pressureValues[2] = pressure[2];
			  _pressureValues[3] = pressure[3];
			  // release the memory
			  free(pressure);
		  }
	// update delegate pressure vals
	for (id<SandwichUpdateDelegate> d in iDelegates)
	  {
		  [d pressureUpdate: self];
	  }
	
}

- (CGPoint) touchCoordsForTouchAtIndex: (int) index;
{
	// returns current coordinates for touch at index
	CGPoint coords; 
	coords.x = rTouches[index].x;
	coords.y = rTouches[index].y;
	return coords;
}

- (CGPoint) previousTouchCoordsForTouchAtIndex: (int) index;
{
	// returns previous coordinates for touch at index
	CGPoint coords;
	coords.x = iPreviousTouches[index].x;
	coords.y = iPreviousTouches[index].y;
	return coords;
}

- (BOOL) rearTouchesActive;
{
	int i = 0;
	//BOOL active = NO;
	for (i = 0; i < K_MAX_TOUCHES; i++)
	  {
		  rear_touch_t touch = rTouches[i];
		  if (touch.phase != UITouchPhaseEnded)
			{
				return YES;
			}
		  
	  }
	return NO;
}

- (void)dealloc {
    [super dealloc];
}


@end
