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

//
//  MyDocument.h
//  OSX2
//
//  Created by jon klein on Fri Nov 29 2002.
//  Copyright (c) 2002  s pi der la nd. All rights reserved.
//


#import <Cocoa/Cocoa.h>

#import "slBreve.h"
#import "format.h"

@class JSTTextView;
@class slSplitView;

@interface slBreveSourceDocument : NSDocument {
  NSWindow *_sourceWindow;
  JSTTextView *_steveText;
  NSTextView *_outputText;
  slSplitView *_splitView;
  
	BOOL inited;
	NSString *loadText;

  NSToolbarItem *_runButton;
  NSToolbarItem *_stopButton;
  
  NSPopUpButton *_methodsPopup;
  NSMutableArray *_methodMenuArray;
  int _runState;
}

@property (retain) IBOutlet NSWindow *sourceWindow;
@property (retain) IBOutlet JSTTextView *steveText;
@property (retain) IBOutlet NSTextView *outputText;
@property (retain) IBOutlet slSplitView *splitView;
@property (retain) IBOutlet NSPopUpButton *methodsPopup;
@property (retain) IBOutlet NSToolbarItem *runButton;
@property (retain) IBOutlet NSToolbarItem *stopButton;
@property (assign, nonatomic) int runState;

- (void)setString:(NSString*)s;

- (IBAction)findSelection:(id)sender;
- (IBAction)scrollToSelection:(id)sender;
- (IBAction)reformat:(id)sender;

- (IBAction) toggleSimulation:(id)sender;
- (IBAction) stopSimulation:(id)sender;

- (IBAction)saveLog:(id)sender;
- (IBAction)clearLog:(id)sender;
- (IBAction)checkSyntax:(id)sender;

- (IBAction)commentLines:(id)sender;
- (IBAction)uncommentLines:(id)sender;

- (NSString*)documentText;

- (id)text;
- (id)window;

@end
