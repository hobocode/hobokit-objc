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

#import "HKPersistentPackageDocument.h"

// inspired heavily by
// http://developer.apple.com/library/mac/#samplecode/PersistentDocumentFileWrappers/Introduction/Intro.html

@implementation NSPersistentDocument (HKPersistentPackageDocument)

- (void)simpleSetFileURL:(NSURL *)fileURL
{
    [super setFileURL:fileURL];
}

@end

@interface HKPersistentPackageDocument (HKPrivate)

- (NSURL *)storeURLFromPath:(NSString *)filePath;

@end


@implementation HKPersistentPackageDocument

#pragma mark -
#pragma mark URL management

- (NSString *)dataStoreName
{
    [NSException raise:@"HKUnimplementedMethodException" format:@"Subclasses must implement -dataStoreName"];
    return nil;
}

// Sets the on-disk location.  NSPersistentDocument's implementation is
// bypassed using the FileWrapperSupport category. The persistent store
// coordinator is directed to use an internal URL rather than
// NSPersistentDocument's default (the main file URL).
- (void)setFileURL:(NSURL *)fileURL
{
    NSURL *originalFileURL = [self storeURLFromPath:[[self fileURL] path]];
    if ( originalFileURL != nil )
    {
        NSPersistentStoreCoordinator *coordinator = [[self managedObjectContext] persistentStoreCoordinator];
        id store = [coordinator persistentStoreForURL:originalFileURL];
        if (store != nil)
        {
            // Switch the coordinator to an internal URL.
            [coordinator setURL:[self storeURLFromPath:[fileURL path]] forPersistentStore:store];
        }
    }

    [super simpleSetFileURL:fileURL];
}


- (NSURL *)storeURLFromPath:(NSString *)filePath
{
    filePath = [filePath stringByAppendingPathComponent:[self dataStoreName]];
    return filePath == nil ? nil : [NSURL fileURLWithPath:filePath];
}


#pragma mark -
#pragma mark Reading (Opening)

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper atPath:(NSString *)path error:(NSError **)error
{
    return YES;
}


// Overridden NSDocument/NSPersistentDocument method to open existing documents.
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)error
{
    BOOL success = NO;
    // Create a file wrapper for the document package.
    NSFileWrapper *directoryFileWrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];
    // File wrapper for the Core Data store within the document package.
    NSFileWrapper *dataStore = [[directoryFileWrapper fileWrappers] objectForKey:[self dataStoreName]];

    if ( dataStore != nil )
    {
        NSString *path = [[absoluteURL path] stringByAppendingPathComponent:[dataStore filename]];
        NSURL *storeURL = [NSURL fileURLWithPath:path];
        // Set the document persistent store coordinator to use the internal Core Data store.
        success = [self configurePersistentStoreCoordinatorForURL:storeURL ofType:typeName
                                               modelConfiguration:nil storeOptions:nil error:error];
    }

    // Don't read anything else if reading the main store failed.
    if (success == YES)
    {
        // Read the other contents of the document.
        success = [self readFromFileWrapper:directoryFileWrapper atPath:[absoluteURL path] error:error];
    }

    [directoryFileWrapper release];

    return success;
}


#pragma mark -
#pragma mark Writing (Saving)

// Overwrite this to save non core data files to filewrapper
- (BOOL)updateFileWrapper:(NSFileWrapper *)documentFileWrapper atPath:(NSString *)path error:(NSError **)error
{
    return YES;
}


// Overridden NSDocument/NSPersistentDocument method to save documents.
- (BOOL)writeSafelyToURL:(NSURL *)inAbsoluteURL ofType:(NSString *)inTypeName forSaveOperation:(NSSaveOperationType)inSaveOperation error:(NSError **)outError
{
    BOOL success = YES;
    NSFileWrapper *filewrapper = nil;
    NSURL *originalURL = [self fileURL];
    NSString *filePath = [inAbsoluteURL path];

    if ( inSaveOperation == NSSaveAsOperation )
    {
        // Nothing exists at the URL: set up the directory and migrate the Core Data store.
        filewrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
        // Need to write once so there's somewhere for the store file to go.
        [filewrapper writeToFile:filePath atomically:NO updateFilenames:NO];

        // Now, the Core Data store...
        NSURL *storeURL = [self storeURLFromPath:filePath];
        NSURL *originalStoreURL = [self storeURLFromPath:[originalURL path]];

        if ( originalStoreURL != nil )
        {
            // This is a "Save As", so migrate the store to the new URL.
            NSPersistentStoreCoordinator *coordinator = [[self managedObjectContext] persistentStoreCoordinator];
            id originalStore = [coordinator persistentStoreForURL:originalStoreURL];
            success = ([coordinator migratePersistentStore:originalStore toURL:storeURL options:nil withType:[self persistentStoreTypeForFileType:inTypeName] error:outError] != nil);
        }
		else
        {
            // This is the first Save of a new document, so configure the store.
            success = [self configurePersistentStoreCoordinatorForURL:storeURL ofType:inTypeName modelConfiguration:nil storeOptions:nil error:nil];
        }

        [filewrapper addFileWithPath:[storeURL path]];
    }
	else // Save as
    {
        filewrapper = [[NSFileWrapper alloc] initWithPath:[inAbsoluteURL path]];
    }

    //  Atomicity during write is a problem that is not addressed in this sample. See the Apple ReadMe for discussion.

    if ( success )
    {
        // Save the Core Data portion of the document.
        success = [[self managedObjectContext] save:outError];
    }

    if ( success )
    {
        success = [self updateFileWrapper:filewrapper atPath:[inAbsoluteURL path] error:outError];
        [filewrapper writeToFile:filePath atomically:NO updateFilenames:NO];
    }

    if ( success )
    {
        // Set the appropriate file attributes (such as "Hide File Extension")
        NSDictionary *fileAttributes = [self fileAttributesToWriteToURL:inAbsoluteURL ofType:inTypeName forSaveOperation:inSaveOperation originalContentsURL:originalURL error:outError];
        success = [[NSFileManager defaultManager] setAttributes:fileAttributes ofItemAtPath:[inAbsoluteURL path] error:outError];
    }


    [filewrapper release];

    return success;
}


#pragma mark -
#pragma mark Revert

- (BOOL)revertToContentsOfURL:(NSURL *)inAbsoluteURL ofType:(NSString *)inTypeName error:(NSError **)outError
{
    NSPersistentStoreCoordinator *coordinator = [[self managedObjectContext] persistentStoreCoordinator];
    id store = [coordinator persistentStoreForURL:[self storeURLFromPath:[inAbsoluteURL path]]];

    if ( store )
    {
        [coordinator removePersistentStore:store error:outError];
    }

    return [super revertToContentsOfURL:inAbsoluteURL ofType:inTypeName error:outError];
}

@end
