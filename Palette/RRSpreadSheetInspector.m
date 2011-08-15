//
//  RRSpreadSheetInspector.m
//  RRSpreadSheet
//
//  Created by Timothy Ritchey on Tue Apr 02 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "RRSpreadSheetInspector.h"

@implementation RRSpreadSheetInspector

- (id)init
{
    self = [super init];
    [NSBundle loadNibNamed:@"RRSpreadSheetInspector" owner:self];
    return self;
}

- (void)ok:(id)sender
{
	/* Your code Here */
    [super ok:sender];
}

- (void)revert:(id)sender
{
	/* Your code Here */
    [super revert:sender];
}

@end
