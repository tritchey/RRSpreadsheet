//
//  RRSSWorksheet.h
//  µ
//
//  Created by Timothy Ritchey on Fri Feb 08 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import "RRSSWorksheet.h"


@interface RRSSWorksheet (Private)
- (void) setSelectedCellsPositions: (NSArray*) cellArray;
- (void) addToSelectedCellsPositions: (NSArray*) cellArray;
- (void) removeFromSelectedCellsPositions: (NSArray*) cellArray;

- (void) setSelectedRows:(NSArray*) inRowAray;
- (void) addRowsToSelectedRow: (NSArray*) inRowArray;
- (void) removeRowsFromSelectedRows: (NSArray*) inRowArray;

- (void) setSelectedColumns:(NSArray*) inColumnArray;
- (void) addColumnsToSelectedColumn: (NSArray*) inColumnArray;
- (void) removeColumnsFromSelectedColumns: (NSArray*) inColumnArray;

- (void) scrollToCellAtRow:(int)row column:(int)column;
- (void) setAttributesOfProtoCellForPosition: (RRPosition*) aCellPosition;

- (void) setRows:(NSMutableArray*)array;
- (void) addRows:(int)count;
- (void) removeRow:(unsigned int)row;
- (void) removeAllRows;

- (void) setColumns:(NSMutableArray*)array;
- (void) addColumns:(int)count;
- (void) removeColumn:(unsigned int)column;
- (void) removeAllColumns;
@end


