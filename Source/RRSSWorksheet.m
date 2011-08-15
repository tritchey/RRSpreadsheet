//
//  RRSSWorksheet.m
//  µ
//
//  Created by Timothy Ritchey on Fri Feb 08 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//
//
//  NOTES:
//  06102002 - updates by Olivier to fix infinite loop in palette
//             (index ranges use NSNotFound instead of -1)
//

#import "RRSSWorksheet.h"
#import "RRSSWorksheetPrivate.h"
#import "RRSSRulerView.h"
#import "RRSpreadSheet.h"
#import "RRFloatRange.h"
#import "RRPosition.h"
#import "RRSSHeader.h"
#import "RRSSCell.h"
#import "RRFloatRange.h"
#import "RRDefaultDataSource.h"

static Class worksheetCellClass;

@implementation RRSSWorksheet

+ (void)initialize
{
    worksheetCellClass = [RRSSCell class];
}

+ (void)setCellClass:(Class)cellClass
{
    worksheetCellClass = cellClass;
}

+ (Class)cellClass
{
    return worksheetCellClass;
}

- (id) prototypeCell
{
    return prototypeCell;
}

- (void) setPrototypeCell: (NSCell*) inPrototypeCell
{
    [prototypeCell autorelease];
    prototypeCell = [inPrototypeCell retain];
}

- (id)initWithFrame:(NSRect)rect cellSize:(NSSize)size
{
    if(self = [super initWithFrame:rect])
    {
        [self setAutoresizesSubviews:NO];
        cellSize = size;
        prototypeCell = [[worksheetCellClass alloc] initTextCell:@""];
        [self setDataSource: [[[RRDefaultDataSource alloc] init] autorelease]];
        [self setDelegate: [self dataSource]];
        selectedCellsPositions = [[NSMutableArray alloc] init];
        rows = [[NSMutableArray alloc] init];
        columns = [[NSMutableArray alloc] init];
        visibleCellPositions = [[NSMutableArray alloc] init];
        visibleRows = [[NSArray alloc] init];
        visibleColumns = [[NSArray alloc] init];
        neededRows = rect.size.height/cellSize.height;
        neededColumns = rect.size.width/cellSize.width;
        allowAutoResize = YES;
        // set up the text editor
        textEditor = [[NSTextView alloc] init];
    }
    return self;
}

- (id)initWithFrame:(NSRect)rect
{
    return [self initWithFrame:rect
                      cellSize:NSMakeSize(64,20)];
}

- (BOOL)allowAutoResize
{
    return allowAutoResize;
}

- (void)setAllowAutoResize:(BOOL)allow
{
    allowAutoResize = allow;
}

- (void)drawRect:(NSRect)rect
{
    NSBezierPath *path = [[NSBezierPath alloc] init];
    int visibleRowIndex, rowCount, visibleColumnIndex, columnCount;
    float start, end;
    RRFloatRange rowFloatRange;
    RRFloatRange columnFloatRange;
    RRSSHeader *header;
    RRPosition *pos = [RRPosition positionForRow:0 column:0];
   // RRSSCell *cell;
    BOOL columnDrawn = NO;

    //    NSLog(@"%.1f,%.1f,%.1f,%.1f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

    if([self inLiveResize]) {
        [self updateVisibleRangesForRect:rect];
        // we need to optimize the drawing here - live resize is awful
        // how to handle this?
    }

    [self updateDirtyRangesForRect:rect];

    rowCount = NSMaxRange(dirtyRowRange);
    columnCount = NSMaxRange(dirtyColumnRange);
    for(visibleRowIndex = dirtyRowRange.location; visibleRowIndex < rowCount; visibleRowIndex++)
    {
        header = [visibleRows objectAtIndex:visibleRowIndex];
        [pos setRow:[header index]];
        rowFloatRange = [header range];
        end = RRMaxFloatRange(rowFloatRange) - 0.5;
        [path moveToPoint:NSMakePoint(rect.origin.x, end)];
        [path lineToPoint:NSMakePoint(rect.origin.x + rect.size.width, end)];

        for(visibleColumnIndex = dirtyColumnRange.location; visibleColumnIndex < columnCount; visibleColumnIndex++)
        {
            header = [visibleColumns objectAtIndex:visibleColumnIndex];
            [pos setColumn:[header index]];
            columnFloatRange = [header range];

            if(!columnDrawn) // we only need to do this for the first row
            {
                start = RRMaxFloatRange(columnFloatRange) - 0.5;
                [path moveToPoint:NSMakePoint(start, rect.origin.y)];
                [path lineToPoint:NSMakePoint(start, rect.origin.y + rect.size.height)];

            }
            //            if(cell = [cells objectForKey:pos]) // see if there is a cell at our position
            {
                //take the prototype cell and set its value to whatever the datasource says
                //
                [self setAttributesOfProtoCellForPosition: pos];

                //let the data source that we are going to draw the cell
                //
                [self worksheet:self willDrawCell: prototypeCell forRow:[pos row] column:[pos column]];

                // move in the right edge to make sure it doesn't hang over the edge of the column
                [prototypeCell drawWithFrame: NSMakeRect(columnFloatRange.location, rowFloatRange.location,
                                                         columnFloatRange.length, rowFloatRange.length)
                                      inView: self];
            }
        }

        columnDrawn = YES;
    }
    [path closePath];
    [[NSColor gridColor] set];
    [path setLineWidth:0.0];
    [path stroke];
    [path release];
    [pos release];

    // finally, add rows/columns if we need to
    if ((NSMaxRange(visibleRowRange) >= [rows count]) && allowAutoResize)
    {
        // we are seeing the last row! add one!
        if ([self worksheetShouldAddRow: self])
            [self worksheetAddRow: self];
    }

    if ((NSMaxRange(visibleColumnRange) >= [columns count]) && allowAutoResize)
    {
        // we are seeing the last row! add one!
        if ([self worksheetShouldAddColumn: self])
            [self worksheetAddColumn: self];
    }
}

- (NSRect)adjustScroll:(NSRect)proposedVisibleRect
{
    [self updateVisibleRangesForRect:proposedVisibleRect];
    
    return proposedVisibleRect;
}

- (void)setFrameSize:(NSSize)size
{
    //filter the size so that our maximum size is what is needed to display our cells
    //
    NSEnumerator *enumerator = [columns objectEnumerator];
    id object;
    NSSize theDisplaySize;

    while (object = [enumerator nextObject]) {
        theDisplaySize.width += [object frame].size.width;
    }

    enumerator = [rows objectEnumerator];
    while (object = [enumerator nextObject]) {
        theDisplaySize.height += [object frame].size.height;
    }

    if (size.width > theDisplaySize.width)
        size.width = theDisplaySize.width;
    if (size.height > theDisplaySize.height + 1)
        size.height = theDisplaySize.height + 1;
        
    NSRect oldFrame = [self frame];
    [super setFrameSize:size];
    if(!NSEqualSizes(size, oldFrame.size)) {
        [self updateVisibleRangesForRect:[self visibleRect]];
    }
}

- (void)setFrameOrigin:(NSPoint)point
{
    NSRect oldFrame = [self frame];
    [super setFrameOrigin:point];
    if(!NSEqualPoints(point, oldFrame.origin))
        [self updateVisibleRangesForRect:[self visibleRect]];
}


/*
 * here is where we will handle overriding the NSControl methods
 */
- (BOOL)abortEditing
{
    [prototypeCell endEditing:textEditor];
    currentlyEditingCellPosition = nil;

    return YES;
}

- (NSText *)currentEditor
{
    return textEditor;
}

- (void)beginEditingCellAtPosition:(RRPosition*)aCellPosition
{
    RRFloatRange rowFloatRange = [[rows objectAtIndex:[aCellPosition row]] range];
    RRFloatRange columnFloatRange = [[columns objectAtIndex:[aCellPosition column]] range];
    NSRect editRect = NSMakeRect(columnFloatRange.location, rowFloatRange.location,
                                 columnFloatRange.length - 1, rowFloatRange.length - 1);


    [self scrollRectToVisible:editRect];

    // make sure and deselect any currently selected cells
    [self deselectAllCells];

    currentlyEditingCellPosition = aCellPosition;
    trackingCellPosition = aCellPosition;

    //set all the values for that cell
    //
    [self setAttributesOfProtoCellForPosition: aCellPosition];

    //then edit it
    //
    [prototypeCell editWithFrame:editRect inView:self editor:textEditor delegate:self event:nil];
}

- (NSArray*)selectedCellsPositions
{
    return selectedCellsPositions;
}

