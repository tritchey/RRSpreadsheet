/* RRSpreadSheet */

#import <Cocoa/Cocoa.h>

@class RRSSWorksheet;

/*!
 * @class RRSpreadSheet
 * @abstract The spreadsheet control class
 * @discussion The RRSpreadSheet class provides the management of multiple worksheet
 * objects, as well as management of the row/column headers. The RRSpreadSheet class
 * is a subclass of NSScrollView.
 */
@interface RRSpreadSheet : NSScrollView
{
    id cornerView;
    id upperRightView;
    id lowerLeftView;
    NSMutableDictionary *worksheets;
}
/*!
* @method setCornerView:
 * @abstract Set the upper left corner view of the spreadsheet
 * @discussion Use this method to change the upper left corner of the spreadsheet to a custom view
 * @param aView the view to be placed in the upper left corner
 */
- (void)setCornerView:(NSView*)aView;

/*!
 * @method cornerView
 * @abstract returns the upper left view of the spreadsheet
 * @result returns the corner view of the spreadsheet
 */
- (NSView*)cornerView;

/*!
 * @method setUpperRightView:
 * @abstract set the upper right corner view of the spreadsheet
 * @discussion Use this method to change the upper right corner of the spreadsheet to a custom view
 * @param aView the view to be used as the upper right corner of the spreadsheet
 */
- (void)setUpperRightView:(NSView*)aView;

/*!
 * @method upperRightView
 * @abstract returns the upper right view of the spreadsheet
 * @discussion this method returns the view being used to fill the upper right corner of the spreadsheet
 * @result returns the upper right view of the spreadsheet
 */
- (NSView*)upperRightView;

/*!
 * @method setLowerLeftView:
 * @abstract set the lower left corner view of the spreadsheet
 * @discussion Use this method to change the lower left corner of the spreadsheet to a custom view
 * @param aView the view to be used as the lower left corner of the spreadsheet
 */
- (void)setLowerLeftView:(NSView*)aView;

/*!
 * @method lowerLeftView
 * @abstract returns the lower left view of the spreadsheet
 * @discussion this method returns the view being used to fill the lower left corner of the spreadsheet
 * @result returns the lower left view of the spreadsheet
 */
- (NSView*)lowerLeftView;

// data source selectors

/*!
 * @method newWorksheet:
 * @abstract create a new worksheet
 * @discussion This method creates and returns a new worksheet after setting
 * it as the current worksheet of the spreadsheet
 * @param label an NSString* holding the name of the new worksheet
 * @result returns the new worksheet
 */
- (id)newWorksheet:(NSString*)label;

/*!
 * @method currentWorksheet
 * @abstract returns the current worksheet
 * @discussion returns the worksheet currently being displayed by the spreadsheet
 * @result returns the current worksheet object
 */
- (id)currentWorksheet;

/*!
 * @method setCurrentWorksheet:
 * @abstract set the current worksheet object
 * @discussion tells the spreadsheet to set the 'worksheet' object as the
 * currently displayed worksheet in the spreadsheet view
 * @param worksheet the RRSSWorksheet object to become the current worksheet
 */
- (void)setCurrentWorksheet:(RRSSWorksheet*)worksheet;

/*!
 * @method setupRulers
 * @abstract set up the rulers for the spreadsheet object
 * @discussion internal method used to create and set up the rulers for the spreadsheet object
 */
- (void)setupRulers;

/*!
 * @method setupCornerViews
 * @abstract set up the corner views for the spreadsheet object
 * @discussion internal method used to create and set up the corner views for the spreadsheet object
 */
- (void)setupCornerViews;

/*!
 * @method setHeaderLabelsEditable:
 * @abstract set editability of header labels
 * @discussion this method determines whether the user is able to edit the
 * header labels of the rows and columns of the spreadsheet
 * @param editable YES = headers can be edited, NO = header cannot be edited
 */ 
- (void)setHeaderLabelsEditable:(BOOL)editable;

/*!
 * @method headerLabelsEditable
 * @abstract get the editability of header labels
 * @discussion returns a boolean value indicating whether the row and column
 * header labels are editable
 * @result returns a BOOL, YES = headers can be edited, NO = headers cannot be edited
 */
- (BOOL)headerLabelsEditable;

@end

/*!
 * @category NSObject(RRSpreadSheetDataSource)
 * @abstract RRSpreadSheet DataSource informal protocol
 * @discussion This is the informal protocol that spreadsheet
 * data sources must implement. Note that each worksheet can have a different
 * data source object
 */
