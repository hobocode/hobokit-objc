//
//  NSTreeController+HKAdditions.m
//  Time
//
//  Created by Måns Severin on 2011-04-08.
//  Copyright 2011 Graphiclife. All rights reserved.
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