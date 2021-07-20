//
//  YBNetworkCache.m
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import "YBNetworkCache.h"
#import "YBNetworkCache+Internal.h"

@interface YBNetworkCachePackage : NSObject <NSCoding>

@property (nonatomic, strong) id<NSCoding> object;
@property (nonatomic, strong) NSDate *updateDate;

@end

@implementation YBNetworkCachePackage

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    self.object = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(object))];
    self.updateDate = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(updateDate))];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.object forKey:NSStringFromSelector(@selector(object))];
    [aCoder encodeObject:self.updateDate forKey:NSStringFromSelector(@selector(updateDate))];
}

@end


static NSString * const YBNetworkCacheName = @"YBNetworkCacheName";
static YYDiskCache *_diskCache = nil;
static YYMemoryCache *_memoryCache = nil;
@implementation YBNetworkCache

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.writeMode = YBNetworkCacheWriteModeNone;
        self.readMode = YBNetworkCacheReadModeNone;
        self.ageSeconds = 0;
        self.extraCacheKey = [@"v" stringByAppendingString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    }
    return self;
}

#pragma mark - public

+ (NSInteger)getDiskCacheSize {
    return [YBNetworkCache.diskCache totalCost] / 1024.0 / 1024.0;
}

+ (void)removeDiskCache {
    [YBNetworkCache.diskCache removeAllObjects];
}

+ (void)removeMemeryCache {
    [YBNetworkCache.memoryCache removeAllObjects];
}

#pragma mark - internal

- (void)removeCacheforKey:(NSString *)key {
    [YBNetworkCache.memoryCache removeObjectForKey:key];
    [YBNetworkCache.diskCache removeObjectForKey:key];

}
- (void)setObject:(id<NSCoding>)object forKey:(id)key isAsyn:(BOOL)isAsyn {
    YBNetworkCachePackage *package = [YBNetworkCachePackage new];
    package.object = object;
    package.updateDate = [NSDate date];
    
    if (self.writeMode & YBNetworkCacheWriteModeMemory) {
        
        [YBNetworkCache.memoryCache setObject:package forKey:key];
    }
    if (self.writeMode & YBNetworkCacheWriteModeDisk) {
        if (isAsyn) {
            [YBNetworkCache.diskCache setObject:package forKey:key withBlock:^{}]; //子线程执行，空闭包仅为了去除警告
        } else {
            [YBNetworkCache.diskCache setObject:package forKey:key];
        }
    }
}

- (void)objectForKey:(NSString *)key isAsyn:(BOOL)isAsyn  withBlock:(nonnull void (^)(NSString * _Nonnull, id<NSCoding> _Nullable))block {
    if (!block) return;
    
    void(^callBack)(id<NSCoding>) = ^(id<NSCoding> obj) {
        YBNETWORK_MAIN_QUEUE_ASYNC(^{
            if (obj && [((NSObject *)obj) isKindOfClass:YBNetworkCachePackage.class]) {
                YBNetworkCachePackage *package = (YBNetworkCachePackage *)obj;
                if (self.ageSeconds != 0 && -[package.updateDate timeIntervalSinceNow] > self.ageSeconds) {//数据过期
                    [YBNetworkCache.memoryCache removeObjectForKey:key];
                    [YBNetworkCache.diskCache removeObjectForKey:key];//清理过期数据
                    NSLog(@"===========clean expired data--key:%@", key);
                    block(key, nil);
                } else {
                    block(key, package.object);
                }
            } else {
                block(key, nil);
            }
        })
    };
    
    id<NSCoding> object = [YBNetworkCache.memoryCache objectForKey:key];
    if (object) {
        callBack(object);
    } else {
        if (isAsyn) {
            [YBNetworkCache.diskCache objectForKey:key withBlock:^(NSString *key, id<NSCoding> object) {
                if (object && ![YBNetworkCache.memoryCache objectForKey:key]) {
                    [YBNetworkCache.memoryCache setObject:object forKey:key];
                }
                callBack(object);
            }];
        } else {
           object = [YBNetworkCache.diskCache objectForKey:key];
            callBack(object);
        }
    }
}

#pragma mark - getter and setter

+ (YYDiskCache *)diskCache {
    if (!_diskCache) {
        NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [cacheFolder stringByAppendingPathComponent:YBNetworkCacheName];
        _diskCache = [[YYDiskCache alloc] initWithPath:path];
    }
    return _diskCache;
}

+ (void)setDiskCache:(YYDiskCache *)diskCache {
    _diskCache = diskCache;
}

+ (YYMemoryCache *)memoryCache {
    if (!_memoryCache) {
        _memoryCache = [YYMemoryCache new];
        _memoryCache.name = YBNetworkCacheName;
    }
    return _memoryCache;
}

+ (void)setMemoryCache:(YYMemoryCache *)memoryCache {
    _memoryCache = memoryCache;
}

@end
