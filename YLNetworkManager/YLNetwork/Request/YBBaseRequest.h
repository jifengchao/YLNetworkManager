//
//  YBBaseRequest.h
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import <Foundation/Foundation.h>
#import "YBNetworkResponse.h"
#import "YBNetworkCache.h"
#import "YBNetworkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBBaseRequest : NSObject
/**如果不允许重复网络请求,重复请求时取消最新的调用start就直接会使用return结束,即该请求任务不发起,其他失败都会调用fail回调,网络请求成功才调success回调**/
#pragma - 网络请求数据

/** 请求方法类型 */
@property (nonatomic, assign) YBRequestMethod requestMethod;

/** 请求方法解析器 */
@property (nonatomic, assign) YBRequestSerialization serialization;

/** 请求访问路径 (例如：/detail/list) */
@property (nonatomic, copy) NSString *requestURI;

/** 请求参数 */
@property (nonatomic, copy, nullable) NSDictionary *requestParameter;

/** 请求超时时间 */
@property (nonatomic, assign) NSTimeInterval requestTimeoutInterval;

/** 请求上传文件包 */
@property (nonatomic, copy, nullable) void(^requestConstructingBody)(id<AFMultipartFormData> formData);

/** 返回数据  */
@property (nonatomic, strong, readonly) YBNetworkResponse *response;

/** 下载路径 */
@property (nonatomic, copy) NSString *downloadPath;

/** 请求时的block **/
@property (nonatomic, copy, nullable) YBRequestProgressBlock uploadProgress;
@property (nonatomic, copy, nullable) YBRequestProgressBlock downloadProgress;
@property (nonatomic, copy, nullable) YBRequestCacheBlock cacheBlock;
@property (nonatomic, copy, nullable) YBRequestSuccessBlock successBlock;
@property (nonatomic, copy, nullable) YBRequestFailureBlock failureBlock;
@property (nonatomic, copy, nullable) YBRequestExceptionBlock exceptionBlock;

#pragma - 发起网络请求

/** 发起网络请求 */
- (NSString *)start;

/** 发起网络请求带回调 */
- (NSString *)startWithSuccess:(nullable YBRequestSuccessBlock)success
                 failure:(nullable YBRequestFailureBlock)failure;

- (NSString *)startWithCache:(nullable YBRequestCacheBlock)cache
               success:(nullable YBRequestSuccessBlock)success
               failure:(nullable YBRequestFailureBlock)failure;

- (NSString *)startWithUploadProgress:(nullable YBRequestProgressBlock)uploadProgress
               downloadProgress:(nullable YBRequestProgressBlock)downloadProgress
                          cache:(nullable YBRequestCacheBlock)cache
                        success:(nullable YBRequestSuccessBlock)success
                        failure:(nullable YBRequestFailureBlock)failure;

- (NSString *)requestByMethod:(YBRequestMethod)method url:(NSString *)url parameters:(NSDictionary *)parameters headers:(nullable NSDictionary <NSString *, NSString *> *)headers success:(YBRequestSuccessBlock)success failure:(YBRequestFailureBlock)failure;

/** 取消网络请求 */
- (void)cancel;

#pragma - 相关回调代理

/** 请求结果回调代理 */
@property (nonatomic, weak) id<YBResponseDelegate> delegate;

#pragma - 缓存

/** 缓存处理器 */
@property (nonatomic, strong, readonly) YBNetworkCache *cacheHandler;

- (void)requestCache:(nonnull void (^)(NSString * _Nonnull, id<NSCoding> _Nullable))block isAsyn:(BOOL)isAsyn;

- (void)removeCache;

#pragma - 其它

/** 网络请求释放策略 (默认 YBNetworkReleaseStrategyHoldRequest)
 使用说明:YBNetworkReleaseStrategyWhenRequestDealloc搭配strong属性使用,当控制器释放的时候request调用dealloc达到目的,当request被释放的时候不会调用任何回调*/
@property (nonatomic, assign) YBNetworkReleaseStrategy releaseStrategy;

/** 重复网络请求处理策略 (默认 YBNetworkRepeatStrategyAllAllowed)
 使用说明:此属性只支持单个实例(如懒加载的属性),如果创建多个相同实例无效*/
@property (nonatomic, assign) YBNetworkRepeatStrategy repeatStrategy;

/** 是否正在网络请求 */
- (BOOL)isExecuting;

/** 请求标识，可以查看完整的请求路径和参数 */
- (NSString *)requestIdentifier;

#pragma - 网络请求公共配置 (以子类化方式实现: 针对不同的接口团队设计不同的公共配置)

/**
 事务管理器 (通常情况下不需设置) 。注意：
 1、其 requestSerializer 和 responseSerializer 属性会被下面两个同名属性覆盖。
 2、其 completionQueue 属性会被框架内部覆盖。
 */
/** 使用自定义的manager **/
@property (nonatomic, strong, nullable) AFHTTPSessionManager *sessionManager;


/** 服务器地址及公共路径 (例如：https://www.baidu.com) */
@property (nonatomic, copy) NSString *baseURI;

@end

/// 请求处理声明周期 (重载分类方法)
@interface YBBaseRequest (RequestLifeCycle)

/** 调用start后开始处理请求 */
- (void)startProcessRequest;

/** 请求处理结束 */
- (void)endProcessRequest;

@end
/// 预处理请求数据 (重载分类方法)
@interface YBBaseRequest (PreprocessRequest)

/** 预处理请求头, 返回需要额外添加的参数 */
- (NSDictionary *)yb_requestCustomHeader;

/** 预处理请求参数, 返回处理后的请求参数 */
- (nullable NSDictionary *)yb_preprocessParameter:(nullable NSDictionary *)parameter;

/** 预处理拼接后的完整 URL 字符串, 返回处理后的 URL 字符串 */
- (NSString *)yb_preprocessURLString:(NSString *)URLString;

@end


/// 预处理响应数据 (重载分类方法)
@interface YBBaseRequest (PreprocessResponse)

/** 预处理请求成功数据 */
- (void)yb_preprocessSuccessInMainThreadWithResponse:(YBNetworkResponse *)response;

/** 预处理请求失败数据 */
- (void)yb_preprocessFailureInMainThreadWithResponse:(YBNetworkResponse *)response;

@end

NS_ASSUME_NONNULL_END
