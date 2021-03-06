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

typedef enum
{
    HKDataStoreChangeTypeInsertion = 0,
    HKDataStoreChangeTypeDeletion = 1,
    HKDataStoreChangeTypeUpdate = 2,
} HKDataStoreChangeType;

typedef enum
{
    HKDataStoreLocationDefault = 0,
    HKDataStoreLocationCaches
} HKDataStoreLocation;

typedef void (^HKDataStoreHandler)( NSManagedObjectContext *context );
typedef void (^HKDataStoreChangeHandler)( NSManagedObjectContext *context, NSSet *objects, HKDataStoreChangeType type );
typedef void (^HKDataStoreSaveHandler)( NSManagedObjectContext *context, NSSet *objects, HKDataStoreChangeType type );

@interface HKDataStore : NSObject
{
@private
    NSManagedObjectModel            *_model;
    NSManagedObjectContext          *_context;
    NSPersistentStoreCoordinator    *_coordinator;
    NSMutableSet                    *_bundles;
    NSMutableSet                    *_chandlers;
    NSMutableSet                    *_shandlers;
    NSMutableSet                    *_detached;
    NSString                        *_filename;
    HKDataStoreLocation              _location;
    BOOL                             _setup;
    BOOL                             _change;
    BOOL                             _usesLightweightMigration;
}

@property (readonly) NSManagedObjectContext *context;
@property (readonly) NSManagedObjectModel *model;

@end

@interface HKDataStore (HKPublic)

+ (id)defaultStore;

- (void)setFilename:(NSString *)filename;
- (NSString *)filename;

- (void)addModelBundle:(NSBundle *)bundle;
- (void)setDataStoreLocation:(HKDataStoreLocation)location;
- (void)setUsesLightweightMigration:(BOOL)flag;

- (void)synchronizedWithContext:(HKDataStoreHandler)handler;
- (void)asynchronizedWithContext:(HKDataStoreHandler)handler;

- (void)synchronizedAndSaveWithContext:(HKDataStoreHandler)handler;
- (void)asynchronizedAndSaveWithContext:(HKDataStoreHandler)handler;

- (void)save;
- (void)saveAll;
- (void)purgeData;

- (void)setMergePolicy:(id)policy;
- (void)setStalenessInterval:(NSTimeInterval)expiration;

- (NSManagedObjectContext *)detachNewContext;
- (void)dismissDetachedContext:(NSManagedObjectContext *)context;

- (void)registerChangeHandler:(HKDataStoreChangeHandler)handler;
- (void)enableChangeHandlers;
- (void)disableChangeHandlers;

- (void)registerSaveHandler:(HKDataStoreSaveHandler)handler;
- (void)enableSaveHandlers;
- (void)disableSaveHandlers;

- (void)enableHandlers;
- (void)disableHandlers;

@end
