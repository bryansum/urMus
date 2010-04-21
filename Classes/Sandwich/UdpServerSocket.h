//
//  UdpServerSocket.h
//  SandwichFront
//
//  Created by Sven Kratz, Micheal Rohs on 6/7/09.
//  Copyright 2009 Deutsche Telekom Laboratories, TU Berlin. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UdpServerSocket : NSObject {
	int portNr;
	bool sending;
}

@property int portNr;
@property (assign) bool sending;

- (id) initWithPort: (int) aPortNr;
- (BOOL) bindServer;
- (BOOL) close;
- (int) receive: (unsigned char*)aBuffer atMost: (int)aLength;
- (void) send: (const char*) aData withLength: (int) aLength;



@end
