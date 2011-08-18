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

#import "HKCacheManagerTestCase.h"

#import "HKCacheManager.h"

@implementation HKCacheManagerTestCase

- (void)setUp
{
    path = [[NSString alloc] initWithString:@"/tmp/test/data.db"];
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    cacheManager = [[HKCacheManager alloc] initWithPath:@"/tmp/test/data.db"];
}

- (void)tearDown
{
    [path release];
    [cacheManager release];
}

- (void)testPath
{
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    STAssertEquals( exists, YES, @"Path %@ doesn't exists", path );
    STAssertEquals( cacheManager.path, path, @"Path is wrong" );
}

- (void)testInsertAndFetch
{
    NSString *identifier = @"identifier";
    NSData *cacheData = [@"This is the string that will be cached" dataUsingEncoding:NSUTF8StringEncoding];
    
    [cacheManager cacheData:cacheData withIdentifier:identifier];

    NSData *fetchedData = [cacheManager cachedDataWithIdentifier:identifier];
    STAssertEqualObjects( fetchedData, cacheData, @"Fetched (%@) and inserted (%@) data not the same", fetchedData, cacheData );
}


- (void)testInsertAndFetchNil
{
    NSString *identifier = @"identifier-nil-insert";
    
    [cacheManager cacheData:nil withIdentifier:identifier];
    
    NSData *fetchedData = [cacheManager cachedDataWithIdentifier:identifier];
    STAssertEqualObjects( fetchedData, nil, @"Fetched data should be nil" );}


- (void)testFetchNil
{
    NSString *identifier = @"identifier-nil";
    NSData *fetchedData = [cacheManager cachedDataWithIdentifier:identifier];
    STAssertEqualObjects( fetchedData, nil, @"Fetched data should be nil" );
}

@end