- (void) addCellPositionToSelectedCellsPositions:(RRPosition*) aCellPosition
{
    //first be sure that no rows or columns are selected
    //
    if ([[(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders] count] != 0)
    {
        NSArray *theSelectedHeaders = [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders]];
        [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] removeHeadersFromSelectedHeaders: theSelectedHeaders];
    }
    if ([[(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders] count] != 0)
    {
        NSArray *theSelectedHeaders = [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders]];
        [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] removeHeadersFromSelectedHeaders: theSelectedHeaders];
    }

    [self addToSelectedCellsPositions: [NSArray arrayWithObject: aCellPosition]];
    
    //refresh it as adding the cell won't
    //
    [self reloadCellDataAtRow:[aCellPosition row] column:[aCellPosition column]];
}

- (void) selectCellAtPosition:(RRPosition*)aCellPosition byExtendingSelection:(BOOL)inExtending scrolling: (BOOL) scroll
{
    NSMutableArray *cellPositionToSelect = [NSMutableArray array];

    //first be sure that no rows or columns are selected
    //
    if ([[(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders] count] != 0)
    {
        NSArray *theSelectedHeaders = [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders]];
        [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] removeHeadersFromSelectedHeaders: theSelectedHeaders];
    }
    if ([[(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders] count] != 0)
    {
        NSArray *theSelectedHeaders = [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders]];
        [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] removeHeadersFromSelectedHeaders: theSelectedHeaders];
    }
    
    if (inExtending == NO)
    {
        //just ask to select the given cell
        //
        [cellPositionToSelect addObject:aCellPosition];
    }
    else
    {
        //try to extend the selection
        //get the position of the cell
        //
        if (selectedCellPosition != nil)
        {
            int fromColumn = [trackingCellPosition column];
            int toColumn = [aCellPosition column];
            int fromRow = [trackingCellPosition row];
            int toRow = [aCellPosition row];
            int tmp, i, j;

            if(toColumn < fromColumn)
            {
                tmp = toColumn; toColumn = fromColumn; fromColumn = tmp;
            }

            if(toRow < fromRow)
            {
                tmp = toRow; toRow = fromRow; fromRow = tmp;
            }

            for(i = fromColumn; i <= toColumn; ++i)
                for(j = fromRow; j <= toRow; ++j)
                    [cellPositionToSelect addObject:[RRPosition positionForRow:j column:i]];
        }
        else
        {
            [cellPositionToSelect addObject:aCellPosition];
        }
    }

    [self setSelectedCellsPositions: cellPositionToSelect];

    if (inExtending == NO)
    {
        trackingCellPosition = [aCellPosition retain];
    }

    draggingCellPosition = [aCellPosition copy];
    selectedCellPosition = aCellPosition;
    
    if (scroll)
        [self scrollToCellAtRow:[aCellPosition row] column:[aCellPosition column]];
}


- (void)selectCellAtPosition:(RRPosition*)aCellPosition
{
    [self selectCellAtPosition:aCellPosition byExtendingSelection: NO scrolling: YES];
}

- (void)selectCellAtRow:(int)row column:(int)column byExtendingSelection:(BOOL)inExtending scrolling: (BOOL) scroll
{
    [self selectCellAtPosition:[RRPosition positionForRow: row column: column] byExtendingSelection:inExtending scrolling:scroll];
}

- (void)selectCellAtRow:(int)row column:(int)column
{
    [self selectCellAtPosition:[RRPosition positionForRow: row column: column]];
}

- (void)selectCellsAtPositions:(NSArray*)selCellsPosition
{
    //deselect any row or column
    //
    if ([[(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders] count] != 0)
    {
        NSArray *theSelectedHeaders = [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders]];
        [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] removeHeadersFromSelectedHeaders: theSelectedHeaders];
    }
    if ([[(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders] count] != 0)
    {
        NSArray *theSelectedHeaders = [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders]];
        [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] removeHeadersFromSelectedHeaders: theSelectedHeaders];
    }
    
    [self setSelectedCellsPositions: selCellsPosition];
}

- (void) selectAllCells
{
    int column, row;
    NSMutableArray *cellPositionsToSelect = [NSMutableArray array];
    for (column = 0; column < [columns count]; column++) {
    	for (row = 0; row < [rows count]; row++) {
            [cellPositionsToSelect addObject: [RRPosition positionForRow: row column: column]];
    	}
    }

    [self selectCellsAtPositions: cellPositionsToSelect];

    [self reloadWorksheetData];
}

- (void)selectRow:(int)row
{
    [self selectRow:row byExtendingSelection:NO scrolling:YES];
}

- (void)selectRow:(int)row byExtendingSelection:(BOOL) extending scrolling:(BOOL) scroll
{
}

- (void)selectColumn:(int)column byExtendingSelection:(BOOL) extending scrolling:(BOOL) scroll
{
}

- (void)selectColumn:(int)column
{
    [self selectColumn:column byExtendingSelection:NO scrolling:YES];
}

- (RRPosition*)selectedCellPosition
{
    return selectedCellPosition;
}

- (void)deselectCellAtPosition:(RRPosition*)aCellPosition
{
    //first set the state of the header to unselected we don't want to deselect them via the regular way as this would
    //also deselect the cells
    //
    if ([[(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders] count] != 0)
    {
        NSArray *theSelectedHeaders = [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders]];
        [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] removeHeadersFromSelectedHeaders: theSelectedHeaders updatingDocumentView: NO];
    }
    if ([[(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders] count] != 0)
    {
        NSArray *theSelectedHeaders = [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders]];
        [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] removeHeadersFromSelectedHeaders: theSelectedHeaders updatingDocumentView: NO];
    }
    
    [self removeFromSelectedCellsPositions: [NSArray arrayWithObject: aCellPosition]];
    if ([aCellPosition isEqualTo: selectedCellPosition])
        selectedCellPosition = nil;

    //refresh it
    //
    [self reloadCellDataAtRow:[aCellPosition row] column:[aCellPosition column]];
}

- (void)deselectCellAtRow:(int)row column:(int)column
{
    [self deselectCellAtPosition: [RRPosition positionForRow: row column: column]];
}

- (void)deselectAllCells
{
    [self setSelectedCellsPositions: [NSArray array]];
}

- (void)deselectSelectedCell
{
    [self deselectCellAtPosition: selectedCellPosition];
    //setting selectedCellPosition to nil is done in deselectCellAtPosition automatically
}

- (void)deselectRow:(int)row
{
    //pass it up to whoever handle row selection
}

- (void)deselectColumn:(int)column
{
    //pass it up to whoever handle Column selection
}

- (void)validateEditing
{
}

- (id)spreadsheet
{
    return [self enclosingScrollView];
}

- (NSSize)cellSize
{
    return cellSize;
}

- (void)setCellSize:(NSSize)size
{
    cellSize = size;
}

- (NSArray*)rows
{
    return rows;
}

- (void) resizeRow:(unsigned int)row range:(RRFloatRange)range
{
    NSArray *subarray = [rows subarrayWithRange:NSMakeRange(row + 1, [rows count] - row - 1)];
    NSEnumerator *e = [subarray objectEnumerator];
    RRSSHeader *rowHeader = [rows objectAtIndex:row];
    RRFloatRange oldRange = [rowHeader range];
    float diff =  range.length - oldRange.length;
    NSSize newSize;
    NSPoint newOrigin;

    [rowHeader setRange:range];
    if(currentlyEditingCellPosition && (row == [trackingCellPosition row]))
    {
        newSize = [[textEditor superview] frame].size;
        newSize.height += diff;
        [[textEditor superview] setFrameSize:newSize];
    }


    while(rowHeader = [e nextObject])
    {
        oldRange = [rowHeader range];
        oldRange.location += diff;
        [rowHeader setRange:oldRange];
        if(currentlyEditingCellPosition && ([rowHeader index] == [trackingCellPosition row]))
        {
            newOrigin = [[textEditor superview] frame].origin;
            newOrigin.y += diff;
            [[textEditor superview] setFrameOrigin:newOrigin];
        }
    }
    newSize = [self frame].size;
    newSize.height += diff;
    [self setFrameSize:newSize];
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (float) rowHeightForContents:(unsigned int)row
{
    int i, j = [columns count];
    RRPosition *pos = [RRPosition positionForRow:row column:0];
    float biggest = cellSize.height;
    NSSize size;

    for(i = 0; i < j; ++i) {
        [pos setColumn:i];
        [self setAttributesOfProtoCellForPosition: pos];
        size = [prototypeCell cellSize];
        biggest = size.height > biggest ? size.height : biggest;
    }

    return biggest;
}


-(NSArray*)columns
{
    return columns;
}

- (void) resizeColumn:(unsigned int)index range:(RRFloatRange)range
{
    NSArray *subarray = [columns subarrayWithRange:NSMakeRange(index + 1, [columns count] - index - 1)];
    NSEnumerator *e = [subarray objectEnumerator];
    RRSSHeader *column = [columns objectAtIndex:index];
    RRFloatRange oldRange = [column range];
    float diff =  range.length - oldRange.length;
    NSSize newSize;
    NSPoint newOrigin;

    [column setRange:range];
    if(currentlyEditingCellPosition && (index == [trackingCellPosition column]))
    {
        newSize = [[textEditor superview] frame].size;
        newSize.width += diff;
        [[textEditor superview] setFrameSize:newSize];
    }

    while(column = [e nextObject])
    {
        oldRange = [column range];
        oldRange.location += diff;
        [column setRange:oldRange];
        if(currentlyEditingCellPosition && ([column index] == [trackingCellPosition column]))
        {
            newOrigin = [[textEditor superview] frame].origin;
            newOrigin.x += diff;
            [[textEditor superview] setFrameOrigin:newOrigin];
        }
    }
    newSize = [self frame].size;
    newSize.width += diff;
    [self setFrameSize:newSize];
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (float) columnWidthForContents:(unsigned int)column
{
    int i = 0, j = [rows count];
    RRPosition *pos = [RRPosition positionForRow:i column:column];
    float biggest = 24;
    NSSize size;

    for(i = 0; i < j; ++i) {
        [pos setRow:i];
        [self setAttributesOfProtoCellForPosition: pos];
        size = [prototypeCell cellSize];
        biggest = size.width > biggest ? size.width : biggest;
    }
    if(biggest == 0.0) biggest = cellSize.width;

    return biggest;
}


- (void)setRulerForSelectionFocus:(RRSSRulerView*)ruler
{
    if(ruler == (RRSSRulerView*)[[self spreadsheet] verticalRulerView])
        [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] loseSelectionFocus];
    if(ruler == (RRSSRulerView*)[[self spreadsheet] horizontalRulerView])
        [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] loseSelectionFocus];
}


