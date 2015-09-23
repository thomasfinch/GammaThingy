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

@interface AppDelegate ()

@end

@interface UIApplication (Private)
- (BOOL)isLocked;
- (void)requestDeviceUnlock;
- (BOOL)isSuspended;
- (BOOL)isSuspendedUnderLock;
@end

@interface UIScreen (Private)
- (id)_snapshotExcludingWindows:(id)arg1 withRect:(struct CGRect)arg2;
- (id)snapshot;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [application setMinimumBackgroundFetchInterval:1800]; //Wake up every half hour at minimum
    
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    NSLog(@"App woke with fetch request");
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"colorChangingEnabled"]) {
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:[NSDate date]];
    NSInteger turnOnHour = 20; //8 pm
    NSInteger turnOffHour = 7; //7 am;
    
    NSLog(@"Current hour: %d", components.hour);
    
    //Wakes up the screen so the gamma can be changed, not the best way to do this by any means
    [application requestDeviceUnlock];

    if (components.hour >= turnOnHour || components.hour < turnOffHour) {
        NSLog(@"Setting color orange");
        [GammaController setGammaWithOrangeness:[[NSUserDefaults standardUserDefaults] floatForKey:@"maxOrange"]];
    }
    else {
        NSLog(@"Setting color normal");
        [GammaController setGammaWithOrangeness:0];
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
