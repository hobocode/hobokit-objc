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

#import "HKRESTAPI.h"

#import "NSData+HKBase64.h"

#import <libkern/OSAtomic.h>

@implementation HKRESTAPIResultAdapter

- (id)resultForData:(NSData *)data error:(NSError **)error
{
    return nil;
}

@end

#import "JSONKit.h"

@implementation HKRESTAPIJSONResultAdapter

- (id)resultForData:(NSData *)data error:(NSError **)error
{
    JSONDecoder *decoder = [[JSONDecoder alloc] initWithParseOptions:JKParseOptionNone];
    id           retval;
    
    retval = [decoder objectWithData:data error:error];
    
    [decoder release];
    
    return retval;
}

@end

#import "HKURLOperation.h"

#import "NSData+HKBase64.h"

static HKRESTAPI *gHKRESTAPI = nil;

@interface HKRESTAPI (HKPrivate)

- (void)setup;

- (void)performRequest:(NSURLRequest *)request synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)completionHandler progressHandler:(HKRESTAPIProgressHandler)progressHandler;
- (NSURLRequest *)requestForMethod:(NSString *)method HTTPMethod:(NSString *)httpMethod HTTPBody:(NSData *)body contentType:(NSString *)contentType;
- (NSString *)URLVariablesUsingParameters:(NSDictionary *)parameters;
- (NSData *)formDataUsingParameters:(NSDictionary *)parameters;

@end

@implementation HKRESTAPI

#pragma mark HKSingleton

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if ( gHKRESTAPI == nil )
        {
            gHKRESTAPI = [super allocWithZone:zone];

            return gHKRESTAPI;
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

- (oneway void)release
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
#ifdef HK_DEBUG_DEALLOC
    NSLog(@"Dealloc: %@", self);
#endif

    dispatch_release( _requests ); _requests = nil;
    [_HTTPHeaders release];
    [_resultAdapter release];

    [super dealloc];
}

#pragma mark HKPublic API

@synthesize APIBaseURL = _APIBaseURL, APIVersion = _APIVersion, APIUsername = _APIUsername, APIPassword = _APIPassword;
@synthesize responseCookies = _responseCookies, resultAdapter = _resultAdapter;
@synthesize HTTPHeaders = _HTTPHeaders;

+ (HKRESTAPI *)defaultAPI
{
    @synchronized ( self )
    {
        if ( gHKRESTAPI == nil )
        {
            [[self alloc] init];
        }
    }

    return gHKRESTAPI;
}

- (void)POSTMethod:(NSString *)method
          HTTPBody:(NSData *)body
       contentType:(NSString *)contentType
     synchronously:(BOOL)synchronously
   progressHandler:(HKRESTAPIProgressHandler)progressHandler
 completionHandler:(HKRESTAPICompletionHandler)completionHandler
{
    [self performRequest:[self requestForMethod:method HTTPMethod:@"POST" HTTPBody:body contentType:contentType] synchronously:synchronously completionHandler:completionHandler progressHandler:progressHandler];
}

- (void)PUTMethod:(NSString *)method
         HTTPBody:(NSData *)body
      contentType:(NSString *)contentType
    synchronously:(BOOL)synchronously
  progressHandler:(HKRESTAPIProgressHandler)progressHandler
completionHandler:(HKRESTAPICompletionHandler)completionHandler
{
    [self performRequest:[self requestForMethod:method HTTPMethod:@"PUT" HTTPBody:body contentType:contentType] synchronously:synchronously completionHandler:completionHandler progressHandler:progressHandler];
}

- (void)DELETEMethod:(NSString *)method
            HTTPBody:(NSData *)body
         contentType:(NSString *)contentType
       synchronously:(BOOL)synchronously
     progressHandler:(HKRESTAPIProgressHandler)progressHandler
   completionHandler:(HKRESTAPICompletionHandler)completionHandler
{
    [self performRequest:[self requestForMethod:method HTTPMethod:@"DELETE" HTTPBody:body contentType:contentType] synchronously:synchronously completionHandler:completionHandler progressHandler:progressHandler];
}

