//
//  BackgroundFetchController.m
//  GammaTest
//
//  Created by Casper Eekhof on 11/10/2015.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import "BackgroundFetchController.h"

#import <CoreLocation/CoreLocation.h>

#import "solar.h"
#import "brightness.h"

#import "GammaController.h"

@implementation BackgroundFetchController

+ (void)switchScreenTemperatureBasedOnLocation:(NSUserDefaults*)defaults {
    float latitude = [defaults floatForKey:@"colorChangingLocationLatitude"];
    float longitude = [defaults floatForKey:@"colorChangingLocationLongitude"];
    
    double solarAngularElevation = solar_elevation([[NSDate date] timeIntervalSince1970], latitude, longitude);
    
    printf("latitude: %f\n", latitude);
    printf("longitude: %f\n", longitude);
    printf("current date: %f\n", [[NSDate date] timeIntervalSince1970]);
    printf("solarAngularElevation %f\n", solarAngularElevation);

    float maxOrangePercentage = [defaults floatForKey:@"maxOrange"] * 100;
    float orangeness = (calculate_interpolated_value(solarAngularElevation, 0, maxOrangePercentage) / 100);
    printf("orangeness %f\n", orangeness);
    
    [GammaController setGammaWithOrangeness: orangeness];
}


+ (void)switchScreenTemperatureBasedOnTime:(NSUserDefaults*)defaults {
    NSDateComponents *curTimeComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit fromDate:[NSDate date]];
    const NSInteger turnOnHour = [defaults integerForKey:@"autoStartHour"];
    const NSInteger turnOffHour = [defaults integerForKey:@"autoEndHour"];
    NSDateComponents *autoOnOffComponents = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:[NSDate date]];
    autoOnOffComponents.hour = turnOnHour;
    const NSDate *turnOnDateToday = [[NSCalendar currentCalendar] dateFromComponents:autoOnOffComponents];
    autoOnOffComponents.hour = turnOffHour;
    const NSDate *turnOffDateToday = [[NSCalendar currentCalendar] dateFromComponents:autoOnOffComponents];
    
    NSLog(@"Current hour: %ld", (long)curTimeComponents.hour);
    NSLog(@"Last auto-change date: %@", [defaults objectForKey:@"lastAutoChangeDate"]);
    
    //Want to change if last change date is before the turn on/off hour of today
    
    //Turns on or off the orange-ness
    //Checks to make sure that the last auto-change was before the auto change time so it doesn't wake up the screen excessively
    //Doing stuff with dates is not fun
    if (curTimeComponents.hour >= turnOnHour || curTimeComponents.hour < turnOffHour) {
        if ([turnOnDateToday timeIntervalSinceDate:[defaults objectForKey:@"lastAutoChangeDate"]] > 0) { //If the last auto-change date was before the turn on time today, then change colors
            NSLog(@"Setting color orange");
            [GammaController enableOrangeness];
        }
    }
    else {
        if ([turnOffDateToday timeIntervalSinceDate:[defaults objectForKey:@"lastAutoChangeDate"]] > 0) {
            NSLog(@"Setting color normal");
            [GammaController disableOrangeness];
        }
    }
    
    [defaults setObject:[NSDate date] forKey:@"lastAutoChangeDate"];
}


@end
