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

@interface UIApplication ()

-(void)suspend;

@end

@interface AppDelegate ()

@end

static NSString * const ShortcutType = @"ShortcutTypeToggleEnable";
static NSString * const ShortcutEnable = @"Enable";
static NSString * const ShortcutDisable = @"Disable";

@implementation AppDelegate

- (BOOL)handleShortcutItem:(UIApplicationShortcutItem *)shortcutItem {
    if ([shortcutItem.type isEqualToString:ShortcutType]) {
        if ([GammaController enabled]) {
            [GammaController disableOrangeness];
        } else {
            [GammaController enableOrangeness];
        }
    }
    return NO;
}

- (UIApplicationShortcutItem *)shortcutItemForCurrentState {
    NSString *title = [GammaController enabled] ? ShortcutDisable : ShortcutEnable;
    UIMutableApplicationShortcutItem *shortcut = [[UIMutableApplicationShortcutItem alloc] initWithType:ShortcutType localizedTitle:title localizedSubtitle:nil icon:nil userInfo:nil];
    return shortcut;
}

- (void)updateShortCutItem {
    UIApplication *application = [UIApplication sharedApplication];
    if (![application respondsToSelector:@selector(shortcutItems)]) {
        return;
    }
    UIApplicationShortcutItem *shortcut = [self shortcutItemForCurrentState];
    application.shortcutItems = @[shortcut];
}

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

    [self updateShortCutItem];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
    
    [GammaController autoChangeOrangenessIfNeeded];
    
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    NSLog(@"App woke with fetch request");
    [GammaController autoChangeOrangenessIfNeeded];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    NSLog(@"handling url");
    NSDictionary *dict = [self parseQueryString:[url query]];
    if ([[url host] isEqualToString:@"orangeness"] && [[url path] isEqualToString:@"/switch"]) {
        id enable = nil;
        if ((enable = [dict objectForKey:@"enable"])) {
            if ([enable boolValue]) {
                //gammathingy://orangeness/switch?enable=1
                [GammaController enableOrangeness];
            } else {
                //gammathingy://orangeness/switch?enable=0
                [GammaController disableOrangeness];
            }
        } else {
            //gammathingy://orangeness/switch
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"]) {
                [GammaController disableOrangeness];
            } else {
                [GammaController enableOrangeness];
            }
        }
    }
    NSString *source = [dict objectForKey:@"x-source"];
    if (source) {
        //gammathingy://orangeness/switch?x-source=prefs
        //always switching back to source app if it's provided
        NSURL *sourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", source]];
        [[UIApplication sharedApplication] openURL:sourceURL];
    } else if ([[dict objectForKey:@"close"] boolValue]) {
        //gammathingy://orangeness/switch?close=1
        [[UIApplication sharedApplication] suspend];
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
    BOOL handledShortCutItem = [self handleShortcutItem:shortcutItem];
    [[UIApplication sharedApplication] suspend];
    [self updateShortCutItem];
    completionHandler(handledShortCutItem);
}

- (void)userDefaultsChanged:(NSNotification *)notification {
    [self updateShortCutItem];
}

@end
