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

#ifndef HOBO_KIT_DEFINES_H
#define HOBO_KIT_DEFINES_H

#ifdef HK_DEBUG
# define HK_DEBUG_DEALLOC
# define HK_DEBUG_ERRORS
# define HK_DEBUG_PROFILE
# define HK_DEBUG_REST_API
#endif

#define HK_ERROR_DOMAIN                         @"com.hobocode.error"

#define HK_RGBTF(rgb)                           (float)((rgb)) / 255.0)

#define HK_COLOR_IPHONE_BLUE                    [UIColor colorWithRed:HK_RGBTF(56) green:HK_RGBTF(84) blue:HK_RGBTF(135) alpha:1.0]

#endif
