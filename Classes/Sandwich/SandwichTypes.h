/*
 *  SandwichRearProtocol.h
 *  SandwichRear
 *
 *  Created by Sven Kratz on 3/31/09.
 *  Copyright 2009 Deutsche Telekom Laboratories. All rights reserved.
 *
 */

// defines
#define OPCODE_WELCOME 1
#define OPCODE_GOODBYE 2
#define OPCODE_TOUCH 3
#define OPCODE_PRESSURE 4

#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 480

// the generic touch type
@class SandwichEventManager;
typedef struct 
  {
	  float x;
	  float y;
	  UITouchPhase phase;
  } rear_touch_t;


// a protocol that sandwich Update delegates must implement
@protocol SandwichUpdateDelegate
- (void) rearTouchUpdate: (SandwichEventManager * ) sender;
- (void) pressureUpdate: (SandwichEventManager * ) sender;
@end
