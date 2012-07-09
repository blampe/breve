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

/*
	+ slBreve
	= is the interface controller class for breve.  Up until release 1.2,
	= this file also controlled all interactions with the breve engine,
	= but the class became confusing and messy.
	= 
	= So this file now handles all strictly interface related tasks, and
	= interacts with the breve engine through the slBreveEngine object.
*/

/*
	aim:goim?screenname=rockstjaerna@mac.com
*/

#import "slBreve.h"
#import "util.h"
#import "slBreveSourceDocument.h"

#include <sys/types.h>
#include <dirent.h>

extern BOOL _engineWillPause;

@implementation slBreve

@synthesize activeDocument = _activeDocument;

extern char *gErrorNames[];

void slPrintLog( const char *text );

/* gSimMenu and gSelf are a bit of a hack--we need to these variables */
/* from regular C callbacks, so we'll stick the values in global variables */

static NSMenu *gSimMenu;
static slBreve *gSelf;
static NSMutableString *gLogString;
static NSRecursiveLock *gLogLock;

- (void)showWelcomeMessage {
	NSString *message = [ NSString stringWithFormat: NSLocalizedStringFromTable(@"Welcome Message", @"General", @""), _versionString ];
	NSString *title = [ NSString stringWithFormat: NSLocalizedStringFromTable(@"Welcome Title", @"General", @""), _versionString ];

	NSBeginInformationalAlertSheet(title, @"Okay", NULL, NULL, runWindow, self, NULL, NULL, NULL, message);
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
	[[[NSDocumentController sharedDocumentController] 
		openDocumentWithContentsOfFile: filename display: YES] retain];

	return YES;
}

- (void)applicationWillFinishLaunching:(NSNotification*)note {
	struct direct **docsArray;
	int demoCount, n;
	NSString *name;
	NSString *bundlePath;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

#define stringify(x) #x
#define expand_macro_stringify(x) stringify(x)

	_versionString = [ [ NSString stringWithCString: expand_macro_stringify( BREVE_VERSION )  encoding:NSUTF8StringEncoding] retain ];

	[_versionField setStringValue: [ NSString stringWithFormat: @"version %@", _versionString ] ];
	
	NSLog(@ " version = %@\n", [ NSString stringWithFormat: @"version %@", _versionString ]  );

	_engineWillPause = NO;
        
	/* we have a C function here that needs access to a class variable   */
	/* so we're going to cheat and make a local copy of it.  please dont */
	/* tell my former computer science professors, it would crush them.  */

	[[NSNotificationCenter defaultCenter] addObserver: displayView selector: @selector(updateSize:) name: nil object: displayView];

	slSetMessageCallbackFunction( slPrintLog );

	logLock = [[NSRecursiveLock alloc] init];

	gSimMenu = simMenu;
	gLogLock = logLock;
	gSelf = self;

	gLogString = [[NSMutableString stringWithCapacity: 1024] retain];
	[gLogString setString: @""];

	editorData = [[slObjectOutline alloc] init];
	[editorData setOutlineView: variableOutlineView];

	[variableOutlineView setDataSource: editorData];
	[variableOutlineView setDelegate: editorData];

	bundlePath = [[NSBundle mainBundle] resourcePath];

	demoPath = strdup([[NSString stringWithFormat: @"%@/demos", bundlePath] cStringUsingEncoding:NSUTF8StringEncoding]);
	classPath = strdup([[NSString stringWithFormat: @"%@/classes", bundlePath] cStringUsingEncoding:NSUTF8StringEncoding]);
	docsPath = strdup([[NSString stringWithFormat: @"%@/docs", bundlePath] cStringUsingEncoding:NSUTF8StringEncoding]);
	classDocsPath = strdup([[NSString stringWithFormat: @"%@/docs/classes", bundlePath] cStringUsingEncoding:NSUTF8StringEncoding]);

	srand(time(NULL));
	srandom(time(NULL));
	
	[self buildDemoMenuForDir: demoPath forMenu: demoMenu];

	demoCount = scandir(classDocsPath, &docsArray, isHTMLfile, alphasort);

	if(demoCount > 0) {
		for(n=0;n<demoCount;n++) {
			name = [NSString stringWithCString: docsArray[n]->d_name encoding:NSUTF8StringEncoding];
			[docsMenu insertItemWithTitle: name action: @selector(docsMenu:) keyEquivalent: @"" atIndex: n];

			free(docsArray[n]);
		}

		if(demoCount) free(docsArray);
	}

	[runWindow setFrameAutosaveName: @"runWindow"];
  [runWindow setAcceptsMouseMovedEvents:YES];

	[simMenu setAutoenablesItems: NO];

	[saveMovieMenuItem setEnabled: NO];
	[savePictureMenuItem setEnabled: NO];

	[runWindow makeKeyAndOrderFront: nil];

	if(![[defaults stringForKey: @"ShowedWelcomeMessage"] isEqualTo: _versionString ] ) {
		[defaults setObject: _versionString forKey: @"ShowedWelcomeMessage"];
		[self showWelcomeMessage];
	}

	[preferences loadPrefs];

	docDictionary = [self parseDocsIndex];

	if([preferences shouldShowOpenOnLaunch]) 
		[[NSDocumentController sharedDocumentController] openDocument: self];

	[NSTimer scheduledTimerWithTimeInterval: .2 target: self selector: @selector(updateLog:) userInfo: NULL repeats: YES];

	[NSTimer scheduledTimerWithTimeInterval: 1.0 target: self selector: @selector(updateSelectionWindow:) userInfo: NULL repeats: YES];
}

