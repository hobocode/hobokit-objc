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

#import <Foundation/Foundation.h>

#ifdef HK_DEBUG
# define HK_DEBUG_CACHE
#endif

#define HK_CACHE_MANAGER_GCD_QUEUE_LABEL     "se.hobocode.gcd.queue.cachemanager"

@interface HKCacheManager : NSObject
{
@private
	sqlite3			   *_database;
	sqlite3_stmt	   *_select;
	sqlite3_stmt	   *_insert;
	dispatch_queue_t	_queue;
}

@end

@interface HKCacheManager (HKPublic)

+ (HKCacheManager *)defaultManager;

- (NSData *)cachedDataWithIdentifier:(NSString *)identifier;
- (void)cacheData:(NSData *)data withIdentifier:(NSString *)identifier;

@end