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

@implementation GammaController

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
    NSString *filePath = [documentsDirectory stringByAppendingString:@"/iomfgammatable.dat"];
    
    FILE *file = fopen([filePath UTF8String], "rb");
    if (file == NULL) {
        IOMobileFramebufferGetGammaTable = dlsym(RTLD_DEFAULT, "IOMobileFramebufferGetGammaTable");
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
    for (i = 0; i != 256; ++i) {
        //int j = 255 - i;
        int j = 255 - (int)i;
        
        int r = j * rs >> 8;
        int g = j * gs >> 8;
        int b = j * bs >> 8;
        
        data[j + 0x000] = data[r + 0x000];
        data[j + 0x100] = data[g + 0x100];
        data[j + 0x200] = data[b + 0x200];
    }
    
    error = IOMobileFramebufferSetGammaTable(fb, data);
    assert(error == 0);
    
}

@end
