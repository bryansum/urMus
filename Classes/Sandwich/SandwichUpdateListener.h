//
//  SandwichUpdateListener.h
//  Sandwich Client
//
//  Created by Sven Kratz on 3/12/09.
//  Copyright 2009 Deutsche Telekom Laboratories. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UdpServerSocket.h"
#import "SandwichTypes.h"
#import "SandwichEventManager.h"


@interface SandwichUpdateListener : NSThread {
	UdpServerSocket * iSocket;
	BOOL  running;
	// id delegate;
	SandwichEventManager * iEventManager;
	@private
	unsigned char udpInBuffer[256];
}

@property (assign) UdpServerSocket * iSocket;
@property BOOL running;
@property (assign) SandwichEventManager * manager;
+ (void) initializeWithServerPort: (int) aPortNr andDelegate: (id<SandwichUpdateDelegate>) aDelegate;
+ (BOOL) startListening;
+(void) addDelegate: (id<SandwichUpdateDelegate>) aDelegate;
- (id) initWithServerPort: (int) aPortNr andDelegate: (id<SandwichUpdateDelegate>) aDelegate;
- (void) main; // thread main method
- (void) parseMessage: (int) length;  // parse the incoming message
- (BOOL) listenToUpdates;
@end

// singleton update listener
static SandwichUpdateListener * single_listener;

