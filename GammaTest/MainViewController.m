//
//  ViewController.m
//  GammaTest
//
//  Created by Thomas Finch on 6/22/15.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import "MainViewController.h"
#import "GammaController.h"
#import "NSUserDefaults+Group.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *enabledSwitch;
@property (weak, nonatomic) IBOutlet UISlider *orangeSlider;
@property (weak, nonatomic) IBOutlet UISwitch *colorChangingEnabledSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *colorChangingLocationBasedSwitch;
@property (weak, nonatomic) IBOutlet UITextField *startTimeTextField;
@property (weak, nonatomic) IBOutlet UITextField *endTimeTextField;
@property (strong, nonatomic) IBOutletCollection(UITableViewCell) NSArray *timeBasedInputCells;

@property CLLocationManager * locationManager;

@end

@implementation MainViewController

@synthesize enabledSwitch;
@synthesize orangeSlider;
@synthesize colorChangingEnabledSwitch;
@synthesize colorChangingLocationBasedSwitch;
@synthesize startTimeTextField;
@synthesize endTimeTextField;
@synthesize timeBasedInputCells;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        timeFormatter = [[NSDateFormatter alloc] init];
        timeFormatter.timeStyle = NSDateFormatterShortStyle;
        timeFormatter.dateStyle = NSDateFormatterNoStyle;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.alwaysBounceVertical = NO;
    
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
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    
    endTimeTextField.delegate = self;
    startTimeTextField.delegate = self;
    
    [self updateUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)updateUI {
    NSUserDefaults* defaults = [NSUserDefaults groupDefaults];
    
    enabledSwitch.on = [defaults boolForKey:@"enabled"];
    orangeSlider.value = [defaults floatForKey:@"maxOrange"];
    colorChangingEnabledSwitch.on = [defaults boolForKey:@"colorChangingEnabled"];
    colorChangingLocationBasedSwitch.on = [defaults boolForKey:@"colorChangingLocationEnabled"];
    
    NSDate *date = [self dateForHour:[defaults integerForKey:@"autoStartHour"] andMinute:[defaults integerForKey:@"autoStartMinute"]];
    startTimeTextField.text = [timeFormatter stringFromDate:date];
    date = [self dateForHour:[defaults integerForKey:@"autoEndHour"] andMinute:[defaults integerForKey:@"autoEndMinute"]];
    endTimeTextField.text = [timeFormatter stringFromDate:date];
}

- (IBAction)enabledSwitchChanged:(UISwitch *)sender {
    NSLog(@"enabled: %lu",(unsigned long)sender.on);
    [[NSUserDefaults groupDefaults] setBool:NO forKey:@"updateUI"];
    
    if (sender.on) {
        [GammaController setGammaWithTransitionFrom:0 to:[[NSUserDefaults groupDefaults] floatForKey:@"maxOrange"]];
    } else {
        [GammaController setGammaWithTransitionFrom:[[NSUserDefaults groupDefaults] floatForKey:@"maxOrange"] to:0];
    }
    if ([[NSUserDefaults groupDefaults] boolForKey:@"colorChangingLocationEnabled"]) {
        [[NSUserDefaults groupDefaults] setBool:NO forKey:@"colorChangingLocationEnabled"];
    }
    if ([[NSUserDefaults groupDefaults] boolForKey:@"colorChangingLocationEnabled"]) {
        [[NSUserDefaults groupDefaults] setBool:NO forKey:@"colorChangingEnabled"];
    }
    
    
    [[NSUserDefaults groupDefaults] setBool:sender.on forKey:@"enabled"];
    [[NSUserDefaults groupDefaults] setBool:YES forKey:@"updateUI"];
}

- (IBAction)maxOrangeSliderChanged:(UISlider *)sender {
    NSLog(@"maxOrange: %f",sender.value);
    [[NSUserDefaults groupDefaults] setFloat:sender.value forKey:@"maxOrange"];
    
    if (enabledSwitch.on)
        [GammaController setGammaWithOrangeness:sender.value];
}

