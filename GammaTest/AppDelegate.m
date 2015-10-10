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
#import <CoreLocation/CoreLocation.h>
#import "solar.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

CLLocationManager *locationManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [application setMinimumBackgroundFetchInterval:900]; //Wake up every 15 minutes at minimum
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        @"enabled": @NO,
        @"maxOrange": [NSNumber numberWithFloat:0.7],
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
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    if (![defaults boolForKey:@"colorChangingEnabled"] && ![defaults boolForKey:@"colorChangingLocationEnabled"]) {
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }
    
    if ([defaults boolForKey:@"colorChangingLocationEnabled"]) {
        [self switchScreenTemperatureBasedOnLocation: defaults];
    } else if ([defaults boolForKey:@"colorChangingEnabled"]){
        [self switchScreenTemperatureBasedOnTime: defaults];
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)switchScreenTemperatureBasedOnLocation:(NSUserDefaults*)defaults {
    if(locationManager == nil) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    }
    
    [locationManager startUpdatingLocation];
//    
    float latitude = locationManager.location.coordinate.latitude;
    float longitude = locationManager.location.coordinate.longitude;
    
    
    double solarAngularElevation = solar_elevation([[NSDate date] timeIntervalSince1970], latitude, longitude);
//
//
    printf("latitude %f\n", latitude);
    printf("longitude %f\n", longitude);
    printf("current date: %f\n", [[NSDate date] timeIntervalSince1970]);
    printf("timeOfSolarElevation %f\n", solarAngularElevation);
    
}

- (void)switchScreenTemperatureBasedOnTime:(NSUserDefaults*)defaults {
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
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
