
#import <SenTestingKit/SenTestingKit.h>

@class HKCacheManager;

@interface HKCacheManagerTestCase : SenTestCase
{
    HKCacheManager *cacheManager;
    NSString *path;
}

@end