@interface NSObject(RRSpreadSheetDataSource)

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
- (int)numberOfRowsInWorksheet:(RRSSWorksheet*)worksheet;

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
- (int)numberOfColumnsInWorksheet:(RRSSWorksheet*)worksheet;

/*!
 * @method worksheet:objectValueForRow:column:
 * @abstract returns the value of a worksheet cell for a row/column
 * @discussion This method is called by the worksheet on the data source to determine
 * the value of a cell. The current implementation expects an NSString object from the
 * data source
 * @param worksheet the worksheet requesting the row/column value
 * @param row the row of the needed object value
 * @param col the column of the needed object value
 * @result the data source should return the value of the cell at the given row and column.
 * The current implementation expects an NSString object.
 */
- (id)worksheet:(RRSSWorksheet*)worksheet objectValueForRow:(unsigned int)row column:(int)col;

/*!
 * @method worksheet:headerLabelForRow:
 * @abstract return the label for a row
 * @discussion this method is used to ask the datasource for the label
 * for the header of specific rows. If this method is not implemented
 * by the datasource, the worksheet will use default header labels
 * @param row this is an integer holding the row number of the header
 * @result the data source must return an NSString holding the label
 * for the header.
 */
- (NSString*)worksheet:(RRSSWorksheet*)worksheet headerLabelForRow:(int)row;

/*!
 * @method worksheet:headerLabelForColumn:
 * @abstract return the label for a column
 * @discussion this method is used to ask the datasource for the label
 * for the header of specific columns. If this method is not implemented
 * by the datasource, the worksheet will use default header labels
 * @param row this is an integer holding the row number of the header
 * @result the data source must return an NSString holding the label
 * for the header.
 */
- (NSString*)worksheet:(RRSSWorksheet*)worksheet headerLabelForColumn:(int)col;

/*!
 * @method worksheet:setHeaderLabel:forRow:
 * @abstract tell the datasource that a row header label has changed
 * @discussion this method is used by the worksheet to tell its datasource
 * when the label for a header has changed
 * @param worksheet the calling worksheet
 * @param label the new header label
 * @param row the header's row index
 */
- (void)worksheet:(RRSSWorksheet*)worksheet setHeaderLabel:(NSString*)label forRow:(int)row;

/*!
 * @method worksheet:setHeaderLabel:forColumn:
 * @abstract tell the datasource that a column header label has changed
 * @discussion this method is used by the worksheet to tell its datasource
 * when the label for a header has changed
 * @param worksheet the calling worksheet
 * @param label the new header label
 * @param column the header's column index
 */
- (void)worksheet:(RRSSWorksheet*)worksheet setHeaderLabel:(NSString*)label forColumn:(int)column;

/*!
 * @method worksheet:setObjectValue:forRow:column:
 * @abstract tell the datasource that a cell value has changed
 * @discussion this method is used by the worksheet to tell its datasource
 * when the value of a cell has changed
 * @param worksheet the calling worksheet
 * @param object the new object for the cell
 * @param row the cell's row
 * @param column the cell's column
 */
- (void)worksheet:(RRSSWorksheet*)worksheet setObjectValue:(id)object forRow:(int)row column:(int)col;

/*!
 * @method worksheet:writeCells:toPasteboard:
 * @abstract documentation forthcoming
 */
- (BOOL)worksheet:(RRSSWorksheet*)worksheet writeCellsAtPositions:(NSArray*)cellsPositions toPasteboard:(NSPasteboard*)pboard;

/*!
 * @method worksheet:validateDrop:proposedRow:column:proposedDropOperation:
 * @abstract documentation forthcoming
 */
- (NSDragOperation)worksheet:(RRSSWorksheet*)worksheet validateDrop:(id <NSDraggingInfo>)info
                   proposedRow:(int)row column:(int)col proposedDropOperation:(NSTableViewDropOperation)op;

/*!
 * @method worksheet:acceptDrop:row:column:dropOperation:
 * @abstract documentation forthcoming
 */
- (BOOL)worksheet:(RRSSWorksheet*)worksheet acceptDrop:(id <NSDraggingInfo>)info
              row:(int)row column:(int)col dropOperation:(NSTableViewDropOperation)op;
