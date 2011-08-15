//
//  RRSpreadSheetPalette.m
//  RRSpreadSheet
//
//  Created by Timothy Ritchey on Tue Apr 02 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import "RRSpreadSheetPalette.h"

@implementation RRSpreadSheetPalette

- (void)finishInstantiate
{
    [(RRSpreadSheet*)view newWorksheet:@""];
}

@end

@implementation RRSpreadSheet (RRSpreadSheetPaletteInspector)

- (NSString *)inspectorClassName
{
    return @"RRSpreadSheetInspector";
}

@end
