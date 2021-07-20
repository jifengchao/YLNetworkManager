//
//  YBBaseRequest.m
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import "YBBaseRequest.h"

#import "YBBaseRequest+Internal.h"
#import "YBNetworkCache+Internal.h"
#import <pthread/pthread.h>
#import "YBRequestTask.h"
#define YBN_IDECORD_LOCK(...) \
pthread_mutex_lock(&self->_lock); \
__VA_ARGS__ \
pthread_mutex_unlock(&self->_lock);

@interface YBBaseRequest ()

@property (nonatomic, strong) YBNetworkCache *cacheHandler;
/** 记录网络任务标识容器,只做增,则记录每一个请求task,并返回唯一的id
 因为manager的cancelAllNetworking会主动删除taskRecords,如果与请求中的records同步就要调用每个记录的taskid对应的request,耦合性太大
 **/
@property (nonatomic, strong) NSMutableSet<NSString *> *taskIDRecord;

@property (nonatomic, strong) YBNetworkResponse *response;

@end

@implementation YBBaseRequest {
    pthread_mutex_t _lock;
}

#pragma mark - life cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        self.releaseStrategy = YBNetworkReleaseStrategyHoldRequest;
        self.repeatStrategy = YBNetworkRepeatStrategyCancelNewest;
        self.serialization = YBRequestFormData;
        self.taskIDRecord = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"===========Request dealloc %@-%@", [self requestMethodString], [self requestURLString]);
    if (self.releaseStrategy == YBNetworkReleaseStrategyWhenRequestDealloc) {
        [self cancel];
    }
    pthread_mutex_destroy(&_lock);
}

#pragma mark - public

- (NSString *)startWithSuccess:(YBRequestSuccessBlock)success failure:(YBRequestFailureBlock)failure {
    return  [self startWithUploadProgress:nil downloadProgress:nil cache:nil success:success failure:failure];
}

- (NSString *)startWithCache:(YBRequestCacheBlock)cache success:(YBRequestSuccessBlock)success failure:(YBRequestFailureBlock)failure {
    return  [self startWithUploadProgress:nil downloadProgress:nil cache:cache success:success failure:failure];
}

- (NSString *)startWithUploadProgress:(nullable YBRequestProgressBlock)uploadProgress
                     downloadProgress:(nullable YBRequestProgressBlock)downloadProgress
                                cache:(nullable YBRequestCacheBlock)cache
                              success:(nullable YBRequestSuccessBlock)success
                              failure:(nullable YBRequestFailureBlock)failure {
        self.uploadProgress = uploadProgress;
        self.downloadProgress = downloadProgress;
        self.cacheBlock = cache;
        self.successBlock = success;
        self.failureBlock = failure;
        return [self start];
}

- (NSString *)requestByMethod:(YBRequestMethod)method url:(NSString *)url parameters:(NSDictionary *)parameters headers:(NSDictionary<NSString *,NSString *> *)headers success:(YBRequestSuccessBlock)success failure:(YBRequestFailureBlock)failure {
    self.requestMethod = method;
    self.requestParameter = parameters;
    self.requestURI = url;
    return [self startWithUploadProgress:nil downloadProgress:nil cache:nil success:success failure:failure];
}