- (RRPosition*)cellPositionForEvent:(NSEvent*)theEvent
{
    RRSSRulerView* ruler;
    int columnIndex, rowIndex;
    RRPosition *pos;
    //RRSSCell *cell;
    id head;
    RRFloatRange rowRange;
    RRFloatRange columnRange;

    ruler = (RRSSRulerView*)[[self spreadsheet] verticalRulerView];
    head = [ruler headerForEvent:theEvent];
    rowRange = [head range];
    rowIndex = [head index];
    ruler = (RRSSRulerView*)[[self spreadsheet] horizontalRulerView];
    head = [ruler headerForEvent:theEvent];
    columnRange = [head range];
    columnIndex = [head index];

    pos = [RRPosition positionForRow:rowIndex column:columnIndex];
    return pos;
}


/*
 * Text delegate methods
 */
- (BOOL)textShouldBeginEditing:(NSText *)textObject {
    return YES;
}
- (BOOL)textShouldEndEditing:(NSText *)textObject
{
    BOOL returnValue = YES;
    id objectValue = nil;
    NSString *error = nil;
    
    if ([prototypeCell formatter] != nil)
        returnValue = [[prototypeCell formatter] getObjectValue: &objectValue forString: [textObject string] errorDescription:&error];
    
    return returnValue;
}


- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector
{
    BOOL returnValue = NO;

    if (([NSStringFromSelector(aSelector) isEqualToString: @"insertTab:"]) ||
        ([NSStringFromSelector(aSelector) isEqualToString: @"insertBacktab:"]) ||
        ([NSStringFromSelector(aSelector) isEqualToString: @"insertNewline:"]))
    {
        returnValue = YES;
        [self performSelector: aSelector withObject: aTextView];
    }
    
    return returnValue;
}

- (NSRange)textView: (NSTextView *)aTextView willChangeSelectionFromCharacterRange: (NSRange)oldSelectedCharRange
   toCharacterRange: (NSRange)newSelectedCharRange
{
    allowLeftArrowMove = NO;
    allowRightArrowMove = NO;

    if(oldSelectedCharRange.location == newSelectedCharRange.location)
        allowLeftArrowMove = YES;
    if(NSMaxRange(oldSelectedCharRange) == newSelectedCharRange.location)
        allowRightArrowMove = YES;

    return newSelectedCharRange;
}

- (void)textDidBeginEditing:(NSNotification *)notification {}
- (void)textDidEndEditing:(NSNotification *)notification
{
    id objectValue;
    NSString *error;

    //if we have a formatter use it to get the objec value
    //
    if ([prototypeCell formatter] != nil)
        [[prototypeCell formatter] getObjectValue: &objectValue forString: [[notification object] string] errorDescription:&error];
    else
        objectValue = [[[notification object] string] copy];
    
    [self worksheet: self
     setObjectValue: objectValue
             forRow: [trackingCellPosition row]
             column: [trackingCellPosition column]];

    currentlyEditingCellPosition = nil;
}

- (void)textDidChange:(NSNotification *)notification
{
}

//
// drawing optimization methods
//
- (void)updateDirtyRangesForRect:(NSRect)rect
{

    dirtyRowRange = [self rangeForArray:[rows subarrayWithRange:visibleRowRange]
                           inFloatRange:RRMakeFloatRange(rect.origin.y, rect.size.height)];

    dirtyColumnRange = [self rangeForArray:[columns subarrayWithRange:visibleColumnRange]
                              inFloatRange:RRMakeFloatRange(rect.origin.x, rect.size.width)];
}

- (void)updateVisibleRangesForRect:(NSRect)rect
{
    //    NSLog(@"rect: %f,%f,%f,%f", rect.origin.y, rect.size.height, rect.origin.x, rect.size.width);

    visibleRowRange = [self rangeForArray:rows
                             inFloatRange:RRMakeFloatRange(rect.origin.y, rect.size.height)];
    if(visibleRowRange.location != NSNotFound)
    {
        [visibleRows autorelease];
        visibleRows = [[rows subarrayWithRange:visibleRowRange] retain];
    }

    visibleColumnRange = [self rangeForArray:columns
                                inFloatRange:RRMakeFloatRange(rect.origin.x, rect.size.width)];
    if(visibleColumnRange.location != NSNotFound)
    {
        [visibleColumns autorelease];
        visibleColumns = [[columns subarrayWithRange:visibleColumnRange] retain];
    }


    int newRows, newColumns;
    
    // check to see if all of our visible rows actually exist!
    //
    newRows = rect.size.height/cellSize.height - [rows count];
    newColumns = rect.size.width/cellSize.width - [columns count];
    //don't loop as asking to add a row or column will for another updateVisibleRangesForRect which
    //will take care of the extra ones
    //
    if ((newRows > 0) && (allowAutoResize))
    {
        // we are seeing the last row! add one!
        if ([self worksheetShouldAddRow: self])
            [self worksheetAddRow: self];
    }
    if ((newColumns > 0) && (allowAutoResize))
    {
        // we are seeing the last row! add one!
        if ([self worksheetShouldAddColumn: self])
            [self worksheetAddColumn: self];
    }
}

- (NSRange)rangeForArray:(NSArray*)array inFloatRange:(RRFloatRange)range
{
    NSRange indexRange;
    if(array) {
        indexRange.location = [self indexOfObjectInArray:array forLocation:range.location];
        indexRange.length = [self indexOfObjectInArray:array forLocation:RRMaxFloatRange(range)] - indexRange.location + 1;
    } else {
        indexRange.location = 0;
        indexRange.length = 0;
    }
    return indexRange;
}


- (int)indexOfObjectInArray:(NSArray*)array forLocation:(float)location
{
    RRSSHeader *object;
    RRFloatRange currentRange;
    int top = [array count] - 1;
    int bottom = 0;
    int middle = (top+bottom)/2;

    // use a binary search to find the row/column that encloses this location in the ruler
    while(top != -1) {
        object = [array objectAtIndex:middle];
        currentRange = [object range];
        if(RRLocationInFloatRange(location, currentRange))
            return middle;
        else if(top != bottom) {
            if(currentRange.location > location) // search lower half
                top = top != middle ? middle : bottom;
            else                                // search upper half
                bottom = bottom != middle ? middle : top;
            middle = (top + bottom)/2;
        } else {
            return middle; // note: this places a floor and ceiling on the search
        }
    }
    return NSNotFound;
}

- (NSRange)dirtyRowRange
{
    return dirtyRowRange;
}

- (NSRange)dirtyColumnRange
{
    return dirtyColumnRange;
}

- (NSRange)visibleRowRange
{
    return visibleRowRange;
}

- (NSArray*)visibleRows
{
    return visibleRows;
}

- (NSRange)visibleColumnRange
{
    return visibleColumnRange;
}

- (NSArray*)visibleColumns
{
    return visibleColumns;
}

- (NSArray*)visibleCellPositions
{
    return visibleCellPositions;
}

- (NSRect)visibleFrameForRect:(NSRect)rect
{
    NSRect vr = [self visibleRect];
    rect.origin.x -= vr.origin.x;
    rect.origin.y -= vr.origin.y;
    return rect;
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)updateMarkers
{
    [self addColumns:neededColumns];
    [self addRows:neededRows];
    neededColumns = 0;
    neededRows = 0;
}

