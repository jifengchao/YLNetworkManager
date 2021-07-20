//
//  YBBatchReqManager.h
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import <Foundation/Foundation.h>

@class  YBBatchRequest;
NS_ASSUME_NONNULL_BEGIN

//用来持有batchRequest延长batchRequest的生命周期
@interface YBBatchReqManager : NSObject

///  Get the shared batch request agent.
+ (YBBatchReqManager *)sharedAgent;

///  Add a batch request.
- (void)addBatchRequest:(YBBatchRequest *)request;

///  Remove a previously added batch request.
- (void)removeBatchRequest:(YBBatchRequest *)request;

@end

NS_ASSUME_NONNULL_END