/*!
* @method worksheet:paste:atRow:column:
* @abstract ask the datasource if a specific menu item should be enabled
* @discussion give a shot to the delegate to enable or disable a menu item
*
*/
- (void) worksheet:(RRSSWorksheet*) worksheet paste: (NSPasteboard*) pBoard atRow:(int) row column: (int)column;


    /*!
* @method worksheet:willDrawCell:forRow:column:
     * @abstract let the datasource know that the control will draw the cell
     * @discussion set any attribute to the cell for drawing purposes
     */
- (void)worksheet:(RRSSWorksheet*)worksheet willDrawCell:(NSCell*) cell forRow:(int) row column:(int) column;
@end

@interface NSObject(RRSpreadSheetDelegate)
/*!
* @method worksheetShouldAddRow:worksheet
* @abstract ask the data source if a row can be added
*/
- (BOOL)worksheetShouldAddRow:(RRSSWorksheet*)worksheet;

/*!
* @method worksheetShouldAddColumn:worksheet
* @abstract ask the data source if a column can be added
*/
- (BOOL)worksheetShouldAddColumn:(RRSSWorksheet*)worksheet;

/*!
* @method worksheetShouldAddRow:worksheet
* @abstract ask the data source if a row can be removed
*/
- (BOOL)worksheet:(RRSSWorksheet*)worksheet shouldRemoveRow: (int)row;

/*!
* @method worksheetShouldAddColumn:worksheet
* @abstract ask the data source if a column can be removed
*/
- (BOOL)worksheet:(RRSSWorksheet*)worksheet shouldRemoveColumn: (int)col;

/*!
* @method worksheetAddRow:worksheet
* @abstract tell the data source to create a row
* @discussion give a shot to the data source to create the row if the data source return NO or does not
* implement this, the row is created by the Spreadsheet. To prevent the creation of the row, respond to
* - (BOOL)worksheetShouldAddRow:(RRSSWorksheet*)worksheet; and return NO
*
*/
- (void)worksheetAddRow:(RRSSWorksheet*)worksheet;

/*!
* @method worksheetAddColumn:worksheet
* @abstract tell the data source to create a column
* @discussion give a shot to the data source to create the column if the data source return NO or does not
* implement this, the column is created by the Spreadsheet. To prevent the creation of the column, respond to
* - (BOOL)worksheetShouldAddColumn:(RRSSWorksheet*)worksheet; and return NO
*
*/
- (void)worksheetAddColumn:(RRSSWorksheet*)worksheet;

/*!
* @method worksheet:removeRow:
* @abstract tell the data source to delete a row
* @discussion give a shot to the data source to delete the row if the data source return NO or does not
* implement this, the row is removed by the Spreadsheet. To prevent the deletion of the row, respond to
* - (BOOL)worksheet:(RRSSWorksheet*)worksheet shouldRemoverRow: (int)row; and return NO
*
*/
- (BOOL)worksheet:(RRSSWorksheet*)worksheet removeRow: (int)row;

/*!
* @method worksheet:removeColumn:
* @abstract tell the data source to delete a column
* @discussion give a shot to the data source to delete the column if the data source return NO or does not
* implement this, the column is removed by the Spreadsheet. To prevent the deletion of the column, respond to
* - (BOOL)worksheet:(RRSSWorksheet*)worksheet shouldRemoveColumn: (int)col; and return NO
*
*/
- (BOOL)worksheet:(RRSSWorksheet*)worksheet removeColumn: (int)col;

/*!
* @method worksheet:complete:forRow:column:
* @abstract tell the delegate that a complete request has been posted for the cell at row and column with the start given in objectTocomplete
* @discussion give a shot to the delegate to complete the given object
*
*/
- (id) worksheet:(RRSSWorksheet*) worksheet complete: (id)objectToComplete forRow: (int) row column:(int) column;

/*!
* @method worksheet:setCornerLabel:
 * @abstract let the delegate get a chance to change the text displayed in the corner
 * @discussion this method should be implemented by the delegate if it wishes to alter the text didplayed in the upper left-hand corner of the worksheet.
 */
- (id) worksheet:(RRSSWorksheet*)worksheet setCornerLabel:(NSString*)label;

/*!
* @method worksheet:validatePasteMenuItem:proposedInsertionLocation:
* @abstract ask the delegate if the paste menu should ne enable
* @discussion give a shot to the delegate to enable or disable the paste menu
*
*/
- (BOOL) worksheet:(RRSSWorksheet*) worksheet validatePasteMenuItem: (id <NSMenuItem>)menuItem atRow:(int) row column: (int)column;
@end
