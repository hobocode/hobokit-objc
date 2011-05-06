//
//  NSStringAdditions.m
//  Swedish Crosswords
//
//  Created by Måns Severin on 2010-06-14.
//  Copyright 2010 Graphiclife. All rights reserved.
//

#import "NSString+HKFormatting.h"

@implementation NSString (NSString_HKFormatting)

+ (NSString *)stringRepresentingNumberAsCurrency:(NSNumber *)number inLocale:(NSLocale *)locale
{
	NSNumberFormatter	*nf = [[NSNumberFormatter alloc] init];
	NSString			*result;
	
	[nf setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[nf setNumberStyle:NSNumberFormatterCurrencyStyle];
	[nf setLocale:locale];
	
	result = [nf stringFromNumber:number];
	
	[nf release];
	
	return result;
}

@end