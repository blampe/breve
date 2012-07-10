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

#import "slBrevePainter.h"
#import <unistd.h>
#import "breveObjectAPI.h"

@implementation slBrevePainter

- (id)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
	self = [super initWithFrame: frame isPreview: isPreview];
  if (self != nil) {
    [self setupImageMenu];
    
    timer = [NSTimer timerWithTimeInterval: 60 
                                    target: self
                                  selector: @selector(updateImageMenu:) 
                                  userInfo: NULL
                                   repeats: YES];
    
    [[NSRunLoop currentRunLoop] addTimer: timer forMode: NSDefaultRunLoopMode];
  }

	return self;
}

- (void)setupImageMenu {
	NSString *slidePath = @"/System/Library/Screen Savers";
  NSArray *slideSavers = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:slidePath error:nil];
	NSMenuItem *item;
	NSUInteger n;
	
	[filePopup removeAllItems];
	[filePopup setAutoenablesItems: NO];
		
	for(n=0;n<[slideSavers count];n++) {
		if([[[slideSavers objectAtIndex: n] pathExtension] isEqualToString: @"slideSaver"]) {
			NSArray *images;
			NSString *resourcePath;
			NSString *name = [[[slideSavers objectAtIndex: n] lastPathComponent] stringByDeletingPathExtension];
			
			item = [NSMenuItem alloc];
			
			resourcePath = [NSString stringWithFormat: @"%@/%@/Contents/Resources", slidePath, [slideSavers objectAtIndex: n]];
			images = [self getImagesInDirectory: resourcePath inArray: NULL];
						
			if([images count] != 0) {
				[item initWithTitle: name action: @selector(updateImageMenu:) keyEquivalent: @""];
				[item setRepresentedObject: resourcePath];
				[item setEnabled: YES];
				[item setTarget: self];
		
				[[filePopup menu] addItem: item];
			}
		}
	}
	
	[[filePopup menu] addItem: [NSMenuItem separatorItem]];

	customItem = [NSMenuItem alloc];
	[customItem setTarget: self];
	[customItem initWithTitle: @"Custom Image or Directory..." action: @selector(runOpenSheet:) keyEquivalent: @""];

	if([defaults integerForKey: @"customSelection"]) {
		[customItem setRepresentedObject: [defaults stringForKey: @"imageSource"]];		
	}
	
	[[filePopup menu] addItem: customItem];
	
	if([defaults objectForKey: @"menuSelection"]) {
		[filePopup selectItemWithTitle: [defaults objectForKey: @"menuSelection"]];
	} else {
		[filePopup selectItemWithTitle: @"Forest"];
	}

	[zoomCheck setIntValue: [defaults integerForKey: @"zoom"]];
	
	[self updateImageMenu: self];
}

- (void)startBreveSimulation {
	[super startBreveSimulation];
	[self updateImage];
	[self setZoom: [defaults integerForKey: @"zoom"]];
}

- (IBAction)checkZoomBox:sender {
	[defaults setInteger: [zoomCheck intValue] forKey: @"zoom"];
	[self setZoom: [zoomCheck intValue]];
}

- (void)setZoom:(int)v {
	if(!viewEngine->controller) return;
	
  const brEval *args[2];
  brEval eval[2];
  brEval e;
  
  eval[0].set( v );
  args[0] = &eval[0];
  args[1] = &eval[1];

	brMethodCallByNameWithArgs(viewEngine->controller, "set-zoom-enabled", args, 1, &e);
}

- (IBAction)updateImageMenu:sender {
	selection = [[filePopup selectedItem] representedObject];
	
	if([filePopup selectedItem] == customItem) {
		[defaults setInteger: 1 forKey: @"customSelection"];
		[customString setStringValue: selection];
	} else {
		[defaults setInteger: 0 forKey: @"customSelection"];
		[customString setStringValue: @""];
	}

	[defaults setObject: selection forKey: @"imageSource"];
	[defaults setObject: [[filePopup selectedItem] title] forKey: @"menuSelection"];

	[self updateImage];
}

- (void)updateImage {
	NSMutableArray *images;

	selection = [defaults objectForKey: @"imageSource"];

	images = [NSMutableArray arrayWithCapacity: 10];

	if(![[selection pathExtension] caseInsensitiveCompare: @"jpg"] || ![[selection pathExtension] caseInsensitiveCompare: @"png"]) {
		[self setImage: selection];
		return;
	}

	images = [self getImagesInDirectory: selection inArray: NULL];

	if([images count] > 0) {
		[self setImage: [images objectAtIndex: random() % [images count]]];
		return;
	}

	[self setImage: @"default.png"];
}

- (id)getImagesInDirectory:(NSString*)dir inArray:(NSMutableArray*)images {
	NSArray *files;
	NSFileManager *manager = [NSFileManager defaultManager];
	NSUInteger n;
	BOOL isDir;
	
	if(!images) images = [NSMutableArray arrayWithCapacity: 100];
	
	files = [manager contentsOfDirectoryAtPath:dir error:nil];

	for(n=0;n<[files count];n++) {
		NSString *file = [files objectAtIndex: n];
		if(![[file pathExtension] caseInsensitiveCompare: @"jpg"] || ![[file pathExtension] caseInsensitiveCompare: @"png"]) {
			[images addObject: [NSString stringWithFormat: @"%@/%@", dir, file]];
		} 

		[manager fileExistsAtPath: [NSString stringWithFormat: @"%@/%@", dir, file] isDirectory: &isDir];

		if(isDir) {
			[self getImagesInDirectory: file inArray: images];
		}
	}
	
	return images;
}

- (void)setImage:(NSString*)image {
	if(!viewEngine->controller) return;

  const brEval *args[2];
  brEval eval[2];
  brEval result;
  
  char *myFile = (char *)[image cStringUsingEncoding:NSUTF8StringEncoding];
  eval[0].set(myFile);
  args[0] = &eval[0];
  args[1] = &eval[1];
  
	brMethodCallByNameWithArgs(viewEngine->controller, "load-file", args, 1, &result);
}

- (IBAction)runOpenSheet:sender {
	NSArray *types = [NSArray arrayWithObjects: @"jpeg", @"jpg", @"png", NULL];
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];

	[openPanel setCanChooseDirectories: YES];
	[openPanel setAllowedFileTypes: types];

	[openPanel beginSheetForDirectory: NULL file: NULL types: types
		modalForWindow: configWindow modalDelegate: self 
		didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo: NULL];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if(returnCode != NSCancelButton) {
		[customItem setRepresentedObject: [panel filename]];
	} else {
		[filePopup selectItemWithTitle: [defaults objectForKey: @"menuSelection"]];
	}

	[self updateImageMenu: self];
}

- (const char*)getSimName {
    return "Painter.tz";
}   

- (const char*)getDefaultsName {
	return "brevePainter";
}

- (NSString*)getNibName {
  return @"brevePainter.nib";
}   

@end
