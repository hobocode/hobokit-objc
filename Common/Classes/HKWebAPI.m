//  Copyright (c) 2011 HoboCode
//
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.
//

#import "HKWebAPI.h"

#import "JSONKit.h"

static HKWebAPI *gHKWebAPI = nil;

@interface HKWebAPI (HKPrivate)

- (void)setup;

- (void)performRequest:(NSURLRequest *)request synchronously:(BOOL)synchronously completionHandler:(HKWebAPIHandler)handler;
- (NSURLRequest *)requestForMethod:(NSString *)method HTTPMethod:(NSString *)httpMethod parameters:(NSDictionary *)parameters;
- (NSString *)URLVariablesUsingParameters:(NSDictionary *)parameters;
- (NSData *)postDataUsingParameters:(NSDictionary *)parameters;

@end

@implementation HKWebAPI

#pragma mark HKSingleton

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
	{
        if ( gHKWebAPI == nil )
		{
            gHKWebAPI = [super allocWithZone:zone];
			
            return gHKWebAPI;
        }
    }
	
    return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (NSUInteger)retainCount
{
    return UINT_MAX;
}

- (void)release
{
}

- (id)autorelease
{
    return self;
}

- (id)init
{
	if ( self = [super init] )
	{
		[self setup];
	}
	
	return self;
}

- (void)dealloc
{
#ifdef SWING_POD_DEBUG_DEALLOC
	NSLog(@"Dealloc: %@", self);
#endif
	dispatch_release( _requests ); _requests = nil;
	
	[super dealloc];
}

#pragma mark HKPublic API

@synthesize APIBaseURL = _APIBaseURL, APIVersion = _APIVersion;

+ (HKWebAPI *)defaultAPI
{
    @synchronized ( self )
	{
        if ( gHKWebAPI == nil )
		{
            [[self alloc] init];
        }
    }
	
    return gHKWebAPI;
}

- (void)GETMethod:(NSString *)method parameters:(NSDictionary *)parameters synchronously:(BOOL)synchronously completionHandler:(HKWebAPIHandler)handler
{
	[self performRequest:[self requestForMethod:method HTTPMethod:@"GET" parameters:parameters] synchronously:synchronously completionHandler:handler];
}

- (void)POSTMethod:(NSString *)method parameters:(NSDictionary *)parameters synchronously:(BOOL)synchronously completionHandler:(HKWebAPIHandler)handler
{
	[self performRequest:[self requestForMethod:method HTTPMethod:@"POST" parameters:parameters] synchronously:synchronously completionHandler:handler];
}

#pragma mark HKPrivate API

- (void)setup
{
	if ( _requests == nil )
	{
		_requests = dispatch_queue_create( "com.hobocode.gcd.webapi", NULL );
	}
}

