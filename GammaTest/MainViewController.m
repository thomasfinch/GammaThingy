//
//  ViewController.m
//  GammaTest
//
//  Created by Thomas Finch on 6/22/15.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import "MainViewController.h"
#import "GammaController.h"

@interface MainViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *enabledSwitch;
@property (weak, nonatomic) IBOutlet UISlider *orangeSlider;

@end

@implementation MainViewController

@synthesize enabledSwitch;
@synthesize orangeSlider;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        @"enabled": @NO,
        @"maxOrange": [NSNumber numberWithFloat:0.7]
    }];

    self.tableView.alwaysBounceVertical = NO;
    orangeSlider.value = [[NSUserDefaults standardUserDefaults] floatForKey:@"maxOrange"];
//    enabledSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"];
}

- (IBAction)enabledSwitchChanged:(UISwitch *)sender {
    if (sender.on)
        [GammaController setGammaWithOrangeness:[[NSUserDefaults standardUserDefaults] floatForKey:@"maxOrange"]];
    else
        [GammaController setGammaWithOrangeness:0];
    
//    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"enabled"];
}

- (IBAction)maxOrangeSliderChanged:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value forKey:@"maxOrange"];
    
    if (enabledSwitch.on)
        [GammaController setGammaWithOrangeness:sender.value];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
