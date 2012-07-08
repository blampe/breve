/*****************************************************************************
 *                                                                           *
 * The breve Simulation Environment                                          *
 * Copyright (C) 2000, 2001, 2002, 2003 Jonathan Klein                       *
 *                                                                           *
 * This program is free software; you can redistribute it and/or modify      *
 * it under the terms of the GNU General Public License as published by      *
 * the Free Software Foundation; either version 2 of the License, or         *
 * (at your option) any later version.                                       *
 *                                                                           *
 * This program is distributed in the hope that it will be useful,           *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of            *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
 * GNU General Public License for more details.                              *
 *                                                                           *
 * You should have received a copy of the GNU General Public License         *
 * along with this program; if not, write to the Free Software               *
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA *
 *****************************************************************************/

#import "slBreveGLView.h"
#import "slBreveApplication.h"
#import "interface.h"
#import "camera.h"
#import "gldraw.h"
#import "image.h"

@implementation slBreveGLView

/*
	+ slBreveGLView.m
	= a NSView subclass which displays breve simulations
*/ 

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (void)initGL {
	if(viewEngine) slInitGL(world, camera);

	/* no padding when we get gl pixels */

	glPixelStorei(GL_PACK_ALIGNMENT, 1);
}

- (void)activateContext {
	[[self openGLContext] makeCurrentContext];
}

- (id)initWithFrame:(NSRect)frameRect {
	// the default attribute values from IB don't seem to work on a lot  
	// of machines.  that's dumb.  we'll use our own values here and hope 
	// for the best. 

  NSOpenGLPixelFormatAttribute attribs[] = {	   
    NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)8,
    NSOpenGLPFAStencilSize, (NSOpenGLPixelFormatAttribute)8,
    NSOpenGLPFAWindow,
    NSOpenGLPFAAccelerated,
    NSOpenGLPFAAllRenderers,
    (NSOpenGLPixelFormatAttribute)0
  };

	NSOpenGLPixelFormat *format = [[[NSOpenGLPixelFormat alloc] initWithAttributes: attribs] autorelease];
	
	drawing = 0;
	drawCrosshair = 0;

	contextEnabled = YES;

	selectionMenu = NULL;

	[self updateSize: self];

	drawLock = [[NSLock alloc] init];

	return [super initWithFrame: frameRect pixelFormat: format];
}

/*!
	\brief update the size of this view.  

	We have to tell our camera about the new size and reallocate our pixelBuffers.
*/

- (void)updateSize:sender {
	NSRect bounds;
	int x, y;

	bounds = [self bounds];

	if(!pixelBuffer || !tempPixelBuffer) {
		pixelBuffer = (unsigned char*)slMalloc( (int)( bounds.size.width * bounds.size.height * 4 ) );
		tempPixelBuffer = (unsigned char*)slMalloc( (int)( bounds.size.width * bounds.size.height * 4 ) );
	} else {
		pixelBuffer = (unsigned char*)slRealloc(pixelBuffer, (int)( bounds.size.width * bounds.size.height * 4 ) );
		tempPixelBuffer = (unsigned char*)slRealloc(tempPixelBuffer, (int)( bounds.size.width * bounds.size.height * 4 ) );
	}

	if(!viewEngine) return;

		x = (int)bounds.size.width;
		y = (int)bounds.size.height;
		[[self openGLContext] makeCurrentContext];

	camera->setBounds( x, y );

	glViewport(0, 0, x, y);
}

/*!
	\brief Associate this view with a brEngine in which a simulation will be run.
*/

- (void)setEngine:(brEngine*)e {
  if (viewEngine != NULL) {
    brEngine *oldEngine = viewEngine;
    brEngineLock(oldEngine);
    viewEngine = NULL;
    brEngineUnlock(oldEngine);
  }
	viewEngine = e;

	if(!e) return;

	camera = brEngineGetCamera(e);
	world = brEngineGetWorld(e);

	if(!world || !camera) {
		e = NULL;
		world = NULL;
		camera = NULL;
		return;
	}

	[self initGL];
	[self updateSize: self];

	[[self openGLContext] makeCurrentContext];
	glClearColor(0, 0, 0, 0);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
}

/*!
	+ setMovie:
	= not the greatest interface to tell this view that a movie is recording 
	= and that it should pass it frames.
*/

- (void)setMovie:(id)movie {
	theMovie = movie;
}

/*!
	+ menuForEvent:
	= makes a context sensitive menu for the selected object... 
*/

