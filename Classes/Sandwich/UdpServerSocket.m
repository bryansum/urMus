//
//  UdpServerSocket.m
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

#import "UdpServerSocket.h"



int                  serverSocket;        // Client socket descriptor
struct sockaddr_in   server_addr;
struct sockaddr_in   client_addr;
socklen_t             addr_len;
char                 out_buf[4096];   // Output buffer for data
char                 in_buf[4096];    // Input buffer for data
int                  retcode;         // Return code



BOOL bindServer(int port)
{
	// get datagram socket file descriptor
	serverSocket = socket(AF_INET, SOCK_DGRAM, 0);
	NSLog(@"Socket created.");
	if (serverSocket < 0) {
		NSLog(@"Error Creating Socket");
		return false;
	}
	
	// set up local server address data (i.e. port number)
	memset((char*) &server_addr, 0, sizeof(server_addr));
	server_addr.sin_family = AF_INET;
	server_addr.sin_port = htons(port);				  // correct byte ordering for port
	
	// http://www.cs.vu.nl/~gpierre/courses/sysprog/5.slides.pdf
	// http://www.slideshare.net/jignesh/socket-programming-tutorial
	// http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_4

	// bind the socket to the address
	if (bind(serverSocket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
		printf("Binding server socket failed.\n");
		return 0;
	}
	
	/*
	 // Send welcome message
	 
	 strcpy(out_buf, "$SWR,127.0.0.1");
	 
	 // Send the message
	 
	 NSLog(@"before sendto.");
	 retcode = sendto(serverSocket, out_buf, (strlen(out_buf) + 1), 0, (struct sockaddr *) & server_addr, sizeof(server_addr));
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
	 retcode = recvfrom(serverSocket, in_buf, sizeof(in_buf), 0, (struct sockaddr*) &server_addr, &addr_len);
	 if (retcode < 0 ) {
	 NSLog(@"Error Receiving reply");
	 return false;
	 }
	 NSLog(@"after recvfrom.");
	 NSLog(@"Received from server: %s", in_buf);
	 */
	return true;
}



@implementation UdpServerSocket
@synthesize portNr;
@synthesize sending;



- (id) initWithPort: (int) aPortNr;
{
	if (self = [super init]) {
		self.portNr = aPortNr;
		self.sending = NO;
	}
	return self;
}



- (BOOL) bindServer
{
	NSLog(@"binding server to port %d", self.portNr);
	if (bindServer(self.portNr)) {
		return true;  
	} else {
		NSLog(@"bindServer failed");
		return false;  
	}
}



-(BOOL) close;
{
	retcode = close(serverSocket);
	if (retcode < 0) {
		NSLog(@"Error closing socket");
		return false;
	}
	NSLog(@"Successfully closed socket");
	return true;
}



- (int) receive: (unsigned char*)aBuffer atMost: (int)aLength;
{
	addr_len = sizeof(client_addr);
	int udpLength = recvfrom(serverSocket, aBuffer, aLength, 0, 
							 (struct sockaddr*) &client_addr, &addr_len);
	return udpLength;
	//	NSLog(@"Received from server: %s", in_buf);
	//	NSData* out_data = [NSData dataWithBytes: in_buf length: sizeof(in_buf)];   // copies buffer to NSData
	//	return out_data;
}



- (void) send: (const char*) aData withLength: (int) aLength;
{
	self.sending = YES;
	retcode = sendto(serverSocket, aData, aLength, 0, 
					 (struct sockaddr*) &server_addr, sizeof(server_addr));
	if (retcode < 0) {
		NSLog(@"Error sending message");
	}
	self.sending = NO;	
}



@end
