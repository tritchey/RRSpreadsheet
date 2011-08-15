//
//  RRSSWorksheet.h
//  µ
//
//  Created by Timothy Ritchey on Fri Feb 08 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RRFloatRange.h"

@class RRSpreadSheet, RRSSRulerView, RRSSRulerMarker, RRSSHeader, RRSSCell, RRPosition;

/*!
* @class RRSSWorksheet
 * @abstract the RRSSWorksheet class is the control representing the field of cells in an RRSpreadSheet
 * @discussion the RRSSWorksheet class is the control representing the field of cells in an RRSpreadSheet
 */
@interface RRSSWorksheet : NSControl {

    id prototypeCell;
    NSSize cellSize;
  //  NSMutableDictionary *cells;
    NSMutableArray *rows;
    NSMutableArray *columns;
    id dataSource;
    id delegate;
    id spreadsheet;

    int neededRows;
    int neededColumns;

    BOOL isDragging;
    BOOL allowLeftArrowMove;
    BOOL allowRightArrowMove;
    BOOL allowAutoResize;
    RRPosition *trackingCellPosition;
    RRPosition *draggingCellPosition;
    NSTextView *textEditor;
    RRPosition *currentlyEditingCellPosition;

    RRPosition * selectedCellPosition;
    NSMutableArray* selectedCellsPositions;

    // cached values for speeding redraw, etc.
    NSRange dirtyRowRange;
    NSRange visibleRowRange;
    NSRange dirtyColumnRange;
    NSRange visibleColumnRange;
    NSMutableArray *visibleCellPositions;
    NSArray *visibleRows;
    NSArray *visibleColumns;
}
/*!
 * @method setCellClass:
 * @abstract set the worksheet cell class
 * @discussion set the prototype cell for spreadsheet created in the future
 * @param cellClass the cell class
 */
+ (void)setCellClass:(Class)cellClass;

/*!
 * @method cellClass
 * @abstract return the worksheet cell class
 * @result the class used by the spreadsheet when creating new cells
 */
+ (Class)cellClass;

/*!
* @method prototypeCell
* @abstract return the worksheet cell prototype
* @result the class used by the spreadsheet when creating new cells
*/
- (id) prototypeCell;

/*!
* @method setPrototypeCell
* @abstract set the worksheet cell prototype
* @result set the cell that is used to display every cell
*/
- (void) setPrototypeCell: (NSCell*) inPrototypeCell;


/*!
 * @method initWithFrame:cellSize:
 * @abstract class initialization method.
 * @discussion class initialization method. This is the default initialization method
 * for the class
 * @param rect an NSRect holding the new control's frame
 * @param size the default cell size for the worksheet
 * @result returns the initialized object, or nil
 */
- (id)initWithFrame:(NSRect)rect cellSize:(NSSize)size;

/*!
 * @method spreadsheet
 * @abstract return the enclosing spreadsheet for this worksheet
 * @result returns the enclosing spreadsheet object
 */
- (id)spreadsheet;

/*!
 * @method setAllowAutoResize:
 * @abstract set the worksheet's auto resizing parameter
 * @discussion the method determines whether the worksheet automatically
 * adds rows and columns to fill the spreadsheet view
 * @param allow YES = allow the worksheet to resize automatically, NO = do not
 * allow the worksheet to automatically resize
 */
- (void)setAllowAutoResize:(BOOL)allow;

/*!
 * @method allowAutoResize
 * @abstract return the autoresize setting
 * @result returns a BOOL holding the setting for the autoresize flag
 */
- (BOOL)allowAutoResize;

/*!
 * @method cellSize:
 * @abstract return the default cell size
 * @discussion description forthcoming
 * @result an NSSize holding the default worksheet cell size
 */
- (NSSize)cellSize;

/*!
 * @method setCellSize:
 * @abstract set the default cell size
 * @discussion description forthcoming
 * @param size the new default cell size
 */