- (void)buildDemoMenuForDir:(char*)directory forMenu:(slDemoMenu*)menu {
	struct direct **demoArray;
	struct stat st;
	char *fullpath;
	int n;
	int menuCount = 0;
	int demoCount = scandir(directory, &demoArray, isTZfile, alphasort);
	NSString *name;

	[menu setPath: [NSString stringWithCString: directory encoding:NSUTF8StringEncoding]];

	for(n=0;n<demoCount;n++) {
		fullpath = (char*)slMalloc(strlen(directory) + strlen(demoArray[n]->d_name) + 2);

		sprintf(fullpath, "%s/%s", directory, demoArray[n]->d_name);

		stat(fullpath, &st);
		
		name = [NSString stringWithCString: demoArray[n]->d_name encoding:NSUTF8StringEncoding];

		if(st.st_mode & S_IFDIR && ![[name pathExtension] isEqualToString: @"nib"]) {
			id item, submenu;

			item = [menu insertItemWithTitle: name action: @selector(demoMenu:) keyEquivalent: @"" atIndex: menuCount++];

			submenu = [[[slDemoMenu alloc] init] autorelease];

			[menu setSubmenu: submenu forItem: item];

			[self buildDemoMenuForDir: fullpath forMenu: submenu];
		} else if(![[name pathExtension] isEqualToString: @"nib"]) {
			[menu insertItemWithTitle: name action: @selector(demoMenu:) keyEquivalent: @"" atIndex: menuCount++];
		}
		
		slFree( fullpath );

		free(demoArray[n]);
	}

	free(demoArray);
}

/*
	+ applicationWillTerminate:
	= actions to be called on quit
*/

- (void)applicationWillTerminate:(NSNotification*)note {
	[breveEngine stopSimulation];
	[preferences savePrefs];
}


- (void) setActiveDocument:(slBreveSourceDocument *)activeDocument {
  if (activeDocument == _activeDocument) {
    return;
  }
  
  if (_activeDocument != nil) {
  	int mode = [breveEngine getRunState];
    if (mode != BX_STOPPED) {
      [self stopSimulation:self];
    }
    [_activeDocument release];
    _activeDocument = nil;
  }
  
  if (activeDocument == nil) {
    [runWindow setTitle:@"breve"];
  }
  else {
    _activeDocument = [activeDocument retain];
    [runWindow setTitle:[NSString stringWithFormat:@"breve — %@", [_activeDocument displayName]]];
  }
}

