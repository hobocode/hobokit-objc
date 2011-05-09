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

#import "CLLocation+HKAdditions.h"

@implementation CLLocation (HKAdditions)

- (id)initWithGridCoordinate:(double)x longitude:(double)y projection:(HKGridProjection)projection
{   
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMakeWithGridCoordinate(x, y, projection);
    
    if (self = [self initWithLatitude:coord.latitude longitude:coord.longitude])
    {
        
    }
    return self;
}

HKGridProjectionParameters HKGRS80ProjectionParameters(HKGridProjection projection)
{
    HKGridProjectionParameters params;
    
    params.axis = 6378137.0;                    // GRS 80.
    params.flattening = 1.0 / 298.257222101;    // GRS 80.
    params.centralMeridian = 0.0;
    params.latitudeOfOrigin = 0.0;
    params.scale = 1.0;
    params.falseNorthing = 0.0;
    params.falseEasting = 0.0;
    
    switch (projection) {
        case HKGridProjectionRT90_7_5_GonV:
            params.centralMeridian = 11.0 + 18.375/60.0;
            params.scale = 1.000006000000;
            params.falseNorthing = -667.282;
            params.falseEasting = 1500025.141;
            break;
        case HKGridProjectionRT90_5_0_GonV:
            params.centralMeridian = 13.0 + 33.376/60.0;
            params.scale = 1.000005800000;
            params.falseNorthing = -667.130;
            params.falseEasting = 1500044.695;
            break;
        case HKGridProjectionRT90_2_5_GonV:
            params.centralMeridian = 15.0 + 48.0/60.0 + 22.624306/3600.0;
            params.scale = 1.00000561024;
            params.falseNorthing = -667.711;
            params.falseEasting = 1500064.274;
            break;
        case HKGridProjectionRT90_0_0_GonV:
            params.centralMeridian = 18.0 + 3.378/60.0;
            params.scale = 1.000005400000;
            params.falseNorthing = -668.844;
            params.falseEasting = 1500083.521;
            break;
        case HKGridProjectionRT90_2_5_GonO:
            params.centralMeridian = 20.0 + 18.379/60.0;
            params.scale = 1.000005200000;
            params.falseNorthing = -670.706;
            params.falseEasting = 1500102.765;
            break;
        case HKGridProjectionRT90_5_0_GonO:
            params.centralMeridian = 22.0 + 33.380/60.0;
            params.scale = 1.000004900000;
            params.falseNorthing = -672.557;
            params.falseEasting = 1500121.846;
            break;
        default:
            break;
    }
    
    return params;
}

HKGridProjectionParameters HKBesselProjectionParameters(HKGridProjection projection)
{
    HKGridProjectionParameters params;
    
    params.axis = 6377397.155;                  // Bessel 1841.
    params.flattening = 1.0 / 299.1528128;      // Bessel 1841.
    params.centralMeridian = 0.0;
    params.latitudeOfOrigin = 0.0;
    params.scale = 1.0;
    params.falseNorthing = 0.0;
    params.falseEasting = 1500000.0;
    
    switch (projection) {
        case HKGridProjectionBesselRT90_7_5_GonV:
            params.centralMeridian = 11.0 + 18.0/60.0 + 29.8/3600.0;
            break;
        case HKGridProjectionBesselRT90_5_0_GonV:
            params.centralMeridian = 13.0 + 33.0/60.0 + 29.8/3600.0;
            break;
        case HKGridProjectionBesselRT90_2_5_GonV:
            params.centralMeridian = 15.0 + 48.0/60.0 + 29.8/3600.0;
            break;
        case HKGridProjectionBesselRT90_0_0_GonV:
            params.centralMeridian = 18.0 + 3.0/60.0 + 29.8/3600.0;
            break;
        case HKGridProjectionBesselRT90_2_5_GonO:
            params.centralMeridian = 20.0 + 18.0/60.0 + 29.8/3600.0;
            break;
        case HKGridProjectionBesselRT90_5_0_GonO:
            params.centralMeridian = 22.0 + 33.0/60.0 + 29.8/3600.0;
            break;
        default:
            break;
    }
    
    return params;
}


