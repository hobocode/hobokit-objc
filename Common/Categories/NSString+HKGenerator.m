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

#import "NSString+HKGenerator.h"

#import <CommonCrypto/CommonDigest.h>

static unsigned char gBase36[36] = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8',
    '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',
    'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q',
    'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
};

@implementation NSString (NSString_HKGenerator)

+ (NSString *)UUIDString
{
    CFUUIDRef   uuid = CFUUIDCreate( kCFAllocatorDefault );
    CFStringRef uuids = CFUUIDCreateString( kCFAllocatorDefault, uuid );
    
    CFRelease( uuid );
    
    return [(NSString *)uuids autorelease];
}

+ (NSString *)randomBase36StringOfLength:(NSUInteger)length
{
    NSMutableString *retval = [NSMutableString stringWithCapacity:length];
    NSUInteger       randidx;
    
    for ( NSUInteger i = 0 ; i < length ; i++ )
    {
        randidx = arc4random() % 36;
        
        [retval appendFormat:@"%c", gBase36[randidx]];
    }
    
    return retval;
}

+ (NSString *)randomBase16StringOfLength:(NSUInteger)length
{
    NSMutableString *retval = [NSMutableString stringWithCapacity:length];
    NSUInteger       randidx;
    
    for ( NSUInteger i = 0 ; i < length ; i++ )
    {
        randidx = arc4random() % 16;
        
        [retval appendFormat:@"%c", gBase36[randidx]];
    }
    
    return retval;
}

+ (NSString *)randomBase10StringOfLength:(NSUInteger)length
{
    NSMutableString *retval = [NSMutableString stringWithCapacity:length];
    NSUInteger       randidx;
    
    for ( NSUInteger i = 0 ; i < length ; i++ )
    {
        randidx = arc4random() % 10;
        
        [retval appendFormat:@"%c", gBase36[randidx]];
    }
    
    return retval;
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (NSString *)hexStringFromColor:(UIColor *)color
{
    CGFloat r, g, b;
    
    if ( ![color getRed:&r green:&g blue:&b alpha:NULL] )
        return nil;
    
    return [NSString stringWithFormat:@"#%02x%02x%02x", ((int)(r * 255.0)), ((int)(g * 255.0)), ((int)(b * 255.0))];
}
#else
+ (NSString *)hexStringFromColor:(NSColor *)color
{
    NSString *cspace = [color colorSpaceName];
    NSColor  *converted = color;
    
    if ( !([cspace isEqualToString:NSDeviceRGBColorSpace] || [cspace isEqualToString:NSCalibratedRGBColorSpace]) )
    {
        converted = [color colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
    }
    
    if ( converted == nil )
        return nil;
    
    CGFloat r, g, b;
    
    [converted getRed:&r green:&g blue:&b alpha:NULL];
    
    return [NSString stringWithFormat:@"#%02x%02x%02x", ((int)(r * 255.0)), ((int)(g * 255.0)), ((int)(b * 255.0))];
}
#endif

- (NSString *)ASCIISlugString
{
    NSData                  *ASCIIData = [self dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString                *ASCIIString = [[[NSString alloc] initWithData:ASCIIData encoding:NSASCIIStringEncoding] autorelease];
    NSMutableCharacterSet   *characters = [[[NSMutableCharacterSet alloc] init] autorelease];
    NSMutableString         *retval;
    NSRange                  srange, frange;
    
    ASCIIString = [ASCIIString lowercaseString];
    
    retval = [NSMutableString stringWithString:ASCIIString];
    
    [characters formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    [characters formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    [characters invert];
    
    srange = NSMakeRange( 0, [retval length] );
    
    do
    {
        frange = [retval rangeOfCharacterFromSet:characters options:0 range:srange];
        
        if ( frange.location == NSNotFound )
            break;
        
        [retval replaceCharactersInRange:frange withString:@""];
        
        srange.location = frange.location;
        srange.length = [retval length] - srange.location;
        
    } while ( YES );
    
    [retval replaceOccurrencesOfString:@" " withString:@"-" options:0 range:NSMakeRange( 0, [retval length] )];
    
    return [NSString stringWithString:retval];
}

- (NSString *)SHA1Digest
{
    NSMutableString *retval = [NSMutableString stringWithCapacity:(CC_SHA1_DIGEST_LENGTH * 2)];
    const char      *cstr = [self cStringUsingEncoding:NSUTF8StringEncoding];    
    uint8_t          digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1( cstr, strlen(cstr), digest );
        
    for ( int i = 0 ; i < CC_SHA1_DIGEST_LENGTH ; i++ )
    {
        [retval appendFormat:@"%02x", digest[i]];
    }
    
    return [NSString stringWithString:retval];
}

@end