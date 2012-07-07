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

#import <AppKit/AppKit.h>

#if !TARGET_CPU_X86_64
# import <Carbon/Carbon.h>
# import <QuickTime/Movies.h>
#endif

@interface slMovieRecord : NSObject
{	
#if !TARGET_CPU_X86_64
    GWorldPtr theGWorld;
    Rect theBounds;
#else
  NSRect theBounds;
#endif
    long movieBytes;
    long maxCompressionSize;

	long movieCodec;

#if !TARGET_CPU_X86_64
    CodecQ movieQuality;

    Handle theCompressedData;

    Movie theMovie;
    short theRefNum;

    Track theTrack;
    Media theMedia;
#endif
    NSMutableArray *theFrameArray;

    int theRowPadding;
    int theDuration;

    NSString *theName;
}

- initWithPath:(NSString *)path bounds:(NSRect)bounds timeScale:(int)scale qualityLevel:(int)q;

- (NSString*)name;

- (void)setRowPadding:(int)padding;
- (int)rowPadding;
- (void)setDuration:(int)duration;
- (int)duration;

- (void)queueFrameFromRGBPixels:(unsigned char*)ptr;

- (int)getQueueSize;
- (int)addFramesFromQueue;
- (int)addFrameFromQueue:(int)n;

- (int)addFrameFromRGBPixels:(unsigned char*)ptr;
#if !TARGET_CPU_X86_64
- (int)addFrameFromPixMapHandle:(PixMapHandle)pmh;
#endif

- (int)closeMovie;

@end

@interface NSString(Carbon_Additions)
-(int)fsSpec:(FSSpec*)s;
@end
