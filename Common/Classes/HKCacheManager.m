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

#import "HKCacheManager.h"

static HKCacheManager *gHCCacheManager = nil;

@interface HKCacheManager (HKPrivate)

- (void)setup;

@end

@implementation HKCacheManager

#pragma mark HKSingleton

+ (id)alloHKithZone:(NSZone *)zone
{
    @synchronized(self)
	{
        if ( gHCCacheManager == nil )
		{
            gHCCacheManager = [super allocWithZone:zone];
			
            return gHCCacheManager;
        }
    }
	
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return UINT_MAX;
}

- (void)release
{
}

- (id)autorelease
{
    return self;
}

- (id)init
{
	if ( self = [super init] )
	{
		[self setup];
	}
	
	return self;
}

- (void)dealloc
{
#ifdef HK_DEBUG_DEALLOC
	NSLog(@"Dealloc: %@", self);
#endif

	if ( _database )
	{
		sqlite3_close( _database ); _database = nil;
	}
	
	if ( _queue )
	{
		dispatch_release( _queue ); _queue = nil;
	}
	
	[super dealloc];
}

#pragma mark HKPublic API

+ (HKCacheManager *)defaultManager
{
    @synchronized ( self )
	{
        if ( gHCCacheManager == nil )
		{
            [[self alloc] init];
        }
    }
	
    return gHCCacheManager;
}

- (NSData *)cachedDataWithIdentifier:(NSString *)identifier
{
	__block NSData *retval = nil;
	
	if ( identifier == nil )
		return nil;
	
#ifdef HK_DEBUG_CACHE
	NSDate *s, *e;
	
	s = [NSDate date];
#endif
	
	const char *cidentifier = [identifier UTF8String];
	const int cilength = strlen( cidentifier );
	
	dispatch_sync( _queue, ^ {
		sqlite3_bind_text( _select, 1, cidentifier, cilength, NULL );
		
		if ( sqlite3_step( _select ) == SQLITE_ROW )
		{
			if ( sqlite3_column_type( _select, 0 ) == SQLITE_BLOB )
			{
				const void *bytes;
				int length;
				
				bytes = sqlite3_column_blob( _select, 0 );
				length = sqlite3_column_bytes( _select, 0 );
				
				if ( length > 0 )
				{
#ifdef HK_DEBUG_CACHE
					NSLog(@"HKCacheManager->Successfully loaded cache with identifier: %@", identifier);
#endif
					retval = [NSData dataWithBytes:bytes length:length];
				}
			}
		}
		
		sqlite3_reset( _select );
	});
	
#ifdef HK_DEBUG_CACHE
	e = [NSDate date];
	
	NSLog(@"HKCacheManager->Last cache transaction (load): %f ms", [e timeIntervalSinceDate:s] * 1000.0f);
#endif
	
	return retval;
}

- (void)cacheData:(NSData *)data withIdentifier:(NSString *)identifier
{
	if ( identifier == nil )
		return;
	
#ifdef HK_DEBUG_CACHE
	NSDate *s, *e;
	
	s = [NSDate date];
#endif
	
	const char *cidentifier = [identifier UTF8String];
	const void *cdata = [data bytes];
	const int cilength = strlen( cidentifier );
	const int cdlength = [data length];
	
	dispatch_sync( _queue, ^ {
		sqlite3_bind_text( _insert, 1, cidentifier, cilength, NULL );
		sqlite3_bind_blob( _insert, 2, cdata, cdlength, NULL );
		
		if ( sqlite3_step( _insert ) == SQLITE_DONE )
		{
#ifdef HK_DEBUG_CACHE
			NSLog(@"HKCacheManager->Successfully saved cache with identifier: %@", identifier);
#endif
		}
		
		sqlite3_reset( _insert );
	});
	
#ifdef HK_DEBUG_CACHE
	e = [NSDate date];
	
	NSLog(@"HKCacheManager->Last cache transaction (save): %f ms", [e timeIntervalSinceDate:s] * 1000.0f);
#endif
}

#pragma mark HKPrivate API

- (void)setup
{
	@synchronized (self)
	{
		if ( _database == nil )
		{
			NSFileManager   *fm = [NSFileManager defaultManager];
            NSString        *dir = [NSFileManager applicationSupportDirectory];
            NSString        *path = [dir stringByAppendingPathComponent:@"Cache.db"];
            NSError         *error = nil;
            
            if ( ![fm fileExistsAtPath:dir isDirectory:NULL] )
            {
                if ( ![fm createDirectoryAtPath:dir withIntermediateDirectories:NO attributes:nil error:&error] )
                {
#ifdef HK_DEBUG_ERRORS
                    NSLog(@"HKCacheManager::setup->Error: '%@'", error);
#endif
                    return;
                }
            }
			
			if ( path )
			{
				if ( sqlite3_open( [path UTF8String], &_database ) != SQLITE_OK )
				{
#ifdef HK_DEBUG_CACHE
					NSLog(@"HKCacheManager->Error: 'Couldn't create cache database!'");
#endif
					abort();
				}
				
				sqlite3_stmt *table_stmt;
				
				if ( sqlite3_prepare_v2( _database, "CREATE TABLE IF NOT EXISTS cache ( pk INTEGER PRIMARY KEY AUTOINCREMENT, identifier STRING, data BLOB )", -1, &table_stmt, NULL ) != SQLITE_OK )
				{
#ifdef HK_DEBUG_CACHE
					NSLog(@"HKCacheManager->Error: 'Couldn't create database cache table statement!'");
#endif
					abort();
				}
				
				if ( sqlite3_step( table_stmt ) != SQLITE_DONE )
				{
#ifdef HK_DEBUG_CACHE
					NSLog(@"HKCacheManager->Error: 'Couldn't execute database cache table statement!'");
#endif
					abort();
				}
				
				sqlite3_finalize( table_stmt );
				
				if ( sqlite3_prepare_v2( _database, "CREATE INDEX IF NOT EXISTS identifier_index on cache ( identifier )", -1, &table_stmt, NULL ) != SQLITE_OK )
				{
#ifdef HK_DEBUG_CACHE
					NSLog(@"HKCacheManager->Error: 'Couldn't create database cache identifier index statement!'");
#endif
					abort();
				}
				
				if ( sqlite3_step( table_stmt ) != SQLITE_DONE )
				{
#ifdef HK_DEBUG_CACHE
					NSLog(@"HKCacheManager->Error: 'Couldn't execute database cache identifier index statement!'");
#endif
					abort();
				}
				
				sqlite3_finalize( table_stmt );
			}
			
			if ( _select )
			{
				sqlite3_finalize( _select ); _select = nil;
			}
			
			if ( sqlite3_prepare_v2( _database, "SELECT data from cache WHERE identifier = ?", -1, &_select, NULL ) != SQLITE_OK )
			{
#ifdef HK_DEBUG_CACHE
				NSLog(@"HKCacheManager->Error: 'Couldn't create database data select statement!'");
#endif
				abort();
			}
			
			if ( _insert )
			{
				sqlite3_finalize( _insert ); _insert = nil;
			}
			
			if ( sqlite3_prepare_v2( _database, "INSERT INTO cache ( identifier, data ) VALUES ( ?, ? )", -1, &_insert, NULL ) != SQLITE_OK )
			{
#ifdef HK_DEBUG_CACHE
				NSLog(@"HKCacheManager->Error: 'Couldn't create database data insert statement!'");
#endif
				abort();
			}
		}
		
		if ( _queue == nil )
		{
			_queue = dispatch_queue_create( HK_CACHE_MANAGER_GCD_QUEUE_LABEL, NULL );
		}
	}
}

@end