- (void)GETMethod:(NSString *)method
       parameters:(NSDictionary *)parameters
    synchronously:(BOOL)synchronously
  progressHandler:(HKRESTAPIProgressHandler)progressHandler
completionHandler:(HKRESTAPICompletionHandler)completionHandler
{
    NSMutableString     *ustring = [NSMutableString stringWithString:method];
    NSString            *variables;
    
    if ( parameters != nil )
    {
        variables = [self URLVariablesUsingParameters:parameters];
        
        if ( variables )
        {
            [ustring appendFormat:@"?%@", variables];
        }
    }
    
    [self performRequest:[self requestForMethod:ustring HTTPMethod:@"GET" HTTPBody:nil contentType:nil] synchronously:synchronously completionHandler:completionHandler progressHandler:progressHandler];
}

- (void)POSTMethod:(NSString *)method
        parameters:(NSDictionary *)parameters
     synchronously:(BOOL)synchronously
   progressHandler:(HKRESTAPIProgressHandler)progressHandler
 completionHandler:(HKRESTAPICompletionHandler)completionHandler
{
    NSData              *data = nil;
    NSString            *contentType = nil;
    
    if ( parameters != nil )
    {
        data = [self formDataUsingParameters:parameters];
        
        if ( data != nil )
        {
            contentType = @"application/x-www-form-urlencoded";
        }
    }
    
    [self performRequest:[self requestForMethod:method HTTPMethod:@"POST" HTTPBody:data contentType:contentType] synchronously:synchronously completionHandler:completionHandler progressHandler:progressHandler];
}

- (NSString *)HTTPHeaderForKey:(NSString *)key
{
    return [self.HTTPHeaders objectForKey:key];
}

- (void)removeHTTPHeaderForKey:(NSString *)key
{
    [self.HTTPHeaders removeObjectForKey:key];
}

- (BOOL)hasPendingRequests
{
    return (_rcount > 0);
}

#pragma mark HKLegacy API

- (void)GETMethod:(NSString *)method parameters:(NSDictionary *)parameters synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)handler
{
    [self GETMethod:method parameters:parameters synchronously:synchronously progressHandler:nil completionHandler:handler];
}

- (void)POSTMethod:(NSString *)method parameters:(NSDictionary *)parameters synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)handler
{
    [self POSTMethod:method parameters:parameters synchronously:synchronously progressHandler:nil completionHandler:handler];
}

- (void)POSTMethod:(NSString *)method HTTPBody:(NSData *)body contentType:(NSString *)contentType synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)handler
{
    [self POSTMethod:method HTTPBody:body contentType:contentType synchronously:synchronously progressHandler:nil completionHandler:handler];
}

- (void)PUTMethod:(NSString *)method HTTPBody:(NSData *)body contentType:(NSString *)contentType synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)handler
{
    [self PUTMethod:method HTTPBody:body contentType:contentType synchronously:synchronously progressHandler:nil completionHandler:handler];
}

- (void)DELETEMethod:(NSString *)method HTTPBody:(NSData *)body contentType:(NSString *)contentType synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)handler
{
    [self DELETEMethod:method HTTPBody:body contentType:contentType synchronously:synchronously progressHandler:nil completionHandler:handler];
}

- (void)setHTTPHeader:(NSString *)value forKey:(NSString *)key
{
    [self.HTTPHeaders setObject:value forKey:key];
}

#pragma mark HKPrivate API

- (void)setup
{
    if ( _requests == nil )
    {
        _requests = dispatch_queue_create( "se.hobocode.gcd.restapi", NULL );
        
        self.HTTPHeaders = [NSMutableDictionary dictionary];
    }
}

