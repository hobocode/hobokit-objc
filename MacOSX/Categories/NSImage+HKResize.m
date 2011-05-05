//  Copyright (c) 2011 HoboCode
//
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
//

#import "NSImage+HKResize.h"

@implementation NSImage (HKResize)

- (NSImage *)resizedImageWithSize:(CGSize)size
{
    NSImage *result = [[NSImage alloc] initWithSize:NSSizeFromCGSize(size)];
	NSSize	osize = [self size];
	
	[result lockFocus];
	
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	
	[self drawInRect:NSMakeRect( 0.0, 0.0, size.width, size.height )
			fromRect:NSMakeRect( 0.0, 0.0, osize.width, osize.height )
		   operation:NSCompositeSourceOver
			fraction:1.0];
	
	[result unlockFocus];
	
	return [result autorelease];
    
}

@end