//
//  NSStringAdditions.h
//  Swedish Crosswords
//
//  Created by Måns Severin on 2010-06-14.
//  Copyright 2010 Graphiclife. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_HKFormatting)

+ (NSString *)stringRepresentingNumberAsCurrency:(NSNumber *)number inLocale:(NSLocale *)locale;

@end
