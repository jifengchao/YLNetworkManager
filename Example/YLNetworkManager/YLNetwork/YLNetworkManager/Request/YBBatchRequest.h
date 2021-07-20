//
//  YBBatchRequest.h
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import <Foundation/Foundation.h>
#import "YBBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface YBBatchRequest : NSObject

///  All the requests are stored in this array.
@property (nonatomic, strong, readonly) NSArray<YBBaseRequest *> *requestArray;

///  The delegate object of the batch request. Default is nil.
@property (nonatomic, weak, nullable) id<YBBatchRequestDelegate,YBResponseDelegate> delegate;

//群发请求策略 默认单个请求结果和群发结果无关
@property (nonatomic, assign) YBBatchRequestStrategy requestStrategy;

//群发请求释放策略 默认所有请求完成之后才会释放对batchReq实例的引用,搭配临时变量使用延长变量声明周期
@property (nonatomic, assign) YBBatchReqReleaseStrategy releaseStrategy;

///  The success callback. Note this will be called only if all the requests are finished.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^successCompletionBlock)(YBBatchRequest *);

///  The failure callback. Note this will be called if one of the requests fails.
///  This block will be called on the main queue.
@property (nonatomic, copy, nullable) void (^failureCompletionBlock)(YBBatchRequest *);


///  The first request that failed (and causing the batch request to fail).
@property (nonatomic, strong, readonly, nullable) YBBaseRequest *failedRequest;

///  Creates a `YTKBatchRequest` with a bunch of requests.
///
///  @param requestArray requests useds to create batch request.
///
- (instancetype)initWithRequestArray:(NSArray<YBBaseRequest *> *)requestArray;

///  Set completion callbacks
- (void)setCompletionBlockWithSuccess:(nullable void (^)(YBBatchRequest *batchRequest))success
                              failure:(nullable void (^)(YBBatchRequest *batchRequest))failure;

///  Nil out both success and failure callback blocks.
- (void)clearCompletionBlock;


///  Append all the requests to queue.
- (void)start;

///  Stop all the requests of the batch request.
- (void)stop;

///  Convenience method to start the batch request with block callbacks.
- (void)startWithCompletionBlockWithSuccess:(nullable void (^)(YBBatchRequest *batchRequest))success
                                    failure:(nullable void (^)(YBBatchRequest *batchRequest))failure;
@end

NS_ASSUME_NONNULL_END
