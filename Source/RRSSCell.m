//
//  RRSSCell.m
//  µ
//
//  Created by Timothy Ritchey on Mon Feb 18 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import "RRSSCell.h"

@implementation RRSSCell
- (NSSize)cellSizeForBounds:(NSRect)cellBounds;
{
    NSSize cellSize;

    cellSize =[super cellSizeForBounds:NSInsetRect(cellBounds, 3, 0)];
    cellSize.width += 6.0;
    
    return cellSize;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    NSClipView *clipView;
    NSTextContainer *textContainer;

    ssDelegate = anObject;

    clipView = [[NSClipView alloc] initWithFrame:aRect];
    [clipView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [clipView setBackgroundColor:[NSColor textBackgroundColor]];
    [controlView addSubview:clipView];
    [controlView setAutoresizesSubviews:NO];
    [clipView release];

    // Set up text view
    [textObj setFrame:aRect];

    // figure out where we are
    [(NSTextView*)textObj setTextContainerInset:NSMakeSize(-2.5,1)];
    
    [textObj setHorizontallyResizable:YES];
    [textObj setVerticallyResizable:NO];
    [textObj setMinSize:aRect.size];
    [textObj setMaxSize:NSMakeSize(1.0e7, NSHeight(aRect))];
    [textObj setAutoresizingMask:NSViewNotSizable];
    [textObj setAlignment:[self alignment]];
    [textObj setFieldEditor:YES];
    [textObj setString:[self title]];
    [(NSTextView*)textObj setUsesRuler:NO];
    [textObj setFont:[self font]];

    textContainer = [(NSTextView*)textObj textContainer];

    // Set up container
    [textContainer setContainerSize:NSMakeSize(1.0e7, NSHeight([textObj frame]))];
    [textContainer setWidthTracksTextView:NO];
    [textContainer setHeightTracksTextView:NO];

    // Add text view to the clipView.
    [clipView setDocumentView:textObj];
    [clipView setAutoresizesSubviews:YES];

    [textObj sizeToFit];
    
    [textObj setDelegate:anObject];
    [textObj setNextResponder:anObject];

    
    [[textObj window] makeFirstResponder:textObj];
    [textObj selectAll:self];
}
@end
