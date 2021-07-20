
//
//  YBBatchRequest.m
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import "YBBatchRequest.h"
#import "YBNetworkManager.h"
#import "YBBatchReqManager.h"

@interface YBBatchRequest() <YBResponseDelegate>

@property (nonatomic,assign) NSInteger startCount;

@end

@implementation YBBatchRequest

- (instancetype)initWithRequestArray:(NSArray<YBBaseRequest *> *)requestArray {
    self = [super init];
    if (self) {
        _requestArray = [requestArray copy];
        _startCount = 0;
        for (YBBaseRequest *req in _requestArray) {
            if (![req isKindOfClass:[YBBaseRequest class]]) {
                NSLog(@"Error, request item must be YBBaseRequest instance.");
                return nil;
            }
        }
    }
    return self;
}

- (void)start {
    if (self.startCount > 0) {
        NSLog(@"Error! Batch request has already started.");
        return;
    }
    NSLog(@"===========BatchRequest start");
    _failedRequest = nil;
    if (self.releaseStrategy == YBBatchReqReleaseHoldRequest) {
        [[YBBatchReqManager sharedAgent] addBatchRequest:self];
    }
    self.startCount = self.requestArray.count;
    for (YBBaseRequest *req in _requestArray) {
        req.delegate = self;
        [req start];
    }
}

- (void)stop {
    [self clearRequest];
}

- (void)startWithCompletionBlockWithSuccess:(void (^)(YBBatchRequest *batchRequest))success
                                    failure:(void (^)(YBBatchRequest *batchRequest))failure {
    [self setCompletionBlockWithSuccess:success failure:failure];
    [self start];
}

- (void)setCompletionBlockWithSuccess:(void (^)(YBBatchRequest *batchRequest))success
                              failure:(void (^)(YBBatchRequest *batchRequest))failure {
    self.successCompletionBlock = success;
    self.failureCompletionBlock = failure;
}

- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}

- (void)dealloc {
    if (self.releaseStrategy==YBBatchReqReleaseWhenRequestDealloc) {
        [self clearRequest];
    }
    NSLog(@"===========BatchRequest dealloc");
}

#pragma mark - Network Request Delegate

/// 请求成功
- (void)request:(__kindof YBBaseRequest *)request successWithResponse:(YBNetworkResponse *)response {
    if ([_delegate respondsToSelector:@selector(request:successWithResponse:)]) {
        [_delegate request:request successWithResponse:response];
    }
    self.startCount--;
    if (self.startCount == 0) {
        [self successBatchBlock];
    }
   
}

- (void)request:(__kindof YBBaseRequest *)request cacheWithResponse:(YBNetworkResponse *)response {
    if ([_delegate respondsToSelector:@selector(request:cacheWithResponse:)]) {
        [_delegate request:request cacheWithResponse:response];
    }
}

/// 请求失败
- (void)request:(__kindof YBBaseRequest *)request failureWithResponse:(YBNetworkResponse *)response {
    if ([_delegate respondsToSelector:@selector(request:failureWithResponse:)]) {
        [_delegate request:request failureWithResponse:response];
    }
    self.startCount--;
    if (self.requestStrategy == YBBatchRequestFailCancel) {//一个失败就整个失败
        _failedRequest = request;
        // Stop
        for (YBBaseRequest *req in _requestArray) {
            [req cancel];
        }
        if (self.startCount == 0) {
            // Callback
            if ([_delegate respondsToSelector:@selector(batchRequestFailed:)]) {
                [_delegate batchRequestFailed:self];
            }
            if (_failureCompletionBlock) {
                _failureCompletionBlock(self);
            }
            // Clear
            [self clearCompletionBlock];
            if (self.releaseStrategy == YBBatchReqReleaseHoldRequest) {
                [[YBBatchReqManager sharedAgent] removeBatchRequest:self];
            }
        }
     
    } else {
        if (self.startCount == 0) {
            [self successBatchBlock];
        }
    }
}

- (void)successBatchBlock {
    if ([_delegate respondsToSelector:@selector(batchRequestSuccessed:)]) {
        [_delegate batchRequestSuccessed:self];
    }
    if (_successCompletionBlock) {
        _successCompletionBlock(self);
    }
    [self clearCompletionBlock];
    if (self.releaseStrategy == YBBatchReqReleaseHoldRequest) {
        [[YBBatchReqManager sharedAgent] removeBatchRequest:self];
    }
}

- (void)clearRequest {
    for (YBBaseRequest * req in _requestArray) {
        [req cancel];//结束后会调用batch回调,自动回清除completion block,防止循环引用
    }
}

@end