- (void)dealloc
{
    //[cells release];
    [rows release];
    [columns release];
    [visibleCellPositions release];
    [visibleRows release];
    [visibleColumns release];
    [dataSource release];
    [super dealloc];
}



/***********
* dataSource methods
*/
- (void)setDataSource:(id)ds
{
    [dataSource autorelease];
    dataSource = [ds retain];

    if([dataSource respondsToSelector:@selector(worksheet:setHeaderLabel:forRow:)])
        [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] setEditable:YES];
    else
        [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] setEditable:NO];

    if([dataSource respondsToSelector:@selector(worksheet:setHeaderLabel:forColumn:)])
        [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] setEditable:YES];
    else
        [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] setEditable:NO];
    
    [self reloadWorksheetData];
}

- (id)dataSource
{
    return dataSource;
}

- (void)reloadWorksheetData
{
    //first fill the display
    //
    [self updateVisibleRangesForRect:[self visibleRect]];

    //then make sure we have at least as many row and column as the data source
    //
    if ([self numberOfColumnsInWorksheet:self] > [columns count])
    {
        [self addColumns: [self numberOfColumnsInWorksheet:self] - [columns count]];
    }
    else
    {
        while ([columns count] > [self numberOfColumnsInWorksheet:self])
        {
            [self removeColumn: [columns count] - 1];
        }
    }
    if ([self numberOfRowsInWorksheet:self] > [rows count])
    {
        [self addRows: [self numberOfRowsInWorksheet:self] - [rows count]];
    }
    else
    {
        while ([rows count] > [self numberOfRowsInWorksheet:self])
        {
            [self removeRow: [rows count] - 1];
        }
    }

    [self setFrameSize: [self frame].size];		//when removing rows or columns this will update the scrollers
    
    [self updateVisibleRangesForRect:[self visibleRect]];
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (void)reloadCellDataAtRow:(int)row column:(int)column
{
    RRPosition *position = [RRPosition positionForRow:row column:column];

    RRSSHeader *header;
    RRFloatRange rowRange;
    RRFloatRange columnRange;

    header = [rows objectAtIndex: [position row]];
    rowRange = [header range];
    header = [columns objectAtIndex: [position column]];
    columnRange = [header range];

    [self setNeedsDisplayInRect: NSMakeRect( columnRange.location,
                                             rowRange.location,
                                             [[[columns objectAtIndex: column] headerCell] cellSize].width,
                                             [[[rows objectAtIndex: row] headerCell] cellSize].height)];
}

- (void)clearWorksheet
{
    int columnIndex, rowIndex;

    for (columnIndex = 0; columnIndex < [columns count]; columnIndex ++)
        for (rowIndex = 0; rowIndex < [rows count]; rowIndex++)
            [self worksheet:self setObjectValue:@"" forRow: rowIndex column: columnIndex];

    //force reload of the data
    [self setNeedsDisplayInRect:[self visibleRect]];
}

- (void)clearCellsAtPositions: (NSArray*) cellPosition
{
    NSEnumerator *enumerator = [cellPosition objectEnumerator];
    id object;

    while (object = [enumerator nextObject])
        [self worksheet:self setObjectValue:@"" forRow: [object row] column: [object column]];

    //force reload of the data
    [self setNeedsDisplayInRect:[self visibleRect]];
}


#pragma mark "---datasource function---"
// these are the data source implementations for when we are our own data source
- (int)numberOfRowsInWorksheet:(RRSSWorksheet*)worksheet
{
    if([dataSource respondsToSelector:@selector(numberOfRowsInWorksheet:)])
        return [dataSource numberOfRowsInWorksheet:self];
    else
        NSLog(@"invalid data source; it does not implement - (int)numberOfRowsInWorksheet:(RRSSWorksheet*)worksheet");

    return [rows count];
}

- (int)numberOfColumnsInWorksheet:(RRSSWorksheet*)worksheet
{
    if([dataSource respondsToSelector:@selector(numberOfColumnsInWorksheet:)])
        return [dataSource numberOfColumnsInWorksheet:self];
    else
        NSLog(@"invalid data source; it does not implement - (int)numberOfColumnsInWorksheet:(RRSSWorksheet*)worksheet");

    return [columns count];
}

- (NSString*)worksheet:(RRSSWorksheet*)worksheet headerLabelForRow:(int)row
{
    if([dataSource respondsToSelector:@selector(worksheet:headerLabelForRow:)])
        return [dataSource worksheet:self headerLabelForRow:row];


    // just turn the row number into a string
    // note - while everything internally is zero-based, externally, we present it as 1-based
    return [NSString stringWithFormat:@"%d", (row+1)];
}

- (NSString*)worksheet:(RRSSWorksheet*)worksheet headerLabelForColumn:(int)col
{
    int i;
    NSString *labels = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSString *label = @"";

    if([dataSource respondsToSelector:@selector(worksheet:headerLabelForColumn:)])
        return [dataSource worksheet:self headerLabelForColumn:col];

    for(i = 0; i <= (col/26); i++) {
        label = [label stringByAppendingString:[labels substringWithRange:NSMakeRange((col%26),1)]];
    }

    return label;
}


- (void)worksheet:(RRSSWorksheet*)worksheet setHeaderLabel:(NSString*)label forRow:(int)row
{
    if ([dataSource respondsToSelector:@selector(worksheet:setHeaderLabel:forRow:)])
    {
        [dataSource worksheet:self setHeaderLabel:label forRow:row];
    }
}

- (void)worksheet:(RRSSWorksheet*)worksheet setHeaderLabel:(NSString*)label forColumn:(int)column
{
    if ([dataSource respondsToSelector:@selector(worksheet:setHeaderLabel:forColumn:)])
    {
        [dataSource worksheet:self setHeaderLabel:label forColumn:column];
    }
}


- (id)worksheet:(RRSSWorksheet*)worksheet objectValueForRow:(unsigned int)row column:(int)col
{
    id returnValue;

    if ([dataSource respondsToSelector: @selector(worksheet:objectValueForRow:column:)])
        returnValue =  [dataSource worksheet:self objectValueForRow:row column:col];
    else
        NSLog(@"invalid data source; it does not implement - (id)worksheet:(RRSSWorksheet*)worksheet objectValueForRow:(unsigned int)row column:(int)col");

    return returnValue;
}

// optional
- (void)worksheet:(RRSSWorksheet*)worksheet setObjectValue:(id)object forRow:(int)row column:(int)col
{
    if ([dataSource respondsToSelector:@selector(worksheet:setObjectValue:forRow:column:)])
    {
        [dataSource worksheet:self setObjectValue: object forRow:row column:col];
    }

    //now refresh that cell (mimic NSTableView behaviour)
    //
    [self reloadCellDataAtRow:row column:col];
}

- (BOOL)worksheet:(RRSSWorksheet*)worksheet writeCellsAtPositions:(NSArray*)cellsPositions toPasteboard:(NSPasteboard*)pboard
{
    BOOL returnValue = NO;

    if ([dataSource respondsToSelector:@selector(worksheet:writeCellsAtPositions:toPasteboard:)])
    {
        returnValue = [dataSource worksheet:self writeCellsAtPositions: cellsPositions toPasteboard:pboard];
    }

    return returnValue;
}

- (NSDragOperation)worksheet:(RRSSWorksheet*)worksheet validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(int)row column:(int)col proposedDropOperation:(NSTableViewDropOperation)op
{
    return NSDragOperationNone;
}

- (BOOL)worksheet:(RRSSWorksheet*)worksheet acceptDrop:(id <NSDraggingInfo>)info
              row:(int)row column:(int)col dropOperation:(NSTableViewDropOperation)op
{
    return NO;
}


- (void)worksheet:(RRSSWorksheet*)worksheet willDrawCell:(NSCell*) cell forRow:(int) row column:(int) column
{
    if(dataSource)
        if ([dataSource respondsToSelector:@selector(worksheet:willDrawCell:forRow:column:)])
            [dataSource worksheet:worksheet willDrawCell: cell forRow:row column:column];
}


#pragma mark "---delegate function---"
- (id) delegate
{
    return delegate;
}

- (void) setDelegate:(id)newDelegate
{
    [delegate autorelease];
    delegate=[newDelegate retain];
}

- (BOOL)worksheetShouldAddRow:(RRSSWorksheet*)worksheet
{
    BOOL returnValue = allowAutoResize;
    if ([delegate respondsToSelector: @selector (worksheetShouldAddRow:)])
        returnValue = [delegate worksheetShouldAddRow: self];

    return returnValue;
}

- (BOOL)worksheetShouldAddColumn:(RRSSWorksheet*)worksheet
{
    BOOL returnValue = allowAutoResize;
    if ([delegate respondsToSelector: @selector (worksheetShouldAddColumn:)])
        returnValue = [delegate worksheetShouldAddColumn: self];

    return returnValue;
}

- (BOOL)worksheet:(RRSSWorksheet*)worksheet shouldRemoveRow: (int)row
{
    BOOL returnValue = allowAutoResize;
    if ([delegate respondsToSelector: @selector (worksheet:shouldRemoveRow:)])
        returnValue = [delegate worksheet:worksheet shouldRemoveRow: row];

    return returnValue;
}

- (BOOL)worksheet:(RRSSWorksheet*)worksheet shouldRemoveColumn: (int)col
{
    BOOL returnValue = allowAutoResize;
    if ([delegate respondsToSelector: @selector (worksheet:shouldRemoveColumn:)])
        returnValue = [delegate worksheet:worksheet shouldRemoveColumn: col];

    return returnValue;
}

- (void)worksheetAddRow:(RRSSWorksheet*) worksheet
{

    if ([delegate respondsToSelector: @selector (worksheetAddRow:)])
    {
       [delegate worksheetAddRow: self];
    }
    else
        NSLog (@"incomlpete delegate, should implement: - (void)worksheetAddRow:(RRSSWorksheet*) worksheet");

    //refresh the selection of the rulers
    //
    if ([[(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders] count] != 0)
    {
        [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectHeaders: [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders]]];
    }
    if ([[(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders] count] != 0)
    {
        [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectHeaders: [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders]]];
    }
}

- (void)worksheetAddColumn:(RRSSWorksheet*) worksheet
{
    if ([delegate respondsToSelector: @selector (worksheetAddColumn:)])
    {
        [delegate worksheetAddColumn: self];
    }
    else
        NSLog (@"incomlpete delegate, should implement: - (void)worksheetAddColumn:(RRSSWorksheet*) worksheet");

    //refresh the selection of the rulers
    //
    if ([[(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders] count] != 0)
    {
        [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectHeaders: [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders]]];
    }
    if ([[(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders] count] != 0)
    {
        [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectHeaders: [NSArray arrayWithArray: [(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders]]];
    }
}

- (BOOL)worksheet:(RRSSWorksheet*)worksheet removeRow: (int)row
{
    BOOL rowRemovedByDataSource = NO;

    if ([delegate respondsToSelector: @selector (worksheet:removeRow:)])
    {
        rowRemovedByDataSource = [delegate worksheet:worksheet removeRow: row];
    }
    else
        NSLog (@"incomlpete delegate, should implement: - (void)worksheet:(RRSSWorksheet*) worksheet removeRow: (int)row");

    return YES;
}

- (BOOL)worksheet:(RRSSWorksheet*)worksheet removeColumn: (int)col
{
    BOOL columnRemovedByDataSource = NO;

    if ([delegate respondsToSelector: @selector (worksheet:removeColumn:)])
        columnRemovedByDataSource = [delegate worksheet:worksheet removeColumn: col];
    else
        NSLog (@"incomlpete delegate, should implement: - (void)worksheet:(RRSSWorksheet*) worksheet removeColumn: (int)col");

    return YES;
}

- (id) worksheet:(RRSSWorksheet*)worksheet setCornerLabel:(NSString*)label
{
    if([delegate respondsToSelector: @selector(worksheet:setCornerLabel:)])
        return [delegate worksheet:self setCornerLabel:label];
    else
        return label;
}



- (id) worksheet:(RRSSWorksheet*) worksheet complete: (id)objectToComplete forRow: (int) row column:(int) column
{
    id returnValue = objectToComplete;

    if ([delegate respondsToSelector: @selector (worksheet:complete:forRow:column:)])
    {
        returnValue = [delegate worksheet:worksheet complete:objectToComplete  forRow: row column:column];
    }

    return returnValue;
}
@end


@implementation RRSSWorksheet (Private)
- (void)setAttributesOfProtoCellForPosition: (RRPosition*) aCellPosition
{
    //set the content
    //
    [prototypeCell setObjectValue: [self worksheet: self
                                 objectValueForRow: [aCellPosition row]
                                            column: [aCellPosition column]]];

    //set selection
    //
    if ([selectedCellsPositions containsObject: aCellPosition])
        [prototypeCell setHighlighted: YES];
    else
        [prototypeCell setHighlighted: NO];
}

#pragma mark "---selection manipulation---"
- (void) setSelectedCellsPositions: (NSArray*) cellPositionArray
{
    //stop any editing
    //
    if(currentlyEditingCellPosition)
        [prototypeCell endEditing: textEditor];

    //then set the new one up
    //
    [selectedCellsPositions autorelease];
    selectedCellsPositions = [[NSMutableArray arrayWithArray: cellPositionArray] retain];
}

- (void) addToSelectedCellsPositions: (NSArray*) cellPositionArray
{
    if(currentlyEditingCellPosition)
        [prototypeCell endEditing:textEditor];

    [selectedCellsPositions addObjectsFromArray: cellPositionArray];

}

- (void) removeFromSelectedCellsPositions: (NSArray*) cellPositionArray
{
    [selectedCellsPositions removeObjectsInArray: cellPositionArray];

    [self setSelectedCellsPositions: selectedCellsPositions];
}

- (void) setSelectedRows:(NSArray*) inRowArray
{
    [self setSelectedCellsPositions: [NSArray array]];
    [self addRowsToSelectedRow: inRowArray];
}

- (void) addRowsToSelectedRow: (NSArray*) inRowArray
{
    NSEnumerator *enumerator = [inRowArray objectEnumerator];
    id currentRow;
    NSMutableArray *cellPositionArray = [NSMutableArray array];

    while (currentRow = [enumerator nextObject])
    {
        //take every cell of the row and pass it down
        //
        int rowIndex = [currentRow index];
        NSEnumerator *enumerator = [columns objectEnumerator];
        id object;

        while (object = [enumerator nextObject])
        {
            RRPosition *pos = [RRPosition positionForRow:rowIndex column:[object index]];

            [cellPositionArray addObject: pos];
        }
    }

    [self addToSelectedCellsPositions: cellPositionArray];
}

- (void) removeRowsFromSelectedRows: (NSArray*) inRowArray
{
    NSEnumerator *enumerator = [inRowArray objectEnumerator];
    id currentRow;
    NSMutableArray *cellPositionArray = [NSMutableArray array];

    while (currentRow = [enumerator nextObject])
    {
        //take every cell of the row and pass it down
        //
        int rowIndex = [currentRow index];
        NSEnumerator *enumerator = [columns objectEnumerator];
        id object;

        while (object = [enumerator nextObject])
        {
            RRPosition *pos = [RRPosition positionForRow:rowIndex column:[object index]];

            [cellPositionArray addObject: pos];
        }
    }
    [self removeFromSelectedCellsPositions: cellPositionArray];
}

- (void) setSelectedColumns:(NSArray*) inColumnArray
{
    [self setSelectedCellsPositions: [NSArray array]];
    [self addColumnsToSelectedColumn: inColumnArray];
}

- (void) addColumnsToSelectedColumn: (NSArray*) inColumnArray
{
    NSEnumerator *enumerator = [inColumnArray objectEnumerator];
    id currentColumn;
    NSMutableArray *cellPositionArray = [NSMutableArray array];

    while (currentColumn = [enumerator nextObject])
    {
        //take every cell of the row and pass it down
        //
        int ColumnIndex = [currentColumn index];
        NSEnumerator *enumerator = [rows objectEnumerator];
        id object;

        while (object = [enumerator nextObject])
        {
            RRPosition *pos = [RRPosition positionForRow:[object index] column: ColumnIndex];

            [cellPositionArray addObject: pos];
        }
    }

    [self addToSelectedCellsPositions: cellPositionArray];
}

- (void) removeColumnsFromSelectedColumns: (NSArray*) inColumnArray
{
    NSEnumerator *enumerator = [inColumnArray objectEnumerator];
    id currentColumn;
    NSMutableArray *cellPositionArray = [NSMutableArray array];

    while (currentColumn = [enumerator nextObject])
    {
        //take every cell of the row and pass it down
        //
        int columnIndex = [currentColumn index];
        NSEnumerator *enumerator = [rows objectEnumerator];
        id object;

        while (object = [enumerator nextObject])
        {
            RRPosition *pos = [RRPosition positionForRow:[object index] column:columnIndex];

            [cellPositionArray addObject: pos];
        }
    }
    [self removeFromSelectedCellsPositions: cellPositionArray];
}


- (void)scrollToCellAtRow:(int)row column:(int)column
{
    RRSSHeader *header;
    RRFloatRange rowRange;
    RRFloatRange columnRange;

    header = [rows objectAtIndex:row];
    rowRange = [header range];
    header = [columns objectAtIndex:column];
    columnRange = [header range];

    [self scrollRectToVisible: NSMakeRect(columnRange.location, rowRange.location, columnRange.length, rowRange.length)];

    [self setNeedsDisplayInRect: NSMakeRect(columnRange.location, rowRange.location, columnRange.length, rowRange.length)];
}


#pragma mark "---row manipulation---"
- (void)setRows:(NSMutableArray*)array
{
    [rows autorelease];
    rows = [array retain];
}

- (void) addRows:(int)count
{
    RRSSHeader *lastRow;
    id ruler;
    RRFloatRange lastRange;
    RRFloatRange r;
    NSString *label;
    RRSSHeader *newRow;
    int rowCount = 0, i = 0;
    NSRect newFrame = [self frame];

    ruler = [[self spreadsheet] verticalRulerView];
    for(; count > 0; count--)
    {
        if(rowCount = [rows count]) {
            lastRow = [rows lastObject];
            lastRange = [lastRow range];
            r = RRMakeFloatRange(lastRange.location + lastRange.length, cellSize.height);
        } else {
            r = RRMakeFloatRange(0, cellSize.height);
        }
        label = [self worksheet:self headerLabelForRow:rowCount];
        newRow = [[RRSSHeader alloc] initWithDocumentView:self ruler:ruler range:r label:label index:rowCount];
        [rows addObject:newRow];

        for(i = 0; i < [columns count]; ++i)
            //ask the data source for the value of this guy
            //
            [self reloadCellDataAtRow:rowCount column:i];

    }
    newFrame.size.height = lastRange.location + lastRange.length + cellSize.height;
    [self setFrame:newFrame];
    [self updateVisibleRangesForRect:[self visibleRect]];
}

- (void) removeRow:(unsigned int)row
{
    RRSSRulerView *ruler = (RRSSRulerView*)[[self spreadsheet] verticalRulerView];
    [ruler removeMarker: [rows objectAtIndex: row]];
    [rows removeObjectAtIndex: row];
    [self updateVisibleRangesForRect:[self visibleRect]];
}

- (void) removeAllRows
{
    RRSSRulerView *ruler = (RRSSRulerView*)[[self spreadsheet] verticalRulerView];
    NSEnumerator *e = [rows objectEnumerator];
    RRSSHeader* row;

    while(row = [e nextObject])
        [ruler removeMarker:row];

    [rows removeAllObjects];

    [self updateVisibleRangesForRect:[self visibleRect]];
    [self setNeedsDisplayInRect:[self visibleRect]];
}

#pragma mark "---column manipulation---"
- (void)setColumns:(NSMutableArray*)array
{
    [columns autorelease];
    columns = [array retain];
}

- (void) addColumns:(int)count
{
    RRSSHeader *lastColumn;
    id ruler;
    RRFloatRange lastRange;
    RRFloatRange r;
    NSString *label;
    RRSSHeader *newColumn;
    int columnCount = 0, i = 0;
    NSRect newFrame = [self frame];

    ruler = [[self spreadsheet] horizontalRulerView];
    for(; count > 0; count--)
    {
        if(columnCount = [columns count]) {
            lastColumn = [columns lastObject];
            lastRange = [lastColumn range];
            r = RRMakeFloatRange(lastRange.location + lastRange.length, cellSize.width);
        } else {
            r = RRMakeFloatRange(0, cellSize.width);
        }
        label = [self worksheet:self headerLabelForColumn:columnCount];
        newColumn = [[RRSSHeader alloc] initWithDocumentView:self ruler:ruler range:r label:label index:columnCount];
        [columns addObject:newColumn];

        for(i = 0; i < [rows count]; ++i)
            [self reloadCellDataAtRow:i column:columnCount];


    }
    newFrame.size.width = lastRange.location + lastRange.length + cellSize.width;
    [self setFrame:newFrame];
    [self updateVisibleRangesForRect:[self visibleRect]];


}

- (void) removeColumn:(unsigned int)index
{
    RRSSRulerView *ruler = (RRSSRulerView*)[[self spreadsheet] horizontalRulerView];
    [ruler removeMarker: [columns objectAtIndex: index]];
    [columns removeObjectAtIndex: index];
    [self updateVisibleRangesForRect:[self visibleRect]];
}

- (void) removeAllColumns
{
    RRSSRulerView *ruler = (RRSSRulerView*)[[self spreadsheet] horizontalRulerView];
    NSEnumerator *e = [columns objectEnumerator];
    RRSSHeader* column;

    while(column = [e nextObject])
        [ruler removeMarker:column];

    [columns removeAllObjects];

    [self updateVisibleRangesForRect:[self visibleRect]];
    [self setNeedsDisplayInRect:[self visibleRect]];
}
@end

@implementation RRSSWorksheet (NSResponder)
- (void)doCommandBySelector:(SEL)aSelector
{
    //NSLog(@"%@", NSStringFromSelector(aSelector));
    [super doCommandBySelector: aSelector];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)insertBacktab:(id)sender
{
    if (([[textEditor delegate] textShouldEndEditing: textEditor]) || (currentlyEditingCellPosition == nil))
    {
        RRPosition *newPos = draggingCellPosition;
        if(!newPos)
            newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                         column:[trackingCellPosition column]];
        int newColumn = 0;

        newColumn = [newPos column] - 1;
        if(newColumn < 0)
        {
            newColumn = 0;
            NSBeep();
        }

        [self selectCellAtRow:[newPos row] column:newColumn];
    }
    else
        NSBeep();
    [[self window] makeFirstResponder:self];
}

- (void)insertNewline:(id)sender
{
    //tell the selected cell to stop editing and go to the next one to the bottom
    //
    if (([[textEditor delegate] textShouldEndEditing: textEditor]) || (currentlyEditingCellPosition == nil))
    {
        RRPosition *newPos = draggingCellPosition;
        if(!newPos)
            newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                         column:[trackingCellPosition column]];
        int newRow = 0;

        // move one row down
        //
        if([newPos row] + 1 == [rows count])
        {
            if ([self worksheetShouldAddRow: self])
            {
                [self worksheetAddRow: self];
                newRow = [newPos row] + 1;
            }
            else
            {
                NSBeep();
                newRow = [newPos row];
            }
        }
        else
            newRow = [newPos row] + 1;

        [self selectCellAtRow:newRow column:[newPos column]];
    }
    else
        NSBeep();
    [[self window] makeFirstResponder:self];
}

- (void)insertTab:(id)sender
{
    if (([[textEditor delegate] textShouldEndEditing: textEditor]) || (currentlyEditingCellPosition == nil))
    {
        RRPosition *newPos = draggingCellPosition;
        if(!newPos)
            newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                         column:[trackingCellPosition column]];
        int newColumn = 0;

        // move one row down
        //
        if([newPos column] + 1 == [columns count])
        {
            if ([self worksheetShouldAddColumn: self])
            {
                [self worksheetAddColumn: self];
                newColumn = [newPos column] + 1;
            }
            else
            {
                NSBeep();
                newColumn = [newPos column];
            }
        }
        else
            newColumn = [newPos column] + 1;

        [self selectCellAtRow:[newPos row] column: newColumn];
    }
    else
        NSBeep();
    [[self window] makeFirstResponder:self];
}

