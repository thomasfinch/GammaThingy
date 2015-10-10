//
//  AppDelegate.m
//  GammaTest
//
//  Created by Thomas Finch on 6/22/15.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "GammaController.h"
#import <objc/runtime.h>
#import "IOKitLib.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [application setMinimumBackgroundFetchInterval:900]; //Wake up every 15 minutes at minimum
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        @"enabled": @NO,
        @"maxOrange": @0.7,
        @"colorChangingEnabled": @YES,
        @"lastAutoChangeDate": [NSDate distantPast],
        @"autoStartHour": @19,
        @"autoStartMinute": @0,
        @"autoEndHour": @7,
        @"autoEndMinute": @0,
    }];
    
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    NSLog(@"App woke with fetch request");
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults boolForKey:@"colorChangingEnabled"]) {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }

    NSDateComponents *curTimeComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:[NSDate date]];
    const NSInteger turnOnHour = [defaults integerForKey:@"autoStartHour"];
    const NSInteger turnOffHour = [defaults integerForKey:@"autoEndHour"];
    NSDateComponents *autoOnOffComponents = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
    autoOnOffComponents.hour = turnOnHour;
    const NSDate *turnOnDateToday = [[NSCalendar currentCalendar] dateFromComponents:autoOnOffComponents];
    autoOnOffComponents.hour = turnOffHour;
    const NSDate *turnOffDateToday = [[NSCalendar currentCalendar] dateFromComponents:autoOnOffComponents];
    
    NSLog(@"Current hour: %ld", (long)curTimeComponents.hour);
    NSLog(@"Last auto-change date: %@", [defaults objectForKey:@"lastAutoChangeDate"]);
    
    //Want to change if last change date is before the turn on/off hour of today
    
    //Turns on or off the orange-ness
    //Checks to make sure that the last auto-change was before the auto change time so it doesn't wake up the screen excessively
    //Doing stuff with dates is not fun
    if (curTimeComponents.hour >= turnOnHour || curTimeComponents.hour < turnOffHour) {
        if ([turnOnDateToday timeIntervalSinceDate:[defaults objectForKey:@"lastAutoChangeDate"]] > 0) { //If the last auto-change date was before the turn on time today, then change colors
            NSLog(@"Setting color orange");
            [GammaController enableOrangeness];
        }
    }
    else {
        if ([turnOffDateToday timeIntervalSinceDate:[defaults objectForKey:@"lastAutoChangeDate"]] > 0) {
            NSLog(@"Setting color normal");
            [GammaController disableOrangeness];
        }
    }
    
    [defaults setObject:[NSDate date] forKey:@"lastAutoChangeDate"];
    
    completionHandler(UIBackgroundFetchResultNewData);
}

@end
