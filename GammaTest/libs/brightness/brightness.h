//
//  brightness.h
//  GammaTest
//
//  Created by Casper Eekhof on 11/10/2015.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#ifndef brightness_h
#define brightness_h

#include <stdio.h>
#include "solar.h"

#define TRANSITION_LOW     SOLAR_CIVIL_TWILIGHT_ELEV
#define TRANSITION_HIGH    3.0

float calculate_interpolated_value(double elevation, float day, float night);

#endif /* brightness_h */

