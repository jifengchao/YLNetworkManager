//
//  YBRequestTask.h
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YBRequestTask : NSObject

@property(nonatomic, strong) NSURLSessionTask *task;
@property(nonatomic,copy)NSString *requestUrl;
@property(nonatomic,copy)NSString *taskId;

@end

NS_ASSUME_NONNULL_END
