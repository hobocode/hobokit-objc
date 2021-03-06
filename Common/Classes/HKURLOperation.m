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

#import "HKURLOperation.h"

@interface HKURLOperation (HKPrivate)

- (void)finish;

@end

@implementation HKURLOperation

@synthesize useCredentialStorage = _useCredentialStorage;

- (id)initWithURL:(NSURL *)url progressHandler:(HKURLOperationProgressHandler)progressHandler completionHandler:(HKURLOperationCompletionHandler)completionHandler authenticationChallengeHandler:(HKURLOperationAuthenticationChallengeHandler)authHandler
{
    NSURLRequest *request = [[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0] retain];

    return [self initWithURLRequest:request progressHandler:progressHandler completionHandler:completionHandler authenticationChallengeHandler:authHandler];
}

- (id)initWithURLRequest:(NSURLRequest *)request progressHandler:(HKURLOperationProgressHandler)progressHandler completionHandler:(HKURLOperationCompletionHandler)completionHandler authenticationChallengeHandler:(HKURLOperationAuthenticationChallengeHandler)authHandler
{
    if ( (self = [super init]) )
    {
        _request = [request retain];
        
        if ( progressHandler != nil )
        {
            _progressHandler = Block_copy( progressHandler );
        }
        
        if ( completionHandler != nil )
        {
            _completionHandler = Block_copy( completionHandler );
        }

        if ( authHandler != nil )
        {
            _authenticationChallengeHandler = Block_copy( authHandler );
        }

        self.useCredentialStorage = YES;
    }
    
    return self;
}


- (id)initWithURL:(NSURL *)url progressHandler:(HKURLOperationProgressHandler)progressHandler completionHandler:(HKURLOperationCompletionHandler)completionHandler
{
    return [self initWithURL:url progressHandler:progressHandler completionHandler:completionHandler authenticationChallengeHandler:nil];
}

- (id)initWithURLRequest:(NSURLRequest *)request progressHandler:(HKURLOperationProgressHandler)progressHandler completionHandler:(HKURLOperationCompletionHandler)completionHandler
{
    return [self initWithURLRequest:request progressHandler:progressHandler completionHandler:completionHandler authenticationChallengeHandler:nil];
}

- (void)dealloc
{
    [_request release]; _request = nil;
    [_connection release]; _connection = nil;
    [_response release]; _response = nil;
    [_data release]; _data = nil;
    [_error release]; _error = nil;
    
    if ( _progressHandler != nil )
    {
        Block_release( _progressHandler );
    }
    
    if ( _completionHandler != nil )
    {
        Block_release( _completionHandler );
    }

    if ( _authenticationChallengeHandler != nil )
    {
        Block_release( _authenticationChallengeHandler );
    }
    
    [super dealloc];
}

#pragma mark HKPrivate API

- (void)main
{
    _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self];
    _data = [[NSMutableData alloc] init];
    
    while ( _connection != nil && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]] )
    {
    }
    
    if ( _completionHandler != nil )
    {
        _completionHandler( (_error == nil), [[_response copy] autorelease], (_error == nil ? [NSData dataWithData:_data] : nil), [[_error copy] autorelease] );
    }
    
    [self finish];
}

- (void)start
{
    if ( [self isCancelled] )
    {
        [self willChangeValueForKey:@"isFinished"];

        _finished = YES;

        [self didChangeValueForKey:@"isFinished"];

        return;
    }

	[self willChangeValueForKey:@"isExecuting"];

    _executing = YES;

    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];

    [self didChangeValueForKey:@"isExecuting"];
}

- (void)cancel
{
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isCancelled"];
	
	_executing = NO;
	_cancelled = YES;
	
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isCancelled"];
}

- (void)finish
{
	[self willChangeValueForKey:@"isExecuting"];
	[self willChangeValueForKey:@"isFinished"];
	
	_executing = NO;
	_finished = YES;
	
	[self didChangeValueForKey:@"isExecuting"];
	[self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isExecuting
{
	return _executing;
}

- (BOOL)isReady
{
	return ( _executing == NO );
}

- (BOOL)isCancelled
{
	return _cancelled;
}

- (BOOL)isFinished
{
	return _finished;
}

- (BOOL)isConcurrent
{
	return YES;
}

#pragma mark NSURLConnectionDelegate Methods

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{	
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    long long length = [response expectedContentLength];
    
    if ( length > 0 )
    {
        _length = (double) length;
    }
    
    [_data setLength:0];
    
    if ( _response != response )
    {
        [_response release];
        _response = [response retain];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_data appendData:data];
	
    if ( _progressHandler != nil )
    {
        if ( _length > 0.0 )
        {
            double dlength = (double) [_data length];
            
            _progressHandler( (dlength / _length) );
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ( _error != error )
    {
        [_error release];
        _error = [error retain];
    }

    [_connection release]; _connection = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ( _authenticationChallengeHandler )
    {
        BOOL tryAgain = _authenticationChallengeHandler( challenge );
        if ( !tryAgain )
        {
            _error = [[NSError alloc] initWithDomain:HK_ERROR_DOMAIN code:HK_ERROR_CODE_URL_OPERATION_NOT_AUTHENTICATED_CODE userInfo:nil];
            [_connection release]; _connection = nil;
        }
    }
    else
    {
        [_connection release]; _connection = nil;
    }
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return self.useCredentialStorage;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _error = nil;

    [_connection release]; _connection = nil;
}

@end
