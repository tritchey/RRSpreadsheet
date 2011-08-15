//
//  RRSSHeader.h
//  µ
//
//  Created by Timothy Ritchey on Mon Feb 18 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RRFloatRange.h"
#import "RRSSRulerView.h"

@class RRSSHeaderCell, RRSSWorksheet;

@interface RRSSHeader : NSRulerMarker
{
    RRSSWorksheet* documentView;
    RRSSRulerView *ruler;
    int index;
    RRFloatRange range;
    NSRect frame;
    NSRulerOrientation orientation;
    RRSSHeaderCell *cell;
    NSTextView *textEditor;
    BOOL selected;
    int state;
}
- (id)initWithDocumentView:(RRSSWorksheet*)doc ruler:(RRSSRulerView*)rule range:(RRFloatRange)rng label:(NSString*)label index:(int)i;
- (id)initWithDocumentView:(RRSSWorksheet*)doc ruler:(RRSSRulerView*)rule range:(RRFloatRange)rng image:(NSImage*)image index:(int)i;
- (id)documentView;
- (RRSSRulerView*)ruler;
- (RRFloatRange)range;
- (void)setRange:(RRFloatRange)rng;
- (NSRect)frame;
- (NSString*)label;
- (void)setLabel:(NSString*)string;
- (void)beginEditingLabel:(NSEvent*)theEvent;
- (void)endEditingLabel;
- (NSImage*)image;
- (void)setImage:(NSImage*)image;
- (int)index;
- (void)setIndex:(int)i;
- (BOOL)selected;
- (void)setSelected:(BOOL)select;
- (BOOL)toggleSelected;
- (int)state;
- (void)setState:(int)s;
- (RRSSHeaderCell *) headerCell;



    /*
     * Text delegate methods
     */
- (BOOL)textShouldBeginEditing:(NSText *)textObject;
- (BOOL)textShouldEndEditing:(NSText *)textObject;
- (void)textDidBeginEditing:(NSNotification *)notification;
- (void)textDidEndEditing:(NSNotification *)notification;
- (void)textDidChange:(NSNotification *)notification;


@end

