//
//  ViewController.m
//  GammaTest
//
//  Created by Thomas Finch on 6/22/15.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import "ViewController.h"
#import "GammaController.h"
#import <dlfcn.h>

void (*setColor)(float, float, float);

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *setButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    setButton.frame = CGRectMake(0, 100, self.view.frame.size.width, 50);
    [setButton setTitle:@"Set Gamma" forState:UIControlStateNormal];
    setButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [setButton addTarget:self action:@selector(setGamma) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:setButton];
    
    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    resetButton.frame = CGRectMake(0, 200, self.view.frame.size.width, 50);
    [resetButton setTitle:@"Reset Gamma" forState:UIControlStateNormal];
    resetButton.titleLabel.font = [UIFont systemFontOfSize:20];
    [resetButton addTarget:self action:@selector(resetGamma) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resetButton];
}

- (void)setGamma {
    //Keeping red at 1.0 and green at 2 * blue works pretty well
    [GammaController setGammaWithRed:1.0 green:0.6 blue:0.3];
}

- (void)resetGamma {
    //Idk why but 1.0, 1.0, 1.0 didn't work, this does
    [GammaController setGammaWithRed:0.95 green:0.95 blue:0.95];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
