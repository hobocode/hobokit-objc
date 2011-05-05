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

#import "HKDataStore.h"

static HKDataStore *gHKDataStore = nil;

@interface HKDataStore (HKPrivate)

- (void)setup;

- (NSString *)applicationSupportDirectory;

@end

@implementation HKDataStore

#pragma mark HKSingleton API

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if ( gHKDataStore == nil )
        {
            gHKDataStore = [super allocWithZone:zone];
            
            return gHKDataStore;
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
    [_model release]; _model = nil;
    [_context release]; _context = nil;
    [_coordinator release]; _coordinator = nil;
    [super dealloc];
}

#pragma mark HKPublic API

@synthesize context = _context;

+ (HKDataStore *)defaultStore
{
    @synchronized ( self )
    {
        if ( gHKDataStore == nil )
        {
            [[self alloc] init];
        }
    }
    
    return gHKDataStore;
}

- (void)synchronizedWithContext:(HKDataStoreHandler)handler
{
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_queue_t current = dispatch_get_current_queue();
    
    if ( current == main )
    {        
        handler( _context );
    }
    else
    {
        dispatch_sync( main, ^{
            handler( _context );
        });
    }
}

- (void)asynchronizedWithContext:(HKDataStoreHandler)handler
{
    dispatch_async( dispatch_get_main_queue(), ^{
        handler( _context );
    });
}

- (void)synchronizedAndSaveWithContext:(HKDataStoreHandler)handler
{
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_queue_t current = dispatch_get_current_queue();
    
    if ( current == main )
    {
        NSError *error = nil;
        
        handler( _context );
        
        if ( ![_context save:&error] )
        {
#ifdef HK_DEBUG_ERRORS
            NSLog(@"HKDataStore::synchronizedAndSaveWithContext->Error: '%@' : '%@'", error, [[error userInfo] objectForKey:NSDetailedErrorsKey]);
#endif
        }
    }
    else
    {
        dispatch_sync( main, ^{
            NSError *error = nil;
            
            handler( _context );
            
            if ( ![_context save:&error] )
            {
#ifdef HK_DEBUG_ERRORS
                NSLog(@"HKDataStore::synchronizedAndSaveWithContext->Error: '%@' : '%@'", error, [[error userInfo] objectForKey:NSDetailedErrorsKey]);
#endif
            }
        });
    }
}

- (void)asynchronizedAndSaveWithContext:(HKDataStoreHandler)handler
{
    dispatch_async( dispatch_get_main_queue(), ^{
        NSError *error = nil;
        
        handler( _context );
        
        if ( ![_context save:&error] )
        {
#ifdef HK_DEBUG_ERRORS
            NSLog(@"HKDataStore::asynchronizedAndSaveWithContext->Error: '%@' : '%@'", error, [[error userInfo] objectForKey:NSDetailedErrorsKey]);
#endif
        }
    });
}

#pragma mark HKPrivate API

- (void)setup
{
    if ( _model == nil )
    {
        _model = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
    }
    
    if ( _coordinator == nil )
    {
        NSFileManager   *fm = [NSFileManager defaultManager];
        NSString        *dir = [self applicationSupportDirectory];
        NSURL           *url = [NSURL fileURLWithPath:[dir stringByAppendingPathComponent:@"Data.db"]];
        NSError         *error = nil;
        
        if ( ![fm fileExistsAtPath:dir isDirectory:NULL] )
        {
            if ( ![fm createDirectoryAtPath:dir withIntermediateDirectories:NO attributes:nil error:&error] )
            {
#ifdef HK_DEBUG_ERRORS
                NSLog(@"HKDataStore::setup->Error: '%@'", error);
#endif
                return;
            }
        }
        
        _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
        
        if ( ![_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error] )
        {
#ifdef HK_DEBUG_ERRORS
            NSLog(@"HKDataStore::setup->Error: '%@'", error);
#endif
            return;
        }
    }
    
    if ( _context == nil )
    {
        _context = [[NSManagedObjectContext alloc] init];
        
        [_context setPersistentStoreCoordinator:_coordinator];
    }
}

- (NSString *)applicationSupportDirectory
{
    NSArray     *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    NSString    *base = ( ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory() );
    NSString    *appname = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
    
    return [base stringByAppendingPathComponent:appname];
}

@end
