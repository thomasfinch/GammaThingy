//
//  NSDate_NSDate_compare.h
//  GammaTest
//
//  Created by Casper Eekhof on 16/10/2015.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (e)
- (BOOL)isEarlierThan:(NSDate*)b;
- (BOOL)isLaterThan:(NSDate*)b;
@end

@implementation NSDate (e)
- (BOOL)isEarlierThan:(NSDate*)b{
    return [self earlierDate:b] == self;
}

- (BOOL)isLaterThan:(NSDate*)b{
    return [self laterDate:b] == self;
}
@end
