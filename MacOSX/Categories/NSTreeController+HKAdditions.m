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

#import "NSTreeController+HKAdditions.h"

@implementation NSTreeController (NSTreeController_HKAdditions)

- (NSArray *)rootNodes
{
    return [[self arrangedObjects] childNodes];
}

- (NSArray *)flattenedNodes
{
    NSMutableArray  *retval = [NSMutableArray array];
    NSTreeNode      *node;
    
    for ( node in [self rootNodes] )
    {
        [retval addObject:node];
        
        if ( [[node childNodes] count] > 0 )
        {
            [retval addObjectsFromArray:[node childNodes]];
        }
    }
    
    return [NSArray arrayWithArray:retval]; 
}

- (NSTreeNode *)treeNodeForObject:(id)object
{   
    NSTreeNode *retval = nil;
    NSTreeNode *node;
    
    for ( node in [self flattenedNodes] )
    {
        if ( [node representedObject] == object )
        {
            retval = node;
            break;
        }
    }
    
    return retval;
}

- (NSIndexPath *)indexPathToObject:(id)object;
{
    return [[self treeNodeForObject:object] indexPath];
}

@end