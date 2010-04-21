//
//  EAGLView.h
//  urMus
//
//  Created by Georg Essl on 6/20/09.
//  Copyright Georg Essl 2009. All rights reserved. See LICENSE.txt for license details.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <CoreLocation/CoreLocation.h>

#undef SANDWICH_SUPPORT

#ifdef SANDWICH_SUPPORT
#import "UdpServerSocket.h"
#import "SandwichTypes.h"
#import "SandwichUpdateListener.h"
#endif

/*
This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
The view content is basically an EAGL surface you render your OpenGL scene into.
Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
*/

//#define USEUDP
#ifdef USEUDP
#import "AsyncUdpSocket.h"
#else
#import "TCPServer.h"
#import <Foundation/NSNetServices.h>
#endif

#define MAX_FINGERS 10

#ifdef SANDWICH_SUPPORT
#ifdef USEUDP
@interface EAGLView : UIView <UIAccelerometerDelegate,CLLocationManagerDelegate,SandwichUpdateDelegate, AsyncUdpSocketDelegate>
#else
@interface EAGLView : UIView <UIAccelerometerDelegate,CLLocationManagerDelegate,SandwichUpdateDelegate, TCPServerDelegate>
#endif
#else
#ifdef USEUDP
@interface EAGLView : UIView <UIAccelerometerDelegate,CLLocationManagerDelegate, AsyncUdpSocketDelegate>
#else
@interface EAGLView : UIView <UIAccelerometerDelegate,CLLocationManagerDelegate, TCPServerDelegate>
#endif
#endif
{
    
@private
    /* The pixel dimensions of the backbuffer */
    GLint backingWidth;
    GLint backingHeight;
    
    EAGLContext *context;
    
    /* OpenGL names for the renderbuffer and framebuffers used to render to this view */
    GLuint viewRenderbuffer, viewFramebuffer;
    
    /* OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist) */
    GLuint depthRenderbuffer;
    
    NSTimer *animationTimer;
    NSTimeInterval animationInterval;
	CLLocationManager *locationManager;

#ifdef USEUDP
	AsyncUdpSocket		*_server;
#else
	TCPServer			*_server;
#endif
	NSInputStream		*_inStream;
	NSOutputStream		*_outStream;
	BOOL				_inReady;
	BOOL				_outReady;
	
@private
//	id<EAGLViewDelegate> _delegate;
	NSString *_searchingForServicesString;
	NSString *_ownName;
	NSNetService *_ownEntry;
	BOOL _showDisclosureIndicators;
	NSMutableArray *_services;
	NSNetServiceBrowser *_netServiceBrowser;
	NSNetService *_currentResolve;
	NSTimer *_timer;
	BOOL _needsActivityIndicator;
	BOOL _initialWaitOver;
}

@property (nonatomic, retain) CLLocationManager *locationManager;

@property NSTimeInterval animationInterval;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView;
- (void)setFramePointer;

#ifdef SANDWICH_SUPPORT
// sandwich update Delegate functions
- (void) rearTouchUpdate: (SandwichEventManager * ) sender;
- (void) pressureUpdate: (SandwichEventManager * ) sender;
#endif

@end

