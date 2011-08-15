//
//  RRSSRulerView.m
//  µ
//
//  Created by Timothy Ritchey on Fri Feb 08 2002.
//  Copyright (c) 2002 Timothy Ritchey. All rights reserved.
//

#import "RRSSRulerView.h"
#import "RRSSHeader.h"
#import "RRSSWorksheet.h"
#import "RRSSWorksheetPrivate.h"

static NSImage *horizontalResizeImage;
static NSImage *verticalResizeImage;


@implementation RRSSRulerView

+ (void)initialize
{
    static BOOL beenHere = NO;
    NSBundle *mainBundle;
    NSString *imagePath;

    if (beenHere) return;

    beenHere = YES;

    mainBundle = [NSBundle bundleForClass:[RRSSRulerView class]];
    imagePath = [mainBundle pathForResource:@"horizontalResizeImage" ofType:@"tiff"];
    horizontalResizeImage = [[NSImage alloc] initByReferencingFile:imagePath];
    [horizontalResizeImage setFlipped:YES];
    imagePath = [mainBundle pathForResource:@"verticalResizeImage" ofType:@"tiff"];
    verticalResizeImage = [[NSImage alloc] initByReferencingFile:imagePath];
    [verticalResizeImage setFlipped:YES];

    return;
}


- (id)initWithScrollView:(NSScrollView *)aScrollView orientation:(NSRulerOrientation)orientation
{
    if(self = [super initWithScrollView:aScrollView orientation:orientation])
    {        
        selectedHeaders = [[NSMutableArray alloc] init];
        // load up our cursors
        horizontalResizeCursor = [[NSCursor alloc] initWithImage:horizontalResizeImage hotSpot:NSMakePoint(8,8)];
        verticalResizeCursor = [[NSCursor alloc] initWithImage:verticalResizeImage hotSpot:NSMakePoint(8,8)];        
        isEditable = NO;
    }
    return self;
}

- (void)drawMarkersInRect:(NSRect)aRect
{

    RRFloatRange dirtyFloatRange;
    NSRange dirtyRange;
    NSEnumerator *e;
    RRSSHeader *header;
    NSArray *visibleHeaders;
    NSArray *dirtyHeaders;
    NSView* view;
    NSRect previousVisibleRect = cachedVisibleRect;
    NSPoint subviewOrigin;
    NSRect subviewRect;

    cachedVisibleRect = [documentView visibleRect];
    
    if([self orientation] == NSVerticalRuler)
    {
        visibleHeaders = [documentView visibleRows];
        dirtyFloatRange = RRMakeFloatRange(aRect.origin.y + cachedVisibleRect.origin.y, aRect.size.height);
        cachedVisibleRect.origin.x = 0;
    } else {
        visibleHeaders = [documentView visibleColumns];
        dirtyFloatRange = RRMakeFloatRange(aRect.origin.x + cachedVisibleRect.origin.x, aRect.size.width);
        cachedVisibleRect.origin.y = 0;
    }
    dirtyRange = [documentView rangeForArray:visibleHeaders inFloatRange:dirtyFloatRange];
    dirtyHeaders = [visibleHeaders subarrayWithRange:dirtyRange];

    e = [dirtyHeaders objectEnumerator];

    // go through the visible headers and redraw
    while(header = [e nextObject])
    {
        [header drawRect:aRect];
    }

    e = [[self subviews] objectEnumerator];
    while(view = [e nextObject])
    {
        subviewRect = [view frame];
        subviewOrigin = subviewRect.origin;
        subviewOrigin.x -= (cachedVisibleRect.origin.x - previousVisibleRect.origin.x);
        subviewOrigin.y -= (cachedVisibleRect.origin.y - previousVisibleRect.origin.y);
        [view setFrameOrigin:subviewOrigin];
    }
        

}

