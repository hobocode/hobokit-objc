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

#import <Foundation/Foundation.h>

#ifdef HK_DEBUG
# define HK_DEBUG_REST_API
#endif

#define HK_ERROR_CODE_WEB_API_ERROR     3001

typedef void (^HKRESTAPIProgressHandler)( double progress );
typedef void (^HKRESTAPICompletionHandler)( id json, NSError *error, NSInteger statusCode );

@interface HKRESTAPI : NSObject
{
@private
    NSString            *_APIBaseURL;
    NSString            *_APIVersion;
    NSString            *_APIUsername;
    NSString            *_APIPassword;
    NSMutableDictionary *_HTTPHeaders;
    dispatch_queue_t     _requests;

    NSArray             *_responseCookies;
}

@property (retain) NSString *APIBaseURL;
@property (retain) NSString *APIVersion;
@property (retain) NSString *APIUsername;
@property (retain) NSString *APIPassword;
@property (retain) NSMutableDictionary *HTTPHeaders;

@property (retain) NSArray *responseCookies;

@end

@interface HKRESTAPI (HKPublic)

+ (HKRESTAPI *)defaultAPI;

- (void)POSTMethod:(NSString *)method
          HTTPBody:(NSData *)body
       contentType:(NSString *)contentType
     synchronously:(BOOL)synchronously
   progressHandler:(HKRESTAPIProgressHandler)progressHandler
 completionHandler:(HKRESTAPICompletionHandler)completionHandler;

- (void)PUTMethod:(NSString *)method
         HTTPBody:(NSData *)body
      contentType:(NSString *)contentType
    synchronously:(BOOL)synchronously
  progressHandler:(HKRESTAPIProgressHandler)progressHandler
completionHandler:(HKRESTAPICompletionHandler)completionHandler;

- (void)DELETEMethod:(NSString *)method
            HTTPBody:(NSData *)body
         contentType:(NSString *)contentType
       synchronously:(BOOL)synchronously
     progressHandler:(HKRESTAPIProgressHandler)progressHandler
   completionHandler:(HKRESTAPICompletionHandler)completionHandler;


- (void)GETMethod:(NSString *)method
       parameters:(NSDictionary *)parameters
    synchronously:(BOOL)synchronously
  progressHandler:(HKRESTAPIProgressHandler)progressHandler
completionHandler:(HKRESTAPICompletionHandler)completionHandler;

- (void)POSTMethod:(NSString *)method
        parameters:(NSDictionary *)parameters
     synchronously:(BOOL)synchronously
   progressHandler:(HKRESTAPIProgressHandler)progressHandler
 completionHandler:(HKRESTAPICompletionHandler)completionHandler;

- (void)setHTTPHeader:(NSString *)value forKey:(NSString *)key;
- (NSString *)HTTPHeaderForKey:(NSString *)key;
- (void)removeHTTPHeaderForKey:(NSString *)key;

@end

@interface HKRESTAPI (HKLegacy)

- (void)POSTMethod:(NSString *)method HTTPBody:(NSData *)body contentType:(NSString *)contentType synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)handler;
- (void)PUTMethod:(NSString *)method HTTPBody:(NSData *)body contentType:(NSString *)contentType synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)handler;
- (void)DELETEMethod:(NSString *)method HTTPBody:(NSData *)body contentType:(NSString *)contentType synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)handler;

- (void)GETMethod:(NSString *)method parameters:(NSDictionary *)parameters synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)handler;
- (void)POSTMethod:(NSString *)method parameters:(NSDictionary *)parameters synchronously:(BOOL)synchronously completionHandler:(HKRESTAPICompletionHandler)handler;


@end
