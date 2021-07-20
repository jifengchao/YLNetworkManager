//
//  YBBaseRequest+Internal.h
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import "YBBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBBaseRequest ()

/// 请求方法字符串
- (NSString *)requestMethodString;

/// 请求 URL 字符串
- (NSString *)requestURLString;

@end

NS_ASSUME_NONNULL_END