- (void)simulateRunClick {
  [self startSimulationFromMenu:self];
}

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem {
  if (menuItem == runSimMenuItem) {
  	int mode = [breveEngine getRunState];
    if (mode == BX_RUN) {
      [runSimMenuItem setTitle: @"Stop Simulation"];
    }
    else {
      [runSimMenuItem setTitle: @"Start Simulation"];
    }
  }
  return YES;
}


- (IBAction)startSimulationWithArchivedFile:sender {
	NSString *saved;
	char *csaved;
	NSString *file;
	char *buffer = NULL;
	char *name = NULL;

	[loadSimText setStringValue: [NSString stringWithFormat: @"Select a file containing an archived simulation of the currently selected simulation file (%@)", [_activeDocument displayName]]];

	saved = [self loadNameForTypes: [NSArray arrayWithObjects: @"xml", @"brevexml", @"tzxml", NULL] withAccView: archiveOpenAccView];

	if(!saved) return;

	csaved = (char*)[saved cStringUsingEncoding:NSUTF8StringEncoding];

	if(!_activeDocument) return;


	buffer = slStrdup((char*)[[(slBreveSourceDocument*)_activeDocument documentText] cStringUsingEncoding:NSUTF8StringEncoding]);

	file = [[_activeDocument fileURL] path];
	if(!file) file = [_activeDocument displayName];

	name = slStrdup((char*)[file cStringUsingEncoding:NSUTF8StringEncoding]);

	[self.activeDocument clearLog: self];

	chdir([preferences defaultPath]);
	[breveEngine setOutputPath: [preferences defaultPath] useSimDir: [preferences shouldUseSimDirForOutput]];

	if([breveEngine startSimulationWithText: buffer withFilename: name withSavedSimulationFile: csaved]) {
		[self runErrorWindow];
		[breveEngine freeEngine];
    [self.activeDocument setRunState:BX_STOPPED];

		slFree(buffer);
		slFree(name);

		return;
	}


	[saveMovieMenuItem setEnabled: YES];
	[savePictureMenuItem setEnabled: YES];
	[self updateObjectSelection];
  [self.activeDocument setRunState:BX_RUN];
	[syntaxMenuItem setEnabled: NO];

	[runWindow makeFirstResponder: displayView];

	slFree(buffer);
	slFree(name);
}

- (IBAction)startSimulationFromMenu:sender {
  if (_activeDocument == nil) {
    return;
  }

	int mode = [breveEngine getRunState];

	[runWindow makeKeyAndOrderFront: self];

	if(mode == BX_STOPPED) {
		[self startSimulation];
		//[runButton setState: NSOnState];
	} else if(mode == BX_RUN) {
		[self stopSimulation: sender];
		//[runButton setState: NSOffState];
	}
}

- (IBAction)toggleSimulation:sender {
	int mode = [breveEngine getRunState];

	if(mode == BX_STOPPED) {
    [self startSimulation];
    [runWindow makeKeyAndOrderFront:self];
  }
	else if(mode == BX_RUN) {
    [breveEngine pauseSimulation: self];
  }
	else if(mode == BX_PAUSE) {
    [breveEngine unpauseSimulation: self];
  }
  
  [_activeDocument setRunState:[breveEngine getRunState]];
}

- (void)startSimulation {
	NSString *file;
	char *buffer = NULL;
	char *name = NULL;
	int mode;

	[breveEngine lock];
	mode = [breveEngine getRunState];
	[breveEngine unlock];

	if(mode != BX_STOPPED) return;

	if(!_activeDocument) {
		return;
	}

	buffer = slStrdup((char*)[[(slBreveSourceDocument*)_activeDocument documentText] cStringUsingEncoding:NSUTF8StringEncoding]);

	file = [[_activeDocument fileURL] path];
	if(!file) file = [_activeDocument displayName];

	name = slStrdup((char*)[file cStringUsingEncoding:NSUTF8StringEncoding]);

	[self.activeDocument clearLog: self];

	chdir([preferences defaultPath]);
	[breveEngine setOutputPath: [preferences defaultPath] useSimDir:  [preferences shouldUseSimDirForOutput]];

	if([breveEngine startSimulationWithText: buffer withFilename: name withSavedSimulationFile: NULL ]) {
		[self runErrorWindow];
		[breveEngine freeEngine];
    [_activeDocument setRunState:BX_STOPPED];
    
		slFree(buffer);
		slFree(name);

		return;
	}

	[saveMovieMenuItem setEnabled: YES];
	[savePictureMenuItem setEnabled: YES];
	[self updateObjectSelection];
  [_activeDocument setRunState:BX_RUN];
	[syntaxMenuItem setEnabled: NO];
	[runCommandButton setEnabled: YES];

	[runWindow makeFirstResponder: displayView];

	slFree(buffer);
	slFree(name);

	[breveEngine go];
}

