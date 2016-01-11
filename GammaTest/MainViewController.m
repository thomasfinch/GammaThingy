//
//  ViewController.m
//  GammaTest
//
//  Created by Thomas Finch on 6/22/15.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import "MainViewController.h"
#import "GammaController.h"

@implementation MainViewController

@synthesize enabledSwitch;
@synthesize maxOrangeSlider;
@synthesize autoChangeSwitch;
@synthesize startTimeTextField;
@synthesize endTimeTextField;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.alwaysBounceVertical = NO;
    
    //Set up auto change start and end time pickers
    
    timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.timeStyle = NSDateFormatterShortStyle;
    timeFormatter.dateStyle = NSDateFormatterNoStyle;
    
    timePicker = [[UIDatePicker alloc] init];
    timePicker.datePickerMode = UIDatePickerModeTime;
    timePicker.minuteInterval = 15;
    timePicker.backgroundColor = [UIColor whiteColor];
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
    
    //Set switch, slider, and time values from saved settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    enabledSwitch.on = [defaults boolForKey:@"enabled"];
    maxOrangeSlider.value = [defaults floatForKey:@"maxOrange"];
    autoChangeSwitch.on = [defaults boolForKey:@"autoChangeEnabled"];
    startTimeTextField.text = [timeFormatter stringFromDate:[self dateForHour:[defaults integerForKey:@"autoStartHour"] andMinute:[defaults integerForKey:@"autoStartMinute"]]];
    endTimeTextField.text = [timeFormatter stringFromDate:[self dateForHour:[defaults integerForKey:@"autoEndHour"] andMinute:[defaults integerForKey:@"autoEndMinute"]]];
}

- (IBAction)enabledSwitchChanged:(UISwitch*)sender {
    [GammaController setEnabled:sender.on];
}

- (IBAction)maxOrangeSliderChanged:(UISlider*)sender {
    [[NSUserDefaults standardUserDefaults] setFloat:sender.value forKey:@"maxOrange"];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"])
        [GammaController setGammaWithOrangeness:sender.value];
}

- (IBAction)autoChangeSwitchChanged:(UISwitch*)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"autoChangeEnabled"];
}


// ---- Everything below here is for the time picker UI ----

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
    [GammaController autoChangeOrangenessIfNeeded];
}

- (void)timePickerValueChanged:(UIDatePicker*)picker {
    UITextField* currentField = nil;
    NSString* defaultsKeyPrefix = nil;
    if ([self.startTimeTextField isFirstResponder]) {
        currentField = startTimeTextField;
        defaultsKeyPrefix = @"autoStart";
    }
    else if ([self.endTimeTextField isFirstResponder]) {
        currentField = endTimeTextField;
        defaultsKeyPrefix = @"autoEnd";
    }
    else {
        return;
    }
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:picker.date];
    currentField.text = [timeFormatter stringFromDate:picker.date];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:components.hour forKey:[defaultsKeyPrefix stringByAppendingString:@"Hour"]];
    [defaults setInteger:components.minute forKey:[defaultsKeyPrefix stringByAppendingString:@"Minute"]];
    
    [defaults setObject:[NSDate distantPast] forKey:@"lastAutoChangeDate"];
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
    [(UIDatePicker*)textField.inputView setDate:date animated:NO];
}

- (NSDate*)dateForHour:(NSInteger)hour andMinute:(NSInteger)minute{
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    comps.hour = hour;
    comps.minute = minute;
    return [[NSCalendar currentCalendar] dateFromComponents:comps];
}

@end
