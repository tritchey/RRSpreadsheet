//
//  RRDefaultDataSource.h
//  RRSpreadSheet
//
//  Created by otusweb on Thu Oct 17 2002.
//  Copyright (c) 2002 Texas Instruments Incorporated. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RRPosition;

@interface RRDefaultDataSource : NSObject
{
    int rowCount;
    int columnCount;
    NSMutableDictionary *theCellValue;
    NSMutableDictionary *columnHeaders;
    NSMutableDictionary *rowHeaders;
    NSMutableDictionary *copiedCells;
}
- (id) objectValueForKey: (RRPosition*) aCellPosition;
@end
