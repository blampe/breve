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
//  MyDocument.m
//  OSX2
//
//  Created by jon klein on Fri Nov 29 2002.
//  Copyright (c) 2002  s pi der la nd. All rights reserved.
//

#import "slBreveSourceDocument.h"
#import "slBreve.h"
#import "slBreveEngine.h"
#import "slSplitView.h"
#import "JSTTextView.h"

extern char *slObjectParseText;
extern int slObjectParseLine;

extern "C" {
	void slObjectParseSetBuffer(char *b);
	int slYylex();
}


char *sl_StripSpaces(char *text) {
	char *out;
	char last = 0;
	int index = 0, doubleSpace = 0;
  
	out = (char*)malloc( strlen( text ) + 1 );
  
	while( *text ) {
		if(*text == ' ' && last == ' ') doubleSpace = 1;
		else doubleSpace = 0;
    
		if(*text != '\n' && !doubleSpace) out[index++] = *text;
    
		last = *text;
    
		text++;
	}
  
	out[ index ] = 0;
  
	return out;
}

@implementation slBreveSourceDocument

@synthesize steveText = _steveText;
@synthesize sourceWindow = _sourceWindow;
@synthesize methodsPopup = _methodsPopup;
@synthesize outputText = _outputText;
@synthesize splitView = _splitView;
@synthesize runButton = _runButton;
@synthesize stopButton = _stopButton;
@synthesize runState = _runState;

- (id)init {
  self = [super init];
  if (self != nil) {
    loadText = nil;
  }
  return self;
}

- (void) dealloc {
  [_methodMenuArray release];
  [super dealloc];
}

- (IBAction)reformat:(id)sender {
	char *newtext;
	const char *text = [[_steveText string] cStringUsingEncoding:NSUTF8StringEncoding];

	newtext = slFormatText((char*)text);

	[_steveText setString: [NSString stringWithCString: newtext encoding:NSUTF8StringEncoding]];
}

- (NSString *)windowNibName
{
    return @"slBreveSourceDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];

	if(loadText) {
		[_steveText setString: loadText];
		[loadText release];
		loadText = NULL;
	}

	[_steveText setAllowsUndo: YES];
//	[_steveText setLineWrappingEnabled: NO];
	[_steveText setFont: [NSFont userFixedPitchFontOfSize: 10.0]];

//	[_steveText setDocDictionary: [breve docDictionary]];
//  [_splitView setCollapsiblePopupSelection:2];
}

- (void) setRunState:(int)runState {
  if (runState == _runState) {
    return;
  }
  
  _runState = runState;

  NSString *runImageName = nil;
  NSString *runLabel = nil;
  BOOL stopButtonEnabled = NO;
  BOOL showOutputLog = NO;
  
  if (runState == BX_RUN) {
    stopButtonEnabled = YES;
    runImageName = @"DVTLibraryPauseAudio.tiff";
    runLabel = @"Pause";
    showOutputLog = YES;
  }
  else if (runState == BX_PAUSE) {
    stopButtonEnabled = YES;
    runImageName = @"DVTLibraryContinueAudio.tiff";
    runLabel = @"Run";
    showOutputLog = YES;
  }
  else if (runState == BX_STOPPED) {
    runImageName = @"DVTLibraryPlayAudio.tiff";
    runLabel = @"Run";
  }

  [_stopButton setEnabled:stopButtonEnabled];
  [_runButton setLabel:runLabel];

  NSImage *image = [NSImage imageNamed:runImageName];
  [_runButton setImage:image];
  
//  if (showOutputLog == YES && [_splitView collapsibleSubviewCollapsed] == YES) {
//    [_splitView toggleCollapse:self];
//  }
}

- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type {
	return [[_steveText string] writeToFile: fileName atomically: YES encoding:NSUTF8StringEncoding error:nil];
}

- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType {
	NSString *s = [[NSString alloc] initWithContentsOfFile: fileName];

	if(!s) return NO;

	if(!inited) {
		loadText = [[NSString stringWithString: s] retain];
	} else {
		[_steveText setString: s];
	}

	[s release];

	return YES;
}

- (void)setString:(NSString*)s {
	[_steveText setString: s];
}

- (IBAction)findSelection:(id)sender {
//    [_steveText findSelection: sender];
}

- (IBAction)scrollToSelection:(id)sender {
//    [_steveText scrollToSelection: sender];
}

- (IBAction) toggleSimulation:(id)sender {
  slBreve *breve = (slBreve *)[[NSApplication sharedApplication] delegate];
  [breve setActiveDocument:self];
  [breve toggleSimulation:self];
}

- (IBAction) stopSimulation:(id)sender {
  slBreve *breve = (slBreve *)[[NSApplication sharedApplication] delegate];
  if (breve.activeDocument == self) {
    [breve stopSimulation:self];
  }
}


