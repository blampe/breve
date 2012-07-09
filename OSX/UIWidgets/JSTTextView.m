//
//  JSTTextView.m
//  jstalk
//
//  Created by August Mueller on 1/18/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTTextView.h"
#import "MarkerLineNumberView.h"
#import "NoodleLineNumberView.h"
#import "TETextUtils.h"

static NSString *JSTQuotedStringAttributeName = @"JSTQuotedString";

@interface JSTTextView (Private)
- (void)setupLineView;
@end


@implementation JSTTextView

@synthesize lastAutoInsert=_lastAutoInsert;

@synthesize typeColor = _typeColor;
@synthesize numberColor = _numberColor;
@synthesize stringColor = _stringColor;
@synthesize commentColor = _commentColor;
@synthesize backgroundColor = _backgroundColor;
@synthesize textColor = _textColor;
@synthesize shouldAutoIndent = _shouldAutoIndent;
@synthesize shouldUseSpaces = _shouldUseSpaces;
@synthesize shouldExtraIndent = _shouldExtraIndent;
@synthesize shouldMatchBraces = _shouldMatchBraces;
@synthesize shouldDoSyntaxColoring = _shouldDoSyntaxColoring;
@synthesize lineWrappingEnabled = _lineWrappingEnabled;
@synthesize tabSpaces = _tabSpaces;

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container {
    
	self = [super initWithFrame:frameRect textContainer:container];
    
	if (self != nil) {
        [self setSmartInsertDeleteEnabled:NO];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
	if (self != nil) {
        // what's the right way to do this?
        [self setSmartInsertDeleteEnabled:NO];
    _shouldDoSyntaxColoring = YES;
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_lineNumberView release];
    [_lastAutoInsert release];
  
  [_typeColor release];
  [_numberColor release];
  [_stringColor release];
  [_commentColor release];
  [_backgroundColor release];
  [_textColor release];

  [super dealloc];
}


- (void)setupLineViewAndStuff {
    
    _lineNumberView = [[NoodleLineNumberView alloc] initWithScrollView:[self enclosingScrollView]];
  _lineNumberView.autoresizingMask = NSViewHeightSizable;
    [[self enclosingScrollView] setVerticalRulerView:_lineNumberView];
    [[self enclosingScrollView] setHasHorizontalRuler:NO];
  [[self enclosingScrollView] setHorizontalRulerView:nil];
    [[self enclosingScrollView] setHasVerticalRuler:YES];
    [[self enclosingScrollView] setRulersVisible:YES];
    
    [[self textStorage] setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(textViewDidChangeSelection:) 
                                                 name:NSTextViewDidChangeSelectionNotification 
                                               object:self];

  _stringColor = [[NSColor greenColor] retain];
  _commentColor = [[NSColor grayColor] retain];
  _numberColor = [[NSColor blueColor] retain];
  _typeColor = [[NSColor redColor] retain];
  _backgroundColor = [[NSColor whiteColor] retain];
  _textColor = [[NSColor blackColor] retain];

  
//    [self parseCode:nil];
}

- (void) awakeFromNib {
  [super awakeFromNib];
  [self setupLineViewAndStuff];
}

- (NSColor*)colorForToken:(char*)string {
  if(!strcmp(string, "int")) return _typeColor;
  else if(!strcmp(string, "ints")) return _typeColor;
  else if(!strcmp(string, "object")) return _typeColor;
  else if(!strcmp(string, "objects")) return _typeColor;
  else if(!strcmp(string, "double")) return _typeColor;
  else if(!strcmp(string, "doubles")) return _typeColor;
  else if(!strcmp(string, "float")) return _typeColor;
  else if(!strcmp(string, "floats")) return _typeColor;
  else if(!strcmp(string, "vector")) return _typeColor;
  else if(!strcmp(string, "vectors")) return _typeColor;
  else if(!strcmp(string, "string")) return _typeColor;
  else if(!strcmp(string, "strings")) return _typeColor;
  else if(!strcmp(string, "hash")) return _typeColor;
  else if(!strcmp(string, "hashes")) return _typeColor;
  else if(!strcmp(string, "list")) return _typeColor;
  else if(!strcmp(string, "lists")) return _typeColor;
  else if(!strcmp(string, "matrix")) return _typeColor;
  else if(!strcmp(string, "matrices")) return _typeColor;
  else return nil;
}

- (void)syntaxColorEntireFile:(BOOL)wholeFile {
  if(!_shouldDoSyntaxColoring) {
    return;
  }

  [[self textStorage] beginEditing];

  NSString *text = [self string];
  NSRange change;
  NSColor *color = NULL;
  BOOL lineStart;
  
  char token[1024];
  
  unsigned int x, n, m;
  unsigned int start, end;
    
  if(wholeFile == YES) {
    start = 0;
    end = [[self string] length];
  } else {
		if([self selectedRange].location == 0) 
      start = 0;
		else 
      start = [self selectedRange].location - 1;
    
    end = [self selectedRange].location + 1;
    
    if(end > [text length]) end = [text length];
    
    while(start > 0 && [text characterAtIndex: start] != '\n') start--;
    while(end < [text length] && [text characterAtIndex: end] != '\n') end++;
  }
  
  change.location = start;
  change.length = (end - start);
  
  [[self textStorage] addAttribute:NSForegroundColorAttributeName 
                             value:_textColor 
                             range:change];

	lineStart = YES;
  
  for(n=start;n<end;n++) {
    char c = [text characterAtIndex: n];
    
    if(c == '#' || (lineStart && c == '%')) {
      m = n+1;
      while(m < end && [text characterAtIndex: m] != '\n') m++;
      color = _commentColor;
    } else if(c == '.' || isdigit(c)) {
      m = n+1;
      while(m < end && (isdigit([text characterAtIndex: m]) || [text characterAtIndex: m] == '.')) m++;
      color = _numberColor;
    } else if(c == '\"') {
      n++;
      m = n;
      
      while(m < end && ([text characterAtIndex: m] != '\"' || [text characterAtIndex: m - 1] == '\\')) m++;
      color = _stringColor;
    } else if(isalpha(c)) {
      x = 0;
      m = n;
      
      while((isalpha(c) || c == '-' || c == '_') && m < end - 1) {
        token[x++] = c;
        m++;
        c = [text characterAtIndex: m];
      }
      
      token[x] = 0;
      
      color = [self colorForToken: token];
    } else {
			m = n;
		}
    
		if(c != '\t' && c != ' ') lineStart = NO;
    
    if(n != m && n < end && color) {
      change.location = n;
      change.length = m - n;
      [[self textStorage] addAttribute:NSForegroundColorAttributeName 
                                 value:color 
                                 range:change];
    }
    
    n = m;
  }

  [[self textStorage] endEditing];
}

- (void)parseCode:(id)sender {
  [self syntaxColorEntireFile:YES];
}



- (void) textStorageDidProcessEditing:(NSNotification *)note {
    [self parseCode:nil];
}

- (NSArray *)writablePasteboardTypes {
    return [[super writablePasteboardTypes] arrayByAddingObject:NSRTFPboardType];
}

- (void)insertTab:(id)sender {
    [self insertText:@"    "];
}

- (void)autoInsertText:(NSString*)text {
    
    [super insertText:text];
    [self setLastAutoInsert:text];
    
}

- (void)insertText:(id)insertString {
#if 0    
    if (!([JSTPrefs boolForKey:@"codeCompletionEnabled"])) {
        [super insertText:insertString];
        return;
    }
#endif
    // make sure we're not doing anything fance in a quoted string.
    if (NSMaxRange([self selectedRange]) < [[self textStorage] length] && [[[self textStorage] attributesAtIndex:[self selectedRange].location effectiveRange:nil] objectForKey:JSTQuotedStringAttributeName]) {
        [super insertText:insertString];
        return;
    }
    
    if ([@")" isEqualToString:insertString] && [_lastAutoInsert isEqualToString:@")"]) {
        
        NSRange nextRange   = [self selectedRange];
        nextRange.length = 1;
        
        if (NSMaxRange(nextRange) <= [[self textStorage] length]) {
            
            NSString *next = [[[self textStorage] mutableString] substringWithRange:nextRange];
            
            if ([@")" isEqualToString:next]) {
                // just move our selection over.
                nextRange.length = 0;
                nextRange.location++;
                [self setSelectedRange:nextRange];
                return;
            }
        }
    }
    
    [self setLastAutoInsert:nil];
    
    [super insertText:insertString];
    
    NSRange currentRange = [self selectedRange];
    NSRange r = [self selectionRangeForProposedRange:currentRange granularity:NSSelectByParagraph];
    BOOL atEndOfLine = (NSMaxRange(r) - 1 == NSMaxRange(currentRange));
    
    
    if (atEndOfLine && [@"{" isEqualToString:insertString]) {
        
        r = [self selectionRangeForProposedRange:currentRange granularity:NSSelectByParagraph];
        NSString *myLine = [[[self textStorage] mutableString] substringWithRange:r];
        
        NSMutableString *indent = [NSMutableString string];
        
        NSUInteger j = 0;
        
        while (j < [myLine length] && ([myLine characterAtIndex:j] == ' ' || [myLine characterAtIndex:j] == '\t')) {
            [indent appendFormat:@"%C", [myLine characterAtIndex:j]];
            j++;
        }
        
        [self autoInsertText:[NSString stringWithFormat:@"\n%@    \n%@}", indent, indent]];
        
        currentRange.location += [indent length] + 5;
        
        [self setSelectedRange:currentRange];
    }
    else if (atEndOfLine && [@"(" isEqualToString:insertString]) {
        
        [self autoInsertText:@")"];
        [self setSelectedRange:currentRange];
        
    }
    else if (atEndOfLine && [@"[" isEqualToString:insertString]) {
        [self autoInsertText:@"]"];
        [self setSelectedRange:currentRange];
    }
    else if ([@"\"" isEqualToString:insertString]) {
        [self autoInsertText:@"\""];
        [self setSelectedRange:currentRange];
    }
}

- (void)insertNewline:(id)sender {
    
    [super insertNewline:sender];
  if (self.shouldAutoIndent) {
        
        NSRange r = [self selectedRange];
        if (r.location > 0) {
            r.location --;
        }
        
        r = [self selectionRangeForProposedRange:r granularity:NSSelectByParagraph];
        
        NSString *previousLine = [[[self textStorage] mutableString] substringWithRange:r];
        
        NSUInteger j = 0;
        
        while (j < [previousLine length] && ([previousLine characterAtIndex:j] == ' ' || [previousLine characterAtIndex:j] == '\t')) {
            j++;
        }
        
        if (j > 0) {
            NSString *foo = [[[self textStorage] mutableString] substringWithRange:NSMakeRange(r.location, j)];
            [self insertText:foo];
        }
    }
}


- (void)changeSelectedNumberByDelta:(NSInteger)d {
    NSRange r   = [self selectedRange];
    NSRange wr  = [self selectionRangeForProposedRange:r granularity:NSSelectByWord];
    NSString *s = [[[self textStorage] mutableString] substringWithRange:wr];
    
    NSInteger i = [s integerValue];
    
    if ([s isEqualToString:[NSString stringWithFormat:@"%ld", (long)i]]) {
        
        NSString *newString = [NSString stringWithFormat:@"%ld", (long)(i+d)];
        
        if ([self shouldChangeTextInRange:wr replacementString:newString]) { // auto undo.
            [[self textStorage] replaceCharactersInRange:wr withString:newString];
            [self didChangeText];
            
            r.length = 0;
            [self setSelectedRange:r];    
        }
    }
}

/*
- (void)moveForward:(id)sender {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    #pragma message "this really really needs to be a pref"
    // defaults write org.jstalk.JSTalkEditor optionNumberIncrement 1
    if ([JSTPrefs boolForKey:@"optionNumberIncrement"]) {
        [self changeSelectedNumberByDelta:-1];
    }
    else {
        [super moveForward:sender];
    }
}

- (void)moveBackward:(id)sender {
    if ([JSTPrefs boolForKey:@"optionNumberIncrement"]) {
        [self changeSelectedNumberByDelta:1];
    }
    else {
        [super moveBackward:sender];
    }
}


- (void)moveToEndOfParagraph:(id)sender {
    
    if (![JSTPrefs boolForKey:@"optionNumberIncrement"] || (([NSEvent modifierFlags] & NSAlternateKeyMask) != 0)) {
        [super moveToEndOfParagraph:sender];
    }
}

- (void)moveToBeginningOfParagraph:(id)sender {
    if (![JSTPrefs boolForKey:@"optionNumberIncrement"] || (([NSEvent modifierFlags] & NSAlternateKeyMask) != 0)) {
        [super moveToBeginningOfParagraph:sender];
    }
}
*/
/*
- (void)moveDown:(id)sender {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}

- (void)moveDownAndModifySelection:(id)sender {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
}
*/
// Mimic BBEdit's option-delete behavior, which is THE WAY IT SHOULD BE DONE

- (void)deleteWordForward:(id)sender {
    
    NSRange r = [self selectedRange];
    NSUInteger textLength = [[self textStorage] length];
    
    if (r.length || (NSMaxRange(r) >= textLength)) {
        [super deleteWordForward:sender];
        return;
    }
    
    // delete the whitespace forward.
    
    NSRange paraRange = [self selectionRangeForProposedRange:r granularity:NSSelectByParagraph];
    
    NSUInteger diff = r.location - paraRange.location;
    
    paraRange.location += diff;
    paraRange.length   -= diff;
    
    NSString *foo = [[[self textStorage] string] substringWithRange:paraRange];
    
    NSUInteger len = 0;
    while ([foo characterAtIndex:len] == ' ' && len < paraRange.length) {
        len++;
    }
    
    if (!len) {
        [super deleteWordForward:sender];
        return;
    }
    
    r.length = len;
    
    if ([self shouldChangeTextInRange:r replacementString:@""]) { // auto undo.
        [self replaceCharactersInRange:r withString:@""];
    }
}

- (void)deleteBackward:(id)sender {
    if ([[self delegate] respondsToSelector:@selector(textView:doCommandBySelector:)]) {
        // If the delegate wants a crack at command selectors, give it a crack at the standard selector too.
        if ([[self delegate] textView:self doCommandBySelector:@selector(deleteBackward:)]) {
            return;
        }
    }
    else {
        NSRange charRange = [self rangeForUserTextChange];
        if (charRange.location != NSNotFound) {
            if (charRange.length > 0) {
                // Non-zero selection.  Delete normally.
                [super deleteBackward:sender];
            } else {
                if (charRange.location == 0) {
                    // At beginning of text.  Delete normally.
                    [super deleteBackward:sender];
                } else {
                    NSString *string = [self string];
                    NSRange paraRange = [string lineRangeForRange:NSMakeRange(charRange.location - 1, 1)];
                    if (paraRange.location == charRange.location) {
                        // At beginning of line.  Delete normally.
                        [super deleteBackward:sender];
                    } else {
                        unsigned tabWidth = self.tabSpaces; //[[TEPreferencesController sharedPreferencesController] tabWidth];
                        unsigned indentWidth = 4;// [[TEPreferencesController sharedPreferencesController] indentWidth];
                      BOOL usesTabs = !self.shouldUseSpaces;
                        NSRange leadingSpaceRange = paraRange;
                        unsigned leadingSpaces = TE_numberOfLeadingSpacesFromRangeInString(string, &leadingSpaceRange, tabWidth);
                        
                        if (charRange.location > NSMaxRange(leadingSpaceRange)) {
                            // Not in leading whitespace.  Delete normally.
                            [super deleteBackward:sender];
                        } else {
                            NSTextStorage *text = [self textStorage];
                            unsigned leadingIndents = leadingSpaces / indentWidth;
                            NSString *replaceString;
                            
                            // If we were indented to an fractional level just go back to the last even multiple of indentWidth, if we were exactly on, go back a full level.
                            if (leadingSpaces % indentWidth == 0) {
                                leadingIndents--;
                            }
                            leadingSpaces = leadingIndents * indentWidth;
                            replaceString = ((leadingSpaces > 0) ? TE_tabbifiedStringWithNumberOfSpaces(leadingSpaces, tabWidth, usesTabs) : @"");
                            if ([self shouldChangeTextInRange:leadingSpaceRange replacementString:replaceString]) {
                                NSDictionary *newTypingAttributes;
                                if (charRange.location < [string length]) {
                                    newTypingAttributes = [[text attributesAtIndex:charRange.location effectiveRange:NULL] retain];
                                } else {
                                    newTypingAttributes = [[text attributesAtIndex:(charRange.location - 1) effectiveRange:NULL] retain];
                                }
                                
                                [text replaceCharactersInRange:leadingSpaceRange withString:replaceString];
                                
                                [self setTypingAttributes:newTypingAttributes];
                                [newTypingAttributes release];
                                
                                [self didChangeText];
                            }
                        }
                    }
                }
            }
        }
    }
}



- (void)TE_doUserIndentByNumberOfLevels:(int)levels {
    // Because of the way paragraph ranges work we will add spaces a final paragraph separator only if the selection is an insertion point at the end of the text.
    // We ask for rangeForUserTextChange and extend it to paragraph boundaries instead of asking rangeForUserParagraphAttributeChange because this is not an attribute change and we don't want it to be affected by the usesRuler setting.
    NSRange charRange = [[self string] lineRangeForRange:[self rangeForUserTextChange]];
    NSRange selRange = [self selectedRange];
    if (charRange.location != NSNotFound) {
        NSTextStorage *textStorage = [self textStorage];
        NSAttributedString *newText;
      unsigned tabWidth = self.tabSpaces;
        unsigned indentWidth = 4;
      BOOL usesTabs = !self.shouldUseSpaces;
        
        selRange.location -= charRange.location;
        newText = TE_attributedStringByIndentingParagraphs([textStorage attributedSubstringFromRange:charRange], levels,  &selRange, [self typingAttributes], tabWidth, indentWidth, usesTabs);
        
        selRange.location += charRange.location;
        if ([self shouldChangeTextInRange:charRange replacementString:[newText string]]) {
            [[textStorage mutableString] replaceCharactersInRange:charRange withString:[newText string]];
            //[textStorage replaceCharactersInRange:charRange withAttributedString:newText];
            [self setSelectedRange:selRange];
            [self didChangeText];
        }
    }
}


- (void)shiftLeft:(id)sender {
    [self TE_doUserIndentByNumberOfLevels:-1];
}

- (void)shiftRight:(id)sender {
    [self TE_doUserIndentByNumberOfLevels:1];
}

- (void)textViewDidChangeSelection:(NSNotification *)notification {
    NSTextView *textView = [notification object];
    NSRange selRange = [textView selectedRange];
    //TEPreferencesController *prefs = [TEPreferencesController sharedPreferencesController];
    
    //if ([prefs selectToMatchingBrace]) {
    if (YES) {
        // The NSTextViewDidChangeSelectionNotification is sent before the selection granularity is set.  Therefore we can't tell a double-click by examining the granularity.  Fortunately there's another way.  The mouse-up event that ended the selection is still the current event for the app.  We'll check that instead.  Perhaps, in an ideal world, after checking the length we'd do this instead: ([textView selectionGranularity] == NSSelectByWord).
        if ((selRange.length == 1) && ([[NSApp currentEvent] type] == NSLeftMouseUp) && ([[NSApp currentEvent] clickCount] == 2)) {
            NSRange matchRange = TE_findMatchingBraceForRangeInString(selRange, [textView string]);
            
            if (matchRange.location != NSNotFound) {
                selRange = NSUnionRange(selRange, matchRange);
                [textView setSelectedRange:selRange];
                [textView scrollRangeToVisible:matchRange];
            }
        }
    }
    
  if ([self shouldMatchBraces]) {
        NSRange oldSelRangePtr;
        
        [[[notification userInfo] objectForKey:@"NSOldSelectedCharacterRange"] getValue:&oldSelRangePtr];
        
        // This test will catch typing sel changes, also it will catch right arrow sel changes, which I guess we can live with.  MF:??? Maybe we should catch left arrow changes too for consistency...
        if ((selRange.length == 0) && (selRange.location > 0) && ([[NSApp currentEvent] type] == NSKeyDown) && (oldSelRangePtr.location == selRange.location - 1)) {
            NSRange origRange = NSMakeRange(selRange.location - 1, 1);
            unichar origChar = [[textView string] characterAtIndex:origRange.location];
            
            if (TE_isClosingBrace(origChar)) {
                NSRange matchRange = TE_findMatchingBraceForRangeInString(origRange, [textView string]);
                if (matchRange.location != NSNotFound) {
                    
                    // do this with a delay, since for some reason it only works when we use the arrow keys otherwise.
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showFindIndicatorForRange:matchRange];
                        });
                    });
                }
            }
        }
    }
}



- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity {
    
    // check for cases where we've got: [foo setValue:bar forKey:"x"]; and we double click on setValue.  The default way NSTextView does the selection
    // is to have it highlight all of setValue:bar, which isn't what we want.  So.. we mix it up a bit.
    // There's probably a better way to do this, but I don't currently know what it is.
    
    if (granularity == NSSelectByWord && ([[NSApp currentEvent] type] == NSLeftMouseUp || [[NSApp currentEvent] type] == NSLeftMouseDown) && [[NSApp currentEvent] clickCount] > 1) {
        
        NSRange r           = [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
        NSString *s         = [[[self textStorage] mutableString] substringWithRange:r];
        NSRange colLocation = [s rangeOfString:@":"];
        
        if (colLocation.location != NSNotFound) {
            
            if (proposedSelRange.location > (r.location + colLocation.location)) {
                r.location = r.location + colLocation.location + 1;
                r.length = [s length] - colLocation.location - 1;
            }
            else {
                r.length = colLocation.location;
            }
        }
        
        return r;
    }
    
    return [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
}

- (void)setInsertionPointFromDragOpertion:(id <NSDraggingInfo>)sender {
    
    NSLayoutManager *layoutManager = [self layoutManager];
    NSTextContainer *textContainer = [self textContainer];
    
    NSUInteger glyphIndex, charIndex, length = [[self textStorage] length];
    NSPoint point = [self convertPoint:[sender draggingLocation] fromView:nil];
    
    // Convert those coordinates to the nearest glyph index
    glyphIndex = [layoutManager glyphIndexForPoint:point inTextContainer:textContainer];
    
    // Convert the glyph index to a character index
    charIndex = [layoutManager characterIndexForGlyphAtIndex:glyphIndex];
    
    // put the selection where we have the mouse.
    if (charIndex == (length - 1)) {
        [self setSelectedRange:NSMakeRange(charIndex+1, 0)];
        //[self setSelectedRange:NSMakeRange(charIndex, 0)];
    }
    else {
        [self setSelectedRange:NSMakeRange(charIndex, 0)];
    }
    
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    
    if (([NSEvent modifierFlags] & NSAlternateKeyMask) != 0) {
        
        [self setInsertionPointFromDragOpertion:sender];
        
        NSPasteboard *paste = [sender draggingPasteboard];
        NSArray *fileArray = [paste propertyListForType:NSFilenamesPboardType];
        
        for (NSString *path in fileArray) {
            
            [self insertText:[NSString stringWithFormat:@"\"%@\"", path]];
            
            if ([fileArray count] > 1) {
                [self insertNewline:nil];
            }
        }
        
        return YES;
    }
    
    return [super performDragOperation:sender];
}


#pragma mark -
#pragma mark
- (int)goToLine:(int)line {
  int current = 1;
  NSRange r;
  
  /* get the data as a c string, fill out an NSRange corresponding to the desired line... */
  
  char *data = (char*)[[self string] cStringUsingEncoding:NSUTF8StringEncoding];
  
  if(*data == 0) return 1;
  
  r.location = r.length = 0;
  
  /* find the start of the desired line */
  
  while(data[r.location] && current < line) {
    if(data[r.location] == '\n') current++;
    r.location++;
  }   
  
  if(!data[r.location]) {
    /* if we're at \0, then we've reached the end of the string without */
    /* finding enough lines--step backwards to select the final line.   */
    
    while(r.location && data[r.location--] != '\n') r.length++;
  } else {
    /* if we're here, then we've found the line we want--step forward  */
    /* until we find a newline or the end of the string */
    
    while(data[r.location + r.length] && data[r.location + r.length] != '\n')
      r.length++;
  }
  
  [self setSelectedRange: r];
  [self scrollRangeToVisible: r];
  [[self window] makeFirstResponder: self];
  
  return current;
}


@end

// stolen from NSTextStorage_TETextExtras.m
@implementation NSTextStorage (TETextExtras)

- (BOOL)_usesProgrammingLanguageBreaks {
    return YES;
}
@end