- (void)performRequest:(NSURLRequest *)request synchronously:(BOOL)synchronously completionHandler:(HKWebAPIHandler)handler
{
	id rhandler = ^{
		id					 json = nil;
		NSData				*result = nil;
		NSError				*error = nil;
		NSHTTPURLResponse	*response = nil;
        JSONDecoder         *decoder = nil;
		
		if ( request == nil )
		{
            if ( synchronously )
            {
                handler( nil, [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:nil] );
            }
            else
            {
                dispatch_async( dispatch_get_main_queue(), ^ {
                    handler( nil, [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:nil] );
                } );
			}
			
			return;
		}
		
#ifdef HK_DEBUG_WEB_API
        NSLog(@"HKWebAPI->Requesting URL: %@", [request URL]);
#endif
        
		result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		
		if ( result == nil )
		{
			if ( synchronously )
            {
                handler( nil, error );
            }
            else
            {
                dispatch_async( dispatch_get_main_queue(), ^ {
                    handler( nil, error );
                } );
			}
			
			return;
		}
		
#ifdef HK_DEBUG_WEB_API
		NSLog(@"\r\n########## HKWebAPI DATA ##########\r\n%@\r\n########## ----------------- ##########\r\n", [[[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding] autorelease]);
#endif
		
		if ( [response statusCode] != 200 )
		{
			error = [NSError errorWithDomain:HK_ERROR_DOMAIN code:HK_ERROR_CODE_WEB_API_ERROR userInfo:nil];
			
			if ( synchronously )
            {
                handler( nil, error );
            }
            else
            {
                dispatch_async( dispatch_get_main_queue(), ^ {
                    handler( nil, error );
                } );
			}
			
			return;
		}
        
        decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
        
        json = [decoder objectWithData:result error:&error];
        
        [decoder release];
        
		if ( json == nil )
		{
            if ( synchronously )
            {
                handler( nil, error );
            }
            else
            {
                dispatch_async( dispatch_get_main_queue(), ^ {
                    handler( nil, error );
                } );
			}
            
			return;
		}
        
        if ( synchronously )
        {
            handler( json, nil );
        }
        else
        {
            dispatch_async( dispatch_get_main_queue(), ^ {
                handler( json, nil );
            } );
        }
	};
	
	if ( synchronously )
	{
		dispatch_sync( _requests, rhandler );
	}
	else
	{
		dispatch_async( _requests, rhandler );
	}
}

- (NSURLRequest *)requestForMethod:(NSString *)method HTTPMethod:(NSString *)httpMethod parameters:(NSDictionary *)parameters
{
	NSMutableURLRequest	*request = [[[NSMutableURLRequest alloc] init] autorelease];
	NSString			*mstring = [NSString stringWithFormat:@"%@/%@/%@", self.APIBaseURL, self.APIVersion, method];	
	NSMutableString		*ustring = [NSMutableString stringWithString:mstring];
	NSString			*variables;
	NSData				*data;
	
	[request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
	[request setTimeoutInterval:60.0];
	[request setHTTPMethod:httpMethod];
	
	if ( [httpMethod isEqualToString:@"GET"] )
	{
		if ( parameters != nil )
		{
			variables = [self URLVariablesUsingParameters:parameters];
			
			if ( variables )
			{
				[ustring appendFormat:@"?%@", variables];
			}
		}
	}
	else if ( [httpMethod isEqualToString:@"POST"] )
	{		
		if ( parameters != nil )
		{
			data = [self postDataUsingParameters:parameters];
			
			if ( data != nil )
			{
				[request setHTTPBody:data];
			}
		}
	}
	
	[request setURL:[NSURL URLWithString:ustring]];
	
	return request;
}

- (NSString *)URLVariablesUsingParameters:(NSDictionary *)parameters
{
	NSMutableString *result = [NSMutableString string];
	NSArray			*keys = [parameters allKeys];
	NSString		*key = nil;
	NSUInteger		i, c;
	id				value;
	
	for ( i = 0, c = [keys count] ; i < c ; i++ )
	{
		key = [keys objectAtIndex:i];
		value = [parameters objectForKey:key];
		
		if ( [value isKindOfClass:[NSString class]] )
		{
			NSString *string = (NSString *) value;
			
			[result appendFormat:@"%@%@=%@", (i == 0 ? @"" : @"&"), key, [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		}
		else if ( [value isKindOfClass:[NSDate class]] )
		{
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			
			[formatter setDateFormat:@"yyyyMMddHHmmss"];
			
			[result appendFormat:@"%@%@=%@", (i == 0 ? @"" : @"&"), key, [[formatter stringFromDate:value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			[formatter release];
		}
		else if ( [value isKindOfClass:[NSNumber class]] )
		{
			NSNumber *number = (NSNumber *) value;

			[result appendFormat:@"%@%@=%d", (i == 0 ? @"" : @"&"), key, [number intValue]];
		}

	}
	
	return [NSString stringWithString:result];
}

- (NSData *)postDataUsingParameters:(NSDictionary *)parameters
{
	return [[self URLVariablesUsingParameters:parameters] dataUsingEncoding:NSUTF8StringEncoding];
}

@end