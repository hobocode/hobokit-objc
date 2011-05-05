//
//  NSTreeController+HKAdditions.h
//  Time
//
//  Created by Måns Severin on 2011-04-08.
//  Copyright 2011 Graphiclife. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTreeController (NSTreeController_HKAdditions)

- (NSArray *)rootNodes;
- (NSArray *)flattenedNodes;
- (NSTreeNode *)treeNodeForObject:(id)object;
- (NSIndexPath *)indexPathToObject:(id)object;

@end