- (NSString *)start {
    if (self.isExecuting) {
        switch (self.repeatStrategy) {
            case YBNetworkRepeatStrategyCancelNewest:
            {
                NSLog(@"===========Request cancel reason:RepeatCancelNewest %@-%@\n===========Request Parameters %@", [self requestMethodString], [self requestURLString],self.requestParameter);
                return @"";
            }
            case YBNetworkRepeatStrategyCancelOldest: {
                [self cancelNetWorking];
            }
                break;
            default: break;
        }
    }
    if ([self respondsToSelector:@selector(startProcessRequest)]) {
        [self startProcessRequest];
    }
    NSString *taskId=[self addRequestTask];
    NSLog(@"===========Request start %@-%@\n===========Request Parameters %@", [self requestMethodString], [self requestURLString],self.requestParameter);
    NSString *cacheKey = [self requestCacheKey];
    if (self.cacheHandler.readMode == YBNetworkCacheReadModeNone) {
        [self startWithCacheKey:cacheKey taskId:taskId];
        return taskId;
    }
    [self.cacheHandler objectForKey:cacheKey  isAsyn:YES withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull object) {
        BOOL contains = [[YBNetworkManager sharedManager] isContainTaskIdSet:[NSSet setWithObject:taskId]];
        void(^cancelBack)(void) = ^(){
            [self requestCompletionWithResponse: [YBNetworkResponse responseWithSessionTask:nil responseObject:nil error:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil]] cacheKey:cacheKey fromCache:NO taskId:taskId];
        };
        if (!contains) {
            cancelBack();//手动返回取消请求结果
            return;
        }
        if (object) { //缓存命中
            YBNetworkResponse *response = [YBNetworkResponse responseWithSessionTask:nil responseObject:object error:nil];
            [self successWithResponse:response cacheKey:cacheKey fromCache:YES];
        }
        
        BOOL needRequestNetwork = !object || self.cacheHandler.readMode == YBNetworkCacheReadModeAlsoNetwork;
        if (needRequestNetwork) {
            //缓存命中仍然发起请求或者没读取成功缓存才请求
            [self startWithCacheKey:cacheKey taskId:taskId];
        } else {
            cancelBack();//手动返回取消请求结果
        }
    }];
    return taskId;
}

- (void)cancelNetWorking {
    YBN_IDECORD_LOCK(
                     NSSet *removeSet = self.taskIDRecord.mutableCopy;
                     )
    [[YBNetworkManager sharedManager] cancelNetworkingWithSet:removeSet];
}

- (void)cancel {
    //此处取消顺序很重要
    [self cancelNetWorking];
}

//这是请求结束后清理taskId和回调block,中止循环引用
- (void)cancelTaskId:(NSString *)taskId {
    NSSet *removeSet = [NSSet setWithObject:taskId];
    [[YBNetworkManager sharedManager] cancelNetworkingWithSet:removeSet];
    [self clearRequestBlocks];
}

- (BOOL)isExecuting {
    YBN_IDECORD_LOCK(
                     NSSet *taskIdSet = self.taskIDRecord.mutableCopy;
                     )
    BOOL isExecuting = [[YBNetworkManager sharedManager] isContainTaskIdSet:taskIdSet];
    //    NSLog(@"===========Request isExecuting \n===========%@:%@", [self requestURLString],isExecuting?@"YES":@"NO");
    return isExecuting;
}

#pragma mark - request

- (void)startWithCacheKey:(NSString *)cacheKey taskId:(NSString *)taskId{
    if (self.releaseStrategy == YBNetworkReleaseStrategyHoldRequest) {
        //使用self持有request,请求block完成后释放block中的self临时变量,从而实现网络任务完成 YBBaseRequest 实例才会释放
        [[YBNetworkManager sharedManager] startNetworkingWithRequest:self uploadProgress:^(NSProgress * _Nonnull progress) {
            BOOL contains = [[YBNetworkManager sharedManager] isContainTaskIdSet:[NSSet setWithObject:taskId]];
            if (!contains) {
                return;
            }
            [self requestUploadProgress:progress];
        } downloadProgress:^(NSProgress * _Nonnull progress) {
            BOOL contains = [[YBNetworkManager sharedManager] isContainTaskIdSet:[NSSet setWithObject:taskId]];
            if (!contains) {
                return;
            }
            [self requestDownloadProgress:progress];
        } completion:^(YBNetworkResponse * _Nonnull response) {
            BOOL contains = [[YBNetworkManager sharedManager] isContainTaskIdSet:[NSSet setWithObject:taskId]];
            if (!contains) {
                response.error=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            }
            [self requestCompletionWithResponse:response cacheKey:cacheKey fromCache:NO taskId:taskId];
        } taskId:taskId];
    } else {
        //使用weakself不持有当前request实例
        __weak typeof(self) weakSelf = self;
        [[YBNetworkManager sharedManager] startNetworkingWithRequest:weakSelf uploadProgress:^(NSProgress * _Nonnull progress) {
            __strong typeof(weakSelf) self = weakSelf;//__strong是因为防止在多线程中block执行中self被释放
            if (!self) return;
            BOOL contains = [[YBNetworkManager sharedManager] isContainTaskIdSet:[NSSet setWithObject:taskId]];
            if (!contains) {
                return;
            }
            [self requestUploadProgress:progress];
        } downloadProgress:^(NSProgress * _Nonnull progress) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            BOOL contains = [[YBNetworkManager sharedManager] isContainTaskIdSet:[NSSet setWithObject:taskId]];
            if (!contains) {
                return;
            }
            [self requestDownloadProgress:progress];
        } completion:^(YBNetworkResponse * _Nonnull response) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) return;
            BOOL contains = [[YBNetworkManager sharedManager] isContainTaskIdSet:[NSSet setWithObject:taskId]];
            if (!contains) {
                response.error=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
            }
            [self requestCompletionWithResponse:response cacheKey:cacheKey fromCache:NO taskId:taskId];
        } taskId:taskId];
    }
}

