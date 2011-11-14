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

#import "NSManagedObjectContext+HKEasyFetch.h"

// taken from: http://cocoawithlove.com/2008/03/core-data-one-line-fetch.html

@interface NSManagedObjectContext (HKEasyFetchPrivate)

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName sortDescriptors:(NSArray *)sortDescriptors withPredicate:(id)stringOrPredicate arguments:(va_list)arguments;

@end

@implementation NSManagedObjectContext (HKEasyFetch)

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName sortDescriptors:(NSArray *)sortDescriptors withPredicate:(id)stringOrPredicate arguments:(va_list)arguments
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    
    if (stringOrPredicate)
    {
        NSPredicate *predicate;
        if ( [stringOrPredicate isKindOfClass:[NSString class]] )
        {
            predicate = [NSPredicate predicateWithFormat:stringOrPredicate arguments:arguments];
        }
        else
        {
            NSAssert2( [stringOrPredicate isKindOfClass:[NSPredicate class]],
                      @"Second parameter passed to %s is of unexpected class %s",
                      sel_getName(_cmd), object_getClassName(stringOrPredicate));

            predicate = (NSPredicate *)stringOrPredicate;
        }

        [request setPredicate:predicate];
    }

    if ( sortDescriptors )
    {
        [request setSortDescriptors:sortDescriptors];
    }

    NSError *error = nil;
    NSArray *results = [self executeFetchRequest:request error:&error];

    if (error != nil)
    {
        [NSException raise:NSGenericException format:[error description]];
    }

    return results;
}

- (NSSet *)fetchObjectsForEntityName:(NSString *)entityName withPredicate:(id)stringOrPredicate, ...
{
    va_list arguments;
    va_start( arguments, stringOrPredicate );
    NSArray *results = [self fetchObjectsForEntityName:entityName sortDescriptors:nil withPredicate:stringOrPredicate arguments:arguments];
    va_end( arguments );

    return [NSSet setWithArray:results];
}

- (NSArray *)fetchObjectsForEntityName:(NSString *)entityName sortDescriptors:(NSArray *)sortDescriptors withPredicate:(id)stringOrPredicate, ...
{
    va_list arguments;
    va_start( arguments, stringOrPredicate );
    NSArray *results = [self fetchObjectsForEntityName:entityName sortDescriptors:nil withPredicate:stringOrPredicate arguments:arguments];
    va_end( arguments );

    return results;
}

@end