- (IBAction)stopSimulation:sender {
	int mode = [breveEngine getRunState];

	if(mode == BX_STOPPED) return;

	if(movieRecording) [self toggleMovieRecord: self];

	[editorData setEngine: NULL instance: NULL];
	[variableOutlineView reloadData];
	[selectionText setStringValue: @"No Selection"];

	[displayView setEngine: NULL ];
	[displayView setNeedsDisplay: YES];

	[self setSimulationMenuEnabled: NO];

	[saveMovieMenuItem setEnabled: NO];
	[savePictureMenuItem setEnabled: NO];
	[runCommandButton setEnabled: NO];

	[breveEngine stopSimulation];

  [self clearSimulationMenu];

  [self.activeDocument setRunState:BX_STOPPED];
	[syntaxMenuItem setEnabled: YES];
}

- (void)doSelectionAt:(NSPoint)p {
	[breveEngine doSelectionAt: p];
}

- (brInstance*)getSelectedInstance {
	return [breveEngine getSelectedInstance];
}

- (void)updateObjectSelection {
	brInstance *i = NULL;
	brEngine *engine = [breveEngine getEngine];
	brInstance *controller;
	
	if(!engine) return;

	controller = brEngineGetController(engine);

	i = [breveEngine getSelectedInstance];

	if(!i || i->status != AS_ACTIVE) {
		[selectionText setStringValue: 
			[NSString stringWithFormat: @"No Selection (%s [%p])", controller->object->name, controller]];

		[editorData setEngine: engine instance: controller];
	} else {
		[editorData setEngine: engine instance: i];

		[selectionText setStringValue: [NSString stringWithFormat: @"%s (%p)", i->object->name, i]];
	}

	[variableOutlineView reloadData];
}

- (IBAction)updateSelectionWindow: sender {
	[variableOutlineView reloadData];
}

- (IBAction)demoMenu:sender {
	NSString *string;

	string = [NSString stringWithFormat: @"%@/%@", [(slDemoMenu*)[sender menu] path], [sender title]];

	[[[NSDocumentController sharedDocumentController] 
		openDocumentWithContentsOfFile: string display: YES] retain];
}

- (IBAction)docsMenu:sender {
	NSString *filePath;
	NSURL *path;

	filePath = [NSString stringWithFormat: @"%s/%@", classDocsPath, [sender title]];

	path = [NSURL fileURLWithPath: filePath];

	[[NSWorkspace sharedWorkspace] openURL: path];
}

- (IBAction)showHTMLHelp:sender {
	NSString *filePath;
	NSString *bundlePath = [[NSBundle mainBundle] resourcePath];

	filePath = [NSString stringWithFormat: @"%@/docs/index.html", bundlePath];
	[[NSWorkspace sharedWorkspace] openURL: [NSURL fileURLWithPath: filePath]];
}

- (IBAction)simMenu:sender {
	brEngine *e = [breveEngine getEngine];
	brInstance *controller = brEngineGetController(e);
	[self doMenuCallbackForInstance: controller item: [sender tag]];
}

- (IBAction)contextualMenu:sender {
	[self doMenuCallbackForInstance: [breveEngine getSelectedInstance] item: [sender tag]];
}

