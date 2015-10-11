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
    
    uint32_t data[0xc00 / sizeof(uint32_t)];
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
    
    // Setting the values when screen is locked will crash the app
    // and increase battery usage.
    if ([self wakeUpScreenIfNeeded]) {
        [self setGammaWithRed:red green:green blue:blue];
    }
}

+ (void)enableOrangeness {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [GammaController setGammaWithOrangeness:[defaults floatForKey:@"maxOrange"]];
    [defaults setObject:[NSDate date] forKey:@"lastOnDate"];
    [defaults setBool:YES forKey:@"enabled"];
}

+ (void)disableOrangeness {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [GammaController setGammaWithOrangeness:0];
    [defaults setObject:[NSDate date] forKey:@"lastOffDate"];
    [defaults setBool:NO forKey:@"enabled"];
}

+ (bool)wakeUpScreenIfNeeded {
    //Wakes up the screen so the gamma can be changed
    mach_port_t sbsMachPort = SBSSpringBoardServerPort();
    BOOL isLocked, passcodeEnabled;
    SBGetScreenLockStatus(sbsMachPort, &isLocked, &passcodeEnabled);
    NSLog(@"Lock status: %d", isLocked);
    if (isLocked)
        SBSUndimScreen();
    return !isLocked;
}

@end
