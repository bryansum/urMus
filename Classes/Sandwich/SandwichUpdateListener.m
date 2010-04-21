//
//  SandwichUpdateListener.m
//  Sandwich Client
//
//  Created by Sven Kratz on 3/12/09.
//  Copyright 2009 Deutsche Telekom Laboratories. All rights reserved.
//
//  - Handles Socket Connection, Packet Parsing
//  - Passes new event information to event manager
//
//
//

#import "SandwichUpdateListener.h"



@implementation SandwichUpdateListener
@synthesize iSocket;
@synthesize running;
//@synthesize manager;
+ (void) initializeWithServerPort: (int) aPortNr andDelegate: (id<SandwichUpdateDelegate>) aDelegate;
{
	// initialize a single instance variable of the rear listener!
	if (single_listener == nil)
	  {
		  single_listener = [[SandwichUpdateListener alloc] initWithServerPort:aPortNr andDelegate:aDelegate];
	  }
}

+(void) addDelegate: (id<SandwichUpdateDelegate>) aDelegate;
{
	if (single_listener != nil)
	  {
		  [single_listener.manager addDelegate: aDelegate];  
	  }
}

+(BOOL) startListening;
{
	return [single_listener listenToUpdates];
}

- (id) initWithServerPort: (int) aPortNr andDelegate: (id<SandwichUpdateDelegate>) aDelegate;
{

	if (self = [super init])
	  {
		  NSLog(@"SandwichUpdateListener Starting");
		  iSocket = [[UdpServerSocket alloc] initWithPort:aPortNr ]; 
		  [iSocket retain];
		  self.running = NO;
		  // delegate = aDelegate;

		  // zero the udp buffer
		  bzero(udpInBuffer, sizeof(udpInBuffer));
		  
		  // the sandwich event manager
		  iEventManager = [[SandwichEventManager alloc] init];
		  [iEventManager addDelegate: aDelegate];
	  }
	return self;
}

- (BOOL) listenToUpdates;
{
	NSLog(@"SandwichUpdateListener Starting connection");
	if ([iSocket bindServer])
	  {
		  [iSocket retain];
		  self.running = YES;
		  [self start];
		  return YES;
	  }
	else
	  {
		  return NO;  
	  }
}

- (void) main; // thread main method
{
	NSLog(@"sandwichUpdateListener Thread Started");
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	while (self.running)
	  {
		  /*
		  NSData* message = [self.iSocket receive];
		  [self parseMessage: message];*/
		  
		  int recv_len  = [self.iSocket receive: udpInBuffer atMost:sizeof(udpInBuffer)];
		  if (recv_len > 0)
			{
#ifdef DEBUG_OUTPUT_MORE
				NSLog(@"received %d bytes\n", udpLength);
				
				for (i = 0; i < udpLength; i++) {
					NSLog(@"%02x ", udpInBuffer[i]);
				}
#endif
				[self parseMessage: recv_len];
				// NSLog(@"received %d bytes\n", udpLength);
			}
		  else 
			{
				NSLog(@"Error Receiving from Socket (0 Bytes)");
			}
	  }
	[pool release];
}

