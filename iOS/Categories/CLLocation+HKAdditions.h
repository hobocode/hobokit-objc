//  Copyright (c) 2011 HoboCode
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

// Port of Arnold Andreasson, 2007, javascript implementation
// http://latlong.mellifica.se/
//
// Source: http://www.lantmateriet.se/geodesi/
// Author: Arnold Andreasson, 2007. http://mellifica.se/konsult
// License: http://creativecommons.org/licenses/by-nc-sa/3.0/

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef enum {
    HKGridProjectionRT90_7_5_GonV = -2,
    HKGridProjectionRT90_5_0_GonV,
    HKGridProjectionRT90_2_5_GonV,
    HKGridProjectionRT90_0_0_GonV,
    HKGridProjectionRT90_2_5_GonO,
    HKGridProjectionRT90_5_0_GonO,
    HKGridProjectionBesselRT90_7_5_GonV,
    HKGridProjectionBesselRT90_5_0_GonV,
    HKGridProjectionBesselRT90_2_5_GonV,
    HKGridProjectionBesselRT90_0_0_GonV,
    HKGridProjectionBesselRT90_2_5_GonO,
    HKGridProjectionBesselRT90_5_0_GonO,
    HKGridProjectionSWEREF99_TM,
    HKGridProjectionSWEREF99_12_00,
    HKGridProjectionSWEREF99_13_30,
    HKGridProjectionSWEREF99_15_00,
    HKGridProjectionSWEREF99_16_30,
    HKGridProjectionSWEREF99_18_00,
    HKGridProjectionSWEREF99_14_15,
    HKGridProjectionSWEREF99_15_45,
    HKGridProjectionSWEREF99_17_15,
    HKGridProjectionSWEREF99_18_45,
    HKGridProjectionSWEREF99_20_15,
    HKGridProjectionSWEREF99_21_45,
    HKGridProjectionSWEREF99_23_15
} HKGridProjection;

typedef struct {
    double x;
    double y;
} HKGridCoordinate;

typedef struct {
    double axis;
    double flattening;
    double centralMeridian;
    double latitudeOfOrigin;
    double scale;
    double falseNorthing;
    double falseEasting;
} HKGridProjectionParameters;

/* Parameter sets */
HKGridProjectionParameters HKGRS80ProjectionParameters(HKGridProjection projection);
HKGridProjectionParameters HKBesselProjectionParameters(HKGridProjection projection);
HKGridProjectionParameters HKSWEREF99ProjectionParameters(HKGridProjection projection);
HKGridProjectionParameters HKTestCaseProjectionParameters();

CLLocationCoordinate2D HKGridToGeodetic(double x, double y, HKGridProjectionParameters parameters);
HKGridCoordinate HKGeodeticToGrid(CLLocationCoordinate2D coord, HKGridProjectionParameters params);
CLLocationCoordinate2D CLLocationCoordinate2DMakeWithGridCoordinate(double x, double y, HKGridProjection projection);

@interface CLLocation (HKAdditions)

- (id)initWithGridCoordinate:(double)x longitude:(double)y projection:(HKGridProjection)projection;

@end