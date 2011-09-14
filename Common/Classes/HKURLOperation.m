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

- (id)initWithURL:(NSURL *)url progressHandler:(HKURLOperationProgressHandler)progressHandler completionHandler:(HKURLOperationCompletionHandler)completionHandler
{
    if ( (self = [super init]) )
    {
        _url = [url retain];
        
        if ( progressHandler != nil )
        {
            _progressHandler = Block_copy( progressHandler );
        }
        
        if ( completionHandler != nil )
        {
            _completionHandler = Block_copy( completionHandler );
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_url release]; _url = nil;
    [_connection release]; _connection = nil;
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
    
    [super dealloc];
}

#pragma mark HKPrivate API

- (void)main
{
    _connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:_url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0]
                                                  delegate:self];
    _data = [[NSMutableData alloc] init];
    
    while ( _connection != nil && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]] )
    {
    }
    
    _completionHandler( (_error == nil), (_error == nil ? [NSData dataWithData:_data] : nil), _error );
        
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
    
    if ( length == NSURLResponseUnknownLength )
    {
        _length = -1.0;
    }
    else
    {
        _length = (double) length;
    }
    
    [_data setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_data appendData:data];
	
    if ( _length > 0.0 )
    {
        double dlength = (double) [_data length];
                
        _progressHandler( (dlength / _length) );
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

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    _error = nil;

    [_connection release]; _connection = nil;
}

@end