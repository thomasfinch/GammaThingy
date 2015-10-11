//
//  BackgroundFetchController.h
//  GammaTest
//
//  Created by Casper Eekhof on 11/10/2015.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BackgroundFetchController : NSObject

+ (void)switchScreenTemperatureBasedOnLocation:(NSUserDefaults*)defaults;
+ (void)switchScreenTemperatureBasedOnTime:(NSUserDefaults*)defaults;

@end
