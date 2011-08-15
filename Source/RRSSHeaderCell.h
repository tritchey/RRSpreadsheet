//
//  RRSSHeaderCell.h
//  µ
//
//  Created by Timothy Ritchey on Mon Feb 18 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RRSSCell.h"


@interface RRSSHeaderCell : NSButtonCell
{
    NSRulerOrientation orientation;
    NSImage *rowHighlightedTab;
    NSImage *columnHighlightedTab;
}
- (void)setOrientation:(NSRulerOrientation)orient;
@end
