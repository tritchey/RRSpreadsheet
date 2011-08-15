//
//  RRPosition.m
//  µ
//
//  Created by Timothy Ritchey on Tue Feb 19 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import "RRPosition.h"

@implementation RRPosition

+ (RRPosition*)positionForRow:(int)r column:(int)c
{
    return [[RRPosition alloc] initWithRow:r column:c];
}

- initWithRow:(int)r column:(int)c
{
    if(self = [super init])
    {
        [self setRow:r];
        [self setColumn:c];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[RRPosition allocWithZone:zone] initWithRow:[self row] column:[self column]];
}

- (void)dealloc
{
    [row release];
    [column release];
    [super dealloc];
}

- (int)row
{
    return [row intValue];
}

- (void)setRow:(int)r
{
    [row autorelease];
    row = [[NSNumber numberWithInt:r] retain];
}

- (int)column
{
    return [column intValue];
}

- (void)setColumn:(int)c
{
    [column autorelease];
    column = [[NSNumber numberWithInt:c] retain];
}

- (BOOL)isEqual:(id)object
{
    return ( ([object row] == [self row]) &&  ([object column] == [self column]) );    
}

- (NSComparisonResult)compare:(id) otherPosition
{
    NSComparisonResult theResult = NSOrderedSame;

    if ([self row] < [otherPosition row])
    {
        theResult = NSOrderedAscending;
    }
    else if ([self row] > [otherPosition row])
    {
        theResult = NSOrderedDescending;
    }
    else if ([self row] == [otherPosition row])
    {
        if ([self column] < [otherPosition column])
        {
            theResult = NSOrderedAscending;
        }
        else if ([self column] > [otherPosition column])
        {
            theResult = NSOrderedDescending;
        }
    }
    return theResult;
}

- (unsigned)hash
{
    return [self row] * 100000 + [self column];
}

- (NSString*) description
{
     return [NSString stringWithFormat: @"col: %i, row: %i", [self column], [self row]];
}
@end

