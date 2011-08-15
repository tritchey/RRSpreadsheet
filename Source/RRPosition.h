//
//  RRPosition.h
//  µ
//
//  Created by Timothy Ritchey on Tue Feb 19 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RRPosition : NSObject
{
    NSNumber *row;
    NSNumber *column;
}
+ (RRPosition*)positionForRow:(int)r column:(int)c;
- initWithRow:(int)r column:(int)c;
- (id)copyWithZone:(NSZone *)zone;
- (int)row;
- (void)setRow:(int)r;
- (int)column;
- (void)setColumn:(int)c;
@end

