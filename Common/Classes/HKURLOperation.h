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

typedef void (^HKURLOperationCompletionHandler)( BOOL success, NSURLResponse *response, NSData *data, NSError *error );
typedef void (^HKURLOperationProgressHandler)( double progress );
typedef BOOL (^HKURLOperationAuthenticationChallengeHandler)( NSURLAuthenticationChallenge *challenge );

#define HK_ERROR_CODE_URL_OPERATION_NOT_AUTHENTICATED_CODE     4001

@interface HKURLOperation : NSOperation
{
@private
    NSURLRequest    *_request;
    NSURLConnection *_connection;
    NSURLResponse   *_response;
    NSMutableData   *_data;
    NSError         *_error;

    HKURLOperationCompletionHandler                 _completionHandler;
    HKURLOperationProgressHandler                   _progressHandler;
    HKURLOperationAuthenticationChallengeHandler    _authenticationChallengeHandler;

    double          _length;
    BOOL            _executing;
    BOOL            _finished;
    BOOL            _cancelled;
}

- (id)initWithURL:(NSURL *)url progressHandler:(HKURLOperationProgressHandler)progressHandler completionHandler:(HKURLOperationCompletionHandler)completionHandler;
- (id)initWithURLRequest:(NSURLRequest *)request progressHandler:(HKURLOperationProgressHandler)progressHandler completionHandler:(HKURLOperationCompletionHandler)completionHandler;

- (id)initWithURL:(NSURL *)url progressHandler:(HKURLOperationProgressHandler)progressHandler completionHandler:(HKURLOperationCompletionHandler)completionHandler authenticationChallengeHandler:(HKURLOperationAuthenticationChallengeHandler)authHandler;
- (id)initWithURLRequest:(NSURLRequest *)request progressHandler:(HKURLOperationProgressHandler)progressHandler completionHandler:(HKURLOperationCompletionHandler)completionHandler authenticationChallengeHandler:(HKURLOperationAuthenticationChallengeHandler)authHandler;

@end
