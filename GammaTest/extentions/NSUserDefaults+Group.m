//
//  NSUserDefaults+Group.m
//  GammaTest
//
//  Created by Arthur Hammer on 28.10.15.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import "NSUserDefaults+Group.h"

@implementation NSUserDefaults (Group)

+ (NSUserDefaults *)groupDefaults {
    NSString *suitName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppGroupIdentifier"];
    return [[NSUserDefaults alloc] initWithSuiteName:suitName];
}

@end