- (void) parseMessage: (int) length 
{
	int i;
	
	
	int j = 0;
	int opcode = udpInBuffer[j++];
	int sequenceNumber = udpInBuffer[j++] << 24;
	sequenceNumber |= udpInBuffer[j++] << 16;
	sequenceNumber |= udpInBuffer[j++] << 8;
	sequenceNumber |= udpInBuffer[j++];
	//touchEventSequenceNumber = sequenceNumber;
	
	// int length = udpInBuffer[j++];
	j++; // Length!!!!!!!!
	
#ifdef DEBUG_OUTPUT
	NSLog(@"opcode = %d, sequenceNumber = %d, length = %d\n", opcode, sequenceNumber, udpInBuffer[j]);
#endif
	
	int n;
	int x, y, phase;
	//int length  = udpInBuffer[j++];

	
	switch (opcode) {
		case OPCODE_TOUCH:
	  {
			// get amount of touch events
			// int touchEventCount = n;
			n = udpInBuffer[j++];
			// allocate memory for rear touch events
			rear_touch_t * touchEvents = malloc(sizeof(rear_touch_t) * n);
			bzero(touchEvents, sizeof(rear_touch_t) *n);
#ifdef DEBUG_OUTPUT
			NSLog(@"number of touches = %d\n", n);
#endif
			for (i = 0; i < n; i++) 
			  {
				x  = udpInBuffer[j++] << 8;
				x |= udpInBuffer[j++];
				y  = udpInBuffer[j++] << 8;
				y |= udpInBuffer[j++];
				phase = udpInBuffer[j++];
#ifdef DEBUG_OUTPUT
				NSLog(@"x = %d, y = %d, phase = %d, j = %d\n", x, y, phase, j);
#endif
				touchEvents[i].x = SCREEN_WIDTH - 1 - x; // reverse coordinates from rear side
				touchEvents[i].y = SCREEN_HEIGHT - 1 - y; // reverse coordinates from rear side*/
				touchEvents[i].phase = phase;

			} // for
		  [iEventManager updateTouchEvents: touchEvents eventCount: n];
			break;	
	  } // case	
		case OPCODE_PRESSURE:
	  {
		  //n = bufferIn[j++];
		  //printf("Pressure info bytes %d\n", n);
		  int * p = malloc(sizeof(int) * 4);
		  bzero(p, sizeof(int) * 4);
		  p[0] = udpInBuffer[j++] << 8; 
		  p[0] |= udpInBuffer[j++];
		  p[1] = udpInBuffer[j++] << 8; 
		  p[1] |= udpInBuffer[j++];
		  p[2] = udpInBuffer[j++] << 8; 
		  p[2] |= udpInBuffer[j++];
		  p[3] = udpInBuffer[j++] << 8; 
		  p[3] |= udpInBuffer[j++];
#ifdef DEBUG_OUTPUT			  
		  printf("p0 = %d p1 = %d p2 = %d p3 = %d\n", p[0],p[1],p[2],p[3]);
#endif
		 
		 [iEventManager updatePressure: p];
		  break;
	  }
	}
	
	//		[self drawView];
	
	


	
	
/////////////////////////////////////////////////////////// OLD CODE!!!!!!
#ifdef OLD_STYLE
	NSString * msg_string =[[[NSString alloc] initWithData:message encoding:NSASCIIStringEncoding] autorelease];
	//NSLog(@"Server Messaged: %@", msg_string);
	NSArray * stringElements = [msg_string componentsSeparatedByString:@","];
	//NSLog(@"First Component %@", [stringElements objectAtIndex: 0]);
	if ([[stringElements objectAtIndex:0] isEqualToString: @"$PRS"])
	  {
		  // NSLog(@"Got Pressure reading, checking...");
		  // Check if pressure reading packet is valid
		  if ([stringElements count] == 5)
			{
				// NSLog(@"Got Pressure Reading"); 
				// copy the pressure readings over to an NSMutableArray
			//	NSMutableArray * pressure = [NSMutableArray arrayWithObjects:
				pressure_values.p1 = [[stringElements objectAtIndex:1] intValue];
				pressure_values.p2 = [[stringElements objectAtIndex:2] intValue];
				pressure_values.p3 = [[stringElements objectAtIndex:3] intValue];
				pressure_values.p4 = [[stringElements objectAtIndex:4] intValue];
				
				gPressureValues.p1 = pressure_values.p1;
				gPressureValues.p2 = pressure_values.p2;
				gPressureValues.p3 = pressure_values.p3;
				gPressureValues.p4 = pressure_values.p4;
				
				
				
				//[delegate performSelectorOnMainThread: @selector(pressureUpdate:) withObject: self waitUntilDone: NO];
				//[delegate updatePressureReading:self];					
			}
	  }
	else {
			
		[delegate performSelectorOnMainThread:@selector(rearTouchUpdate:) withObject:message waitUntilDone:YES];
		//[delegate rearTouchUpdate:message];
		
		//[delegate rearTouchUpdate:rear_touches];		
			
	}
#endif
////////////////////////////////////////////////////// End old Code!
}

@end