- menuForEvent:(NSEvent*)theEvent {
	brInstance *i;
	NSString *title;
	NSPoint p;
	id item;

	p = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	[theController doSelectionAt: p];

	if(selectionMenu) [selectionMenu release];
	selectionMenu = NULL;

	i = [theController getSelectedInstance];

	if(!i) return NULL;

	title = [NSString stringWithFormat: @"%s (0x%x)", i->object->name, i];

	selectionMenu = [[NSMenu alloc] init];
	[selectionMenu setAutoenablesItems: NO];

	item = [selectionMenu addItemWithTitle: title action: NULL keyEquivalent: @""];
	[item setEnabled: NO];

	[self updateContextualMenu: selectionMenu withInstance: i];

	return selectionMenu;
}

/*!
	\brief Draws the breve view, by calling slRenderWorld.
*/

- (void)drawRect:(NSRect)r {

	[[self openGLContext] makeCurrentContext];

	drawing = 1;

	if(viewEngine) {
    brEngineLock(viewEngine);
			camera->renderScene( world, drawCrosshair );
			if(theMovie) [theMovie addFrameFromRGBPixels: [self updateRGBPixels]];
    brEngineUnlock(viewEngine);
	} else {
		glClearColor(0.0, 0.0, 0.0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
	}

	glFlush();

	drawing = 0;

}

- (int)drawing {
	return drawing;
}

/*
	+ mouseDown:
	= handle mouse input, checking which type of motion is currently selected
*/

- (void)mouseDown:(NSEvent*)theEvent {
	NSPoint p, lastp;
	static NSPoint d;
	int mode;
	BOOL firstTime = YES;

	if(!viewEngine) return;

	lastp = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	mode = [motionSelector selectedColumn];

	do {
		theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];

		p = [self convertPoint:[theEvent locationInWindow] fromView:nil];

		d.x = (p.x - lastp.x);
		d.y = -(p.y - lastp.y);

		lastp = p;

		switch(mode) {
			case 0: // rotation
				drawCrosshair = 1;
				camera->rotateWithMouseMovement( d.x, d.y );
				break;

			case 1: // zoom
				drawCrosshair = 1;
				camera->zoomWithMouseMovement( d.x, d.y );
				break;

			case 2: // motion 
				drawCrosshair = 1;
				camera->moveWithMouseMovement( d.x, d.y );
				break;
			case 3: // select
				if(firstTime) {
					[theController doSelectionAt: p];
					firstTime = NO;
					drawCrosshair = 0;
				} else {
					unsigned int x, y;

					[drawLock lock];
					camera->getBounds( &x, &y );
					brDragCallback(viewEngine, (int)p.x, (int)(y - p.y));
					[drawLock unlock];
				}

				[self setNeedsDisplay: YES];
				break;
			default:
				break;
		}
		
		camera->update();
		[self setNeedsDisplay: YES];

	} while([theEvent type] != NSLeftMouseUp);

	drawCrosshair = 0;
}

- (void)keyDown:(NSEvent *)theEvent {
	unichar key;
	NSString *str;

	if([theEvent isARepeat]) return;

	str = [theEvent characters];
	if([str length] != 1) return;
	key = [str characterAtIndex: 0];

  NSWindow *window = [self window];
  if (([window styleMask] & NSFullScreenWindowMask) == NSFullScreenWindowMask) {
    if (key == 0x1b) {
      [window toggleFullScreen:self];
    }
  }
  
	if(!viewEngine) return;

	brEngineLock(viewEngine);
	switch(key) {
		case NSUpArrowFunctionKey:
			brSpecialKeyCallback(viewEngine, (char *)"up", 1);
			break;
		case NSLeftArrowFunctionKey:
			brSpecialKeyCallback(viewEngine, (char *)"left", 1);
			break;
		case NSDownArrowFunctionKey:
			brSpecialKeyCallback(viewEngine, (char *)"down", 1);
			break;
		case NSRightArrowFunctionKey:
			brSpecialKeyCallback(viewEngine, (char *)"right", 1);
			break;
		default:
			brKeyCallback(viewEngine, key, 1);
			break;
	}
	brEngineUnlock(viewEngine);
}

- (void)keyUp:(NSEvent *)theEvent {
	unichar key;
	NSString *str;

	if(!viewEngine) return;

	str = [theEvent characters];
	if([str length] != 1) return;
	key = [str characterAtIndex: 0];

	brEngineLock(viewEngine);
	switch(key) {
		case NSUpArrowFunctionKey:
			brSpecialKeyCallback(viewEngine, (char *)"up", 0);
			break;
		case NSLeftArrowFunctionKey:
			brSpecialKeyCallback(viewEngine, (char *)"left", 0);
			break;
		case NSDownArrowFunctionKey:
			brSpecialKeyCallback(viewEngine, (char *)"down", 0);
			break;
		case NSRightArrowFunctionKey:
			brSpecialKeyCallback(viewEngine, (char *)"right", 0);
			break;
		default:
			brKeyCallback(viewEngine, key, 0);
			break;
	}
	brEngineUnlock(viewEngine);
}

