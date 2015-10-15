//
//  TodayViewController.m
//  GammaTestWidget
//
//  Created by Frederik Delaere on 15/10/15.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import <QuartzCore/QuartzCore.h>


@interface TodayViewController () <NCWidgetProviding>

@end

@implementation TodayViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIButton *onButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [onButton addTarget:self
                 action:@selector(onButtonClicked:)
       forControlEvents:UIControlEventTouchUpInside];
    [onButton setTitle:@"Enable" forState:UIControlStateNormal];
    [onButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    onButton.frame = CGRectMake(0.0, 40.0, 100.0, 40.0);
    
    onButton.layer.borderColor = [UIColor whiteColor].CGColor;
    onButton.layer.backgroundColor = [UIColor whiteColor].CGColor;
    onButton.layer.borderWidth = 1.0;
    onButton.layer.cornerRadius = 10;
    [self.view addSubview:onButton];
    
    UIButton *offButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [offButton addTarget:self
                 action:@selector(offButtonClicked:)
       forControlEvents:UIControlEventTouchUpInside];
    [offButton setTitle:@"Disable" forState:UIControlStateNormal];
    [offButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    offButton.frame = CGRectMake(120.0, 40.0, 100.0, 40.0);
    
    offButton.layer.borderColor = [UIColor whiteColor].CGColor;
    offButton.layer.backgroundColor = [UIColor whiteColor].CGColor;
    offButton.layer.borderWidth = 1.0;
    offButton.layer.cornerRadius = 10;
    [self.view addSubview:offButton];
    
    self.preferredContentSize = CGSizeMake(120, 80);
}

-(void) onButtonClicked:(UIButton*)sender {
    [[self extensionContext] openURL:[NSURL URLWithString:@"gammathingy://orangeness/switch?enable=1&close=1"] completionHandler:nil];
}

-(void) offButtonClicked:(UIButton*)sender {
    [[self extensionContext] openURL:[NSURL URLWithString:@"gammathingy://orangeness/switch?enable=0&close=1"] completionHandler:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData

    completionHandler(NCUpdateResultNewData);
}

@end
