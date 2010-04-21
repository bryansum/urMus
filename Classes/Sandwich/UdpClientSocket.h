//
//  UdpClientSocket.h
//  SandwichFront
//
//  Created by Sven Kratz, Micheal Rohs on 6/7/09.
//  Copyright 2009 Deutsche Telekom Laboratories, TU Berlin. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UdpClientSocket : NSObject {
	NSString* serverAddress;
	int portNr;
	bool sending;
}

@property (nonatomic, retain) NSString* serverAddress;
@property int portNr;
@property (assign) bool sending;

- (id) initWithServerAddress: (NSString*) aServerAddress withPort: (int) aPortNr;
- (BOOL) clientConnect;
- (BOOL) clientDisconnect;
// - (NSData*) receive;
- (int) receive: (char*)aBuffer atMost: (int)aLength;
- (void) send: (const char*) aData withLength: (int) aLength;



@end
