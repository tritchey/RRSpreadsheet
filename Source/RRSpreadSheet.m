
#import "RRSpreadSheet.h"
#import "RRSSRulerView.h"
#import "RRSSWorksheet.h"

@implementation RRSpreadSheet

+ (void)initialize
{
    static BOOL beenHere = NO;
    if (beenHere) return;
    beenHere = YES;

    // set default ruler
    [RRSpreadSheet setRulerViewClass:[RRSSRulerView class]];
    
    return;
}

- (id)initWithFrame:(NSRect)rect
{
  
    if(self = [super initWithFrame:rect]) {

        [self setupRulers];

        [self setupCornerViews];

        worksheets = [[NSMutableDictionary alloc] init];

        // turn on the rulers
        [self setRulersVisible:YES];

    }
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{

    if(self = [super initWithCoder:coder]) {
        // turn on the rulers
        [self setupRulers];

        // create the corners of the control
        [self setupCornerViews];

        worksheets = [[NSMutableDictionary alloc] init];
        
        // make the rulers visible
        [self setRulersVisible:YES];

        [[self newWorksheet:@"ib"] setFrame:[self frame]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [super encodeWithCoder:coder];        
}

- (void)awakeFromNib
{

    if(![worksheets count])
        [self newWorksheet:@""];
    else {
        NSEnumerator *e = [worksheets keyEnumerator];
        NSString *key;
        
        while (key = [e nextObject]) {
            if([key isEqualTo:@"ib"] && ([worksheets count] == 1)) {
                [worksheets removeAllObjects];
                [self newWorksheet:@""];
            }
        }
        [self setCurrentWorksheet:[worksheets objectForKey:key]];
    }
}

- (void)setupRulers
{
    // lets set up the scroll view and rulers now
    [self setHasHorizontalRuler:YES];
    [self setHasVerticalRuler:YES];
    [self setHasHorizontalScroller:YES];
    [self setHasVerticalScroller:YES];

    [[self horizontalRulerView] setRuleThickness:0.0];
    [[self verticalRulerView] setRuleThickness:0.0];
}

- (void)setupCornerViews
{
    // we are trying to create a corner view here.
    cornerView = [[NSButton alloc] initWithFrame:NSMakeRect(0,0, 0,0)];
    [cornerView setButtonType:NSMomentaryPushInButton];
    [cornerView setBezelStyle:NSShadowlessSquareBezelStyle];
    [cornerView setTitle:@""];
    [self setCornerView:cornerView];

    upperRightView = [[NSButton alloc] initWithFrame:NSMakeRect(0,0, 0,0)];
    [upperRightView setButtonType:NSMomentaryPushInButton];
    [upperRightView setBezelStyle:NSShadowlessSquareBezelStyle];
    [upperRightView setImagePosition:NSImageOnly];
    [upperRightView setEnabled:NO];
    [self setUpperRightView:upperRightView];

    lowerLeftView = [[NSButton alloc] initWithFrame:NSMakeRect(0,0, 0,0)];
    [lowerLeftView setButtonType:NSMomentaryPushInButton];
    [lowerLeftView setBezelStyle:NSShadowlessSquareBezelStyle];
    [lowerLeftView setImagePosition:NSImageOnly];
    [lowerLeftView setEnabled:NO];
    [self setLowerLeftView:lowerLeftView];
}

- (void)setDocumentView:(NSView*)aView
{
    NSSize cellSize;
    id ruler;
    id doc = aView;
    
    if([aView isKindOfClass:[RRSSWorksheet class]])
    {
        [super setDocumentView:doc];
        cellSize = [doc cellSize];
        // adjust for the trim
        cellSize.width += 6;
        cellSize.height += 6;
        
        // set up rulers
        // horizontal ruler
        ruler = [self horizontalRulerView];
        [ruler setReservedThicknessForMarkers:cellSize.height];
        [ruler setClientView:aView];
        // vertical ruler
        ruler = [self verticalRulerView];
        [ruler setReservedThicknessForMarkers:cellSize.width];
        [ruler setClientView:aView];

        // adjust the corner marker
        [cornerView setFrame:NSMakeRect(0,0,cellSize.width, cellSize.height)];

        [self tile];

        //[doc updateMarkers];
        [doc updateVisibleRangesForRect:[self frame]];
        [doc reloadWorksheetData];
    }

}

- (void)setCornerView:(NSView*)aView
{
    [cornerView removeFromSuperview];
    cornerView = aView;
    [self addSubview:cornerView];
}

- (NSView*)cornerView
{
    return cornerView;
}

- (void)setUpperRightView:(NSView*)aView
{
    [upperRightView removeFromSuperview];
    upperRightView = aView;
    [self addSubview:upperRightView];
}

- (NSView*)upperRightView
{
    return upperRightView;
}

- (void)setLowerLeftView:(NSView*)aView
{
    [lowerLeftView removeFromSuperview];
    lowerLeftView = aView;
    [self addSubview:lowerLeftView];
}

- (NSView*)lowerLeftView
{
    return lowerLeftView;
}

- (void)tile
{
    // we have nine views to set up;
    NSRect cornerRect = [cornerView frame];
    NSRect horizRulerRect = [[self horizontalRulerView] frame];
    NSRect urCornerRect = [upperRightView frame];
    NSRect vertRulerRect = [[self horizontalRulerView] frame];
    NSRect vertScrollerRect = [[self verticalScroller] frame];
    NSRect llCornerRect = [lowerLeftView frame];
    NSRect horizScrollerRect = [[self horizontalScroller] frame];

    NSRect rect = [self frame];
    [super tile];
    [self setRulersVisible:YES];

    // put our corner marker in the corner (shocking!)
    // leave it to its size
    cornerRect.origin = NSMakePoint(0,0);
    [cornerView setFrameOrigin:cornerRect.origin];

    // move the horizontal ruler over to make room
    horizRulerRect.origin = NSMakePoint(cornerRect.size.width, 0);
    horizRulerRect.size.width = rect.size.width - cornerRect.size.width - vertScrollerRect.size.width;
    horizRulerRect.size.height = cornerRect.size.height;
    [[self horizontalRulerView] setFrame:horizRulerRect];

    // set upper right view
    urCornerRect.origin = NSMakePoint(horizRulerRect.origin.x + horizRulerRect.size.width, 0);
    urCornerRect.size = NSMakeSize(vertScrollerRect.size.width, cornerRect.size.height);
    [upperRightView setFrame:urCornerRect];
    
    // set vertical ruler
    vertRulerRect.size.height =  rect.size.height - cornerRect.size.height - horizScrollerRect.size.height;
    vertRulerRect.size.width = cornerRect.size.width;
    vertRulerRect.origin = NSMakePoint(0, cornerRect.size.height);
    [[self verticalRulerView] setFrame:vertRulerRect];

    // set clip view
    // NOT NEEDED
    //    clipRect.origin = NSMakePoint(cornerRect.size.width, cornerRect.size.height);
//    clipRect.size = NSMakeSize(horizRulerRect.size.width, vertRulerRect.size.height);
//    [[self contentView] setFrame:clipRect];
    
    // set vert scroll
    // NOT NEEDED
//    vertScrollerRect.size.height = vertRulerRect.size.height;
//    vertScrollerRect.origin = NSMakePoint(rect.size.width - vertScrollerRect.size.width, vertRulerRect.origin.y);
//    [[self verticalScroller] setFrame:vertScrollerRect];

    // lower left
    llCornerRect.origin = NSMakePoint(0, rect.size.height - horizScrollerRect.size.height);
    llCornerRect.size = NSMakeSize(cornerRect.size.width, horizScrollerRect.size.height);
    [lowerLeftView setFrame:llCornerRect];
    // horiz scroll
    
    
    [self setNeedsDisplayInRect:rect];

}

- (void)setFrameOrigin:(NSPoint)frameOrigin
{
    [super setFrameOrigin:frameOrigin];
    [(RRSSWorksheet*)[self documentView] setFrameOrigin:frameOrigin];
}

- (void)setFrameSize:(NSSize)frameSize
{
    NSSize docSize = [[self documentView] frame].size;
    [super setFrameSize:frameSize];
    docSize.width = docSize.width >= frameSize.width ? docSize.width : frameSize.width;
    docSize.height = docSize.height >= frameSize.height ? docSize.height : frameSize.height;
 
    [(RRSSWorksheet*)[self documentView] setFrameSize:docSize];
}

- (id)newWorksheet:(NSString*)label;
{
    RRSSWorksheet* worksheet = [[RRSSWorksheet alloc] initWithFrame:[self frame]];
    [worksheets setObject:worksheet forKey:label];
    [self setDocumentView:worksheet];
    return [worksheet autorelease];
}

- (id)currentWorksheet
{
    return [self documentView];
}

- (void)setCurrentWorksheet:(RRSSWorksheet*)worksheet
{
    [self setDocumentView:worksheet];
}

- (void)setHeaderLabelsEditable:(BOOL)editable
{
    [(RRSSRulerView*)[self horizontalRulerView] setEditable:editable];
    [(RRSSRulerView*)[self verticalRulerView] setEditable:editable];
}

- (BOOL)headerLabelsEditable
{
    return [(RRSSRulerView*)[self horizontalRulerView] isEditable];
}

- (void)dealloc
{
    [cornerView release];
    [upperRightView release];
    [lowerLeftView release];
    [worksheets release];
    [super dealloc];
}


@end