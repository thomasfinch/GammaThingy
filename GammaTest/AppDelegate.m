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

extern mach_port_t SBSSpringBoardServerPort();
extern void SBGetScreenLockStatus(mach_port_t port, BOOL *lockStatus, BOOL *passcodeEnabled);
extern void SBLockDevice(mach_port_t port, BOOL locked);
extern void SBSUndimScreen();

typedef void *IOMobileFramebufferRef;
kern_return_t IOMobileFramebufferOpen(io_service_t, mach_port_t, void *, IOMobileFramebufferRef *);
kern_return_t IOMobileFramebufferRequestPowerChange(IOMobileFramebufferRef, uint32_t value);
kern_return_t IOMobileFramebufferSetBrightnessCorrection(mach_port_t, uint32_t correction);

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [application setMinimumBackgroundFetchInterval:900]; //Wake up every 15 minutes at minimum
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        @"enabled": @NO,
        @"maxOrange": [NSNumber numberWithFloat:0.7],
        @"colorChangingEnabled": @YES,
        @"lastOnDate": [NSDate distantPast],
        @"lastOffDate": [NSDate distantPast]
    }];
    
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    NSLog(@"App woke with fetch request");
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"colorChangingEnabled"]) {
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }

    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:[NSDate date]];
    const NSInteger turnOnHour = 19; //7 pm
    const NSInteger turnOffHour = 7; //7 am
    const NSInteger minCheckTimeHours = 12;
    const NSTimeInterval minCheckTime = minCheckTimeHours * 60 * 60;
    
    NSLog(@"Current hour: %ld", (long)components.hour);
    
    //Turns on or off the orange-ness
    if (components.hour >= turnOnHour || components.hour < turnOffHour) {
        if ([[NSDate date] timeIntervalSinceDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastOnDate"]] >= minCheckTime) {
            NSLog(@"Setting color orange");
            [self wakeUpScreenIfNeeded];
            [GammaController setGammaWithOrangeness:[[NSUserDefaults standardUserDefaults] floatForKey:@"maxOrange"]];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastOnDate"];
        }
    }
    else {
        if ([[NSDate date] timeIntervalSinceDate:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastOnDate"]] >= minCheckTime) {
            NSLog(@"Setting color normal");
            [self wakeUpScreenIfNeeded];
            [GammaController setGammaWithOrangeness:0];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastOffDate"];
        }
    }
    
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)wakeUpScreenIfNeeded {
    //Wakes up the screen so the gamma can be changed, not the best way to do this really but it works
    mach_port_t sbsMachPort = SBSSpringBoardServerPort();
    BOOL isLocked, passcodeEnabled;
    SBGetScreenLockStatus(sbsMachPort, &isLocked, &passcodeEnabled);
    NSLog(@"Lock status: %d", isLocked);
    if (isLocked)
        SBSUndimScreen();
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