- (void)setCellSize:(NSSize)size;

/*!
 * @method beginEditingCell:
 * @abstract begin editing a worksheet cell
 * @discussion description forthcoming
 * @param aCell the cell to begin editing
 */
- (void)beginEditingCellAtPosition:(RRPosition*)aCellPosition;

/*!
 * @method selectedCells
 * @abstract return all selected cells in the worksheet
 * @discussion description forthcoming
 * @result returns an array of all selected cells in the worksheet
 */
- (NSArray*)selectedCellsPositions;

/*!
* @method selectCell:byExtendingSelection:scrolling:
* @abstract select the given cell in the worksheet
* @discussion forthcoming
* @param aCell the cell to select
* @param scroll BOOL scroll view to selected cell
* @param inExtending BOOL extend the selection from the top left selected cell to the input cell
*/
- (void)selectCellAtPosition:(RRPosition*)aCellPosition byExtendingSelection:(BOOL)inExtending scrolling: (BOOL) scroll;

/*!
* @method selectCell:byExtendingSelection:scrolling:
* @abstract select the given cell in the worksheet
* @discussion call selectCell:aCell byExtendingSelection:NO scrolling:YES on the receiver
* @param aCell the cell to select
*/
- (void)selectCellAtPosition:(RRPosition*)aCellPosition;

/*!
* @method selectCellAtRow:column:scroll:
* @abstract select a cell in the worksheet by row/column
* @discussion call selectCell:(NSCell*)aCell byExtendingSelection:inExtending scrolling:scroll on the given cell
* @param row integer row index
* @param column integer column index
* @param scroll BOOL scroll view to selected cell
* @param inExtending BOOL extend the selection from the top left selected cell to the input cell
*/
- (void)selectCellAtRow:(int)row column:(int)column byExtendingSelection:(BOOL)inExtending scrolling: (BOOL) scroll;

/*!
* @method selectCellAtRow:column:scroll:
* @abstract select a cell in the worksheet by row/column
* @discussion call selectCell:(NSCell*)aCell on the given cell
* @param row integer row index
* @param column integer column index
*/
- (void)selectCellAtRow:(int)row column:(int)column;

/*!
 * @method selectCells:
 * @abstract select a number of cells at once
 * @discussion description forthcoming
 * @param selCells NSArray of cells to select
 */
- (void)selectCellsAtPositions:(NSArray*)selCellsPosition;

/*!
 * @method addCellPositionToSelectedCellsPositions:
 * @abstract add a cell to the currently selected cell (for discontinuous selection)
 * @discussion deselect any headers and add this cell to the list of selected cell
 * @param aCellPosition an RRPosition object
 */
- (void) addCellPositionToSelectedCellsPositions:(RRPosition*) aCellPosition;


/*!
* @method selectAllCells:
* @abstract select all cell  of the spreadsheet
* @discussion deselect any headers and add this cell to the list of selected cell
*/
- (void) selectAllCells;

/*!
 * @method selectRow:
 * @abstract select an entire row
 * @discussion description forthcoming
 * @param row integer row index
 */
- (void)selectRow:(int)row;
- (void)selectRow:(int)row byExtendingSelection:(BOOL) extending scrolling:(BOOL) scroll;

/*!
 * @method selectColumn:
 * @abstract select an entire column
 * @discussion description forthcoming
 * @param column integer column index
 */
- (void)selectColumn:(int)column;
- (void)selectColumn:(int)column byExtendingSelection:(BOOL) extending scrolling:(BOOL) scroll;

/*!
 * @method selectCell:
 * @abstract deselect a cell
 * @discussion description forthcoming
 * @param aCell cell to deselect
 */
- (void)deselectCellAtPosition:(RRPosition*)aCellPosition;

/*!
 * @method deselectCellAtRow:column:
 * @abstract deselect a cell by row/column
 * @discussion description forthcoming
 * @param row integer row index
 * @param column integer column index
 */