- (IBAction)colorChangingEnabledSwitchChanged:(UISwitch *)sender {
    NSLog(@"colorChangingEnabled: %lu",(unsigned long)sender.on);
    [[NSUserDefaults groupDefaults] setBool:NO forKey:@"updateUI"];
    [[NSUserDefaults groupDefaults] setBool:sender.on forKey:@"colorChangingEnabled"];
    [[NSUserDefaults groupDefaults] setObject:[NSDate distantPast] forKey:@"lastAutoChangeDate"];
    NSLog(@"color changing switch changed");
    
    if(sender.on) {
        // Only one auto temperature change can be activated
        if (colorChangingLocationBasedSwitch.on) {
            [colorChangingLocationBasedSwitch setOn:NO animated:YES];
        }
        // Make the time fields full opacity.
        for(UITableViewCell *cell in timeBasedInputCells)
            [[cell contentView] setAlpha: 1];
        [[NSUserDefaults groupDefaults] setBool:NO forKey:@"colorChangingLocationEnabled"];
        [[NSUserDefaults groupDefaults] setBool:sender.on forKey:@"colorChangingEnabled"];
    }
    [[NSUserDefaults groupDefaults] setBool:YES forKey:@"updateUI"];
    [GammaController autoChangeOrangenessIfNeeded];
}

- (IBAction)colorChangingLocationSwitchValueChanged:(UISwitch *)sender {
    if(sender.on) {
        [[NSUserDefaults groupDefaults] setBool:NO forKey:@"updateUI"];
        BOOL requestedLocationAuthorization = NO;

        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
                [self.locationManager requestWhenInUseAuthorization];
                // Let the location manager delegate take it from here.
                return;
            }
        }
        
        // Only one auto temperature change can be activated
        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            // Search for location
            [self.locationManager startUpdatingLocation];
            
            // Update the user location everytime this is switched on
            // This is only here, instead of in every background refresh, in order to prolong battery life.
            CGFloat latitude = self.locationManager.location.coordinate.latitude;
            CGFloat longitude = self.locationManager.location.coordinate.longitude;
            if (latitude != 0 && longitude != 0) { // make sure the location is available
                [[NSUserDefaults groupDefaults] setFloat:latitude forKey:@"colorChangingLocationLatitude"];
                [[NSUserDefaults groupDefaults] setFloat:longitude forKey:@"colorChangingLocationLongitude"];
            }
            
            [colorChangingEnabledSwitch setOn:NO animated:YES];
            
            for(UITableViewCell *cell in timeBasedInputCells) 
                [[cell contentView] setAlpha: .6];
            
            [[NSUserDefaults groupDefaults] setBool:YES forKey:@"colorChangingLocationEnabled"];
            [[NSUserDefaults groupDefaults] setBool:NO forKey:@"colorChangingEnabled"];
            
        } else if(!requestedLocationAuthorization) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No access to location"
                                                            message:@"You must enable location services in settings."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [sender setOn:NO animated:YES];
        }
        [[NSUserDefaults groupDefaults] setBool:YES forKey:@"updateUI"];
        [GammaController autoChangeOrangenessIfNeeded];
    } else {
        [[NSUserDefaults groupDefaults] setBool:NO forKey:@"colorChangingLocationEnabled"];
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusDenied) {
        [colorChangingLocationBasedSwitch setOn:NO animated:YES];
        [[NSUserDefaults groupDefaults] setBool:NO forKey:@"colorChangingLocationEnabled"];
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        // revaluate the UISwitch status
        [self colorChangingLocationSwitchValueChanged: colorChangingLocationBasedSwitch];
    }
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
    
    NSUserDefaults *defaults = [NSUserDefaults groupDefaults];
    [defaults setInteger:components.hour forKey:[defaultsKeyPrefix stringByAppendingString:@"Hour"]];
    [defaults setInteger:components.minute forKey:[defaultsKeyPrefix stringByAppendingString:@"Minute"]];
    
    [defaults setObject:[NSDate distantPast] forKey:@"lastAutoChangeDate"];
    [GammaController autoChangeOrangenessIfNeeded];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    NSUserDefaults *defaults = [NSUserDefaults groupDefaults];
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

- (void)userDefaultsChanged:(NSNotification *)notification {
    if([[NSUserDefaults groupDefaults] boolForKey:@"updateUI"])
        [self updateUI];
}

@end