- (void)performRequest:(NSURLRequest *)request synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)completionHandler progressHandler:(HKRESTAPIProgressHandler)progressHandler
{
    id rhandler = ^{

        if ( request == nil )
        {
            completionHandler( nil, [NSError errorWithDomain:NSPOSIXErrorDomain code:EINVAL userInfo:nil], -1 );

            return;
        }

#ifdef HK_DEBUG_REST_API
        NSData *ddata = [request HTTPBody];
        NSString *dstring;
        
        if ( [ddata length] > 1024 )
            dstring = [NSString stringWithFormat:@"[data length='%d']", [ddata length]];
        else
            dstring = [[[NSString alloc] initWithData:ddata encoding:NSUTF8StringEncoding] autorelease];
        
        NSLog(@"HKRESTAPI->Requesting URL (%@): %@ (with body: %@)", [request HTTPMethod], [request URL], dstring);
#endif
        
        HKURLOperation *operation = [[HKURLOperation alloc] initWithURLRequest:request
                                                        progressHandler:^( double progress ) {
                                                            if ( progressHandler != nil )
                                                            {
                                                                progressHandler( progress );
                                                            }
                                                        }
                                                      completionHandler:^( BOOL success, NSURLResponse *response, NSData *data, NSError *error ) {
                                                          id                   result = nil;
                                                          NSInteger            statusCode = 0;
                                                          NSError             *oerror = error;
#ifdef HK_DEBUG_REST_API_HTTP_HEADERS
                                                          NSDictionary        *headers = nil;
#endif
                                                          if ( [response isKindOfClass:[NSHTTPURLResponse class]] )
                                                          {
                                                              NSHTTPURLResponse *hresponse = (NSHTTPURLResponse *) response;
                                                            
                                                              statusCode = [hresponse statusCode];
#ifdef HK_DEBUG_REST_API_HTTP_HEADERS
                                                              headers = [hresponse allHeaderFields];
#endif
                                                          }
                                                          
                                                          if ( success )
                                                          {
#ifdef HK_DEBUG_REST_API
                                                              NSLog(@"\r\n########## HKRESTAPI DATA from %@ (status code: %i) ##########\r\n%@\r\n########## ------------------------------------------- ##########\r\n", [request HTTPMethod], (int)statusCode, [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
# ifdef HK_DEBUG_REST_API_HTTP_HEADERS
                                                              if ( headers != nil )
                                                              {
                                                                  NSLog(@"\r\n########## HKRESTAPI HEADERS ##########\r\n%@\r\n########## ------------------------------------------- ##########\r\n", headers );
                                                              }
# endif
#endif
                                                              
                                                              if ( statusCode < 200 || statusCode >= 300 )
                                                              {
                                                                  NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                                                                   request, @"request",
                                                                                                   response, @"response",
                                                                                                   nil];
                                                                  
                                                                  if ( data ) [userInfo setValue:data forKey:@"responseBody"];
                                                                  
                                                                  oerror = [NSError errorWithDomain:HK_ERROR_DOMAIN code:HK_ERROR_CODE_WEB_API_ERROR userInfo:userInfo];
                                                                  
                                                                  completionHandler( nil, oerror, statusCode );
                                                                  
                                                                  return;
                                                              }
                                                              
                                                              BOOL returnsResult = ( statusCode == 200 ||
                                                                                    statusCode == 201 ||
                                                                                    ( statusCode == 202 && [[request HTTPMethod] isEqualToString:@"PUT"] )
                                                                                    );
                                                              
                                                              if ( returnsResult )
                                                              {
                                                                  if ( [response isKindOfClass:[NSHTTPURLResponse class]] )
                                                                  {
                                                                      NSHTTPURLResponse *hresponse = (NSHTTPURLResponse *) response;
                                                                      NSArray           *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[hresponse allHeaderFields] forURL:[response URL]];
                                                                      
                                                                      [self setResponseCookies:cookies];
                                                                  }
                                                                  
                                                                  if ( _resultAdapter == nil )
                                                                  {
                                                                      _resultAdapter = [[HKRESTAPIJSONResultAdapter alloc] init];
                                                                  }
                                                                  
                                                                  result = [_resultAdapter resultForData:data error:&oerror];
                                                              }
                                                              
                                                              if ( result == nil )
                                                              {
                                                                  completionHandler( nil, returnsResult ? oerror : nil, statusCode );
                                                                  
                                                                  return;
                                                              }
                                                              
                                                              completionHandler( result, nil, statusCode );
                                                          }
                                                          else
                                                          {
                                                              completionHandler( nil, oerror, statusCode );
                                                          }
                                                      }];
        
        [operation start];
        [operation waitUntilFinished];
        [operation release];
        
        OSAtomicDecrement32( &_rcount );
    };
    
    OSAtomicIncrement32( &_rcount );

    if ( synchronously )
    {
        dispatch_sync( _requests, rhandler );
    }
    else
    {
        dispatch_async( _requests, rhandler );
    }
}