- (void) insertText: (id) sender
{
    //pass it down to the cell that is selected
    //
    if (selectedCellPosition != nil)
    {
        [self beginEditingCellAtPosition: selectedCellPosition];
        [textEditor keyDown: [NSEvent keyEventWithType: NSKeyDown
                                              location: NSMakePoint(0,0)
                                         modifierFlags: 0
                                             timestamp: 0
                                          windowNumber: 0
                                               context: [NSGraphicsContext currentContext]
                                            characters: sender
                           charactersIgnoringModifiers: sender
                                             isARepeat: NO
                                               keyCode: 0]];
    }
}

- (void)deleteBackward:(id)sender
{
    //if we have a selected row or column delete it
    //
    BOOL needToReload = NO;
    if ([[(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders] count] != 0)
    {
        //start the remove process from the end as we remove them one at a time  by index
        //
        NSEnumerator *enumerator = [[(RRSSRulerView*)[[self spreadsheet] horizontalRulerView] selectedHeaders] reverseObjectEnumerator];
        id object;

        while (object = [enumerator nextObject])
        {
            if ([self worksheet:self shouldRemoveColumn: [object index]])
            {
                [self worksheet:self removeColumn: [object index]];
                needToReload = YES;
            }
        }
    }
    if ([[(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders] count] != 0)
    {
        //start the remove process from the end as we remove them one at a time  by index
        //
        NSEnumerator *enumerator = [[(RRSSRulerView*)[[self spreadsheet] verticalRulerView] selectedHeaders] reverseObjectEnumerator];
        id object;

        while (object = [enumerator nextObject])
        {
            if ([self worksheet:self shouldRemoveRow: [object index]])
            {
                [self worksheet:self removeRow: [object index]];
                needToReload = YES;
            }
        }
    }

    if (needToReload)
        [self reloadWorksheetData];
}

- (void)deleteForward:(id)sender
{
    [self deleteBackward: sender];
}

- (void)moveDown:(id)sender
{
    int newIndex = 0;
    RRPosition *newPos = draggingCellPosition;
    if(!newPos)
        newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                     column:[trackingCellPosition column]];
    // move one row down
    //
    if([newPos row] + 1 == [rows count])
    {
        if ([self worksheetShouldAddRow: self])
        {
            [self worksheetAddRow: self];
            newIndex = [newPos row] + 1;
        }
        else
        {
            NSBeep();
            newIndex = [newPos row];
        }
    }
    else
        newIndex = [newPos row] + 1;

    [self selectCellAtRow:newIndex column:[newPos column] byExtendingSelection: NO scrolling: YES];
}

- (void)moveDownAndModifySelection:(id)sender
{
    int newIndex = 0;
    RRPosition *newPos = draggingCellPosition;
    if(!newPos)
        newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                     column:[trackingCellPosition column]];
    // move one row down
    //
    if([newPos row] + 1 == [rows count])
    {
        if ([self worksheetShouldAddRow: self])
        {
            [self worksheetAddRow: self];
            newIndex = [newPos row] + 1;
        }
        else
        {
            NSBeep();
            newIndex = [newPos row];
        }
    }
    else
        newIndex = [newPos row] + 1;
    [self selectCellAtRow:newIndex column:[newPos column] byExtendingSelection: YES scrolling:YES];
}

