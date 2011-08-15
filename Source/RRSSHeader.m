//
//  RRSSHeader.m
//  µ
//
//  Created by Timothy Ritchey on Mon Feb 18 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import "RRSSHeader.h"
#import "RRSSHeaderCell.h"
#import "RRSpreadSheet.h"
#import "RRSSWorksheet.h"
#import "RRSSRulerView.h"

@implementation RRSSHeader

- (id)initWithDocumentView:(RRSSWorksheet*)doc ruler:(RRSSRulerView*)rule range:(RRFloatRange)rng label:(NSString*)label index:(int)i
{
    if(self = [super init]) {
        index = i;
        range = rng;
        documentView = [doc retain];
        ruler = [rule retain];
        orientation = [ruler orientation];
        if(orientation == NSHorizontalRuler)
            frame = NSMakeRect(range.location, 0, range.length, [ruler reservedThicknessForMarkers]);
        else
            frame = NSMakeRect(0, range.location, [ruler reservedThicknessForMarkers], range.length);
        cell = [[RRSSHeaderCell alloc] initTextCell:label];
        [cell setOrientation:orientation];
        [cell setAlignment:NSCenterTextAlignment];
        [cell setWraps:NO];
        [cell setBezelStyle:NSShadowlessSquareBezelStyle];
        [cell setAllowsMixedState:YES];
        [self setState:NSOffState];
        [ruler addMarker:self];
    }
    return self;
}

- (id)initWithDocumentView:(RRSSWorksheet*)doc ruler:(RRSSRulerView*)rule range:(RRFloatRange)rng image:(NSImage*)image index:(int)i
{
    if(self = [super init]) {
        index = i;
        range = rng;
        documentView = [doc retain];
        ruler = [rule retain];
        orientation = [ruler orientation];
        if(orientation == NSHorizontalRuler)
            frame = NSMakeRect(range.location, 0, range.length, [ruler reservedThicknessForMarkers]);
        else
            frame = NSMakeRect(0, range.location, [ruler reservedThicknessForMarkers], range.length);
        cell = [[RRSSHeaderCell alloc] initImageCell:image];
        [cell setOrientation:orientation];        
        [cell setBezelStyle:NSShadowlessSquareBezelStyle];
        [ruler addMarker:self];
    }
    return self;
}


- (void)drawRect:(NSRect)rect
{
    [cell drawWithFrame:[ruler visibleFrameForRect:frame] inView:ruler];
}

- (id)documentView {
    return documentView;
}

- (RRSSRulerView*)ruler
{
    return ruler;
}

- (RRFloatRange)range
{
    return range;
}

- (void)setRange:(RRFloatRange)rng
{
    range = rng;
    if(orientation == NSHorizontalRuler)
        frame = NSMakeRect(range.location, 0, range.length, [ruler reservedThicknessForMarkers]);
    else
        frame = NSMakeRect(0, range.location, [ruler reservedThicknessForMarkers], range.length);
}

- (NSRect)frame
{
    return frame;
}

- (NSString*)label
{
    return [cell title];
}

- (void)setLabel:(NSString*)string
{
    [cell setTitle:string];
}

- (void)beginEditingLabel:(NSEvent*)theEvent
{
    NSRect editRect = [ruler visibleFrameForRect:frame];

    // adjust text to inset it from the header outline
    editRect.origin.x += 4;
    editRect.origin.y += 2;
    editRect.size.width -= 8;
    editRect.size.height -= 4;
    if(orientation == NSHorizontalRuler)
        editRect.size.height -= 6;
    else
        editRect.size.width -= 6;

    textEditor = [[NSTextView alloc] initWithFrame:editRect];
    
    [cell setEditable:YES];
    [cell editWithFrame:editRect inView:ruler editor:textEditor delegate:self event:theEvent];

}

- (void)endEditingLabel
{
    if([cell isEditable])
        [cell endEditing:textEditor];
}

- (NSImage*)image
{
    return [cell image];
}

- (void)setImage:(NSImage*)image
{
    [cell setImage:image];
}

- (int)index
{
    return index;
}

- (void)setIndex:(int)i
{
    [ruler moveHeader:self to:i];
    index = i;
}

- (BOOL)selected
{
    return selected;
}

- (void)setSelected:(BOOL)select
{
    selected = select;
    if(select) {
        [self setState:NSOnState];
        if(orientation == NSHorizontalRuler)
            [documentView selectColumn:index];
        else
            [documentView selectRow:index];
    } else {
        [self setState:NSOffState];
        if(orientation == NSHorizontalRuler)
            [documentView deselectColumn:index];
        else
            [documentView deselectRow:index];
    }
    if(!select && [cell isEditable])
        [cell endEditing:textEditor];
    [ruler setNeedsDisplayInRect:[ruler visibleFrameForRect:frame]];

}

- (BOOL)toggleSelected
{
    [self setSelected:!selected];
    return selected;
}

- (int)state
{
    return state;
}

- (void)setState:(int)s
{
    state = s;
    [cell setState:s];
    [ruler setNeedsDisplayInRect:[ruler visibleFrameForRect:frame]];
}

- (RRSSHeaderCell *) headerCell
{
    return cell;
}


/*
 * Text delegate methods
 */
- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    BOOL returnValue = NO;

    if ([NSStringFromSelector(aSelector) isEqualToString: @"insertNewline:"])
    {
        returnValue = YES;
        [cell endEditing:textEditor];
    }

    return returnValue;
}


- (BOOL)textShouldBeginEditing:(NSText *)textObject { return YES; }
- (BOOL)textShouldEndEditing:(NSText *)textObject { return YES; }

- (void)textDidBeginEditing:(NSNotification *)notification {}
- (void)textDidEndEditing:(NSNotification *)notification
{
    // grab the string and set the label

    if(orientation == NSHorizontalRuler) {
        [documentView worksheet:documentView setHeaderLabel:[[notification object] string] forColumn:index];
        [self setLabel:[documentView worksheet:documentView headerLabelForColumn:index]];
    } else {
        [documentView worksheet:documentView setHeaderLabel:[[notification object] string] forRow:index];
        [self setLabel:[documentView worksheet:documentView headerLabelForRow:index]];
    }
}
- (void)textDidChange:(NSNotification *)notification {}


- (void)dealloc
{
    [documentView release];
    [ruler release];
    [cell release];
    [super dealloc];
}

@end

