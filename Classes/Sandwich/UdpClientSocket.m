//
//  UdpClientSocket.m
//  SandwichFront
//
//  Created by Sven Kratz, Micheal Rohs on 6/7/09.
//  Copyright 2009 Deutsche Telekom Laboratories, TU Berlin. All rights reserved.
//

#include <sys/types.h>    // Needed for system defined identifiers.
#include <netinet/in.h>   // Needed for internet address structure.
#include <sys/socket.h>   // Needed for socket(), bind(), etc...
#include <arpa/inet.h>    // Needed for inet_ntoa()
#include <fcntl.h>        // Needed for sockets stuff
#include <netdb.h>        // Needed for sockets stuff

#import "UdpClientSocket.h"



int                  clientSocket;        // Client socket descriptor
struct sockaddr_in   server_addr;     // Server Internet address
socklen_t             addr_len;        // Internet address length
char                 out_buf[4096];   // Output buffer for data
char                 in_buf[4096];    // Input buffer for data
int                  retcode;         // Return code



BOOL clientConnect(const char* ipaddr, int port)
{
	// get datagram socket file descriptor
	clientSocket = socket(AF_INET, SOCK_DGRAM, 0);
	NSLog(@"Socket created.");
	if (clientSocket < 0) {
		NSLog(@"Error Creating Socket");
		return false;
	}
	
	// set server address information
	memset((char*) &server_addr, 0, sizeof(server_addr));
	server_addr.sin_family = AF_INET;
	server_addr.sin_port = htons(port);				  // correct byte ordering for port
	server_addr.sin_addr.s_addr = inet_addr(ipaddr); // convert string to address
	
	// http://www.cs.vu.nl/~gpierre/courses/sysprog/5.slides.pdf
	// http://www.slideshare.net/jignesh/socket-programming-tutorial
	// http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_4
	
	/*
	 // Send welcome message
	 
	 strcpy(out_buf, "$SWR,127.0.0.1");
	 
	 // Send the message
	 
	 NSLog(@"before sendto.");
	 retcode = sendto(clientSocket, out_buf, (strlen(out_buf) + 1), 0, (struct sockaddr *) & server_addr, sizeof(server_addr));
	 if (retcode< 0) {
	 NSLog(@"Error sending initial message");
	 return false;
	 }
	 NSLog(@"after sendto.");
	 */
	/*
	 // receive initial reply
	 addr_len = sizeof(server_addr);
	 
	 NSLog(@"before recvfrom.");
	 retcode = recvfrom(clientSocket, in_buf, sizeof(in_buf), 0, (struct sockaddr*) &server_addr, &addr_len);
	 if (retcode < 0 ) {
	 NSLog(@"Error Receiving reply");
	 return false;
	 }
	 NSLog(@"after recvfrom.");
	 NSLog(@"Received from server: %s", in_buf);
	 */
	return true;
}



@implementation UdpClientSocket
@synthesize portNr;
@synthesize serverAddress;
@synthesize sending;



- (id) initWithServerAddress: (NSString*) aServerAddress withPort: (int) aPortNr;
{
	if (self = [super init]) {
		self.portNr = aPortNr;
		self.serverAddress = aServerAddress;
		self.sending = NO;
	}
	return self;
}



- (BOOL) clientConnect;
{
	NSLog(@"starting connection to %@ port %d", self.serverAddress, self.portNr);
	if (clientConnect([self.serverAddress cString], self.portNr)) {
		return true;  
	} else {
		NSLog(@"connection failed");
		return false;  
	}
}



-(BOOL) clientDisconnect;
{
	retcode = close(clientSocket);
	if (retcode < 0) {
		NSLog(@"Error closing socket");
		return false;
	}
	NSLog(@"Successfully closed socket");
	return true;
}



- (int) receive: (char*)aBuffer atMost: (int)aLength;
{
	int udpLength = recvfrom(clientSocket, aBuffer, aLength, 0, 
							 (struct sockaddr*) &server_addr, &addr_len);
	return udpLength;
//	NSLog(@"Received from server: %s", in_buf);
//	NSData* out_data = [NSData dataWithBytes: in_buf length: sizeof(in_buf)];   // copies buffer to NSData
//	return out_data;
}



- (void) send: (const char*) aData withLength: (int) aLength;
{
	self.sending = YES;
	retcode = sendto(clientSocket, aData, aLength, 0, 
					 (struct sockaddr*) &server_addr, sizeof(server_addr));
	if (retcode < 0) {
		NSLog(@"Error sending message");
	}
	self.sending = NO;	
}



@end
