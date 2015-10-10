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
    [GammaController autoChangeOrangenessIfNeeded];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSDictionary *dict = [self parseQueryString:[url query]];
    if ([[url host] isEqualToString:@"switch_orangeness"]) {
        id temp = nil;
        if ((temp = [dict objectForKey:@"enable"])) {
            if ([temp boolValue]) {
                //gammathingy://switch_orangeness?enable=1
                [GammaController enableOrangeness];
            } else {
                //gammathingy://switch_orangeness?enable=0
                [GammaController disableOrangeness];
            }
        } else {
            //gammathingy://switch_orangeness
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"]) {
                [GammaController disableOrangeness];
            } else {
                [GammaController enableOrangeness];
            }
        }
    }
    return YES;
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    //Found on http://www.idev101.com/code/Objective-C/custom_url_schemes.html
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [GammaController autoChangeOrangenessIfNeeded];
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

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
