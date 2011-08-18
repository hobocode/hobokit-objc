//
//  HKCacheManagerTestCase.m
//  HoboKit Tests
//
//  Created by Gustaf on 2011-08-18.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
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
