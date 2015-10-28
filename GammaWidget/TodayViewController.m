//
//  TodayViewController.m
//  GammaWidget
//
//  Created by Arthur Hammer on 27.10.15.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "GammaController.h"
#import "NSUserDefaults+Group.h"

@interface TodayViewController () <NCWidgetProviding>
@property IBOutlet UIButton *toggleButton;
@property IBOutlet UIButton *increaseButton;
@property IBOutlet UIButton *decreaseButton;
@end

@implementation TodayViewController

float increaseOrangenessBy = 0.1f;

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [GammaController autoChangeOrangenessIfNeeded];
    [self updateUI];
}

- (void)updateUI {
    BOOL enabled = [[NSUserDefaults groupDefaults] boolForKey:@"enabled"];
    self.toggleButton.selected = enabled;
    self.increaseButton.enabled = enabled;
    self.decreaseButton.enabled = enabled;
}

- (IBAction)toggle:(id)sender {
    if ([[NSUserDefaults groupDefaults] boolForKey:@"enabled"]) {
        [GammaController disableOrangeness];
    } else {
        [GammaController enableOrangeness];
    }
    [self updateUI];
}

- (IBAction)increase:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults groupDefaults];
    
    if ([defaults boolForKey:@"enabled"]) {
        float intensity = [defaults floatForKey:@"maxOrange"];
        float newIntensity = intensity + increaseOrangenessBy;
        newIntensity = newIntensity >= 1 ? 1 : newIntensity;
        [GammaController setGammaWithTransitionFrom:intensity to:newIntensity];
        // This should be somewhere else, no?
        [defaults setFloat:newIntensity forKey:@"maxOrange"];
        [defaults synchronize];
        [self updateUI];
    }
}

- (IBAction)decrease:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults groupDefaults];
    
    if ([defaults boolForKey:@"enabled"]) {
        float intensity = [defaults floatForKey:@"maxOrange"];
        float newIntensity = intensity - increaseOrangenessBy;
        newIntensity = newIntensity <= 0 ? 0 : newIntensity;
        [GammaController setGammaWithTransitionFrom:intensity to:newIntensity];
        // This should be somewhere else, no?
        [defaults setFloat:newIntensity forKey:@"maxOrange"];
        [defaults synchronize];
        [self updateUI];
    }
}

- (IBAction)openApp:(id)sender {
    [[self extensionContext] openURL:[NSURL URLWithString:@"gammathingy://"] completionHandler:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    NSUserDefaults *defaults = [NSUserDefaults groupDefaults];
    BOOL enabledOnLastCheck = [defaults boolForKey:@"widgetLastCheckEnabled"];
    BOOL enabled = [defaults boolForKey:@"enabled"];
    [defaults setBool:enabled forKey:@"widgetLastCheckEnabled"];
    [defaults synchronize];
    
    completionHandler(enabledOnLastCheck != enabled ? NCUpdateResultNewData : NCUpdateResultNoData);
}

@end
