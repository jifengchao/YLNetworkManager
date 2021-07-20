//
//  YBNetworkManager.h
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import <Foundation/Foundation.h>
#import "YBNetworkResponse.h"

@class YBRequestTask;

NS_ASSUME_NONNULL_BEGIN

typedef void(^YBRequestCompletionBlock)(YBNetworkResponse *response);

@interface YBNetworkManager : NSObject

/** 响应序列化器 (这是afnetworking解析的的属性,单例模式下只能全局改)*/
@property (nonatomic, strong) AFHTTPResponseSerializer *responseSerializer;

+ (instancetype)sharedManager;

- (void)startNetworkingWithRequest:(YBBaseRequest *)request
                    uploadProgress:(nullable YBRequestProgressBlock)uploadProgress
                  downloadProgress:(nullable YBRequestProgressBlock)downloadProgress
                        completion:(nullable YBRequestCompletionBlock)completion taskId:(NSString *)taskId;
- (NSString *)addRequestTask:(YBRequestTask *)task;//return unique string
-(BOOL)isContainTaskIdSet:(NSSet<NSString *> *)set;
- (void)cancelAllNetWorking;
- (void)cancelNetworkingWithSet:(NSSet<NSString *> *)set;//仅供内部使用
- (instancetype)init OBJC_UNAVAILABLE("use '+sharedManager' instead");
+ (instancetype)new OBJC_UNAVAILABLE("use '+sharedManager' instead");
@property (nonatomic, strong) NSMutableDictionary<NSString *, YBRequestTask *> *taskRecord;

@end

NS_ASSUME_NONNULL_END
