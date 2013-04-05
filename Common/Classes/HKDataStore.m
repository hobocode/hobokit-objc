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

#import "NSFileManager+HKDirectories.h"

@interface HKDataStore (HKPrivate)

- (void)setup;

- (NSString *)applicationSupportDirectory;

@end

@implementation HKDataStore

- (id)init
{
    if ( self = [super init] )
    {
        [self setFilename:@"Data.db"];
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

+ (id)defaultStore
{
    static dispatch_once_t once;
    static id shared;
    dispatch_once(&once, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (void)setFilename:(NSString *)filename
{
    if ( !_setup )
    {
        if ( filename != _filename )
        {
            _filename = [filename copy];
        }
    }
}

- (NSString *)filename
{
    return _filename;
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

- (void)setDataStoreLocation:(HKDataStoreLocation)location
{
    @synchronized (self)
    {
        _location = location;
    }
}

- (void)setUsesLightweightMigration:(BOOL)flag
{
    @synchronized (self)
    {
        _usesLightweightMigration = flag;
    }
}

- (void)synchronizedWithContext:(HKDataStoreHandler)handler
{
    if ( !_setup )
    {
        [self setup];
    }

    [_context performBlockAndWait:^{
        handler( _context );
    }];
}

- (void)asynchronizedWithContext:(HKDataStoreHandler)handler
{
    if ( !_setup )
    {
        [self setup];
    }

    [_context performBlock:^{
        handler( _context );
    }];
}

- (void)synchronizedAndSaveWithContext:(HKDataStoreHandler)handler
{
    if ( !_setup )
    {
        [self setup];
    }

    [_context performBlockAndWait:^{
        NSError *error = nil;

        handler( _context );

        if ( ![_context save:&error] )
        {
#ifdef HK_DEBUG_ERRORS
            NSLog(@"HKDataStore::synchronizedAndSaveWithContext->Error: '%@' : '%@'", error, [[error userInfo] objectForKey:NSDetailedErrorsKey]);
#endif
        }
    }];
}

- (void)asynchronizedAndSaveWithContext:(HKDataStoreHandler)handler
{
    if ( !_setup )
    {
        [self setup];
    }

    [_context performBlock:^{
        NSError *error = nil;

        handler( _context );

        if ( ![_context save:&error] )
        {
#ifdef HK_DEBUG_ERRORS
            NSLog(@"HKDataStore::synchronizedAndSaveWithContext->Error: '%@' : '%@'", error, [[error userInfo] objectForKey:NSDetailedErrorsKey]);
#endif
        }
    }];
}

- (void)registerChangeHandler:(HKDataStoreChangeHandler)handler
{
    @synchronized (self)
    {
        if ( _chandlers == nil )
        {
            _chandlers = [[NSMutableSet alloc] init];
        }

        [_chandlers addObject:Block_copy( handler )];
    }
}


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

- (void)registerSaveHandler:(HKDataStoreSaveHandler)handler
{
    @synchronized (self)
    {
        if ( _shandlers == nil )
        {
            _shandlers = [[NSMutableSet alloc] init];
        }

        [_shandlers addObject:Block_copy( handler )];
    }
}

- (void)enableSaveHandlers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:_context];
}

- (void)disableSaveHandlers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:_context];
}

- (void)enableHandlers
{
    [self enableChangeHandlers];
    [self enableSaveHandlers];
}

- (void)disableHandlers
{
    [self disableChangeHandlers];
    [self disableSaveHandlers];
}


- (void)save
{
    if ( _setup == NO )
    {
        [self setup];
    }

    if ( [_context hasChanges] )
    {
        NSError *error = nil;

        @try
        {
            if ( ![_context save:&error] )
            {

            }
        }
        @catch (NSException *exception)
        {
        }
    }
}

- (void)saveAll
{
    [self save];

    for ( NSManagedObjectContext *context in _detached )
    {
        if ( [context hasChanges] )
        {
            NSError *error = nil;

            @try
            {
                if ( ![context save:&error] )
                {

                }
            }
            @catch (NSException *exception)
            {
            }
        }
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

- (void)setMergePolicy:(id)policy
{
    if ( !_setup )
    {
        [self setup];
    }

    [_context setMergePolicy:policy];
}

- (void)setStalenessInterval:(NSTimeInterval)expiration
{
    if ( !_setup )
    {
        [self setup];
    }

    [_context setStalenessInterval:expiration];
}

- (NSManagedObjectContext *)detachNewContext
{
    if ( !_setup )
    {
        [self setup];
    }

    if ( _detached == nil )
        _detached = [[NSMutableSet alloc] init];

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

    [context setPersistentStoreCoordinator:_coordinator];
    [context setMergePolicy:[_context mergePolicy]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(detachedManagedObjectContextDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:context];

    [_detached addObject:context];

    return context;
}

- (void)dismissDetachedContext:(NSManagedObjectContext *)context
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:context];

    [_detached removeObject:context];

    [context release];
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
        NSFileManager   *fm = [[[NSFileManager alloc] init] autorelease];
        NSString        *dir;
        NSURL           *url;
        NSError         *error = nil;
        NSDictionary    *options = nil;

        switch ( _location )
        {
            case HKDataStoreLocationDefault:
                dir = [NSFileManager applicationSupportDirectory];
                break;

            case HKDataStoreLocationCaches:
                dir = [NSFileManager cacheDirectory];
                break;

            default:
                dir = [NSFileManager applicationSupportDirectory];
                break;
        }

        url = [NSURL fileURLWithPath:[dir stringByAppendingPathComponent:_filename]];

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

        if ( _usesLightweightMigration )
        {
            options = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                       [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        }

        if ( ![_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error] )
        {
#ifdef HK_DEBUG_ERRORS
            NSLog(@"HKDataStore::setup->Error: '%@'", error);
#endif
            [_coordinator release]; _coordinator = nil;

#ifdef HK_DATA_STORE_DELETE_FAULTY_STORE
#warning "HK_DATA_STORE_DELETE_FAULTY_STORE set"

         // if ( [error code] == NSPersistentStoreIncompatibleVersionHashError )
            {
                [fm copyItemAtURL:url
                            toURL:[[url URLByDeletingLastPathComponent]
                                   URLByAppendingPathComponent:
                                   [NSString stringWithFormat:@"Data-old-%lu.db", (unsigned long)[[NSDate date] timeIntervalSince1970]]]
                            error:&error];

                [fm removeItemAtURL:url error:&error];

                [self setup];
                return;
            }
#endif
            return;
        }
    }

    if ( _context == nil )
    {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

        [_context setPersistentStoreCoordinator:_coordinator];

        [self enableHandlers]; // enabled by default
    }

    _setup = YES;
}

#pragma mark Notifications

- (void)managedObjectContextDidChange:(NSNotification *)notification
{
    @synchronized (self)
    {
        NSDictionary                *ui = [notification userInfo];
        NSSet                       *objects;
        NSManagedObjectContext      *context = [notification object];

        if ( (objects = [ui objectForKey:NSInsertedObjectsKey]) != nil )
        {
            [_chandlers enumerateObjectsUsingBlock:^ ( id obj, BOOL *stop ) {
                HKDataStoreChangeHandler handler = (HKDataStoreChangeHandler) obj;

                handler( context, objects, HKDataStoreChangeTypeInsertion );
            }];
        }

        if ( (objects = [ui objectForKey:NSDeletedObjectsKey]) != nil )
        {
            [_chandlers enumerateObjectsUsingBlock:^ ( id obj, BOOL *stop ) {
                HKDataStoreChangeHandler handler = (HKDataStoreChangeHandler) obj;

                handler( context, objects, HKDataStoreChangeTypeDeletion );
            }];
        }

        if ( (objects = [ui objectForKey:NSUpdatedObjectsKey]) != nil )
        {
            [_chandlers enumerateObjectsUsingBlock:^ ( id obj, BOOL *stop ) {
                HKDataStoreChangeHandler handler = (HKDataStoreChangeHandler) obj;

                handler( context, objects, HKDataStoreChangeTypeUpdate );
            }];
        }
    }
}

- (void)managedObjectContextDidSave:(NSNotification *)notification
{
    @synchronized (self)
    {
        NSDictionary                *ui = [notification userInfo];
        NSSet                       *objects;
        NSManagedObjectContext      *context = [notification object];

        if ( (objects = [ui objectForKey:NSInsertedObjectsKey]) != nil )
        {
            [_shandlers enumerateObjectsUsingBlock:^ ( id obj, BOOL *stop ) {
                HKDataStoreChangeHandler handler = (HKDataStoreChangeHandler) obj;

                handler( context, objects, HKDataStoreChangeTypeInsertion );
            }];
        }

        if ( (objects = [ui objectForKey:NSDeletedObjectsKey]) != nil )
        {
            [_shandlers enumerateObjectsUsingBlock:^ ( id obj, BOOL *stop ) {
                HKDataStoreChangeHandler handler = (HKDataStoreChangeHandler) obj;

                handler( context, objects, HKDataStoreChangeTypeDeletion );
            }];
        }

        if ( (objects = [ui objectForKey:NSUpdatedObjectsKey]) != nil )
        {
            [_shandlers enumerateObjectsUsingBlock:^ ( id obj, BOOL *stop ) {
                HKDataStoreChangeHandler handler = (HKDataStoreChangeHandler) obj;

                handler( context, objects, HKDataStoreChangeTypeUpdate );
            }];
        }
    }
}

- (void)detachedManagedObjectContextDidSave:(NSNotification *)notification
{
    [_context mergeChangesFromContextDidSaveNotification:notification];
}

@end