- (NSURLRequest *)requestForMethod:(NSString *)method HTTPMethod:(NSString *)httpMethod HTTPBody:(NSData *)body contentType:(NSString *)contentType
{
    NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
    NSString            *mstring;
    
    if ( self.APIVersion != nil )
    {
        mstring = [NSString stringWithFormat:@"%@/%@/%@", self.APIBaseURL, self.APIVersion, method];
    }
    else
    {
        mstring = [NSString stringWithFormat:@"%@/%@", self.APIBaseURL, method];
    }

    [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    [request setTimeoutInterval:60.0];
    [request setHTTPMethod:httpMethod];

    if ( self.APIUsername && self.APIPassword )
    {
        NSString	*astring = [NSString stringWithFormat:@"%@:%@", self.APIUsername, self.APIPassword];
        NSData		*adata = [astring dataUsingEncoding:NSASCIIStringEncoding];
        NSString	*avalue = [NSString stringWithFormat:@"Basic %@", [adata base64EncodingWithLineLength:80]];

        [request setValue:avalue forHTTPHeaderField:@"Authorization"];
    }

    for ( NSString *field in self.HTTPHeaders )
    {
        NSString *value = [self.HTTPHeaders objectForKey:field];
        [request setValue:value forHTTPHeaderField:field];
    }

    if ( body != nil )
    {
        [request setHTTPBody:body];
    }

    if ( contentType != nil )
    {
        [request setValue:contentType forHTTPHeaderField:@"Content-type"];
    }

    if ( self.responseCookies != nil )
    {
        if ([[self responseCookies] count] > 0)
        {
            NSHTTPCookie *cookie;
            NSString *cookieHeader = nil;
            for ( cookie in [self responseCookies] )
            {
                if ( !cookieHeader )
                {
                    cookieHeader = [NSString stringWithFormat:@"%@=%@", [cookie name], [cookie value]];
                }
                else
                {
                    cookieHeader = [NSString stringWithFormat: @"%@; %@=%@", cookieHeader, [cookie name], [cookie value]];
                }
            }

            if ( cookieHeader )
            {
                [request setValue:cookieHeader forHTTPHeaderField:@"Cookie"];
            }
        }
    }
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setURL:[NSURL URLWithString:mstring]];

    return request;
}

- (NSString *)URLVariablesUsingParameters:(NSDictionary *)parameters
{
    NSMutableString *result = [NSMutableString string];
    NSArray         *keys = [parameters allKeys];
    NSString        *key = nil;
    NSUInteger      i, c;
    id              value;

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
        else if ( [value isKindOfClass:[NSData class]] )
        {
            NSData *data = (NSData *) value;
            
            if ( [data respondsToSelector:@selector(base64Encoding)] )
            {
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                
                [result appendFormat:@"%@%@=%@", (i == 0 ? @"" : @"&"), key, [data base64Encoding]];
                
                [pool release];
            }
        }
        else if ( [value isKindOfClass:[NSArray class]] )
        {
            BOOL first = YES;
            
            for ( id element in value )
            {
                if ( [value isKindOfClass:[NSString class]] )
                {
                    NSString *string = (NSString *) element;
                    
                    [result appendFormat:@"%@%@[]=%@", (first ? @"" : @"&"), key, [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                }
                else if ( [element isKindOfClass:[NSNumber class]] )
                {
                    NSNumber *number = (NSNumber *) element;
                    
                    [result appendFormat:@"%@%@[]=%d", (first ? @"" : @"&"), key, [number intValue]];
                }
                
                first = NO;
            }
        }
    }

    return [NSString stringWithString:result];
}

- (NSData *)formDataUsingParameters:(NSDictionary *)parameters
{
    return [[self URLVariablesUsingParameters:parameters] dataUsingEncoding:NSUTF8StringEncoding];
}

@end
