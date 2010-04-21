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

#ifdef SANDWICH_SUPPORT
@interface EAGLView : UIView <UIAccelerometerDelegate,CLLocationManagerDelegate,SandwichUpdateDelegate>
#else
@interface EAGLView : UIView <UIAccelerometerDelegate,CLLocationManagerDelegate>
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

