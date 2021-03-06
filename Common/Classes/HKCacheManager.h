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

#import <Foundation/Foundation.h>

#import <sqlite3.h>

#ifdef HK_DEBUG
# define HK_DEBUG_CACHE
#endif

#define HK_CACHE_MEMORY_LIMIT   1048576

typedef void (^HKCacheManagerCompletionHandler)( BOOL success, NSString *identifier, NSError *error );
typedef void (^HKCacheManagerProgressHandler)( double progress );

@interface HKCacheManager : NSObject
{
@private
	sqlite3			   *_database;
	sqlite3_stmt	   *_select;
	sqlite3_stmt	   *_insert;
	sqlite3_stmt	   *_update;
	sqlite3_stmt	   *_selectIdentifiers;
	dispatch_queue_t	_queue;

    NSString            *_path;
    NSMutableDictionary *_fastcache;
    NSMutableArray      *_fastcacheIdentifiers;
    NSMutableArray      *_fastcacheSizes;
    NSUInteger           _fastcacheSize;
}

@property (nonatomic, retain) NSString *path;

+ (HKCacheManager *)defaultManager;
+ (HKCacheManager *)cacheManagerWithPath:(NSString *)path;

- (id)initWithPath:(NSString *)path;

- (NSData *)cachedDataWithIdentifier:(NSString *)identifier;
- (void)cacheData:(NSData *)data withIdentifier:(NSString *)identifier;

- (void)cacheURL:(NSURL *)url completionHandler:(HKCacheManagerCompletionHandler)handler;
- (void)cacheURL:(NSURL *)url identifier:(NSString *)identifier progressHandler:(HKCacheManagerProgressHandler)progressHandler completionHandler:(HKCacheManagerCompletionHandler)completionHandler;

- (NSArray *)allIdentifiers;

@end