- (void)deselectCellAtRow:(int)row column:(int)column;

/*!
 * @method deselectAllCells
 * @abstract deselect all currently selected cells
 * @discussion description forthcoming
 */
- (void)deselectAllCells;

/*!
 * @method deselectSelectedCell
 * @abstract deselect the last selected cell
 * @discussion description forthcoming
 */
- (void)deselectSelectedCell;

/*!
 * @method deselectRow:
 * @abstract deselect all cells in a row
 * @discussion description forthcoming
 * @param row integer row index
 */
- (void)deselectRow:(int)row;

/*!
 * @method deselectColumn:
 * @abstract deselect all cells in a column
 * @discussion description forthcoming
 * @param column integer column index
 */
- (void)deselectColumn:(int)column;

/*!
 * @method rows
 * @abstract return all rows in the worksheet
 * @discussion description forthcoming
 * @result an NSArray holding all of the rows in the worksheet
 */
- (NSArray*) rows;

/*!
 * @method resizeRow:range:
 * @abstract resize a row vertically
 * @discussion description forthcoming
 * @param index index of the row to resize
 * @param range an RRFloatRange holding the new location and length of the row
 */
- (void) resizeRow:(unsigned int)index range:(RRFloatRange)range;

/*!
 * @method rowHeightForContents:
 * @abstract return the row height
 * @discussion description forthcoming
 * @param row integer index of the row
 */
- (float) rowHeightForContents:(unsigned int)row;


/*!
 * @method columns
 * @abstract return an array holding all of the columns in the worksheet
 * @discussion description forthcoming
 * @result returns and NSArray holding all of the columns in the worksheet
 */
- (NSArray*)columns;

/*!
 * @method resizeColumn:range:
 * @abstract resize column to new range
 * @discussion description forthcoming
 * @param column integer index of column to resize
 * @param range RRFloatRange holding new location and length for column
 */
- (void) resizeColumn:(unsigned int)column range:(RRFloatRange)range;

/*!
 * @method columnWidthForContents:
 * @abstract return the width of a column
 * @discussion description forthcoming
 * @param column integer index of column
 * @result width of the column
 */
- (float) columnWidthForContents:(unsigned int)column;

/*!
 * @method setRulerForSelectionFocus:
 * @abstract sets the ruler that should have selection focus
 * @discussion description forthcoming
 * @param ruler the ruler to receive selection focus
 */
- (void)setRulerForSelectionFocus:(RRSSRulerView*)ruler;

/*!
 * @method cellPositionForEvent:
 * @abstract return an RRPosition holding the row/column position for an event
 * @discussion description forthcoming
 * @param theEvent the event you are interested in
 * @result an RRPosition object holding the row/column within which <i>theEvent</i> occured
 */
- (RRPosition*)cellPositionForEvent:(NSEvent*)theEvent;

    // drawing optimization routines

/*!
 * @method updateDirtyRangesForRect:
 * @abstract compute the row/column ranges within rect
 * @discussion description forthcoming
 * @param rect dirty NSRect 
 */
- (void)updateDirtyRangesForRect:(NSRect)rect;

/*!
 * @method updateVisibleRangesForRect:
 * @abstract compute the visible rows/columns inthe worksheet
 * @discussion description forthcoming
 * @param rect visible NSRect
 */
- (void)updateVisibleRangesForRect:(NSRect)rect;

/*!
 * @method rangeForArray:inFloatRange
 * @abstract return the range of row/column indecies that cover the viewable range
 * @discussion This method returns the range of row or column indicies which are known
 * to cover the visible bounds specified in <i>range</i>. This method is used to determine
 * which rows or columns are currently visible.
 * @param array an array holding either the list of row or column headers
 * @param range the visible range we are interested in
 * @result NSRange with the range of headers covering <i>range</i>
 */
