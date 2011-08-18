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

#import "HKCacheManager.h"

#import "NSFileManager+HKApplicationSupport.h"
#import "NSString+HKGenerator.h"

static HKCacheManager *gHKCacheManager = nil;

@interface HKCacheManager (HKPrivate)

- (BOOL)setup;

@end

@implementation HKCacheManager

@synthesize path = _path;

- (id)initWithPath:(NSString *)path
{
    BOOL success = NO;

    if ( self = [super init] )
    {
        self.path = path;

        success = [self setup];
    }

    if ( !success )
    {
        [self release];
        return nil;
    }

    return self;
}

+ (HKCacheManager *)cacheManagerWithPath:(NSString *)path
{
    return [[[HKCacheManager alloc] initWithPath:path] autorelease];
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

    [_path release];

    [super dealloc];
}

#pragma mark HKPublic API

+ (HKCacheManager *)defaultManager
{
    @synchronized ( self )
    {
        if ( gHKCacheManager == nil )
        {
            NSString *path = [[NSFileManager applicationSupportDirectory] stringByAppendingPathComponent:@"Cache.db"];

            gHKCacheManager = [[self alloc] initWithPath:path];
        }
    }
    
    return gHKCacheManager;
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

- (void)cacheURL:(NSURL *)url completionHandler:(HKCacheManagerCompletionHandler)handler
{
    dispatch_queue_t cqueue = dispatch_get_current_queue();
    
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^ {
        NSError *error = nil;
        NSData  *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
        
        if ( data != nil )
        {
            NSString *identifier = [NSString randomBase36StringOfLength:12];
            
            [self cacheData:data withIdentifier:identifier];
            
            dispatch_async( cqueue, ^{
                handler( YES, identifier, nil );
            });
        }
        else
        {
            dispatch_async( cqueue, ^{
                handler( NO, nil, error );
            });
        }
    });
}

#pragma mark HKPrivate API

- (BOOL)setup
{
    @synchronized (self)
    {
        if ( _database == nil )
        {
            NSFileManager   *fm = [[NSFileManager alloc] init];
            NSString        *dir = [self.path stringByDeletingLastPathComponent];
            NSError         *error = nil;

            if ( ![fm fileExistsAtPath:dir isDirectory:NULL] )
            {
                if ( ![fm createDirectoryAtPath:dir withIntermediateDirectories:NO attributes:nil error:&error] )
                {
#ifdef HK_DEBUG_ERRORS
                    NSLog(@"HKCacheManager::setup->Error: '%@'", error);
#endif
                    return NO;
                }
            }

            [fm release], fm = nil;

            if ( !_path )
            {
                [NSException raise:@"HKNilObjectException" format:@"Path cannot be nil"];
            }
            else
            {
                if ( sqlite3_open( [_path UTF8String], &_database ) != SQLITE_OK )
                {
#ifdef HK_DEBUG_CACHE
                    NSLog(@"HKCacheManager->Error: 'Couldn't create cache database!'");
#endif
                    return NO;
                }
                
                sqlite3_stmt *table_stmt;
                
                if ( sqlite3_prepare_v2( _database, "CREATE TABLE IF NOT EXISTS cache ( pk INTEGER PRIMARY KEY AUTOINCREMENT, identifier STRING, data BLOB )", -1, &table_stmt, NULL ) != SQLITE_OK )
                {
#ifdef HK_DEBUG_CACHE
                    NSLog(@"HKCacheManager->Error: 'Couldn't create database cache table statement!'");
#endif
                    return NO;
                }
                
                if ( sqlite3_step( table_stmt ) != SQLITE_DONE )
                {
#ifdef HK_DEBUG_CACHE
                    NSLog(@"HKCacheManager->Error: 'Couldn't execute database cache table statement!'");
#endif
                    return NO;
                }
                
                sqlite3_finalize( table_stmt );
                
                if ( sqlite3_prepare_v2( _database, "CREATE INDEX IF NOT EXISTS identifier_index on cache ( identifier )", -1, &table_stmt, NULL ) != SQLITE_OK )
                {
#ifdef HK_DEBUG_CACHE
                    NSLog(@"HKCacheManager->Error: 'Couldn't create database cache identifier index statement!'");
#endif
                    return NO;
                }
                
                if ( sqlite3_step( table_stmt ) != SQLITE_DONE )
                {
#ifdef HK_DEBUG_CACHE
                    NSLog(@"HKCacheManager->Error: 'Couldn't execute database cache identifier index statement!'");
#endif
                    return NO;
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
                return NO;
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
                return NO;
            }
        }
        
        if ( _queue == nil )
        {
            NSString *queueName = [NSString stringWithFormat:@"%@.gcd.queue.cachemanager-%p", [[NSBundle mainBundle] bundleIdentifier], self];
            _queue = dispatch_queue_create( [queueName UTF8String], NULL );
        }
    }

    return YES;
}

@end
