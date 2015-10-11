//
//  brightness.c
//  GammaTest
//
//  Created by Casper Eekhof on 11/10/2015.
//  Copyright © 2015 Thomas Finch. All rights reserved.
//

#include "brightness.h"

/*also from Redshift*/
float calculate_interpolated_value(double elevation, float day, float night)
{
    float result;
    if (elevation < TRANSITION_LOW) {
        result = night;
    } else if (elevation < TRANSITION_HIGH) {
        /* Transition period: interpolate */
        float a = (TRANSITION_LOW - elevation) /
        (TRANSITION_LOW - TRANSITION_HIGH);
        result = (1.0-a)*night + a*day;
    } else {
        result = day;
    }
    
    return result;
}