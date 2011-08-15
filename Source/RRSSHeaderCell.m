//
//  RRSSHeaderCell.m
//  µ
//
//  Created by Timothy Ritchey on Mon Feb 18 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import "RRSSHeaderCell.h"

static NSImage *columnClearTab;
static NSImage *columnBlueTab;
static NSImage *columnGraphiteTab;
static NSImage *columnDarkenedTab;
static NSImage *rowClearTab;
static NSImage *rowBlueTab;
static NSImage *rowGraphiteTab;
static NSImage *rowDarkenedTab;

@implementation RRSSHeaderCell

+ (void)initialize
{
    static BOOL beenHere = NO;
    NSBundle *mainBundle;
    NSString *imagePath;

    if (beenHere) return;

    beenHere = YES;

    mainBundle = [NSBundle bundleForClass:[RRSSHeaderCell class]];
    imagePath = [mainBundle pathForResource:@"columnClearTab" ofType:@"tiff"];
    columnClearTab = [[NSImage alloc] initByReferencingFile:imagePath];
    [columnClearTab setFlipped:YES];
    imagePath = [mainBundle pathForResource:@"columnBlueTab" ofType:@"tiff"];
    columnBlueTab = [[NSImage alloc] initByReferencingFile:imagePath];
    [columnBlueTab setFlipped:YES];
    imagePath = [mainBundle pathForResource:@"columnGraphiteTab" ofType:@"tiff"];
    columnGraphiteTab = [[NSImage alloc] initByReferencingFile:imagePath];
    [columnGraphiteTab setFlipped:YES];
    imagePath = [mainBundle pathForResource:@"columnDarkenedTab" ofType:@"tiff"];
    columnDarkenedTab = [[NSImage alloc] initByReferencingFile:imagePath];
    [columnDarkenedTab setFlipped:YES];
    imagePath = [mainBundle pathForResource:@"rowClearTab" ofType:@"tiff"];
    rowClearTab = [[NSImage alloc] initByReferencingFile:imagePath];
    [rowClearTab setFlipped:YES];
    imagePath = [mainBundle pathForResource:@"rowBlueTab" ofType:@"tiff"];
    rowBlueTab = [[NSImage alloc] initByReferencingFile:imagePath];
    [rowBlueTab setFlipped:YES];
    imagePath = [mainBundle pathForResource:@"rowGraphiteTab" ofType:@"tiff"];
    rowGraphiteTab = [[NSImage alloc] initByReferencingFile:imagePath];
    [rowGraphiteTab setFlipped:YES];
    imagePath = [mainBundle pathForResource:@"rowDarkenedTab" ofType:@"tiff"];
    rowDarkenedTab = [[NSImage alloc] initByReferencingFile:imagePath];
    [rowDarkenedTab setFlipped:YES];


    return;
}

- (id)initTextCell:(NSString*)aString
{
    if(self = [super initTextCell:aString]) {

        // check for the current color of blue or graphite,
        // and select the proper widget images
        if(1) { // this will be blue
            rowHighlightedTab = rowBlueTab;
            columnHighlightedTab = columnBlueTab;
        } else if(0) { // this will be graphite
            rowHighlightedTab = rowGraphiteTab;
            columnHighlightedTab = columnGraphiteTab;
        }
        
    }
    return self;
}

// we are overridding this to draw our nice little spreadsheet header