- (void)doMenuCallbackForInstance:(brInstance*)i item:(int)n {
	int result;
	brEngine *e = [breveEngine getEngine];

	if([breveEngine getRunState] == BX_RUN) [breveEngine lock];
	result = brMenuCallback(e, i, n);

	if(result != EC_OK) {
		[self runErrorWindow];
		[breveEngine unlock];
		[self stopSimulation: self];

		return;
	}

	[displayView setNeedsDisplay: YES];

	if([breveEngine getRunState] == BX_RUN) [breveEngine unlock];
}

- (IBAction)newWithTemplate:sender {
	NSString *templateFile, *type;
	NSDocument *d;

	templateFile = [NSString stringWithFormat: @"%@/Template.tz", 
					[[NSBundle mainBundle] resourcePath]];

	type = [[NSDocumentController sharedDocumentController] typeFromFileExtension: @"tz"];

	d = [[[NSDocumentController sharedDocumentController] 
		openDocumentWithContentsOfFile: templateFile display: YES] retain];

	[d setFileURL:nil];
}

- (IBAction)snapshot:sender {
	NSString *result;
	int mode;

	if(!breveEngine) return;

	mode = [breveEngine getRunState];

	if(mode == BX_RUN) [breveEngine lock];

  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd 'at' h.mm.ss a"];

  NSString *defaultName = [NSString stringWithFormat:@"breve Snapshot %@", [dateFormatter stringFromDate:[NSDate date]]];

	result = [self saveNameForType:@"png"
                    defaultValue:defaultName
                     withAccView:NULL];

	if(result) [displayView snapshotToFile:result
                                fileType:NSPNGFileType];

	if(mode == BX_RUN) [breveEngine unlock];
  
  if ([sender isKindOfClass:[NSSegmentedControl class]] == YES) {
    NSSegmentedControl *segmentedControl = (NSSegmentedControl *)sender;
    [segmentedControl setSelected:NO
                       forSegment:[segmentedControl selectedSegment]];
  }
}

- (void)clearSimulationMenu {
	int n, items = [(NSMenu*)simMenu numberOfItems];
  
	/* once an item is removed, apparently the others shift down to */
	/* take it's place, so the index we want to remove is ALWAYS 0 */
  
	for(n=4;n<items;n++) [simMenu removeItemAtIndex: 4];
}

- (void)setSimulationMenuEnabled:(BOOL)state {
	int n, items = [(NSMenu*)simMenu numberOfItems];
	id item;
  
	for(n=0;n<items;n++) {
		item = [simMenu itemAtIndex: n];
		[item setEnabled: state];
	}
}


void slPrintLog( const char *text ) {
	// print-log occurs in its own thread, so we have to have an 
	// autorelease pool in place.

	[ gLogLock lock];
  NSString *logString = [[NSString alloc] initWithCString:text encoding:NSUTF8StringEncoding];
	[ gLogString appendString: logString ];
  [logString release];
	[ gLogLock unlock ];
}

- (int)updateLog:sender {
	if(breveEngine && _engineWillPause) [breveEngine pauseSimulation: self];

	if([gLogString length] == 0) return 0;

	[logLock lock];

  slBreveSourceDocument *sourceDocument = (slBreveSourceDocument *)_activeDocument;
  [sourceDocument.outputText moveToEndOfDocument:self];
  [sourceDocument.outputText insertText:gLogString];
  
	[gLogString setString: @""];

	[logLock unlock];

	return 1;
}

- (NSArray *) documents {
  return [[NSDocumentController sharedDocumentController] documents];
}

