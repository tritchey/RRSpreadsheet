//
//  RRSpreadSheetPalette.h
//  RRSpreadSheet
//
//  Created by Timothy Ritchey on Tue Apr 02 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import <InterfaceBuilder/InterfaceBuilder.h>
#import <RRSpreadSheet/RRSpreadSheet.h>

@interface RRSpreadSheetPalette : IBPalette
{
    IBOutlet RRSpreadSheet *view;
}
@end

@interface RRSpreadSheet (RRSpreadSheetPaletteInspector)
- (NSString *)inspectorClassName;
@end