- (unsigned char*)updateRGBPixels {
	NSRect bounds = [self bounds];

	if(!pixelBuffer || !tempPixelBuffer) [self updateSize: self];

	glPixelStorei( GL_PACK_ALIGNMENT, 1 );
	glReadPixels( 0, 0, (int)bounds.size.width, (int)bounds.size.height, GL_RGB, GL_UNSIGNED_BYTE, tempPixelBuffer );

	slReversePixelBuffer( tempPixelBuffer, pixelBuffer, (int)bounds.size.width * 3, (int)bounds.size.height );

	return pixelBuffer;
}

- (int)snapshotToFile:(NSString*)filename {
	NSBitmapImageRep *i = [self newImageRep];
	NSData *image;

	image = [i TIFFRepresentationUsingCompression: NSTIFFCompressionNone factor: 0.0];

	if(!image) {
		[i release];
		return -1;
	}

	[image writeToFile: filename atomically: NO];
	[i release];

	return 0;
}

- (NSBitmapImageRep*)newImageRep {
	NSBitmapImageRep *i;
	NSRect bounds;
	int x, y;

	bounds = [self bounds];

	x = (int)bounds.size.width;
	y = (int)bounds.size.height;

	i = [NSBitmapImageRep alloc];

	[self updateRGBPixels];

	[i initWithBitmapDataPlanes: &pixelBuffer
		pixelsWide: x
		pixelsHigh: y
		bitsPerSample: 8
		samplesPerPixel: 3
		hasAlpha: NO
		isPlanar: NO 
		colorSpaceName: @"NSDeviceRGBColorSpace"
		bytesPerRow: x * 3  
		bitsPerPixel: 24 ];

	return i;
}

- (void)setContextMenuEnabled:(BOOL)c {
	contextEnabled = c;
}


- (void)updateContextualMenu:(id)menu withInstance:(brInstance*)i {
	id menuItem;
	unsigned int n;

	if( i->_menus.size() == 0) return;

	[selectionMenu addItem: [NSMenuItem separatorItem]];

	for(n=0;n< i->_menus.size(); n++ ) {
		brMenuEntry *menuEntry = i->_menus[ n ];

		if(!strcmp(menuEntry->title, "")) {
			[menu addItem: [NSMenuItem separatorItem]];
		} else {
			menuItem = [menu addItemWithTitle: [NSString stringWithCString: menuEntry->title encoding:NSUTF8StringEncoding] 
                                 action: @selector(contextualMenu:) 
                          keyEquivalent: @""];
	
			[menuItem setTag: n];
	
			if(contextEnabled == YES) [menuItem setEnabled: menuEntry->enabled];
			else [menuItem setEnabled: NO];

			[menuItem setState: menuEntry->checked]; 
		}
	}   
}

- (void)dealloc {
	[super dealloc];
}

- (void)print:(id)sender {
    NSBitmapImageRep *r = [self newImageRep];
    NSData *imageData;
    NSImage *image;
    NSRect b;

    if(!r) return;

    imageData = [r TIFFRepresentationUsingCompression: NSTIFFCompressionNone factor: 0.0];

    image = [[NSImage alloc] initWithData: imageData];

    b = [self bounds];
    b.origin.x = -b.size.width - 100;
    b.origin.y = -b.size.height - 100;

	// for some reason, the printView size isn't getting set 
	// correctly the first time.

    [printView setBounds: b];
    [printView setFrame: b];
    [printView setImage: image];
    [printView setImageScaling: NSScaleNone];
    [printView setNeedsDisplay: YES];
    [printView setBounds: b];
    [printView setFrame: b];

	b = [printView bounds];

    [printView lockFocus];
    [image lockFocus];
    [image drawAtPoint: NSMakePoint(0, 0) fromRect: [self bounds] operation: NSCompositeCopy fraction: 1.0];
    [image unlockFocus];
    [printView unlockFocus];

    [[NSPrintInfo sharedPrintInfo] setHorizontalPagination: NSAutoPagination];
    [[NSPrintInfo sharedPrintInfo] setVerticalPagination: NSAutoPagination];

    [printView print: sender];
    [r release];
    [image release];
}

@end
