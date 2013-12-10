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

#import "HKURLOperation.h"

#import "NSFileManager+HKDirectories.h"
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
    
    _fastcache = [[NSMutableDictionary alloc] initWithCapacity:10];
    _fastcacheIdentifiers = [[NSMutableArray alloc] initWithCapacity:10];
    _fastcacheSizes = [[NSMutableArray alloc] initWithCapacity:10];
    _fastcacheSize = 0;

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
    [_fastcache release];
    [_fastcacheIdentifiers release];
    [_fastcacheSizes release];
    [super dealloc];
}

#pragma mark HKPublic API

+ (HKCacheManager *)defaultManager
{
    @synchronized ( self )
    {
        if ( gHKCacheManager == nil )
        {
            NSString *path = [[NSFileManager cacheDirectory] stringByAppendingPathComponent:@"Cache.db"];

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
    
    const char *cidentifier = [identifier UTF8String];
    const int cilength = (int)strlen( cidentifier );
    
    dispatch_sync( _queue, ^ {
        if ( (retval = [_fastcache objectForKey:identifier]) == nil )
        {
            int length = 0;
            
            sqlite3_bind_text( _select, 1, cidentifier, cilength, NULL );
            
            if ( sqlite3_step( _select ) == SQLITE_ROW )
            {
                if ( sqlite3_column_type( _select, 0 ) == SQLITE_BLOB )
                {
                    const void *bytes;
                    
                    bytes = sqlite3_column_blob( _select, 0 );
                    length = sqlite3_column_bytes( _select, 0 );
                    
                    if ( length > 0 )
                    {
#ifdef HK_DEBUG_CACHE
                        NSLog(@"HKCacheManager->Successfully loaded cache (size='%d') with identifier: %@", length, identifier);
#endif
                        retval = [NSData dataWithBytes:bytes length:length];
                    }
                }
            }
            
            sqlite3_reset( _select );
            
            if ( retval != nil && length < HK_CACHE_MEMORY_LIMIT )
            {
                NSString    *cident;
                NSNumber    *csize;
                NSUInteger   goal = (HK_CACHE_MEMORY_LIMIT - length);
                
                while ( _fastcacheSize > goal )
                {
                    cident = [_fastcacheIdentifiers objectAtIndex:0];
                    csize = [_fastcacheSizes objectAtIndex:0];
                    
                    [_fastcache removeObjectForKey:cident];
                    
                    _fastcacheSize -= [csize unsignedIntegerValue];
                    
                    [_fastcacheIdentifiers removeObjectAtIndex:0];
                    [_fastcacheSizes removeObjectAtIndex:0];
                }
                
                [_fastcacheIdentifiers addObject:identifier];
                [_fastcacheSizes addObject:[NSNumber numberWithInt:length]];
                [_fastcache setObject:retval forKey:identifier];
                
                _fastcacheSize += length;
            }
        }
#ifdef HK_DEBUG_CACHE
        else
        {
            NSLog(@"HKCacheManager->Successfully loaded fastcache with identifier: %@", identifier);
        }
#endif
    });
        
    return retval;
}

- (void)clearFastCacheForIdentifier:(NSString *)identifier
{
    NSNumber    *csize;
    NSUInteger   index = [_fastcacheIdentifiers indexOfObject:identifier];
    
    if ( index == NSNotFound )
        return;
    
    csize = [_fastcacheSizes objectAtIndex:index];
        
    [_fastcache removeObjectForKey:identifier];
    
    _fastcacheSize -= [csize unsignedIntegerValue];
    
    [_fastcacheIdentifiers removeObjectAtIndex:index];
    [_fastcacheSizes removeObjectAtIndex:index];
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
    const int cilength = (int)strlen( cidentifier );
    const int cdlength = (int)[data length];
    
    dispatch_sync( _queue, ^ {
        sqlite3_bind_blob( _update, 1, cdata, cdlength, NULL );
        sqlite3_bind_text( _update, 2, cidentifier, cilength, NULL );
        
        sqlite3_step( _update );
        sqlite3_reset( _update );
        
        if ( sqlite3_changes( _database ) > 0 )
        {
#ifdef HK_DEBUG_CACHE
            NSLog(@"HKCacheManager->Successfully updated cache with identifier: %@", identifier);
#endif
        }
        else
        {
            sqlite3_bind_text( _insert, 1, cidentifier, cilength, NULL );
            sqlite3_bind_blob( _insert, 2, cdata, cdlength, NULL );
            
            if ( sqlite3_step( _insert ) == SQLITE_DONE )
            {
#ifdef HK_DEBUG_CACHE
                NSLog(@"HKCacheManager->Successfully saved cache with identifier: %@", identifier);
#endif
            }
            
            sqlite3_reset( _insert );
        }
        
        [self clearFastCacheForIdentifier:identifier];
    });
    
#ifdef HK_DEBUG_CACHE
    e = [NSDate date];
    
    NSLog(@"HKCacheManager->Last cache transaction (save): %f ms", [e timeIntervalSinceDate:s] * 1000.0f);
#endif
}

- (void)cacheURL:(NSURL *)url completionHandler:(HKCacheManagerCompletionHandler)handler
{
    [self cacheURL:url identifier:[url absoluteString] progressHandler:nil completionHandler:handler];
}

- (void)cacheURL:(NSURL *)url identifier:(NSString *)identifier progressHandler:(HKCacheManagerProgressHandler)progressHandler completionHandler:(HKCacheManagerCompletionHandler)completionHandler
{
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0 ), ^ {
        HKURLOperation *operation = [[HKURLOperation alloc] initWithURL:url
                                                        progressHandler:^( double progress ) {
                                                            if ( progressHandler != nil )
                                                            {
                                                                dispatch_async( dispatch_get_main_queue(), ^{
                                                                    progressHandler( progress ); 
                                                                });
                                                            }
                                                        }
                                                      completionHandler:^( BOOL success, NSURLResponse *response, NSData *data, NSError *error ) {
                                                          if ( success )
                                                          {
                                                              NSString *sid = identifier;
                                                              
                                                              if ( sid == nil )
                                                              {
                                                                  sid = [NSString randomBase36StringOfLength:12];
                                                              }
                                                              
                                                              [self cacheData:data withIdentifier:sid];
                                                              
                                                              dispatch_async( dispatch_get_main_queue(), ^{
                                                                  completionHandler( YES, sid, nil );
                                                              });
                                                          }
                                                          else
                                                          {
                                                              dispatch_async( dispatch_get_main_queue(), ^{
                                                                  completionHandler( NO, nil, error );
                                                              });
                                                          }
                                                      }];
        
        [operation start];
        [operation waitUntilFinished];
        [operation release];
    });
}

