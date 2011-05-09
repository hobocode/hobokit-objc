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

#import "NSData+HKBase64.h"

static char gEncodingTable[64] = {
		'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
		'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
		'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
		'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
};

@implementation NSData (NSData_HKBase64)

- (NSString *)base64Encoding
{
	return [self base64EncodingWithLineLength:0];
}

- (NSString *)base64EncodingWithLineLength:(NSUInteger)lineLength
{
    NSMutableString     *retval = [NSMutableString stringWithCapacity:self.length];
	const unsigned char	*bytes = [self bytes];
	unsigned long        ixtext = 0;
	unsigned long        lentext = self.length;
    unsigned long        ix = 0;
	unsigned char        inbuf[3], outbuf[4];
	unsigned short       i = 0;
	unsigned short       charsonline = 0, ctcopy = 0;
    long                 ctremaining = 0;

	while( YES )
    {
		ctremaining = lentext - ixtext;
        
		if ( ctremaining <= 0 )
            break;

		for ( i = 0 ; i < 3 ; i++ )
        {
			ix = ixtext + i;
            
			if ( ix < lentext )
                inbuf[i] = bytes[ix];
			else
                inbuf[i] = 0;
		}

		outbuf[0] = (inbuf[0] & 0xFC) >> 2;
		outbuf[1] = ((inbuf[0] & 0x03) << 4) | ((inbuf[1] & 0xF0) >> 4);
		outbuf[2] = ((inbuf[1] & 0x0F) << 2) | ((inbuf[2] & 0xC0) >> 6);
		outbuf[3] = inbuf[2] & 0x3F;
        
		ctcopy = 4;

		switch( ctremaining )
        {
            case 1:
                ctcopy = 2;
                break;
            
            case 2:
                ctcopy = 3;
                break;
		}

		for ( i = 0 ; i < ctcopy ; i++ )
			[retval appendFormat:@"%c", gEncodingTable[outbuf[i]]];

		for ( i = ctcopy ; i < 4 ; i++ )
			[retval appendString:@"="];

		ixtext += 3;
		charsonline += 4;

		if ( lineLength > 0 )
        {
			if ( charsonline >= lineLength )
            {
				charsonline = 0;
			
                [retval appendString:@"\n"];
			}
		}
	}

	return [NSString stringWithString:retval];
}

@end