- (void)drawWithFrame:(NSRect)rect inView:(NSView*)view
{
    NSRect drawRect;
    NSImage *sourceImage = columnHighlightedTab;

    [[NSColor whiteColor] set];
    [NSBezierPath fillRect:rect];
    
    if(orientation == NSHorizontalRuler) {
        switch([self state]) {
            case NSOnState:
                sourceImage = columnHighlightedTab;
                break;
            case NSMixedState:
                sourceImage = columnDarkenedTab;
                break;
            case NSOffState:
                sourceImage = columnClearTab;
                break;
            default:
                sourceImage = columnClearTab;
        }
        
    } else {
        switch([self state]) {
            case NSOnState:
                sourceImage = rowHighlightedTab;
                break;
            case NSMixedState:
                sourceImage = rowDarkenedTab;
                break;
            case NSOffState:
                sourceImage = rowClearTab;
                break;
            default:
                sourceImage = rowClearTab;
        }
    }

    drawRect = NSMakeRect(rect.origin.x, rect.origin.y + rect.size.height - 11,
                          15, 11);
    [sourceImage drawInRect:drawRect fromRect:NSMakeRect(0, 0, 15, 11)
                  operation:NSCompositeSourceOver fraction:1.0];
    drawRect = NSMakeRect(rect.origin.x + 15, rect.origin.y + rect.size.height - 11,
                          rect.size.width - 30, 11);
    [sourceImage drawInRect:drawRect fromRect:NSMakeRect(15, 0, 1, 11)
                  operation:NSCompositeSourceOver fraction:1.0];
    drawRect = NSMakeRect(rect.origin.x + rect.size.width - 15, rect.origin.y + rect.size.height - 11,
                          15, 11);
    [sourceImage drawInRect:drawRect fromRect:NSMakeRect(16, 0, 15, 11)
                  operation:NSCompositeSourceOver fraction:1.0];

    drawRect = NSMakeRect(rect.origin.x, rect.origin.y + 11,
                          15, rect.size.height - 22);
    [sourceImage drawInRect:drawRect fromRect:NSMakeRect(0, 11, 15, 1)
                  operation:NSCompositeSourceOver fraction:1.0];
    drawRect = NSMakeRect(rect.origin.x + 15, rect.origin.y + 11,
                          rect.size.width - 30, rect.size.height - 22);
    [sourceImage drawInRect:drawRect fromRect:NSMakeRect(15, 11, 1, 1)
                  operation:NSCompositeSourceOver fraction:1.0];
    drawRect = NSMakeRect(rect.origin.x + rect.size.width - 15, rect.origin.y + 11,
                          15, rect.size.height - 22);
    [sourceImage drawInRect:drawRect fromRect:NSMakeRect(16, 11, 15, 1)
                  operation:NSCompositeSourceOver fraction:1.0];

    drawRect = NSMakeRect(rect.origin.x, rect.origin.y, 15, 11);
    [sourceImage drawInRect:drawRect fromRect:NSMakeRect(0, 12, 15, 11)
                  operation:NSCompositeSourceOver fraction:1.0];
    drawRect = NSMakeRect(rect.origin.x + 15, rect.origin.y, rect.size.width - 30, 11);
    [sourceImage drawInRect:drawRect fromRect:NSMakeRect(15, 12, 1, 11)
                  operation:NSCompositeSourceOver fraction:1.0];
    drawRect = NSMakeRect(rect.origin.x + rect.size.width - 15, rect.origin.y, 15, 11);
    [sourceImage drawInRect:drawRect fromRect:NSMakeRect(16, 12, 15, 11)
                  operation:NSCompositeSourceOver fraction:1.0];
    
 
    
    [self drawInteriorWithFrame:rect inView:view];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
{
    if(orientation == NSHorizontalRuler) {
        cellFrame.origin.y -= 2;
    }
    
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}


- (void) setOrientation:(NSRulerOrientation)orient
{
    orientation = orient;
}



- (void)editWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent
{
    NSClipView *clipView;
    NSTextContainer *textContainer;

    clipView = [[NSClipView alloc] initWithFrame:aRect];
    [clipView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [clipView setBackgroundColor:[NSColor textBackgroundColor]];
    [controlView addSubview:clipView];
    [controlView setAutoresizesSubviews:YES];
    [clipView release];

    // Set up text view
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

    [[textObj window] makeFirstResponder:textObj];
    [textObj selectAll:self];
}
@end