- (NSArray *)allIdentifiers
{
    NSMutableArray *retval = [NSMutableArray array];

#ifdef HK_DEBUG_CACHE
    NSDate *s, *e;

    s = [NSDate date];
#endif

    dispatch_sync( _queue, ^ {

        while ( sqlite3_step( _selectIdentifiers ) == SQLITE_ROW )
        {
            if ( sqlite3_column_type( _selectIdentifiers, 0 ) == SQLITE_TEXT )
            {
                const unsigned char *bytes = sqlite3_column_text( _selectIdentifiers, 0 );

                NSString *identifier = [NSString stringWithUTF8String:(const char *)bytes];

                [retval addObject:identifier];
            }
        }

        sqlite3_reset( _selectIdentifiers );
    });

#ifdef HK_DEBUG_CACHE
    e = [NSDate date];

    NSLog(@"HKCacheManager->Last cache transaction (load): %f ms", [e timeIntervalSinceDate:s] * 1000.0f);
#endif

    return retval;
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

            if ( _selectIdentifiers )
            {
                sqlite3_finalize( _selectIdentifiers ); _selectIdentifiers = nil;
            }

            if ( sqlite3_prepare_v2( _database, "SELECT identifier from cache", -1, &_selectIdentifiers, NULL ) != SQLITE_OK )
            {
#ifdef HK_DEBUG_CACHE
                NSLog(@"HKCacheManager->Error: 'Couldn't create database identifiers select statement!'");
#endif
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
            
            if ( _update )
            {
                sqlite3_finalize( _update ); _update = nil;
            }
            
            if ( sqlite3_prepare_v2( _database, "UPDATE cache SET data = ? WHERE identifier = ?", -1, &_update, NULL ) != SQLITE_OK )
            {
#ifdef HK_DEBUG_CACHE
                NSLog(@"HKCacheManager->Error: 'Couldn't create database data update statement!'");
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
