//
//  GammaController.m
//  GammaTest
//
//  Created by Thomas Finch on 6/22/15.
//  Copyright (c) 2015 Thomas Finch. All rights reserved.
//

#import "GammaController.h"

#import "IOKitLib.h"

#include <stdio.h>
#include <stdlib.h>
#include <mach/mach.h>
#include <assert.h>
#include <dlfcn.h>

typedef void *IOMobileFramebufferRef;

kern_return_t IOMobileFramebufferOpen(io_service_t, mach_port_t, void *, IOMobileFramebufferRef *);
kern_return_t IOMobileFramebufferSetGammaTable(IOMobileFramebufferRef, void *);
kern_return_t (*IOMobileFramebufferGetGammaTable)(IOMobileFramebufferRef, void *);

extern mach_port_t SBSSpringBoardServerPort();
extern void SBGetScreenLockStatus(mach_port_t port, BOOL *lockStatus, BOOL *passcodeEnabled);
extern void SBSUndimScreen();

@interface NSDate (e)
- (BOOL)isEarlierThan:(NSDate*)b;
- (BOOL)isLaterThan:(NSDate*)b;
@end

// TheClass.h
@interface TheClass : NSObject
+ (int)count;
@end

static BOOL firstExecution = YES;

@implementation GammaController

//This function is largely the same as the one in iomfsetgamma.c from Saurik's UIKitTools package. The license is pasted below.

/* UIKit Tools - command-line utilities for UIKit
 * Copyright (C) 2008-2012  Jay Freeman (saurik)
 */

/* Modified BSD License {{{ */
/*
 *        Redistribution and use in source and binary
 * forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the
 *    above copyright notice, this list of conditions
 *    and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the
 *    above copyright notice, this list of conditions
 *    and the following disclaimer in the documentation
 *    and/or other materials provided with the
 *    distribution.
 * 3. The name of the author may not be used to endorse
 *    or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/* }}} */

+ (void)setGammaWithRed:(float)red green:(float)green blue:(float)blue {
    
    
    unsigned rs = red * 0x100;
    assert(rs <= 0x100);
    
    unsigned gs = green * 0x100;
    assert(gs <= 0x100);
    
    unsigned bs = blue * 0x100;
    assert(bs <= 0x100);
    
    kern_return_t error;
    mach_port_t selfPort = mach_task_self();
    
    io_service_t service = 0;
    
    if (service == 0)
        service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleCLCD"));
    if (service == 0)
        service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleH1CLCD"));
    if (service == 0)
        service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleM2CLCD"));
    
    assert(service != 0);
    
    IOMobileFramebufferRef fb;
    error = IOMobileFramebufferOpen(service, selfPort, 0, &fb);
    assert(error == 0);

    uint32_t data[0xc0c / sizeof(uint32_t)];
    memset(data, 0, sizeof(data));
    
    //Create the path string pointing to the temporary gamma table file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingString:@"/gammatable.dat"];
    FILE *file = fopen([filePath UTF8String], "rb");
    
    if (file == NULL) {
        kern_return_t (*IOMobileFramebufferGetGammaTable)(IOMobileFramebufferRef, void *) = (kern_return_t (*)(IOMobileFramebufferRef, void *)) dlsym(RTLD_DEFAULT, "IOMobileFramebufferGetGammaTable");
        assert(IOMobileFramebufferGetGammaTable != NULL);
        error = IOMobileFramebufferGetGammaTable(fb, data);
        assert(error == 0);
        
        file = fopen([filePath UTF8String], "wb");
        assert(file != NULL);
        
        fwrite(data, 1, sizeof(data), file);
        fclose(file);
        
        file = fopen([filePath UTF8String], "rb");
        assert(file != NULL);
    }
    
    fread(data, 1, sizeof(data), file);
    fclose(file);
    
    size_t i;
    for (i = 0; i < 256; ++i) {
        int j = 255 - (int)i;
        
        int r = j * rs >> 8;
        int g = j * gs >> 8;
        int b = j * bs >> 8;
        
        //This part only works on iOS versions >=7, otherwise see Saurik's UIKitTools source
        data[j + 0x001] = data[r + 0x001];
        data[j + 0x102] = data[g + 0x102];
        data[j + 0x203] = data[b + 0x203];
    }
    
    error = IOMobileFramebufferSetGammaTable(fb, data);
    assert(error == 0);
}

+ (void)setGammaWithOrangeness:(float)percentOrange {
    if (percentOrange > 1)
        percentOrange = 1;
    else if (percentOrange < 0)
        percentOrange = 0;
    
    float red = 1.0;
    float blue = 1 - percentOrange;
    float green = (red + blue)/2.0;
    
    if (percentOrange == 0) {
        red = blue = green = 0.99;
    }
    
    [self setGammaWithRed:red green:green blue:blue];
}

