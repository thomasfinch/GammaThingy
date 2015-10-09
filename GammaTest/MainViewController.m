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
@property (weak, nonatomic) IBOutlet UISwitch *colorChangingEnabledSwitch;

@end

@implementation MainViewController

@synthesize enabledSwitch;
@synthesize orangeSlider;
@synthesize colorChangingEnabledSwitch;

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.alwaysBounceVertical = NO;
    enabledSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"];
    orangeSlider.value = [[NSUserDefaults standardUserDefaults] floatForKey:@"maxOrange"];
    colorChangingEnabledSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"colorChangingEnabled"];
}

- (IBAction)enabledSwitchChanged:(UISwitch *)sender {
    if (sender.on)
        [GammaController setGammaWithOrangeness:[[NSUserDefaults standardUserDefaults] floatForKey:@"maxOrange"]];
    else
        [GammaController setGammaWithOrangeness:0];
    
	[[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"enabled"];
}

- (IBAction)maxOrangeSliderChanged:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value forKey:@"maxOrange"];
    
    if (enabledSwitch.on)
        [GammaController setGammaWithOrangeness:sender.value];
}

- (IBAction)colorChangingEnabledSwitchChanged:(UISwitch *)sender {
    NSLog(@"color changing switch changed");
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"colorChangingEnabled"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row == 1) { //Start time cell
        NSLog(@"start time cell selected");
    }
    else if (indexPath.section == 2 && indexPath.row == 2) { //end time cell
        NSLog(@"end time cell selected");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