- (void)moveLeft:(id)sender
{
    if (currentlyEditingCellPosition == nil)
    {
        int newIndex = 0;
        RRPosition *newPos = draggingCellPosition;
        if(!newPos)
            newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                         column:[trackingCellPosition column]];

        newIndex = [newPos column] - 1;
        if(newIndex < 0)
        {
            newIndex = 0;
            NSBeep();
        }
        [newPos setColumn:newIndex];

        [self selectCellAtRow:[newPos row] column:newIndex byExtendingSelection: NO scrolling:YES];
    }
}

- (void)moveRight:(id)sender
{
    if (currentlyEditingCellPosition == nil)
    {
        int newIndex = 0;
        RRPosition *newPos = draggingCellPosition;
        if(!newPos)
            newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                         column:[trackingCellPosition column]];
        // move one column right
        //
        if([newPos column] + 1 == [columns count])
        {
            if ([self worksheetShouldAddColumn: self])
            {
                [self worksheetAddColumn: self];
                newIndex = [newPos column] + 1;
            }
            else
            {
                NSBeep();
                newIndex = [newPos column];
            }
        }
        else
            newIndex = [newPos column] + 1;
        [self selectCellAtRow:[newPos row] column:newIndex byExtendingSelection: NO scrolling:YES];
    }
}