- (NSString*)documentText {
	return [_steveText string];
}

- (id)text {
	return _steveText;
}

- (id)window {
	return _sourceWindow;
}

- (void)textView:(NSTextView *)textView doubleClickedOnCell:(id <NSTextAttachmentCell>)cell inRect:(NSRect)cellFrame atIndex:(unsigned)charIndex {
    // NSLog(@"got double\n");
}

- (void)printShowingPrintPanel:(BOOL)showPanels {
    // Construct the print operation and setup Print panel

    NSPrintOperation *op = [NSPrintOperation
                printOperationWithView: _steveText
                printInfo:[self printInfo]];

  [op setShowsPrintPanel:showPanels];
  [op setShowsProgressPanel:showPanels];

    // Run operation, which shows the Print panel if showPanels was YES

    [self runModalPrintOperation:op
                delegate:nil
                didRunSelector:NULL
                contextInfo:NULL];
}

- (void) awakeFromNib {
  _methodMenuArray = [[NSMutableArray alloc] initWithCapacity:100];
  [[NSNotificationCenter defaultCenter] addObserver: self 
                                           selector: @selector(setPopupMenu:) 
                                               name: NSPopUpButtonWillPopUpNotification
                                             object: _methodsPopup];
}

- (IBAction)goToMethod:(id)sender {
  int line;
  
  line = [[_methodMenuArray objectAtIndex: [sender indexOfSelectedItem]] intValue];
  
  [_steveText goToLine: line];
  [[self window] makeFirstResponder: _steveText];
}

- (void)setPopupMenu:(NSNotification*)note {
  NSNumber *number;
  NSString *title;
  char *text;
  int type;
  
  [_methodsPopup removeAllItems];
  [_methodsPopup addItemWithTitle: @"Go to method..."];
  
  [_methodMenuArray removeAllObjects];
  [_methodMenuArray addObject: [NSNumber numberWithInt: -1]];
  
  text = (char*)[[_steveText string] cStringUsingEncoding:NSUTF8StringEncoding];
  
  slObjectParseSetBuffer( text );
  
  while( (type = slYylex()) ) {
    if(type != 1) {
			char *objectText;
      
			objectText = sl_StripSpaces(slObjectParseText);
      
      title = [NSString stringWithFormat: @"%s (line %d)", objectText, slObjectParseLine];
      
			free(objectText);
      
      [_methodsPopup addItemWithTitle: title]; 
      
      number = [NSNumber numberWithInt: slObjectParseLine];
      [_methodMenuArray addObject: number];
    }
  }
  
  [_methodsPopup synchronizeTitleAndSelectedItem];
}

- (IBAction)saveLog:(id)sender {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd 'at' h.mm.ss a"];
  
  NSString *defaultName = [NSString stringWithFormat:@"%@ Log %@", [self displayName], [dateFormatter stringFromDate:[NSDate date]]];

  slBreve *breve = (slBreve *)[[NSApplication sharedApplication] delegate];
	NSString *logFile = [breve saveNameForType: @"txt" 
                                defaultValue:defaultName
                                 withAccView: NULL];
  if (logFile == nil) {
    return;
  }
  
	[[self.outputText string] writeToFile:logFile
                             atomically:YES 
                               encoding:NSUTF8StringEncoding 
                                  error:nil];
}

- (IBAction)clearLog:(id)sender {
  [self.outputText setString:@""];
}

- (IBAction)checkSyntax:(id)sender {
	NSString *file;
	char *buffer = NULL;
	char *name = NULL;
  
	buffer = slStrdup((char*)[[self documentText] cStringUsingEncoding:NSUTF8StringEncoding]);
  
	file = [[self fileURL] path];
	if(!file) file = [self displayName];
  
	name = (char*)[file cStringUsingEncoding:NSUTF8StringEncoding];
  /*
	if([breveEngine checkSyntax: buffer withFilename: name]) {
		[self runErrorWindow];
	} else {
		NSString *title = NSLocalizedStringFromTable(@"Syntax Check Passed Title", @"General", @"");
		NSString *message = NSLocalizedStringFromTable(@"Syntax Check Passed Message", @"General", @"");
    
		NSRunAlertPanel(title, message, nil, nil, nil);
	}
  
	[breveEngine freeEngine];
   */
}

- (IBAction)commentLines:(id)sender {
	id document = [[NSDocumentController sharedDocumentController] currentDocument];
	[[document text] commentSelection: self];
}

- (IBAction)uncommentLines:(id)sender {
	id document = [[NSDocumentController sharedDocumentController] currentDocument];
	[[document text] uncommentSelection: self];
}

#pragma mark -
#pragma mark
- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
  return [splitView bounds].size.height - 250;
}
@end