#pragma mark - response

- (void)requestUploadProgress:(NSProgress *)progress {
    YBNETWORK_MAIN_QUEUE_ASYNC(^{
        if ([self.delegate respondsToSelector:@selector(request:uploadProgress:)]) {
            [self.delegate request:self uploadProgress:progress];
        }
        if (self.uploadProgress) {
            self.uploadProgress(progress);
        }
    })
}

- (void)requestDownloadProgress:(NSProgress *)progress {
    YBNETWORK_MAIN_QUEUE_ASYNC(^{
        if ([self.delegate respondsToSelector:@selector(request:downloadProgress:)]) {
            [self.delegate request:self downloadProgress:progress];
        }
        if (self.downloadProgress) {
            self.downloadProgress(progress);
        }
    })
}

- (void)requestCompletionWithResponse:(YBNetworkResponse *)response cacheKey:(NSString *)cacheKey fromCache:(BOOL)fromCache taskId:(NSString *)taskId {
    self.response=response;//允许重复网络请求返回response会覆盖
    if (response.error) {
        NSLog(@"===========request failed %@-%@\n===========response error=%@", [self requestMethodString], [self requestURLString],response.error);
        [self failureWithResponse:response];
    } else {
        NSLog(@"===========request successed %@-%@\n===========response data=%@", [self requestMethodString], [self requestURLString],response.responseObject);
        [self successWithResponse:response cacheKey:cacheKey fromCache:fromCache];
    }
    if ([self respondsToSelector:@selector(endProcessRequest)]) {
        [self endProcessRequest];
    }
    if (nil != taskId) {
        [self cancelTaskId:taskId];
    }
}

//主线程处理
- (void)successWithResponse:(YBNetworkResponse *)response cacheKey:(NSString *)cacheKey fromCache:(BOOL)fromCache {
    @try {
        BOOL shouldCache = ((self.cacheHandler.shouldCacheBlock&&self.cacheHandler.shouldCacheBlock(response))||!self.cacheHandler.shouldCacheBlock) &&(self.cacheHandler.writeMode!=YBNetworkCacheWriteModeNone);
        
        BOOL isSendFile = self.requestConstructingBody ||![self __isStringEmpty:self.downloadPath];
        if (!fromCache && !isSendFile && shouldCache) {
            NSLog(@"===========cache data %@-%@", [self requestMethodString], [self requestURLString]);
            [self.cacheHandler setObject:response.responseObject forKey:cacheKey isAsyn:YES];//yycache保证读写安全,异步
        }
        
        if (fromCache) {
            if ([self.delegate respondsToSelector:@selector(request:cacheWithResponse:)]) {
                NSLog(@"===========data from cache %@-%@\n===========cache data=%@", [self requestMethodString], [self requestURLString],response.responseObject);
                [self.delegate request:self cacheWithResponse:response];
            }
            if (self.cacheBlock) {
                self.cacheBlock(response);
            }
            if (self.successBlock) {
                self.successBlock(response);
            }
        } else {
            if ([self respondsToSelector:@selector(yb_preprocessSuccessInMainThreadWithResponse:)]) {
                [self yb_preprocessSuccessInMainThreadWithResponse:response];
            }
            if ([self.delegate respondsToSelector:@selector(request:successWithResponse:)]) {
                [self.delegate request:self successWithResponse:response];
            }
            if (self.successBlock) {
                self.successBlock(response);
            }
        }
    } @catch (NSException *exception) {
        if (self.exceptionBlock) {
            self.exceptionBlock(exception);
        }
    } @finally {
    }
    
}

