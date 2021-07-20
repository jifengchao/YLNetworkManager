//
//  YBNetworkDefine.h
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

/*
 YBNetwork<https://github.com/indulgeIn/YBNetwork>
 */

#ifndef YBNetworkDefine_h
#define YBNetworkDefine_h

#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif


#define YBNETWORK_QUEUE_ASYNC(queue, block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {\
block();\
} else {\
dispatch_async(queue, block);\
}

#define YBNETWORK_MAIN_QUEUE_ASYNC(block) YBNETWORK_QUEUE_ASYNC(dispatch_get_main_queue(), block)


NS_ASSUME_NONNULL_BEGIN

/// 请求类型
typedef NS_ENUM(NSInteger, YBRequestMethod) {
    YBRequestMethodGET,
    YBRequestMethodPOST,
    YBRequestMethodDELETE,
    YBRequestMethodPUT,
    YBRequestMethodHEAD,
    YBRequestMethodPATCH
};
/// 请求解析器类型
typedef NS_ENUM(NSInteger, YBRequestSerialization) {
    YBRequestFormData,
    YBRequestApplicationJson,
};

/// 网络响应错误类型
typedef NS_ENUM(NSInteger, YBResponseErrorType) {
    YBResponseErrorTypeNone,       //无
    YBResponseErrorTypeTimedOut,   //超时
    YBResponseErrorTypeCancelled,  //取消
    YBResponseErrorTypeNoNetwork,   //用户无网络
    YBResponseErrorNoNetworkPermissions,   //无网络权限
    YBResponseErrorCancelNetworkPermissions,   //用户取消网络权限
    YBResponseErrorTypeOther,   //其他

};

/// 缓存存储模式
typedef NS_OPTIONS(NSUInteger, YBNetworkCacheWriteMode) {
    YBNetworkCacheWriteModeNone = 0,            //无缓存
    YBNetworkCacheWriteModeMemory = 1 << 0,     //内存缓存
    YBNetworkCacheWriteModeDisk = 1 << 1,       //磁盘缓存
    YBNetworkCacheWriteModeMemoryAndDisk = YBNetworkCacheWriteModeMemory | YBNetworkCacheWriteModeDisk
};

/// 缓存读取模式
typedef NS_ENUM(NSInteger, YBNetworkCacheReadMode) {
    YBNetworkCacheReadModeNone,            //不读取缓存
    YBNetworkCacheReadModeAlsoNetwork,     //缓存命中后仍然发起网络请求
    YBNetworkCacheReadModeCancelNetwork,   //缓存命中后不发起网络请求
};

/// 网络请求释放策略
typedef NS_ENUM(NSInteger, YBNetworkReleaseStrategy) {
    YBNetworkReleaseStrategyHoldRequest,        //网络任务会持有 YBBaseRequest 实例，网络任务完成 YBBaseRequest 实例才会释放
    YBNetworkReleaseStrategyWhenRequestDealloc, //网络请求将随着 YBBaseRequest 实例的释放而取消,搭配请求当做属性(如果当做临时变量会在作用域中结束后直接被释放)
};

/// 重复网络请求处理策略
typedef NS_ENUM(NSInteger, YBNetworkRepeatStrategy) {
    YBNetworkRepeatStrategyAllAllowed,     //允许重复网络请求
    YBNetworkRepeatStrategyCancelOldest,   //取消最旧的网络请求
    YBNetworkRepeatStrategyCancelNewest    //取消最新的网络请求
};
/// 群发网络请求策略
typedef NS_ENUM(NSInteger, YBBatchRequestStrategy) {
    YBBatchRequestNone,//默认 请求失败成功跟群发请求结果无关,全部请求结果回来之后 调用batch success
    YBBatchRequestFailCancel,       //若其中一个请求失败就取消所有请求,调用batch fail回调
};
/// 网络请求释放策略
typedef NS_ENUM(NSInteger, YBBatchReqReleaseStrategy) {
    YBBatchReqReleaseHoldRequest,        //网络任务会持有 YBBaseRequest 实例，网络任务完成 YBBaseRequest 实例才会释放
    YBBatchReqReleaseWhenRequestDealloc, //网络请求将随着 YBBaseRequest 实例的释放而取消,搭配请求当做属性(如果当做临时变量会在作用域中结束后直接被释放)
};

@class YBBaseRequest;
@class YBNetworkResponse;
@class YBBatchRequest;

/// 进度闭包
typedef void(^YBRequestProgressBlock)(NSProgress *progress);

/// 缓存命中闭包
typedef void(^YBRequestCacheBlock)(YBNetworkResponse *response);

/// 请求成功闭包
typedef void(^YBRequestSuccessBlock)(YBNetworkResponse *response);

/// 请求失败闭包
typedef void(^YBRequestFailureBlock)(YBNetworkResponse *response);

/// 请求处理异常闭包
typedef void (^YBRequestExceptionBlock)(NSException *exception);

/// 组请求结束闭包
typedef void(^YBBatchRequestFinishedBlock)(YBBatchRequest *response);

/// 网络请求响应代理
@protocol YBResponseDelegate <NSObject>
@optional

/// 上传进度
- (void)request:(__kindof YBBaseRequest *)request uploadProgress:(NSProgress *)progress;

/// 下载进度
- (void)request:(__kindof YBBaseRequest *)request downloadProgress:(NSProgress *)progress;

/// 缓存命中
- (void)request:(__kindof YBBaseRequest *)request cacheWithResponse:(YBNetworkResponse *)response;

/// 请求成功
- (void)request:(__kindof YBBaseRequest *)request successWithResponse:(YBNetworkResponse *)response;

/// 请求失败
- (void)request:(__kindof YBBaseRequest *)request failureWithResponse:(YBNetworkResponse *)response;

@end

@protocol YBBatchRequestDelegate <NSObject>
@optional

/// 请求成功
- (void)batchRequestSuccessed:(YBBatchRequest *)batchRequest;

/// 请求失败
- (void)batchRequestFailed:(YBBatchRequest *)batchRequest;


@end

NS_ASSUME_NONNULL_END

#endif /* YBNetworkDefine_h */