- (void)setClientView:(NSView*)clientView
{
    if([clientView isKindOfClass:[RRSSWorksheet class]])
    {
        documentView = clientView;
        if([self orientation] == NSVerticalRuler) {
            [self setHeaders:[documentView rows]];
            if([[(RRSSWorksheet*)documentView dataSource]
                    respondsToSelector:@selector(worksheet:setHeaderLabel:forRow:)])
                [self setEditable:YES];
            else
                [self setEditable:NO];
        } else {
            [self setHeaders:[documentView columns]];
            if([[(RRSSWorksheet*)documentView dataSource]
                    respondsToSelector:@selector(worksheet:setHeaderLabel:forColumn:)])
                [self setEditable:YES];
            else
                [self setEditable:NO];
            
        }
        [super setClientView:clientView];
    }
}


- (NSRect)visibleFrameForRect:(NSRect)rect
{
    if([self orientation] == NSVerticalRuler)
        rect.origin.y -= cachedVisibleRect.origin.y;
    else
        rect.origin.x -= cachedVisibleRect.origin.x;
    return rect;
}

// converts from the visible ruler position, to an absolute position
- (NSPoint)rulerPositionForPoint:(NSPoint)point
{
    if([self orientation] == NSVerticalRuler)
        point.y += cachedVisibleRect.origin.y;
    else
        point.x += cachedVisibleRect.origin.x;
    return point;
}

- (void)moveHeader:(RRSSHeader*)header to:(int)index
{

}

- (NSArray*)headers
{
    return headers;
}

- (RRSSHeader*)headerAtIndex:(int)index{
    return [headers objectAtIndex:index];
}


- (void)setHeaders:(NSArray*)array
{
    [headers autorelease];
    headers = [array retain];
}

- (void)setEditable:(BOOL)editable
{
    isEditable = editable;
}

- (BOOL)isEditable
{
    return isEditable;
}


- (RRSSHeader*)headerForEvent:(NSEvent*)theEvent
{
    int headerIndex;
    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p fromView:nil];
    p = [self rulerPositionForPoint:p];

    // search through the cachedVisibleMarkers for the marker that contains this event
    if([self orientation] == NSVerticalRuler)
        trackingLocation = p.y;
    else
        trackingLocation = p.x;

    headerIndex = [documentView indexOfObjectInArray:headers forLocation:trackingLocation];
    return [headers objectAtIndex:headerIndex];
}

// handle all of the mouse events
- (void)mouseDown:(NSEvent *)theEvent
{
    RRSSHeader *head = [self headerForEvent:theEvent];
    RRFloatRange headerFloatRange;
    int headIndex;

    if(trackingHeader && isEditing){
        isEditing = NO;
        [trackingHeader endEditingLabel];
    }
    
    trackingHeader = head;
    
    [head setState:NSMixedState];

    
    if([theEvent clickCount] > 1)
    {
        if(isResizing) {
            headerFloatRange = [trackingHeader range];
            headIndex = [headers indexOfObject:trackingHeader];
            if([self orientation] == NSVerticalRuler) {
                headerFloatRange.length = ceil([documentView
                     rowHeightForContents:headIndex]);
                [documentView resizeRow:headIndex range:headerFloatRange];
                cachedVisibleRect.size.height += headerFloatRange.length;
            } else {
                headerFloatRange.length = ceil([documentView
                     columnWidthForContents:headIndex]);
                [documentView resizeColumn:headIndex range:headerFloatRange];
                cachedVisibleRect.size.width += headerFloatRange.length;
            }
            [self setNeedsDisplayInRect:cachedVisibleRect];
            
        } else if(isEditable) {
            [self selectHeaders: [NSArray array]];
            // if it is in the main area, then edit the label
            [head setState:NSOnState];
            [head beginEditingLabel:theEvent];

            isEditing = YES;
        }
    } else {
        if([NSCursor currentCursor] == horizontalResizeCursor
           || [NSCursor currentCursor] == verticalResizeCursor)
            isResizing = YES;
        else
            isResizing = NO;
    }        


}