//主线程处理
- (void)failureWithResponse:(YBNetworkResponse *)response {
    @try {
        if ([self respondsToSelector:@selector(yb_preprocessFailureInMainThreadWithResponse:)]) {
            [self yb_preprocessFailureInMainThreadWithResponse:response];
        }
        
        if ([self.delegate respondsToSelector:@selector(request:failureWithResponse:)]) {
            [self.delegate request:self failureWithResponse:response];
        }
        if (self.failureBlock) {
            self.failureBlock(response);
        }
    } @catch (NSException *exception) {
        if (self.exceptionBlock) {
            self.exceptionBlock(exception);
        }
    } @finally {
    }
}

#pragma mark - private

- (void)clearRequestBlocks {
    if (![self isExecuting]) {
        self.uploadProgress = nil;
        self.downloadProgress = nil;
        self.cacheBlock = nil;
        self.successBlock = nil;
        self.failureBlock = nil;
    }
}

- (NSString *)requestIdentifier {
    NSString *identifier = [NSString stringWithFormat:@"%@-%@%@", [self requestMethodString], [self requestURLString], [self stringFromParameter:self.requestParameter]];
    return identifier;
}

- (NSString *)requestCacheKey {
    NSString *cacheKey = [NSString stringWithFormat:@"%@%@", self.cacheHandler.extraCacheKey, [self requestIdentifier]];
    if (self.cacheHandler.customCacheKeyBlock) {
        cacheKey = self.cacheHandler.customCacheKeyBlock(cacheKey);
    }
    return cacheKey;
}

- (NSString *)stringFromParameter:(NSDictionary *)parameter {
    NSMutableString *string = [NSMutableString string];
    NSArray *allKeys = [parameter.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[NSString stringWithFormat:@"%@", obj1] compare:[NSString stringWithFormat:@"%@", obj2] options:NSLiteralSearch];
    }];
    for (id key in allKeys) {
        [string appendString:[NSString stringWithFormat:@"%@%@=%@", string.length > 0 ? @"&" : @"?", key, parameter[key]]];
    }
    return string;
}

- (NSString *)addRequestTask {
    YBRequestTask *task = [[YBRequestTask alloc]init];
    task.requestUrl = self.requestURI;
    NSString *taskId = [[YBNetworkManager sharedManager] addRequestTask:task];
    YBN_IDECORD_LOCK([self.taskIDRecord addObject:taskId];)//请求开始
    return taskId;
}

- (NSString *)requestMethodString {
    switch (self.requestMethod) {
        case YBRequestMethodGET: return @"GET";
        case YBRequestMethodPOST: return @"POST";
        case YBRequestMethodPUT: return @"PUT";
        case YBRequestMethodDELETE: return @"DELETE";
        case YBRequestMethodHEAD: return @"HEAD";
        case YBRequestMethodPATCH: return @"PATCH";
    }
}

- (NSString *)requestURLString {
    NSURL *baseURL = [NSURL URLWithString:self.baseURI];
    NSString *URLString = [NSString stringWithFormat:@"%@%@", baseURL, self.requestURI];
    return URLString;
}

- (void)requestCache:(nonnull void (^)(NSString * _Nonnull, id<NSCoding> _Nullable))block isAsyn:(BOOL)isAsyn {
    [self.cacheHandler objectForKey:[self requestCacheKey]  isAsyn:isAsyn withBlock:block];
}

- (void)removeCache {
    [self.cacheHandler removeCacheforKey:[self requestCacheKey]];
}

#pragma mark - getter

- (YBNetworkCache *)cacheHandler {
    if (!_cacheHandler) {
        _cacheHandler = [YBNetworkCache new];
    }
    return _cacheHandler;
}

- (BOOL)__isStringEmpty:(NSString * _Nullable)value {
    BOOL result = NO;
    if (!value || [value isKindOfClass:[NSNull class]] ||[value isEqualToString:@"null"] ||[value isEqualToString:@"(null)"] ||[value isEqualToString:@"nil"] ||[value isEqualToString:@"<null>"]) {
        result = YES;
    } else {
        NSString *trimedString = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([value isKindOfClass:[NSString class]] && [trimedString length] == 0) {
            result = YES;
        }
    }
    return result;
}

@end

