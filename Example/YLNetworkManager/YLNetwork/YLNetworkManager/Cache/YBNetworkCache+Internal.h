//
//  YBNetworkCache+Internal.h
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import "YBNetworkCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBNetworkCache ()

/**
 存数据
 
 @param object 数据对象
 @param isAsyn 同步或异步
 @param key 标识
 */
- (void)setObject:(id<NSCoding>)object forKey:(id)key isAsyn:(BOOL)isAsyn;
/**
 取数据
 
 @param key 标识
 @param isAsyn 同步或异步
 @param block 回调 (主线程)
 */
- (void)objectForKey:(NSString *)key isAsyn:(BOOL)isAsyn  withBlock:(nonnull void (^)(NSString * _Nonnull, id<NSCoding> _Nullable))block ;
/**
 删除数据
 
 @param key 标识
 */
- (void)removeCacheforKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