- (void)keyDown:(NSEvent *)theEvent
{
    [super keyDown:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    RRSSHeader *head = [self headerForEvent:theEvent];
    RRSSHeader *otherHeader = nil;
    unsigned int modifier = [theEvent modifierFlags];
    int startIndex, endIndex, tmpIndex;

    if(isResizing)
    {
        // we have just finished a resizing operation
    //    isResizing = NO;
       // [[NSCursor currentCursor] pop];
        
        // reset all of the cursor rects for the new ranges
        [[self window] invalidateCursorRectsForView:self];

        // reset the header state to its previous value
        if([trackingHeader selected])
            [trackingHeader setState:NSOnState];
        else
            [trackingHeader setState:NSOffState];
            
    }
    else if(isEditing)
    {
        // we have just finished selecting a header for editing
        return;
    }
    else if(isDragging)
    {
        isDragging = NO;
        [self removeHeadersFromSelectedHeaders: [NSArray arrayWithObject: trackingHeader]];
    }
    else
    {
        if ((modifier & NSShiftKeyMask) && ([selectedHeaders count]))
        {
            [documentView setRulerForSelectionFocus:self];
            // shift key - add all headers between this one and the last one
            otherHeader = [selectedHeaders objectAtIndex:0];
            id headerToInsert;
            startIndex = [otherHeader index];
            endIndex = [head index];

            if(startIndex > endIndex)
            {
                tmpIndex = startIndex; startIndex = endIndex; endIndex = tmpIndex;
                headerToInsert = [headers subarrayWithRange:NSMakeRange(startIndex, endIndex - startIndex +1)];

                //flip the order of the array so that the first item of the array is the origin of
                //the selection
                //
                NSMutableArray *flippedOtherHeader =  [NSMutableArray array];
                NSEnumerator *enumerator = [headerToInsert reverseObjectEnumerator];
                id object;

                while (object = [enumerator nextObject])
                {
                    [flippedOtherHeader addObject: object];
                }
                
                headerToInsert = flippedOtherHeader;
            }
            else
            {
                headerToInsert = [headers subarrayWithRange:NSMakeRange(startIndex, endIndex - startIndex +1)];
            }
            [self selectHeaders: headerToInsert];
        }
        else if (modifier & NSCommandKeyMask)
        { //the command key in the Finder is used for multiple non continuous selection
            [documentView setRulerForSelectionFocus:self];
            // add (or remove this one from the list)
            if(![head selected])
            {
                [self addHeadersToSelectedHeaders: [NSArray arrayWithObject: head]];
            }
            else
            {
                [self removeHeadersFromSelectedHeaders: [NSArray arrayWithObject: head]];
            }
        }
        else
        {
            [documentView setRulerForSelectionFocus:self];
            // otherwise, deselect all cells and select the one clicked on
            [self selectHeaders: [NSArray arrayWithObject: head]];
        }
    }
    
    [[self window] makeFirstResponder: documentView];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    RRFloatRange headerFloatRange;
    RRSSHeader *head;
    int trackingHeaderIndex = [headers indexOfObject:trackingHeader];
    float newLength;
    NSPoint p = [theEvent locationInWindow];
    p = [self convertPoint:p fromView:nil];
    p = [self rulerPositionForPoint:p];

    // need to determine if we are going to be dragging the whole row/column around,
    // or just resizing this one
    if(isResizing) {

        headerFloatRange = [trackingHeader range];
        if ([self orientation] == NSVerticalRuler) {
            // we are resizing row
            if(trackingLocation != p.y) {
                
                newLength = headerFloatRange.length + (p.y - trackingLocation);
                trackingLocation = p.y;
                headerFloatRange.length = newLength > 8 ? newLength : headerFloatRange.length;
                [documentView resizeRow:trackingHeaderIndex range:headerFloatRange];
                cachedVisibleRect.size.height += newLength;
                [self setNeedsDisplayInRect:cachedVisibleRect];

            }
        } else if ([self orientation] == NSHorizontalRuler) {
            // we are resizing column
            if(trackingLocation != p.x)
            {
                newLength = headerFloatRange.length + (p.x - trackingLocation);
                trackingLocation = p.x;
                headerFloatRange.length = newLength > 8 ? newLength : headerFloatRange.length;
                [documentView resizeColumn:trackingHeaderIndex range:headerFloatRange];
                cachedVisibleRect.size.width += newLength;
                [self setNeedsDisplayInRect:cachedVisibleRect];

            }
        }
    } else {
        // we are dragging an entire column
        head = [self headerForEvent:theEvent];

        if(trackingHeader != head) {
            isDragging = YES;
        }
    }

}

- (void)loseSelectionFocus
{

    if(trackingHeader && isEditing){
        isEditing = NO;
        [trackingHeader endEditingLabel];
    }

    [self removeHeadersFromSelectedHeaders: [NSArray arrayWithArray: selectedHeaders]];
}

- (void)resetCursorRects
{
    NSEnumerator *e;
    RRSSHeader *header;
    NSRect headerRect;
    if([self orientation] == NSVerticalRuler)
    {
        e = [[documentView visibleRows] objectEnumerator];
        while(header = [e nextObject])
        {
            headerRect = [self visibleFrameForRect:[header frame]];
            headerRect.origin.y += headerRect.size.height - 2;
            headerRect.size.height = 2;
            [self addCursorRect:headerRect cursor:verticalResizeCursor];
        }
    }
    else
    {
        e = [[documentView visibleColumns] objectEnumerator];
        while(header = [e nextObject])
        {
            headerRect = [self visibleFrameForRect:[header frame]];
            headerRect.origin.x += headerRect.size.width - 2;
            headerRect.size.width = 2;
            [self addCursorRect:headerRect cursor:horizontalResizeCursor];
        }
    }        
}

- (void)dealloc
{
    [selectedHeaders release];
    [super dealloc];
}

- (void) selectHeaders: (NSArray*) headerArray
{
    //unselect the old ones
    //
    [selectedHeaders makeObjectsPerformSelector: @selector(setSelected:) withObject: NO];
    [selectedHeaders removeAllObjects];

    //select the new ones
    //
    [selectedHeaders addObjectsFromArray: headerArray];
    [headerArray makeObjectsPerformSelector: @selector(setSelected:) withObject: YES];

    //let the document view know
    //
    if ([self orientation] == NSHorizontalRuler)
        [documentView setSelectedColumns: headerArray];
    else
        [documentView setSelectedRows: headerArray];
}

- (void) addHeadersToSelectedHeaders: (NSArray*) headerArray
{
    //if there was no selected header before then just select those so that the old selection is cleared
    //
    if ([selectedHeaders count] == 0)
        [self selectHeaders: headerArray];
    else
    {
        //select the extra ones
        //
        [selectedHeaders addObjectsFromArray: headerArray];
        [headerArray makeObjectsPerformSelector: @selector(setSelected:) withObject: YES];

        //let the document view know
        //
        if ([self orientation] == NSHorizontalRuler)
            [documentView addColumnsToSelectedColumn: selectedHeaders];
        else
            [documentView addRowsToSelectedRow: selectedHeaders];
    }
}

- (void) removeHeadersFromSelectedHeaders: (NSArray*) headerArray updatingDocumentView: (BOOL) updating
{
    [selectedHeaders removeObjectsInArray: headerArray];
    [headerArray makeObjectsPerformSelector: @selector(setSelected:) withObject: NO];

    //let the document view know
    //
    if (updating)
    {
        if ([self orientation] == NSHorizontalRuler)
            [documentView removeColumnsFromSelectedColumns: headerArray];
        else
            [documentView removeRowsFromSelectedRows: headerArray];
    }
}

- (void) removeHeadersFromSelectedHeaders: (NSArray*) headerArray
{
    [self removeHeadersFromSelectedHeaders: headerArray updatingDocumentView: YES];
}

- (NSArray*) selectedHeaders
{
    return selectedHeaders;
}
@end

