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

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [application setMinimumBackgroundFetchInterval:900]; //Wake up every 15 minutes at minimum
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        @"enabled": @NO,
        @"maxOrange": [NSNumber numberWithFloat:0.7],
        @"colorChangingEnabled": @YES,
        @"lastOnDate": [NSDate distantPast],
        @"lastOffDate": [NSDate distantPast],
		@"autoStartHour": @19,
		@"autoStartMinute": @0,
		@"autoEndHour": @7,
		@"autoEndMinute": @0
    }];
    
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
	NSLog(@"App woke with fetch request");
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
    if (![defaults boolForKey:@"colorChangingEnabled"]) {
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:[NSDate date]];
    const NSInteger turnOnHour = [defaults integerForKey:@"autoStartHour"];
	const NSInteger turnOffHour = [defaults integerForKey:@"autoEndHour"];
    const NSInteger minCheckTimeHours = 12;
    const NSTimeInterval minCheckTime = minCheckTimeHours * 60 * 60;
    
    NSLog(@"Current hour: %ld", (long)components.hour);
    
    //Turns on or off the orange-ness
    if (components.hour >= turnOnHour || components.hour < turnOffHour) {
        if ([[NSDate date] timeIntervalSinceDate:[defaults objectForKey:@"lastOnDate"]] >= minCheckTime) {
            NSLog(@"Setting color orange");
			[GammaController enableOrangeness];
        }
    }
    else {
        if ([[NSDate date] timeIntervalSinceDate:[defaults objectForKey:@"lastOnDate"]] >= minCheckTime) {
            NSLog(@"Setting color normal");
			[GammaController disableOrangeness];
        }
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
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