HKGridProjectionParameters HKSWEREF99ProjectionParameters(HKGridProjection projection)
{
    HKGridProjectionParameters params;

    params.axis = 6378137.0;                    // GRS 80.
    params.flattening = 1.0 / 298.257222101;    // GRS 80.
    params.centralMeridian = 0.0;
    params.latitudeOfOrigin = 0.0;
    params.scale = 1.0;
    params.falseNorthing = 0.0;
    params.falseEasting = 150000.0;
    
    switch (projection) {
        case HKGridProjectionSWEREF99_TM:
            params.centralMeridian = 15.0;
            params.latitudeOfOrigin = 0.0;
            params.scale = 0.9996;
            params.falseNorthing = 0.0;
            params.falseEasting = 500000.0;
            break;
        case HKGridProjectionSWEREF99_12_00:
            params.centralMeridian = 12.0;
            break;
        case HKGridProjectionSWEREF99_13_30:
            params.centralMeridian = 13.5;
            break;
        case HKGridProjectionSWEREF99_15_00:
            params.centralMeridian = 15.0;
            break;
        case HKGridProjectionSWEREF99_16_30:
            params.centralMeridian = 16.5;
            break;
        case HKGridProjectionSWEREF99_18_00:
            params.centralMeridian = 18.0;
            break;
        case HKGridProjectionSWEREF99_14_15:
            params.centralMeridian = 14.25;
            break;
        case HKGridProjectionSWEREF99_15_45:
            params.centralMeridian = 15.75;
            break;
        case HKGridProjectionSWEREF99_17_15:
            params.centralMeridian = 17.25;
            break;
        case HKGridProjectionSWEREF99_18_45:
            params.centralMeridian = 18.75;
            break;
        case HKGridProjectionSWEREF99_20_15:
            params.centralMeridian = 20.25;
            break;
        case HKGridProjectionSWEREF99_21_45:
            params.centralMeridian = 21.75;
            break;
        case HKGridProjectionSWEREF99_23_15:
            params.centralMeridian = 23.25;
            break;
        default:
            break;
    }
    
    return params;
}

HKGridProjectionParameters HKTestCaseProjectionParameters()
{
    // Test-case:
    //  Lat: 66 0'0", lon: 24 0'0".
    //  X:1135809.413803 Y:555304.016555.
    
    HKGridProjectionParameters params;
    
    params.axis = 6378137.0;
    params.flattening = 1.0 / 298.257222101;
    params.centralMeridian = 13.0 + 35.0/60.0 + 7.692000/3600.0;
    params.latitudeOfOrigin = 0.0;
    params.scale = 1.000002540000;
    params.falseNorthing = -6226307.8640;
    params.falseEasting = 84182.8790;

    return params;
}


CLLocationCoordinate2D CLLocationCoordinate2DMakeWithGridCoordinate(double x, double y, HKGridProjection projection)
{
    HKGridProjectionParameters params = HKGRS80ProjectionParameters(projection);
    CLLocationCoordinate2D coord = HKGridToGeodetic(x, y, params);
    
    return coord;
}

HKGridCoordinate HKGeodeticToGrid(CLLocationCoordinate2D coord, HKGridProjectionParameters params)
{
    HKGridCoordinate gridCoord;
    
    if (params.centralMeridian == 0.0) {
        return gridCoord;
    }
    
    // Prepare ellipsoid-based stuff.
    double e2 = params.flattening * (2.0 - params.flattening);
    double n = params.flattening / (2.0 - params.flattening);
    double a_roof = params.axis / (1.0 + n) * (1.0 + n * n / 4.0 + n * n * n * n / 64.0);
    double A = e2;
    double B = (5.0 * e2 * e2 - e2 * e2 * e2) / 6.0;
    double C = (104.0 * e2 * e2 * e2 - 45.0 * e2 * e2 * e2 * e2) / 120.0;
    double D = (1237.0 * e2 * e2 * e2 * e2) / 1260.0;
    double beta1 = n / 2.0 - 2.0 * n * n / 3.0 + 5.0 * n * n * n / 16.0 + 41.0 * n * n * n * n / 180.0;
    double beta2 = 13.0 * n * n / 48.0 - 3.0 * n * n * n / 5.0 + 557.0 * n * n * n * n / 1440.0;
    double beta3 = 61.0 * n * n * n / 240.0 - 103.0 * n * n * n * n / 140.0;
    double beta4 = 49561.0 * n * n * n * n / 161280.0;
    
    // Convert.
    double deg_to_rad = M_PI / 180.0;
    double phi = coord.latitude * deg_to_rad;
    double lambda = coord.longitude * deg_to_rad;
    double lambda_zero = params.centralMeridian * deg_to_rad;
    
    double phi_star = phi - sin(phi) * cos(phi) * (A + 
                                                   B * pow(sin(phi), 2.0) + 
                                                   C * pow(sin(phi), 4.0) + 
                                                   D * pow(sin(phi), 6.0));
    double delta_lambda = lambda - lambda_zero;
    double xi_prim = atan(tan(phi_star) / cos(delta_lambda));
    double eta_prim = atanh(cos(phi_star) * sin(delta_lambda));
    double x = params.scale * a_roof * (xi_prim +
                                beta1 * sin(2.0 * xi_prim) * cosh(2.0 * eta_prim) +
                                beta2 * sin(4.0 * xi_prim) * cosh(4.0 * eta_prim) +
                                beta3 * sin(6.0 * xi_prim) * cosh(6.0 * eta_prim) +
                                beta4 * sin(8.0 * xi_prim) * cosh(8.0 * eta_prim)) + 
                                params.falseNorthing;
    
    double y = params.scale * a_roof * (eta_prim +
                                beta1 * cos(2.0 * xi_prim) * sinh(2.0 * eta_prim) +
                                beta2 * cos(4.0 * xi_prim) * sinh(4.0 * eta_prim) +
                                beta3 * cos(6.0 * xi_prim) * sinh(6.0 * eta_prim) +
                                beta4 * cos(8.0 * xi_prim) * sinh(8.0 * eta_prim)) + 
                                params.falseEasting;
    
    gridCoord.x = x; //round(x * 1000.0) / 1000.0;
    gridCoord.y = y; //round(y * 1000.0) / 1000.0;

    return gridCoord;
}