- (void)moveUp:(id)sender
{
    int newIndex = 0;
    RRPosition *newPos = draggingCellPosition;
    if(!newPos)
        newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                     column:[trackingCellPosition column]];
    newIndex = [newPos row] - 1;
    if(newIndex < 0)
    {
        newIndex = 0;
        NSBeep();
    }
    [self selectCellAtRow:newIndex column:[newPos column] byExtendingSelection: NO scrolling:YES];
}

- (void)moveUpAndModifySelection:(id)sender
{
    int newIndex = 0;
    RRPosition *newPos = draggingCellPosition;
    if(!newPos)
        newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                     column:[trackingCellPosition column]];
    newIndex = [newPos row] - 1;
    if(newIndex < 0)
    {
        newIndex = 0;
        NSBeep();
    }
    [self selectCellAtRow:newIndex column:[newPos column] byExtendingSelection: YES scrolling:YES];
}



- (void)moveBackward:(id)sender
{
    [self pageUp: sender];
}

- (void)moveBackwardAndModifySelection:(id)sender
{
    int newIndex = 0;
    RRPosition *newPos = draggingCellPosition;
    if(!newPos)
        newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                     column:[trackingCellPosition column]];

    newIndex = [newPos column] - 1;
    if(newIndex < 0)
    {
        newIndex = 0;
        NSBeep();
    }
    [newPos setColumn:newIndex];

    [self selectCellAtRow:[newPos row] column:newIndex byExtendingSelection: YES scrolling:YES];
}

- (void)moveForward:(id)sender
{
    [self pageDown: sender];
}

- (void)moveForwardAndModifySelection:(id)sender
{
    //to us it will be more a moveRightAndModifySelection
    //
    int newIndex = 0;
    RRPosition *newPos = draggingCellPosition;
    if(!newPos)
        newPos = [RRPosition positionForRow:[trackingCellPosition row]
                                     column:[trackingCellPosition column]];
    // move one column right
    //
    if([newPos column] + 1 == [columns count])
    {
        if ([self worksheetShouldAddColumn: self])
        {
            [self worksheetAddColumn: self];
            newIndex = [newPos column] + 1;
        }
        else
        {
            NSBeep();
            newIndex = [newPos column];
        }
    }
    else
        newIndex = [newPos column] + 1;
    [self selectCellAtRow:[newPos row] column:newIndex byExtendingSelection: YES scrolling:YES];
}


- (void)moveToBeginningOfDocument:(id)sender
{
    [self selectCellAtRow: 0
                   column: [draggingCellPosition column]
     byExtendingSelection: NO
                scrolling: YES];
}

- (void)moveToBeginningOfDocumentAndModifySelection:(id)sender
{
    [self selectCellAtRow: 0
                   column: [draggingCellPosition column]
     byExtendingSelection: YES
                scrolling: YES];
}

- (void)moveToEndOfDocument:(id)sender
{
    [self selectCellAtRow: [rows count] - 1
                   column: [draggingCellPosition column]
     byExtendingSelection: NO
                scrolling: YES];
}

- (void)moveToEndOfDocumentAndModifySelection:(id)sender
{
    [self selectCellAtRow: [rows count] - 1
                   column: [draggingCellPosition column]
     byExtendingSelection: YES
                scrolling: YES];
}

- (void)moveToBeginningOfLine:(id)sender
{
    //get the current selected cell and go to the end of that row
    //
    [self selectCellAtRow:[draggingCellPosition row] column: 0 byExtendingSelection: NO scrolling:YES];
}

- (void)moveToBeginningOfLineAndModifySelection:(id)sender
{
    //get the current selected cell and go to the end of that row
    //
    [self selectCellAtRow:[draggingCellPosition row] column: 0 byExtendingSelection: YES scrolling:YES];
}

- (void)moveToEndOfLine:(id)sender
{
    //get the current selected cell and go to the end of that row
    //
    [self selectCellAtRow:[draggingCellPosition row] column: [columns count]-1 byExtendingSelection: NO scrolling:YES];

}

- (void)moveToEndOfLineAndModifySelection:(id)sender
{
    //get the current selected cell and go to the end of that row
    //
    [self selectCellAtRow:[draggingCellPosition row] column: [columns count]-1 byExtendingSelection: YES scrolling:YES];

}

- (void) moveToEndOfParagraph: (id) sender
{

}

- (void) moveToBeginningOfParagraph:(id)sender
{

}

- (void) pageDown:(id)sender
{
    RRSSHeader *header;
    RRFloatRange rowRange;

    header = [rows objectAtIndex:(visibleRowRange.location + visibleRowRange.length - 1)];
    rowRange = [header range];

    [self scrollRectToVisible: NSMakeRect([self visibleRect].origin.x,
                                          rowRange.location + 1,
                                          [self visibleRect].size.width,
                                          [self visibleRect].size.height)];

    //select the cell at the top of this
    //
    [self selectCellAtRow: visibleRowRange.location column: [trackingCellPosition column]];
}

- (void) pageDownAndModifySelection: (id) sender
{
    RRSSHeader *header;
    RRFloatRange rowRange;

    header = [rows objectAtIndex:(visibleRowRange.location + visibleRowRange.length - 1)];
    rowRange = [header range];

    [self scrollRectToVisible: NSMakeRect([self visibleRect].origin.x,
                                          rowRange.location + 1,
                                          [self visibleRect].size.width,
                                          [self visibleRect].size.height)];

    //select the cell at the top of this
    //
    [self selectCellAtRow: visibleRowRange.location column: [trackingCellPosition column] byExtendingSelection: YES scrolling: YES];
}

- (void) pageUp:(id)sender
{
    RRSSHeader *header;
    RRFloatRange rowRange;
    if (visibleRowRange.location == 0)
        NSBeep();
    else
    {
        int topRowIndex = (visibleRowRange.location - visibleRowRange.length + 1);
        if (topRowIndex < 0)
            topRowIndex = 0;
        header = [rows objectAtIndex: topRowIndex];
        rowRange = [header range];


        [self scrollRectToVisible: NSMakeRect([self visibleRect].origin.x,
                                              rowRange.location - 1,
                                              [self visibleRect].size.width,
                                              [self visibleRect].size.height)];
    }

    //select the cell at the top of this
    //
    [self selectCellAtRow: visibleRowRange.location column: [trackingCellPosition column]];
}