- (void)runErrorWindow {
	NSRect bounds;
	NSPoint origin;
	char *simpleFilename, *currentCName = NULL;
	brEngine *engine;
	unsigned int n;
	NSString *stringKey, *text;
	brErrorInfo *error;
	
	engine = [breveEngine getEngine];

	if(!engine) return;

	error = brEngineGetErrorInfo(engine);

	if(error->file) {
		simpleFilename = (char*)[[[NSString stringWithCString: error->file encoding:NSUTF8StringEncoding] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding];
	} else {
		// this shouldn't happen, but it happened once and caused a crash, so I'm
		// fixing the symptom instead of the disease.  for shame.

		simpleFilename = "(untitled)";
	}

  NSArray *documents = [self documents];
	for(n=0;n<[documents count];n++) {
		slBreveSourceDocument *doc = [documents objectAtIndex: n];

		if([[doc fileURL] path]) {
			currentCName = (char*)[[[[doc fileURL] path] lastPathComponent] cStringUsingEncoding:NSUTF8StringEncoding];

			if(!strcmp(currentCName, simpleFilename)) {
				[[doc text] goToLine: error->line];
				[[doc window] makeKeyAndOrderFront: self];
			}
		}
	}

	stringKey = [NSString stringWithFormat: @"%s Title", gErrorNames[error->type]];
	text = NSLocalizedStringFromTable(stringKey, @"Errors", @"");

	[errorWindow setTitle: text];

	[errorWindowErrorMessage setHorizontallyResizable: NO];
	[errorWindowErrorMessage setVerticallyResizable: YES];

	[errorWindowErrorMessage setDrawsBackground: NO];
	[errorWindowErrorMessage setEditable: NO];
	[errorWindowErrorMessage setSelectable: NO];

	stringKey = [NSString stringWithFormat: @"%s Text", gErrorNames[error->type]];
	text = NSLocalizedStringFromTable(stringKey, @"Errors", @"");

	[errorWindowErrorMessage setString: 
		[NSString stringWithFormat: @"Error in file \"%s\" at line %d:\n\n%s\n\n%@", 
			simpleFilename, 
			error->line, 
			error->message, 
			text
		]
	];

	[errorWindowErrorMessage sizeToFit];
	bounds = [errorWindowErrorMessage bounds];

	// the following values are determined from IB 

	origin.x = 120;
	origin.y = 60;

	bounds.size.height += 80; // 80 is the space for the border/button from IB 
	bounds.size.width += 140; // 120 is the space for the border from IB 

	[errorWindowErrorMessage setFrameOrigin: origin];
	[errorWindow setContentSize: bounds.size];
	[errorWindow center];

	[NSApp runModalForWindow: errorWindow];

	brClearError(engine);
}

- (IBAction)stopErrorWindowModal:sender {
	[errorWindow orderOut: self];
	[NSApp stopModal];
}

- (IBAction)toggleMovieRecord:sender {
	if(!movieRecording) {
		if([breveEngine startMovie] == YES) {
			movieRecording = YES;
		} else {
			return;
		}
		
		[saveMovieMenuItem setTitle: @"Stop Recording"];
	} else {
		[saveMovieMenuItem setTitle: @"Record Movie..."];
		[breveEngine stopMovie];
		movieRecording = NO;
	}
}

- (IBAction)openBreveHomepage:sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://www.spiderland.org/breve"]];
}

- (IBAction)openEmailMessage:sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"mailto:jklein@spiderland.org"]];
}

#if (MAC_OS_X_VERSION_MAX_ALLOWED > 1070)
int isTZfile(const struct dirent *d)
#else
int isTZfile(struct dirent *d)
#endif
{
	const char *filename = d->d_name;
	int m;

	if(d->d_type == DT_DIR && strcmp(filename, ".") && strcmp(filename, "..")) return 1;

	m = strlen(filename);
   
	if(m < 4) return 0;

	return !strcmp(&filename[m - 3], ".tz");
}

#if (MAC_OS_X_VERSION_MAX_ALLOWED > 1070)
int isHTMLfile( const struct dirent *d)
#else
int isHTMLfile( struct dirent *d)
#endif
{
	const char *filename = d->d_name;
	int m;

	m = strlen(filename);
   
	if(m < 6) return 0;

	return !strcmp(&filename[m - 5], ".html");
}

