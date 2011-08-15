//
//  RRFloatRange.h
//  µ
//
//  Created by Timothy Ritchey on Mon Feb 11 2002.
//  Copyright (c) 2001 Timothy Ritchey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct _RRFloatRange {
    float location;
    float length;
} RRFloatRange;

typedef RRFloatRange *RRFloatRangePointer;

FOUNDATION_STATIC_INLINE RRFloatRange RRMakeFloatRange(float loc, float len) {
    RRFloatRange r;
    r.location = loc;
    r.length = len;
    return r;
}

FOUNDATION_STATIC_INLINE RRFloatRange RRMakeFloatRangeFromRange(NSRange r) {
    return RRMakeFloatRange(r.location, r.length);
}

FOUNDATION_STATIC_INLINE float RRMaxFloatRange(RRFloatRange range) {
    return (range.location + range.length);
}

FOUNDATION_STATIC_INLINE BOOL RRLocationInFloatRange(float loc, RRFloatRange range) {
    return (loc >= range.location && loc <= RRMaxFloatRange(range));
}

FOUNDATION_STATIC_INLINE BOOL RREqualFloatRanges(RRFloatRange range1, RRFloatRange range2) {
    return (range1.location == range2.location && range1.length == range2.length);
}

FOUNDATION_STATIC_INLINE BOOL RRFloatRangesOverlap(RRFloatRange range1, RRFloatRange range2) {
    return (RRLocationInFloatRange(range1.location, range2) || RRLocationInFloatRange(range2.location, range1));
}

FOUNDATION_EXPORT RRFloatRange RRUnionFloatRange(RRFloatRange range1, RRFloatRange range2);
FOUNDATION_EXPORT RRFloatRange RRIntersectionFloatRange(RRFloatRange range1, RRFloatRange range2);