- (void) pageUpAndModifySelection: (id) sender
{
    RRSSHeader *header;
    RRFloatRange rowRange;
    if (visibleRowRange.location == 0)
        NSBeep();
    else
    {
        int topRowIndex = (visibleRowRange.location - visibleRowRange.length + 1);
        if (topRowIndex < 0)
            topRowIndex = 0;
        header = [rows objectAtIndex: topRowIndex];
        rowRange = [header range];


        [self scrollRectToVisible: NSMakeRect([self visibleRect].origin.x,
                                              rowRange.location - 1,
                                              [self visibleRect].size.width,
                                              [self visibleRect].size.height)];
    }

    //select the cell at the top of this
    //
    [self selectCellAtRow: visibleRowRange.location column: [trackingCellPosition column] byExtendingSelection: YES scrolling: NO];
}

- (void) scrollPageDown:(id)sender
{
    RRSSHeader *header;
    RRFloatRange rowRange;

    header = [rows objectAtIndex:(visibleRowRange.location + visibleRowRange.length - 1)];
    rowRange = [header range];

    [self scrollRectToVisible: NSMakeRect([self visibleRect].origin.x,
                                          rowRange.location + 1,
                                          [self visibleRect].size.width,
                                          [self visibleRect].size.height)];
}

- (void) scrollPageUp:(id)sender
{
    RRSSHeader *header;
    RRFloatRange rowRange;
    if (visibleRowRange.location == 0)
        NSBeep();
    else
    {
        int topRowIndex = (visibleRowRange.location - visibleRowRange.length + 1);
        if (topRowIndex < 0)
            topRowIndex = 0;
        header = [rows objectAtIndex: topRowIndex];
        rowRange = [header range];


        [self scrollRectToVisible: NSMakeRect([self visibleRect].origin.x,
                                              rowRange.location - 1,
                                              [self visibleRect].size.width,
                                              [self visibleRect].size.height)];
    }
}

- (void) scrollLineDown:(id)sender
{
    RRSSHeader *header;
    RRFloatRange rowRange;

    header = [rows objectAtIndex:(visibleRowRange.location + 1)];
    rowRange = [header range];

    [self scrollRectToVisible: NSMakeRect([self visibleRect].origin.x,
                                          rowRange.location + 1,
                                          [self visibleRect].size.width,
                                          [self visibleRect].size.height)];
}

- (void) scrollLineUp:(id)sender
{
    RRSSHeader *header;
    RRFloatRange rowRange;
    if (visibleRowRange.location == 0)
        NSBeep();
    else
    {
        int topRowIndex = (visibleRowRange.location - 1);
        if (topRowIndex < 0)
            topRowIndex = 0;
        header = [rows objectAtIndex: topRowIndex];
        rowRange = [header range];


        [self scrollRectToVisible: NSMakeRect([self visibleRect].origin.x,
                                              rowRange.location - 1,
                                              [self visibleRect].size.width,
                                              [self visibleRect].size.height)];
    }
}

- (void) scrollWheel:(NSEvent *)theEvent
{

}

- (void) scrollToEndOfDocument: (id) sender
{
    [self scrollToCellAtRow:[rows count] - 1 column:[draggingCellPosition column]];
}

- (void) scrollToBeginningOfDocument: (id) sender
{
    [self scrollToCellAtRow:0 column:[draggingCellPosition column]];
}

- (void)complete:(id)sender
{
    int test = 8;
}

- (void)keyDown:(NSEvent *)theEvent
{
    [self interpretKeyEvents: [NSArray arrayWithObject: theEvent]];
}

- (void)keyUp:(NSEvent *)theEvent
{

}


// handle all of the mouse events
- (void)mouseDown:(NSEvent *)theEvent
{
    unsigned int modifier = [theEvent modifierFlags];
    RRPosition *pos = [self cellPositionForEvent:theEvent];
    //NSCell* cell = [cells objectForKey:pos];

    if(currentlyEditingCellPosition) {
        // we are already in a cell, so stop editing there
        // and start in the next one
        [prototypeCell endEditing:textEditor];
    }

    if (modifier & NSShiftKeyMask)
    {
        // we have shift-clicked on another cell while
        // editing another one. end the editing, and select everything in-between
        // by simulating a mouse drag
        if([pos isEqualTo: currentlyEditingCellPosition])
        {
            [prototypeCell endEditing:textEditor];
            [self selectCellAtRow:[pos row] column:[pos column]];
        }
        isDragging = YES;
        [self mouseDragged:theEvent];

    }
    else if (modifier & NSCommandKeyMask) //command key for non continuous selection
    {
        trackingCellPosition = pos;
    }
    else
    {
        [self selectCellAtRow:[pos row] column:[pos column]];
    }
    [[self window] makeFirstResponder:self];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    unsigned int modifier = [theEvent modifierFlags];
    RRPosition *pos = [self cellPositionForEvent:theEvent];
    //NSCell* cell = [cells objectForKey:pos];

    if(isDragging)
    {
        // we must have selected a range of cells...
        isDragging = NO;
    }
    else if(currentlyEditingCellPosition)
    {

    }
    else
    {
        // we got here from a simple mousedown/up sequence,
        // move the editing to this cell
        // deselect this cell
        if (modifier & NSShiftKeyMask)
        {
        }
        else if (modifier & NSCommandKeyMask)
        {
            if([pos isEqualTo: currentlyEditingCellPosition])
            {
                [prototypeCell endEditing:textEditor];
            }

            if([selectedCellsPositions containsObject: pos])
            {
                //deselect the given cell
                [self deselectCellAtRow:[pos row] column:[pos column]];
            }
            else
            {
                //add that cell to the selected cell
                [self addCellPositionToSelectedCellsPositions: pos];
            }
        }
        else if ([theEvent clickCount] > 1)
        {
            trackingCellPosition = [self cellPositionForEvent:theEvent];
            [self beginEditingCellAtPosition: selectedCellPosition];
        }
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    int i,j, fromColumn, toColumn, fromRow, toRow, tmp, originalToColumn, originalToRow;

    RRPosition *newCorner = [self cellPositionForEvent:theEvent];

    isDragging = YES;
    if(trackingCellPosition != newCorner && draggingCellPosition != newCorner) {

        draggingCellPosition = newCorner;

        fromColumn = [trackingCellPosition column];
        originalToColumn = toColumn = [newCorner column];
        fromRow = [trackingCellPosition row];
        originalToRow = toRow = [newCorner row];

        [self deselectAllCells];

        if(toColumn < fromColumn) {
            tmp = toColumn; toColumn = fromColumn; fromColumn = tmp;
        }

        if(toRow < fromRow) {
            tmp = toRow; toRow = fromRow; fromRow = tmp;
        }

        NSMutableArray *cellPositionsToSelect = [NSMutableArray array];
        for(i = fromColumn; i <= toColumn; ++i)
        {
            for(j = fromRow; j <= toRow; ++j)
            {
                [cellPositionsToSelect addObject: [RRPosition positionForRow: j column: i]];
            }
        }

        [self setSelectedCellsPositions: cellPositionsToSelect];

        [self scrollToCellAtRow: originalToRow column: originalToColumn];
    }
}

-(void) copy: (id) sender
{
    [self worksheet:self writeCellsAtPositions:selectedCellsPositions toPasteboard:[NSPasteboard generalPasteboard]];
}

-(void) paste: (id) sender
{
    if ([delegate respondsToSelector: @selector (worksheet:paste:atRow:column:)])
    {
        int row = [selectedCellPosition row];
        int column = [selectedCellPosition column];
        [dataSource worksheet:self paste: [NSPasteboard generalPasteboard] atRow:row column: column];
    }
}

-(void) cut: (id) sender
{
    [self copy: sender];

    //then clear those cells
    //
    [self clearCellsAtPositions: selectedCellsPositions];
}

- (void) clear: (id) sender
{
    [self clearCellsAtPositions: selectedCellsPositions];
}

- (void) selectAll: (id) sender
{
    [self selectAllCells];
}
@end

@implementation RRSSWorksheet (NSMenuValidation)
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;
{
    BOOL returnValue;
    
    if (([NSStringFromSelector([menuItem action]) isEqualToString: @"copy:"]) ||
        ([NSStringFromSelector([menuItem action]) isEqualToString: @"cut:"]) ||
        ([NSStringFromSelector([menuItem action]) isEqualToString: @"clear:"]))
    {
        returnValue = ([selectedCellsPositions count] != 0);
    }
    else if ([NSStringFromSelector([menuItem action]) isEqualToString: @"paste:"])
    {
        if ([delegate respondsToSelector: @selector (worksheet:validatePasteMenuItem:atRow:column:)])
        {
            int row = [selectedCellPosition row];
            int column = [selectedCellPosition column];
            returnValue = [delegate worksheet:self validatePasteMenuItem: menuItem atRow:row column: column];
        }
        else
            returnValue = YES;
    }
    else if ([NSStringFromSelector([menuItem action]) isEqualToString: @"selectAll:"])
    {
        returnValue = YES;
    }

    return returnValue;
}
@end