- (NSRange)rangeForArray:(NSArray*)array inFloatRange:(RRFloatRange)range;

/*!
 * @method indexOfObjectInArray:forLocation:
 * @abstract return the index of a row/column in an array based on its location
 * @discussion description forthcoming
 */
- (int)indexOfObjectInArray:(NSArray*)array forLocation:(float)location;

/*!
 * @method dirtyRowRange
 * @abstract return the range of dirty rows
 * @discussion description forthcoming
 */
- (NSRange)dirtyRowRange;

/*!
 * @method visibleRowRange
 * @abstract return the range of visible rows
 * @discussion description forthcoming
 */
- (NSRange)visibleRowRange;

/*!
 * @method dirtyColumnRange
 * @abstract return the range of dirty columns
 * @discussion description forthcoming
 */
- (NSRange)dirtyColumnRange;

/*!
 * @method visibleColumnRange
 * @abstract return the range of visible columns
 * @discussion description forthcoming
 */
- (NSRange)visibleColumnRange;

/*!
 * @method visibleCellPositions
 * @abstract return the visible cell positions
 * @discussion description forthcoming
 */
- (NSArray*)visibleCellPositions;

/*!
 * @method visibleRows
 * @abstract return the visible rows
 * @discussion description forthcoming
 */
- (NSArray*)visibleRows;

/*!
 * @method visibleColumns
 * @abstract return the visible columns
 * @discussion description forthcoming
 */
- (NSArray*)visibleColumns;

/*!
 * @method visibleFrameForRect:
 * @abstract return the visible portion of a rectangle
 * @discussion description forthcoming
 */
- (NSRect)visibleFrameForRect:(NSRect)rect;

/*!
 * @method updateMarkers
 * @abstract get the worksheet to update the ruler markers
 * @discussion description forthcoming
 */
- (void)updateMarkers;

// dataSource routines

/*!
 * @method setDataSource:
 * @abstract the the worksheet datasource
 * @discussion set the data source for the worksheet. The datasource must implement
 * the RRSpreadSheetDataSource as defined in RRSpreadSheet
 * @param ds the new worksheet data source
 */
- (void)setDataSource:(id)ds;

/*!
 * @method dataSource
 * @abstract return the datasource for this worksheet
 * @discussion This method retuns the current datasource object
 * for this worksheet
 * @result the worksheet's current datasource object
 */
- (id)dataSource;

/*!
 * @method delegate
 * @abstract return the delegate for this worksheet
 * @discussion This method retuns the current delegate object
 * for this worksheet
 * @result the worksheet's current delegate object
 */
- (id) delegate;


/*!
* @method setDelegate:
* @abstract the the worksheet delegate
* @discussion set the delegate for the worksheet. The delegate must implement
* the RRSpreadSheetDelegate as defined in RRSpreadSheet
* @param ds the new worksheet delegate
*/
- (void) setDelegate:(id)newDelegate;


/*!
 * @method reloadWorksheetData
 * @abstract reload all worksheet cells
 * @discussion This method causes the worksheet to query its
 * data source for the object values for all its cells and redisplay
 */
- (void)reloadWorksheetData;

/*!
 * @method reloadCellDataAtRow:column:
 * @abstract reload the data for a cell
 * @discussion This method causes the worksheet to poll its data source
 * for the contents of cell <i>row</i>/<i>column</i> and display the value
 * received.
 * @param row integer row index
 * @param column integer column index
 */
- (void)reloadCellDataAtRow:(int)row column:(int)column;

/*!
 * @method clearWorksheet
 * @abstract clear the content of every cell
 * @discussion description forthcoming
 */
- (void)clearWorksheet;

/*!
* @method clearCellsAtOpsitions:
* @abstract clear the content of the cell at the positions in cellPosition
* @discussion description forthcoming
* @param an array of RRPosition
*/
- (void)clearCellsAtPositions: (NSArray*) cellPosition;
@end

