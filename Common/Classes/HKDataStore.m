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

#import "NSFileManager+HKApplicationSupport.h"

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

- (oneway void)release
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
    [_bundles release]; _bundles = nil;
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

- (NSManagedObjectContext *)context
{
    if ( !_setup )
    {
        [self setup];
    }

    return _context;
}

- (void)addModelBundle:(NSBundle *)bundle
{
    @synchronized (self)
    {
        if ( _bundles == nil )
        {
            _bundles = [[NSMutableSet alloc] init];
        }
        
        if ( bundle != nil )
        {
            [_bundles addObject:bundle];
        }
    }
}

- (void)synchronizedWithContext:(HKDataStoreHandler)handler
{
    if ( !_setup )
    {
        [self setup];
    }
    
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
    if ( !_setup )
    {
        [self setup];
    }
    
    dispatch_async( dispatch_get_main_queue(), ^{
        handler( _context );
    });
}

- (void)synchronizedAndSaveWithContext:(HKDataStoreHandler)handler
{
    if ( !_setup )
    {
        [self setup];
    }
    
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
    if ( !_setup )
    {
        [self setup];
    }
    
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

- (void)registerChangeHandler:(HKDataStoreChangeHandler)changeHandler forEntityWithName:(NSString *)entityName
{
    @synchronized (self)
    {
        NSMutableSet *handlers = nil;
        
        if ( _changeHandlers == nil )
        {
            _changeHandlers = [[NSMutableDictionary alloc] init];
        }
        
        handlers = [_changeHandlers objectForKey:entityName];
        
        if ( handlers == nil )
        {
            handlers = [NSMutableSet set];
        
            [_changeHandlers setObject:handlers forKey:entityName];
        }
        
        [handlers addObject:changeHandler];
    }
}

- (void)purgeData
{
    if ( !_setup )
    {
        [self setup];
    }

    NSPersistentStore *store = [[_coordinator persistentStores] objectAtIndex:0];
    NSError *error = nil;
    NSURL *storeURL = store.URL;
    [_coordinator removePersistentStore:store error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error];

    [_model release]; _model = nil;
    [_context release]; _context = nil;
    [_coordinator release]; _coordinator = nil;

    _setup = NO;
}


#pragma mark HKPrivate API

- (void)setup
{
    if ( _model == nil )
    {
        _model = [[NSManagedObjectModel mergedModelFromBundles:[_bundles allObjects]] retain];
    }
    
    if ( _coordinator == nil )
    {
        NSFileManager   *fm = [NSFileManager defaultManager];
        NSString        *dir = [NSFileManager applicationSupportDirectory];
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

        [self enableChangeHandlers]; // enabled by default
    }
    
    _setup = YES;
}

#pragma mark Notifications

#ifdef HK_DEBUG_PROFILE
static int32_t gHKDataStoreTimeTaken = 0;
#endif

- (void)enableChangeHandlers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextDidChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:_context];
}

- (void)disableChangeHandlers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:_context];
}

- (void)managedObjectContextDidChange:(NSNotification *)notification
{

#ifdef HK_DEBUG_PROFILE
    NSDate  *s, *e;
    int32_t  time;
    
    s = [NSDate date];
#endif
    
    @synchronized (self)
    {
        NSDictionary                *ui = [notification userInfo];
        NSSet                       *handlers;
        NSSet                       *objects;
        NSManagedObject             *object;
        NSManagedObjectContext      *context = [notification object];
        HKDataStoreChangeHandler     handler;
        
        objects = [ui objectForKey:NSInsertedObjectsKey];
        
        for ( object in objects )
        {
            handlers = [_changeHandlers objectForKey:[[object entity] name]];
            
            for ( handler in handlers )
            {
                handler( context, object, HKDataStoreChangeTypeInsertion );
            }
        }
        
        objects = [ui objectForKey:NSDeletedObjectsKey];
        
        for ( object in objects )
        {
            handlers = [_changeHandlers objectForKey:[[object entity] name]];
            
            for ( handler in handlers )
            {
                handler( context, object, HKDataStoreChangeTypeDeletion );
            }
        }
        
        objects = [ui objectForKey:NSUpdatedObjectsKey];
        
        for ( object in objects )
        {
            handlers = [_changeHandlers objectForKey:[[object entity] name]];
            
            for ( handler in handlers )
            {
                handler( context, object, HKDataStoreChangeTypeUpdate );
            }
        }
    }

#ifdef HK_DEBUG_PROFILE
    e = [NSDate date];
    
    time = (int32_t) (([e timeIntervalSinceDate:s]) * 1e6);
    
    OSAtomicAdd32Barrier( time, &gHKDataStoreTimeTaken );
    
    NSLog(@"HKDataStore::managedObjectContextDidChange->Total time taken: %d usec", gHKDataStoreTimeTaken);
#endif
}

@end
