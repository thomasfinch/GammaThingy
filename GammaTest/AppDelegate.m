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

typedef NS_ENUM(NSInteger, GammaAction) {
    GammaActionNone,
    GammaActionEnable,
    GammaActionDisable
};

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [application setMinimumBackgroundFetchInterval:900]; //Wake up every 15 minutes at minimum
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        @"enabled": @YES,
        @"maxOrange": [NSNumber numberWithFloat:0.5],
        @"autoChangeEnabled": @NO,
        @"lastAutoChangeDate": [NSDate distantPast],
        @"autoStartHour": [NSNumber numberWithInteger:20],
        @"autoStartMinute": [NSNumber numberWithInteger:0],
        @"autoEndHour": [NSNumber numberWithInteger:7],
        @"autoEndMinute": [NSNumber numberWithInteger:0]
    }];
    
    if ([application respondsToSelector:@selector(shortcutItems)] && application.shortcutItems.count == 0)
        [self updateShortcutItem];
    
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    [GammaController autoChangeOrangenessIfNeeded];
    completionHandler(UIBackgroundFetchResultNewData); //Always return "new data" result so iOS doesn't launch for fetches less often
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    NSDictionary *dict = [self parseQueryString:[url query]];
    
    if ([[url host] isEqualToString:@"orangeness"] && [[url path] isEqualToString:@"/switch"]) {
        if ([dict objectForKey:@"enable"]) {
            // gammathingy://orangeness/switch?enable=1
            [GammaController setEnabled:[[dict objectForKey:@"enable"] boolValue]];
        }
        else {
            // gammathingy://orangeness/switch
            [GammaController setEnabled:![[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"]];
        }
    }
    
    NSString *source = [dict objectForKey:@"x-source"];
    if (source) {
        //gammathingy://orangeness/switch?x-source=prefs
        //always switching back to source app if it's provided
        NSURL *sourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", source]];
        [[UIApplication sharedApplication] openURL:sourceURL];
    }
    
    return YES;
}

- (NSDictionary *)parseQueryString:(NSString *)query {
    //Found on http://www.idev101.com/code/Objective-C/custom_url_schemes.html
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        NSString *key = [[elements objectAtIndex:0] stringByRemovingPercentEncoding];
        NSString *val = [[elements objectAtIndex:1] stringByRemovingPercentEncoding];
        
        [dict setObject:val forKey:key];
    }
    return dict;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    [GammaController setEnabled:![[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"]];
    [self updateShortcutItem];
    completionHandler(YES);
}

- (void)updateShortcutItem {
    NSString *newShortcutTitle = [[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"] ? @"Disable" : @"Enable";
    UIMutableApplicationShortcutItem *newShortcutItem = [[UIMutableApplicationShortcutItem alloc] initWithType:@"GammaThingyShortcut" localizedTitle:newShortcutTitle localizedSubtitle:nil icon:nil userInfo:nil];
    [UIApplication sharedApplication].shortcutItems = @[newShortcutItem];
}

@end
