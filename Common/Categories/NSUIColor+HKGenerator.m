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

#import "NSUIColor+HKGenerator.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
@implementation UIColor (HKGenerator)

+ (UIColor *)colorFromHexString:(NSString *)string
{
    if ( string == nil )
        return nil;
    
    int r, g, b;
    int result = sscanf( [string UTF8String], "#%02x%02x%02x", &r, &g, &b );
    
    if ( result == 3 )
    {
        return [UIColor colorWithRed:(r / 255.0) green:(g / 255.0) blue:(b / 255.0) alpha:1.0];
    }
    
    return nil;
}

@end
#else
CGColorRef CGColorCreateFromNSColor ( CGColorSpaceRef colorSpace, NSColor *color )
{
    NSColor *deviceColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
    CGFloat  components[4];
    
    [deviceColor getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
    
    return CGColorCreate( colorSpace, components );
}

@implementation NSColor (HKGenerator)

+ (NSColor *)colorFromHexString:(NSString *)string
{
    if ( string == nil )
        return nil;
    
    int r, g, b;
    int result = sscanf( [string UTF8String], "#%02x%02x%02x", &r, &g, &b );
    
    if ( result == 3 )
    {
        return [NSColor colorWithDeviceRed:(r / 255.0) green:(g / 255.0) blue:(b / 255.0) alpha:1.0];
    }
    
    return nil;
}

@end
#endif
