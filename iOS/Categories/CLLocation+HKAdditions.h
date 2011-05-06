//
//  CLLocation+HKAdditions.h
//  MapMashup
//
//  Created by Simon Fransson on 2011-03-16.
//  Copyright 2011 Hobo Code. All rights reserved.
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