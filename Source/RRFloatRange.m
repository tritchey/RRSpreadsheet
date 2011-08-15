//
//  RRFloatRange.m
//  µ
//
//  Created by Timothy Ritchey on Mon Feb 11 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import "RRFloatRange.h"


FOUNDATION_EXPORT RRFloatRange RRUnionFloatRange(RRFloatRange range1, RRFloatRange range2)
{
    float max1, max2;
    RRFloatRange r;
    r.location = 0;
    r.length = 0;
    if(RRLocationInFloatRange(range1.location, range2) || RRLocationInFloatRange(range2.location, range1))
        r.location = range2.location < range1.location ?  range2.location : range1.location;
    else
        return r;
    max1 = RRMaxFloatRange(range1);
    max2 = RRMaxFloatRange(range2);
    r.length = (max1 >= max2 ? max1 - r.location : max2 - r.location); 
    return r;
    
}

FOUNDATION_EXPORT RRFloatRange RRIntersectionFloatRange(RRFloatRange range1, RRFloatRange range2)
{
    RRFloatRange r;
    float max1, max2;
    if(RRLocationInFloatRange(range1.location, range2) || RRLocationInFloatRange(range2.location, range1))
        r.location = range2.location < range1.location ?  range2.location : range1.location;
    else
        return r;

    max1 = RRMaxFloatRange(range1);
    max2 = RRMaxFloatRange(range2);
    r.location = range1.location >= range2.location ? range1.location : range2.location;
    r.length = r.location - (max1 <= max2 ? max1 : max2);
    return r;
    
}
