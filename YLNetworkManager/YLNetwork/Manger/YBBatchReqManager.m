//
//  YBBatchReqManager.m
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import "YBBatchReqManager.h"
#import "YBBatchRequest.h"

@interface YBBatchReqManager ()

@property (strong, nonatomic) NSMutableArray<YBBatchRequest *> *requestArray;

@end

@implementation YBBatchReqManager

+ (YBBatchReqManager *)sharedAgent {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _requestArray = [NSMutableArray array];
    }
    return self;
}

- (void)addBatchRequest:(YBBatchRequest *)request {
    @synchronized(self) {
        [_requestArray addObject:request];
    }
}

- (void)removeBatchRequest:(YBBatchRequest *)request {
    @synchronized(self) {
        [_requestArray removeObject:request];
    }
}

@end