+ (void)enableOrangeness {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self wakeUpScreenIfNeeded];
    [GammaController setGammaWithOrangeness:[defaults floatForKey:@"maxOrange"]];
    [defaults setObject:[NSDate date] forKey:@"lastAutoChangeDate"];
    [defaults setBool:YES forKey:@"enabled"];
    [defaults synchronize];
}

+ (void)disableOrangeness {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self wakeUpScreenIfNeeded];
    [GammaController setGammaWithOrangeness:0];
    [defaults setObject:[NSDate date] forKey:@"lastAutoChangeDate"];
    [defaults setBool:NO forKey:@"enabled"];
    [defaults synchronize];
}

+ (void)wakeUpScreenIfNeeded {
    //Wakes up the screen so the gamma can be changed
    mach_port_t sbsMachPort = SBSSpringBoardServerPort();
    BOOL isLocked, passcodeEnabled;
    SBGetScreenLockStatus(sbsMachPort, &isLocked, &passcodeEnabled);
    NSLog(@"Lock status: %d", isLocked);
    if (isLocked)
        SBSUndimScreen();
}

+ (void)autoChangeOrangenessIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Reboot persistence code
    if ([defaults boolForKey:@"enabled"] && firstExecution){
        NSLog(@"First execution code was triggered");
        [self enableOrangeness];
        firstExecution = NO;
    }
    
    if (![defaults boolForKey:@"colorChangingEnabled"]) {
        return;
    }
    
    NSDate* now = [NSDate date];
    
    NSDateComponents *autoOnOffComponents = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];
    
    autoOnOffComponents.hour = [defaults integerForKey:@"autoStartHour"];
    autoOnOffComponents.minute = [defaults integerForKey:@"autoStartMinute"];
    NSDate* turnOnDate = [[NSCalendar currentCalendar] dateFromComponents:autoOnOffComponents];
    
    autoOnOffComponents.hour = [defaults integerForKey:@"autoEndHour"];
    autoOnOffComponents.minute = [defaults integerForKey:@"autoEndMinute"];
    NSDate *turnOffDate = [[NSCalendar currentCalendar] dateFromComponents:autoOnOffComponents];
    
    //special treatment for intervals wrapping around midnight needed
    if ([turnOnDate isLaterThan:turnOffDate]) {
        if ([now isEarlierThan:turnOnDate] && [now isEarlierThan:turnOffDate]) {
            //Handles the case when we're in the early morning after midnight (before turnOffDate)
            //__|______!__________I....................I________________|__//
            //00:00   now    turnOffDate           turnOnDate         24:00//
            //thus, we need to set the on date to yesterday to be able to correctly figure out stuff
            autoOnOffComponents.day = autoOnOffComponents.day - 1;
            turnOnDate = [[NSCalendar currentCalendar] dateFromComponents:autoOnOffComponents];
        }else if ([turnOnDate isEarlierThan:now] && [turnOffDate isEarlierThan:now]) {
            //Handles the case when we're in the night before midnight (after turnOnDate)
            //__|_________________I....................I_________!______|__//
            //00:00          turnOffDate           turnOnDate   now   24:00//
            //thus, we need to set the off date to tomorrow to be able to correctly figure out stuff
            autoOnOffComponents.day = autoOnOffComponents.day + 1;
            turnOffDate = [[NSCalendar currentCalendar] dateFromComponents:autoOnOffComponents];
        }
    }
    
    NSLog(@"Last auto-change date: %@", [defaults objectForKey:@"lastAutoChangeDate"]);
    
    //Turns on or off the orange-ness
    //Checks to make sure that the last auto-change was before the auto change time so it doesn't wake up the screen excessively
    
    //If the "turn on" date for today is in the past
    //AND if the "turn off" date is in the future
    //we're in the period the screen is supposed to be orange (whoa! inhuman conclusions!)
    if ([turnOnDate isEarlierThan:now] && [turnOffDate isLaterThan:now]) {
        NSLog(@"We're in the orange interval, considering switch to orange");
        if ([turnOnDate isLaterThan:[defaults objectForKey:@"lastAutoChangeDate"]]) { //If the last auto-change date was before the turn on time today, then change colors
            NSLog(@"Setting color orange");
            [GammaController enableOrangeness];
        }
    } else {
        NSLog(@"Orange times have either passed or are not quite here just yet, considering switch to normal");
        if ([turnOffDate isLaterThan:[defaults objectForKey:@"lastAutoChangeDate"]]) {
            NSLog(@"Setting color normal");
            [GammaController disableOrangeness];
        }
    }
    
    [defaults setObject:[NSDate date] forKey:@"lastAutoChangeDate"];
}
	
+ (BOOL)enabled {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"enabled"];
}

@end


@implementation NSDate (e)
- (BOOL)isEarlierThan:(NSDate*)b{
    return [self earlierDate:b] == self;
}

- (BOOL)isLaterThan:(NSDate*)b{
    return [self laterDate:b] == self;
}
@end
