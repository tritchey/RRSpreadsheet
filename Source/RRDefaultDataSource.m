//
//  RRDefaultDataSource.m
//  RRSpreadSheet
//
//  Created by otusweb on Thu Oct 17 2002.
//  Copyright (c) 2002 Texas Instruments Incorporated. All rights reserved.
//

#import "RRDefaultDataSource.h"
#import "RRSSWorksheet.h"
#import "RRPosition.h"

static NSString* privatepBoardType = @"RRSpreadsheetCell";

@implementation RRDefaultDataSource
- (id) init
{
    if(self = [super init]) {
        columnCount = rowCount = 0;
        theCellValue = [[NSMutableDictionary alloc] init];
        columnHeaders = [[NSMutableDictionary alloc] init];
        rowHeaders = [[NSMutableDictionary alloc] init];
        copiedCells = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id) objectValueForKey: (RRPosition*) aCellPosition
{
    id objectValue = [theCellValue objectForKey: aCellPosition];
    if (objectValue == nil)
        objectValue = @"";

    return objectValue;
}

/*!
* @method numberOfRowsInWorksheet:
 * @abstract return the number of rows in the worksheet
 * @discussion This method is called by the worksheet to determine the number of rows it needs to
 * create to support the data source. Note that if autoresizing is enabled, then the number
 * of rows may increase beyond this number
 * @param worksheet the requesting worksheet
 * @result the data source object must return an integer with the number of rows
 * needed in the worksheet
 */
- (int)numberOfRowsInWorksheet:(RRSSWorksheet*)worksheet
{
    return rowCount;
}

/*!
* @method numberOfColumnsInWorksheet:
 * @abstract return the number of columns in the worksheet
 * @discussion This method is called by the worksheet to determine the number of columns it needs to
 * create to support the data source. Note that if autoresizing is enabled, then the number
 * of columns may increase beyond this number
 * @param worksheet the requesting worksheet
 * @result the data source object must return an integer with the number of columns
 * needed in the worksheet
 */
- (int)numberOfColumnsInWorksheet:(RRSSWorksheet*)worksheet
{
    return columnCount;
}


- (id)worksheet:(RRSSWorksheet*)worksheet objectValueForRow:(unsigned int)row column:(int)col
{
    return [self objectValueForKey:[RRPosition positionForRow: row column: col]];
}

- (void)worksheet:(RRSSWorksheet*)worksheet setObjectValue:(id)object forRow:(int)row column:(int)col
{
    [theCellValue setObject: object forKey: [RRPosition positionForRow: row column: col]];
}

- (BOOL)worksheet:(RRSSWorksheet*)worksheet writeCellsAtPositions:(NSArray*)cellsPositions toPasteboard:(NSPasteboard*)pboard
{
    //create a dictionary with the given cell so that we can at least paste it in ourself
    //
    NSEnumerator *enumerator = [cellsPositions objectEnumerator];
    id object;
    [copiedCells removeAllObjects];

    while (object = [enumerator nextObject]) {
        [copiedCells setObject: [self objectValueForKey: object] forKey: object];
    }

    // Provide data for our custom type, and simple NSStrings.
    [pboard declareTypes:[NSArray arrayWithObject: privatepBoardType] owner:self];

    //no need to put anydata as we are the only one to see it anyway
    //
    return YES;
}

- (void) worksheet:(RRSSWorksheet*) worksheet paste: (NSPasteboard*) pBoard atRow:(int) row column: (int)column
{
    NSArray *theCellPositionOrdered = [[copiedCells allKeys]
                     sortedArrayUsingSelector: @selector (compare:)];
    // now that we ordered the keys, let's get the top left one to get
    // the position difference
    int rowDifference = [[theCellPositionOrdered objectAtIndex: 0] row] - row;
    int columnDifference = [[theCellPositionOrdered objectAtIndex: 0] column] - column;

    // now we have a bunch of cell that have kept their coordinate,
    // when we set the values, we need to shift
    // those value according to the insertion location
    //
    NSEnumerator *enumerator = [theCellPositionOrdered objectEnumerator];
    id object;

    while (object = [enumerator nextObject])
        [self worksheet: worksheet
         setObjectValue: [copiedCells objectForKey:object]
                 forRow: [object row] - rowDifference
                 column: [object column] - columnDifference];

    //now select the cell we just pasted and relod the cell we modified
    //
    NSMutableArray *theCellToSelect = [[NSMutableArray alloc] init];
    enumerator = [[copiedCells allKeys] objectEnumerator];

    while (object = [enumerator nextObject])
    {
        id copyOfPosition = [object copy];
        [copyOfPosition setRow: [object row] - rowDifference];
        [copyOfPosition setColumn: [object column] - columnDifference];
        [theCellToSelect addObject: copyOfPosition];
    }
    [worksheet selectCellsAtPositions: theCellToSelect];

    enumerator = [theCellToSelect objectEnumerator];
    while (object = [enumerator nextObject])
    {
        if (([[worksheet columns] count] > [object column]) && ([[worksheet rows] count] > [object row]))
            [worksheet reloadCellDataAtRow: [object row]
                                    column: [object column]];
    }
}


- (NSString*)worksheet:(RRSSWorksheet*)worksheet headerLabelForRow:(int)row
{
    NSString *label;
    NSNumber *rowNum = [NSNumber numberWithInt:row];

    if(!(label = [rowHeaders objectForKey:rowNum])) {
        // just turn the row number into a string
        // note - while everything internally is zero-based, externally, we present it as 1-based
        label = [NSString stringWithFormat:@"%d", (row+1)];
        [rowHeaders setObject:label forKey:rowNum];
    }
    return label;
}

- (NSString*)worksheet:(RRSSWorksheet*)worksheet headerLabelForColumn:(int)col
{
    int i;
    NSString *labels = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    NSString *label = @"";
    NSNumber *colNum = [NSNumber numberWithInt:col];

    if(!(label = [columnHeaders objectForKey:colNum])) {
        label = @"";
        for(i = 0; i <= (col/26); i++) {
            label = [label stringByAppendingString:[labels
                                      substringWithRange:NSMakeRange((col%26),1)]];
        }
        [columnHeaders setObject:label forKey:colNum];
    }
    return label;

}


- (void)worksheet:(RRSSWorksheet*)worksheet setHeaderLabel:(NSString*)label forRow:(int)row
{
    [rowHeaders setObject:label forKey:[NSNumber numberWithInt:row]];
    
}

- (void)worksheet:(RRSSWorksheet*)worksheet setHeaderLabel:(NSString*)label forColumn:(int)column
{
    [columnHeaders setObject:label forKey:[NSNumber numberWithInt:column]];
}


- (void)dealloc
{
    [theCellValue release];
    [rowHeaders release];
    [columnHeaders release];
    [copiedCells release];
    [super dealloc];
}

@end

@implementation RRDefaultDataSource (RRSpreadSheetDelegate)

- (void)worksheetAddRow:(RRSSWorksheet*) worksheet
{
    rowCount ++;
    [worksheet reloadWorksheetData];
}

- (void)worksheetAddColumn:(RRSSWorksheet*) worksheet
{
    columnCount++;
    [worksheet reloadWorksheetData];
}

- (BOOL)worksheet:(RRSSWorksheet*)worksheet removeRow: (int)row
{
    //remove all the key that we had stored for that row
    //
    int column;
    for (column = 0; column < columnCount; column++) 
    	[theCellValue removeObjectForKey: [RRPosition positionForRow: row column: column]];
    [rowHeaders removeObjectForKey:[NSNumber numberWithInt:row]];
    rowCount--;
    [worksheet reloadWorksheetData];
    return YES;
}

- (BOOL)worksheet:(RRSSWorksheet*)worksheet removeColumn: (int)col
{
    //remove all the key that we had stored for that column
    //
    int row;
    for (row = 0; row < rowCount; row++)
        [theCellValue removeObjectForKey: [RRPosition positionForRow: row column: col]];
    [columnHeaders removeObjectForKey:[NSNumber numberWithInt:col]];
    columnCount--;
    [worksheet reloadWorksheetData];
    return YES;
}

- (BOOL) worksheet:(RRSSWorksheet*) worksheet validatePasteMenuItem: (id <NSMenuItem>)menuItem atRow:(int) row column: (int)column
{
    return [[[NSPasteboard generalPasteboard] types] containsObject: privatepBoardType];
}

@end
