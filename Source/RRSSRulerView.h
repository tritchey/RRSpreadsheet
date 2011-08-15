//
//  RRSSRulerView.h
//  µ
//
//  Created by Timothy Ritchey on Fri Feb 08 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RRFloatRange.h"

@class RRSSHeader, RRSSWorksheet;

@interface RRSSRulerView : NSRulerView
{
    NSCursor *horizontalResizeCursor;
    NSCursor *verticalResizeCursor;
    id documentView;
    NSArray *headers;
    NSRect cachedVisibleRect;
    NSMutableArray *selectedHeaders;
    RRSSHeader *trackingHeader;
    float trackingLocation;
    BOOL isEditable;
    BOOL isResizing;
    BOOL isDragging;
    BOOL isEditing;
}
- (void)moveHeader:(RRSSHeader*)header to:(int)index;
- (NSArray*)headers;
- (RRSSHeader*)headerAtIndex:(int)index;
- (void)setHeaders:(NSArray*)array;
- (void)setEditable:(BOOL)editable;
- (BOOL)isEditable;

    // position helper functions
- (RRSSHeader*)headerForEvent:(NSEvent*)theEvent;
- (NSRect)visibleFrameForRect:(NSRect)rect;
- (NSPoint)rulerPositionForPoint:(NSPoint)point;
- (void)loseSelectionFocus;
- (void) selectHeaders: (NSArray*) headerArray;
- (NSArray*) selectedHeaders;
- (void) addHeadersToSelectedHeaders: (NSArray*) headerArray;
- (void) removeHeadersFromSelectedHeaders: (NSArray*) headerArray updatingDocumentView: (BOOL) updating;
- (void) removeHeadersFromSelectedHeaders: (NSArray*) headerArray;
@end
