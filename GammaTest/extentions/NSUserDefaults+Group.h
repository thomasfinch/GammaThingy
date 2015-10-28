//
//  NSUserDefaults+Group.h
//  GammaTest
//
//  Created by Arthur Hammer on 28.10.15.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (Group)

// Returns a new NSUserDefaults object for app groups to share defaults in multiple targets.
// The suit name is the bundles' "App Group Identifier" key.
//
// (Note: For now, this returns a new instance on every call.)
+ (NSUserDefaults *)groupDefaults;

@end
