//
//  JSTTextView.h
//  jstalk
//
//  Created by August Mueller on 1/18/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NoodleLineNumberView;

@interface JSTTextView : NSTextView <NSTextStorageDelegate>{
  NoodleLineNumberView	*_lineNumberView;
  
  NSString                *_lastAutoInsert;

  NSColor *_typeColor;
  NSColor *_numberColor;
  NSColor *_stringColor;
  NSColor *_commentColor;
  NSColor *_backgroundColor;
  NSColor *_textColor;

  BOOL _shouldAutoIndent;
  BOOL _shouldUseSpaces;
  BOOL _shouldExtraIndent;
  BOOL _shouldMatchBraces;
  BOOL _shouldDoSyntaxColoring;
  BOOL _lineWrappingEnabled;
  int _tabSpaces;
}

@property (retain) NSString *lastAutoInsert;

@property (retain) NSColor *typeColor;
@property (retain) NSColor *numberColor;
@property (retain) NSColor *stringColor;
@property (retain) NSColor *commentColor;
@property (retain) NSColor *backgroundColor;
@property (retain) NSColor *textColor;

@property (assign) BOOL shouldAutoIndent;
@property (assign) BOOL shouldUseSpaces;
@property (assign) BOOL shouldExtraIndent;
@property (assign) BOOL shouldMatchBraces;
@property (assign) BOOL shouldDoSyntaxColoring;
@property (assign) BOOL lineWrappingEnabled;
@property (assign) int tabSpaces;

- (IBAction)parseCode:(id)sender;

- (int)goToLine:(int)line;

@end
