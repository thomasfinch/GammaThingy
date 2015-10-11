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
@property (weak, nonatomic) IBOutlet UITextField *startTimeTextField;
@property (weak, nonatomic) IBOutlet UITextField *endTimeTextField;
@property (weak, nonatomic) IBOutlet UISlider *dimSlider;

@end

@implementation MainViewController

@synthesize enabledSwitch;
@synthesize orangeSlider;
@synthesize dimSlider;
@synthesize colorChangingEnabledSwitch;
@synthesize startTimeTextField;
@synthesize endTimeTextField;

float orange;
float dim;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.timeStyle = NSDateFormatterShortStyle;
    timeFormatter.dateStyle = NSDateFormatterNoStyle;
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    self.tableView.alwaysBounceVertical = NO;
    enabledSwitch.on = [defaults boolForKey:@"enabled"];
    orangeSlider.value = [defaults floatForKey:@"maxOrange"];
    dimSlider.value = [defaults floatForKey:@"dim"];
    orange = [defaults floatForKey:@"maxOrange"];
    dim = [defaults floatForKey:@"dim"];
    colorChangingEnabledSwitch.on = [defaults boolForKey:@"colorChangingEnabled"];
    
    NSDate *date = [self dateForHour:[defaults integerForKey:@"autoStartHour"] andMinute:[defaults integerForKey:@"autoStartMinute"]];
    startTimeTextField.text = [timeFormatter stringFromDate:date];
    date = [self dateForHour:[defaults integerForKey:@"autoEndHour"] andMinute:[defaults integerForKey:@"autoEndMinute"]];
    endTimeTextField.text = [timeFormatter stringFromDate:date];
    
    timePicker = [[UIDatePicker alloc] init];
    timePicker.datePickerMode = UIDatePickerModeTime;
    [timePicker addTarget:self action:@selector(timePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    endTimeTextField.inputView = timePicker;
    startTimeTextField.inputView = timePicker;
    
    timePickerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 0, 44)];
    UIBarButtonItem* doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(toolbarDoneButtonClicked:)];
    [timePickerToolbar setItems:@[doneButton]];
    endTimeTextField.inputAccessoryView = timePickerToolbar;
    startTimeTextField.inputAccessoryView = timePickerToolbar;
    
    endTimeTextField.delegate = self;
    startTimeTextField.delegate = self;
}

- (IBAction)enabledSwitchChanged:(UISwitch *)sender {
    if (sender.on)
        [GammaController setGammaWithOrangenessAndDim:[[NSUserDefaults standardUserDefaults] floatForKey:@"maxOrange"] percentDim:[[NSUserDefaults standardUserDefaults] floatForKey:@"dim"]];
    else
        [GammaController setGammaWithOrangeness:0];
    
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"enabled"];
}


- (IBAction)maxOrangeSliderChanged:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value forKey:@"maxOrange"];
    orange = sender.value;
    
    if (enabledSwitch.on)
        [GammaController setGammaWithOrangenessAndDim:orange percentDim:dim];
}
- (IBAction)dimSliderChanged:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value forKey:@"dim"];
    dim = sender.value;
    
    if (enabledSwitch.on)
        [GammaController setGammaWithOrangenessAndDim:orange percentDim:dim];
}

- (IBAction)colorChangingEnabledSwitchChanged:(UISwitch *)sender {
    NSLog(@"color changing switch changed");
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"colorChangingEnabled"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row == 1) { //Start time cell
        [self.startTimeTextField becomeFirstResponder];
    }
    else if (indexPath.section == 2 && indexPath.row == 2) { //end time cell
        [self.endTimeTextField becomeFirstResponder];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)toolbarDoneButtonClicked:(UIBarButtonItem*)button{
    [self.startTimeTextField resignFirstResponder];
    [self.endTimeTextField resignFirstResponder];
}

- (void)timePickerValueChanged:(UIDatePicker*)picker {
    UITextField* currentField = nil;
    NSString* defaultsKeyPrefix = nil;
    if ([self.startTimeTextField isFirstResponder]) {
        currentField = startTimeTextField;
        defaultsKeyPrefix = @"autoStart";
    } else if ([self.endTimeTextField isFirstResponder]) {
        currentField = endTimeTextField;
        defaultsKeyPrefix = @"autoEnd";
    } else {
        return;
    }
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:picker.date];
    currentField.text = [timeFormatter stringFromDate:picker.date];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:components.hour forKey:[defaultsKeyPrefix stringByAppendingString:@"Hour"]];
    [defaults setInteger:components.minute forKey:[defaultsKeyPrefix stringByAppendingString:@"Minute"]];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *date = nil;
    if (textField == startTimeTextField) {
        date = [self dateForHour:[defaults integerForKey:@"autoStartHour"] andMinute:[defaults integerForKey:@"autoStartMinute"]];
    } else if (textField == endTimeTextField){
        date = [self dateForHour:[defaults integerForKey:@"autoEndHour"] andMinute:[defaults integerForKey:@"autoEndMinute"]];
    } else {
        return;
    }
    [(UIDatePicker*)textField.inputView setDate:date animated:YES];
}

- (NSDate*)dateForHour:(NSInteger)hour andMinute:(NSInteger)minute{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    comps.hour = hour;
    comps.minute = minute;
    return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

@end