CLLocationCoordinate2D HKGridToGeodetic(double x, double y, HKGridProjectionParameters params)
{
    CLLocationCoordinate2D coord;
    
    if (params.centralMeridian == 0.0) {
        return coord;
    }
    
    // Prepare ellipsoid-based stuff.
    double e2 = params.flattening * (2.0 - params.flattening);
    double n = params.flattening / (2.0 - params.flattening);
    double a_roof = params.axis / (1.0 + n) * (1.0 + n * n/4.0 + n * n * n * n / 64.0);
    double delta1 = n / 2.0 - 2.0 * n * n /3.0 + 37.0 * n * n * n / 96.0 - n * n * n * n /360.0;
    double delta2 = n * n / 48.0 + n * n * n / 15.0 - 437.0 * n * n * n * n / 1440.0;
    double delta3 = 17.0 * n * n * n / 480.0 - 37 * n * n * n * n / 840.0;
    double delta4 = 4397.0 * n * n * n * n / 161280.0;
    
    double Astar = e2 + e2 * e2 + e2 * e2 * e2 + e2 * e2 * e2 *e2;
    double Bstar = -(7.0 * e2 * e2 + 17.0 * e2 * e2 * e2 + 30.0 * e2 * e2 * e2 * e2) / 6.0;
    double Cstar = (224.0 * e2 * e2 * e2 + 889.0 * e2 * e2 * e2 * e2) / 120.0;
    double Dstar = -(4279.0 * e2 * e2 * e2 * e2) / 1260.0;
    
    // Convert.
    double deg_to_rad = M_PI / 180;
    double lambda_zero = params.centralMeridian * deg_to_rad;
    double xi = (x - params.falseNorthing) / (params.scale * a_roof);       
    double eta = (y - params.falseEasting) / (params.scale * a_roof);
    double xi_prim = xi - 
                delta1 * sin(2.0 * xi) * cosh(2.0 * eta) - 
                delta2 * sin(4.0 * xi) * cosh(4.0 * eta) - 
                delta3 * sin(6.0 * xi) * cosh(6.0 * eta) - 
                delta4 * sin(8.0 * xi) * cosh(8.0 * eta);
    double eta_prim = eta - 
                delta1 * cos(2.0 * xi) * sinh(2.0 * eta) - 
                delta2 * cos(4.0 * xi) * sinh(4.0 * eta) - 
                delta3 * cos(6.0 * xi) * sinh(6.0 * eta) - 
                delta4 * cos(8.0 * xi) * sinh(8.0 * eta);
    
    double phi_star = asin(sin(xi_prim) / cosh(eta_prim));
    double delta_lambda = atan(sinh(eta_prim) / cos(xi_prim));
    double lon_radian = lambda_zero + delta_lambda;
    double lat_radian = phi_star + sin(phi_star) * cos(phi_star) * 
                (Astar + 
                 Bstar * pow(sin(phi_star), 2.0) + 
                 Cstar * pow(sin(phi_star), 4.0) + 
                 Dstar * pow(sin(phi_star), 6.0));
    
    coord.latitude = lat_radian * 180.0 / M_PI;
    coord.longitude = lon_radian * 180.0 / M_PI;
    
    return coord;
}

@end
