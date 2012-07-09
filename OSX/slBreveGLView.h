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

#import <Cocoa/Cocoa.h>

#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

#import "slBreve.h"

#import "kernel.h"

@interface slBreveGLView : NSOpenGLView
{
	id printView;
  
  brEngine *viewEngine;
	slCamera *camera;
	slWorld *world;
  
  IBOutlet NSSegmentedControl *_cursorControl;
  id theMovie;
  
  unsigned char *pixelBuffer;
  unsigned char *tempPixelBuffer;
  
  id theController;
  
  int drawCrosshair;
  int drawing;
  BOOL contextEnabled;
  
  id selectionMenu;
  
  NSLock *drawLock;
  
  BOOL noDraw;
  
  NSTimer *_mouseHideTimer;
  BOOL _fullScreen;
}

@property (assign, nonatomic) BOOL fullScreen;

- (void)initGL;

- (void)setMovie:(id)movie;

- (void)updateSize:sender;

- (void)setEngine:(brEngine*)e;

- (int)drawing;

- (void)drawRect:(NSRect)aRect;

- (void)mouseDown:(NSEvent*)theEvent;

- (unsigned char*)updateRGBPixels;
- (int)snapshotToFile:(NSString*)filename 
             fileType:(NSBitmapImageFileType)fileType;

- (void)setContextMenuEnabled:(BOOL)c;
- (void)updateContextualMenu:(id)menu withInstance:(brInstance*)i;

- (void)activateContext;

- (NSBitmapImageRep*)newImageRep;

- (IBAction) cursorModeToggled:(id)sender;
- (IBAction) zoomToggled:(id)sender;
- (IBAction) rotateToggled:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;
- (IBAction) rotateLeft:(id)sender;
- (IBAction) rotateRight:(id)sender;

@end