void updateMenu(brInstance *i) {
	id menuItem;
	unsigned int n;

	if(!i->engine || i != brEngineGetController(i->engine)) return;

  [gSelf clearSimulationMenu];

	for(n=0;n< i->_menus.size(); n++ ) {
		brMenuEntry *entry = i->_menus[ n ];

		if(!strcmp(entry->title, "")) {
			[gSimMenu addItem: [NSMenuItem separatorItem]];
		} else {
			menuItem = [gSimMenu addItemWithTitle: [NSString stringWithCString: entry->title encoding:NSUTF8StringEncoding] action: @selector(simMenu:) keyEquivalent: @""];

			[menuItem setTag: n];

			[menuItem setEnabled: entry->enabled];
			[menuItem setState: entry->checked];
		}
	}
}

- (NSString*)saveNameForType:(NSString *)type 
                defaultValue:(NSString *)defaultValue
                 withAccView:(NSView*)view 
{
	NSSavePanel *savePanel;
  
	savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes: [NSArray arrayWithObject:type]];
  if (defaultValue != nil) {
    [savePanel setNameFieldStringValue:defaultValue];
  }
	[savePanel setAccessoryView: view];
  
	if([savePanel runModal] == NSFileHandlingPanelCancelButton) return NULL;
  
	return [[savePanel URL] path];
}

- (NSString*)saveNameForType:(NSString *)type withAccView:(NSView*)view {
  return [self saveNameForType:type
                  defaultValue:nil
                   withAccView:view];
}

- (NSString*)loadNameForTypes:(NSArray*)types withAccView:(NSView*)view {
	NSOpenPanel *openPanel;

	openPanel = [NSOpenPanel openPanel];

	[openPanel setAccessoryView: view];

	if([openPanel runModal] != NSOKButton) return NULL;

	return [[[openPanel URLs] objectAtIndex: 0] path];
}

- (IBAction)showAboutBox:sender {
	[aboutBox center];
	[aboutBox makeKeyAndOrderFront: self];
}

- (NSSize)windowWillResize:(NSWindow*)window toSize:(NSSize)newSize {
	NSRect bounds;

	// if we're recording a movie, we can't allow the window to resize

	if(movieRecording && window == runWindow) {
		bounds = [window frame];
		return bounds.size;
	}

	return newSize;
}

- (IBAction)findSelection:sender {
	id document = [[NSDocumentController sharedDocumentController] currentDocument];

	[document findSelection: sender];
}

- (IBAction)scrollToSelection:sender {
	id document = [[NSDocumentController sharedDocumentController] currentDocument];

	[document scrollToSelection: sender];
}

- (NSMutableDictionary*)parseDocsIndex {
	NSString *index = [NSString stringWithFormat: @"%s/index.txt", docsPath];
	NSString *text = [NSString stringWithContentsOfFile:index encoding:NSUTF8StringEncoding error:nil];
	NSScanner *scanner;
	NSString *name, *title, *location;
	NSMutableCharacterSet *set;
	NSMutableArray *a;

	NSMutableDictionary *dict;

	if(!text) return nil;

	dict = [[NSMutableDictionary dictionaryWithCapacity: 50] retain];

	scanner = [[NSScanner alloc] initWithString: text];
	set = [[NSMutableCharacterSet alloc] init];
	[set addCharactersInString: @"\n:"];

	while(![scanner isAtEnd]) {
		[scanner scanUpToCharactersFromSet: set intoString: &name];
		[scanner scanCharactersFromSet: set intoString: NULL];
		[scanner scanUpToCharactersFromSet: set intoString: &title];
		[scanner scanCharactersFromSet: set intoString: NULL];
		[scanner scanUpToCharactersFromSet: set intoString: &location];
		[scanner scanCharactersFromSet: set intoString: NULL];

		if(!(a = [dict objectForKey: name])) {
			a = [NSMutableArray arrayWithCapacity: 10];
			[dict setObject: a forKey: name];
		}

		[a addObject: [NSString stringWithString: location]];
	}

	[scanner release];
  [set release];

	return dict;
}

- (NSDictionary*)docDictionary {
	return docDictionary;
}

- (void)updateAllEditorPreferences {
	unsigned int n;

  NSArray *documents = [self documents];
	for(n=0;n<[documents count];n++) {
		[preferences updateTextView: [[documents objectAtIndex: n] text]];
	}
}

- (id) displayView {
  return displayView;
}

@end
