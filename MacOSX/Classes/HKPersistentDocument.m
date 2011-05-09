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

#import "HKPersistentDocument.h"

@implementation HKPersistentDocument

- (void)synchronizedWithContext:(HKPersistentDocumentHandler)handler
{
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_queue_t current = dispatch_get_current_queue();

    if ( current == main )
    {
        handler( [self managedObjectContext] );
    }
    else
    {
        dispatch_sync( main, ^{
            handler( [self managedObjectContext] );
        });
    }
}

- (void)asynchronizedWithContext:(HKPersistentDocumentHandler)handler
{
    dispatch_async( dispatch_get_main_queue(), ^{
        handler( [self managedObjectContext] );
    });
}

- (void)synchronizedAndSaveWithContext:(HKPersistentDocumentHandler)handler
{
    dispatch_queue_t main = dispatch_get_main_queue();
    dispatch_queue_t current = dispatch_get_current_queue();

    if ( current == main )
    {
        NSError *error = nil;

        handler( [self managedObjectContext] );

        if ( ![[self managedObjectContext] save:&error] )
        {
            NSLog(@"HKPersistentDocument::synchronizedAndSaveWithContext->Error: '%@' : '%@'", error, [[error userInfo] objectForKey:NSDetailedErrorsKey]);
        }
    }
    else
    {
        dispatch_sync( main, ^{
            NSError *error = nil;

            handler( [self managedObjectContext] );

            if ( ![[self managedObjectContext] save:&error] )
            {
                NSLog(@"HKPersistentDocument::synchronizedAndSaveWithContext->Error: '%@' : '%@'", error, [[error userInfo] objectForKey:NSDetailedErrorsKey]);
            }
        });
    }
}

- (void)asynchronizedAndSaveWithContext:(HKPersistentDocumentHandler)handler
{
    dispatch_async( dispatch_get_main_queue(), ^{
        NSError *error = nil;

        handler( [self managedObjectContext] );

        if ( ![[self managedObjectContext] save:&error] )
        {
            NSLog(@"HKPersistentDocument::asynchronizedAndSaveWithContext->Error: '%@' : '%@'", error, [[error userInfo] objectForKey:NSDetailedErrorsKey]);
        }
    });
}



@end
