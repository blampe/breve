//
//  slSplitView.m
//  breve
//
//  Created by Steve White on 7/8/12.
//  Copyright (c) 2012 Steve White. All rights reserved.
//

#import "slSplitView.h"

@implementation slSplitView
#if 0
- (void)awakeFromNib
{
	image = [[NSImage imageNamed:@"sourceSplitDivider"] retain];
	[image setFlipped:YES];
}

- (void)dealloc
{
  [image release];
  [super dealloc];
}

- (CGFloat)dividerThickness
{
	return 22.0;
}

- (void)drawDividerInRect:(NSRect)rect
{
	[self lockFocus];
  
	[image drawInRect:rect 
           fromRect:NSZeroRect 
          operation:NSCompositeSourceOver
           fraction:1.0];
	[self unlockFocus];
}
#endif
@end
