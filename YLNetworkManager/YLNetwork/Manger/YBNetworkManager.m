//
//  YBNetworkManager.m
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import "YBNetworkManager.h"
#import "YBBaseRequest+Internal.h"
#import <pthread/pthread.h>
#import "YBRequestTask.h"
#define YBNM_TASKRECORD_LOCK(...) \
pthread_mutex_lock(&self->_lock); \
__VA_ARGS__ \
pthread_mutex_unlock(&self->_lock);

@interface YBNetworkManager ()

@property(nonatomic,assign)NSUInteger numId;//自增数字id

@end

@implementation YBNetworkManager {
    pthread_mutex_t _lock;
}

#pragma mark - life cycle

- (void)dealloc {
    pthread_mutex_destroy(&_lock);
}

+ (instancetype)sharedManager {
    static YBNetworkManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YBNetworkManager alloc] initSpecially];
    });
    return manager;
}

- (instancetype)initSpecially {
    self = [super init];
    if (self) {
        self.numId=0;
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (void)startDownloadTaskWithManager:(AFHTTPSessionManager *)manager URLRequest:(NSURLRequest *)URLRequest downloadPath:(NSString *)downloadPath  downloadProgress:(nullable YBRequestProgressBlock)downloadProgress completion:(YBRequestCompletionBlock)completion taskId:(NSString *)taskId {
    
    // 保证下载路径是文件而不是目录
    NSString *validDownloadPath = downloadPath.copy;
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:validDownloadPath isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    if (isDirectory) {
        validDownloadPath = [NSString pathWithComponents:@[validDownloadPath, URLRequest.URL.lastPathComponent]];
    }
    
    // 若存在文件则移除
    if ([[NSFileManager defaultManager] fileExistsAtPath:validDownloadPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:validDownloadPath error:nil];
    }
    
    __block NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:URLRequest progress:downloadProgress destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:validDownloadPath isDirectory:NO];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        YBNM_TASKRECORD_LOCK([self.taskRecord removeObjectForKey:taskId];)
        if (completion) {
            completion([YBNetworkResponse responseWithSessionTask:task responseObject:filePath error:error]);
        }
    }];
    
    YBNM_TASKRECORD_LOCK(if (self.taskRecord[taskId]) {
                             self.taskRecord[taskId].task=task;
                         })
    [task resume];
}

- (void)startDataTaskWithManager:(AFHTTPSessionManager *)manager URLRequest:(NSURLRequest *)URLRequest uploadProgress:(nullable YBRequestProgressBlock)uploadProgress downloadProgress:(nullable YBRequestProgressBlock)downloadProgress completion:(YBRequestCompletionBlock)completion taskId:(NSString *)taskId {
    
    __block NSURLSessionDataTask *task = [manager dataTaskWithRequest:URLRequest uploadProgress:^(NSProgress * _Nonnull _uploadProgress) {
        if (uploadProgress) {
            uploadProgress(_uploadProgress);
        }
    } downloadProgress:^(NSProgress * _Nonnull _downloadProgress) {
        if (downloadProgress) {
            downloadProgress(_downloadProgress);
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (completion) {
            completion([YBNetworkResponse responseWithSessionTask:task responseObject:responseObject error:error]);
        }
    }];
   YBNM_TASKRECORD_LOCK(if (self.taskRecord[taskId])
     {
         self.taskRecord[taskId].task = task;
     })
    NSLog(@"taskid==%lu", (unsigned long)task.taskIdentifier);
    [task resume];
}

#pragma mark - public

- (NSString *)addRequestTask:(YBRequestTask *)task {
    YBNM_TASKRECORD_LOCK(
                         self.numId += 1;
                         NSString *identifier = [NSString stringWithFormat:@"%@-%lu", (task.requestUrl ?:@""), (unsigned long)self.numId];
                         self.taskRecord[identifier] = task;
                         NSLog(@"===========Request taskRecord %@ identifier:%@", self.taskRecord, identifier);
    )
    return identifier;
}

- (void)cancelNetworkingWithSet:(NSSet<NSString *> *)set {
    YBNM_TASKRECORD_LOCK(
        for (NSString *identifier in set) {
            YBRequestTask *task = self.taskRecord[identifier];//可能是已经被取消掉了的
            if (task&&task.task) {
                [task.task cancel];
            }
            [self.taskRecord removeObjectForKey:identifier];
        }
    )
}

- (void)cancelAllNetWorking {
    YBNM_TASKRECORD_LOCK(
          for (YBRequestTask *task in self.taskRecord.allValues) {
              if (task&&task.task) {
                  [task.task cancel];
              }
          }
         [self.taskRecord removeAllObjects];
        )
}

- (BOOL)isContainTaskIdSet:(NSSet<NSString *> *)set
{
    YBNM_TASKRECORD_LOCK(
                         BOOL isContain=[[NSSet setWithArray:self.taskRecord.allKeys] intersectsSet:set];
                         )
    return isContain;
}

- (void)startNetworkingWithRequest:(YBBaseRequest *)request uploadProgress:(nullable YBRequestProgressBlock)uploadProgress downloadProgress:(nullable YBRequestProgressBlock)downloadProgress completion:(nullable YBRequestCompletionBlock)completion taskId:(NSString *)taskId {
    
    // 构建网络请求数据
    NSString *method = [request requestMethodString];
    AFHTTPRequestSerializer *serializer = [self requestSerializerForRequest:request];
    NSString *URLString = [self URLStringForRequest:request];
    id parameter = [self parameterForRequest:request];
    
    // 构建 URLRequest
    NSError *error = nil;
    NSMutableURLRequest *URLRequest = nil;
    if (request.requestConstructingBody) {//上传文件
        URLRequest = [serializer multipartFormRequestWithMethod:@"POST" URLString:URLString parameters:parameter constructingBodyWithBlock:request.requestConstructingBody error:&error];
    } else {
        URLRequest = [serializer requestWithMethod:method URLString:URLString parameters:parameter error:&error];
    }
    
    if (error) {//构建请求失败
        if (completion) completion([YBNetworkResponse responseWithSessionTask:nil responseObject:nil error:error]);
    }
    
    // 发起网络请求
    AFHTTPSessionManager *manager = [self sessionManagerForRequest:request];
    if (request.downloadPath.length > 0) {
        return [self startDownloadTaskWithManager:manager URLRequest:URLRequest downloadPath:request.downloadPath downloadProgress:downloadProgress completion:completion taskId:taskId];
    } else {
        return [self startDataTaskWithManager:manager URLRequest:URLRequest uploadProgress:uploadProgress downloadProgress:downloadProgress completion:completion taskId:taskId];
    }
}

#pragma mark - read info from request

- (AFHTTPRequestSerializer *)requestSerializerForRequest:(YBBaseRequest *)request {
    AFHTTPRequestSerializer *serializer = [self requestSerializer:request];
    if (request.requestTimeoutInterval > 0) {//设置超时时间
        [serializer willChangeValueForKey:@"timeoutInterval"];
        serializer.timeoutInterval = request.requestTimeoutInterval;
        [serializer didChangeValueForKey:@"timeoutInterval"];
    }
    if ([request respondsToSelector:@selector(yb_requestCustomHeader)]) { //设置请求头
        if ([request yb_requestCustomHeader]) {
            NSDictionary *customHeader = [request yb_requestCustomHeader];
            for(NSString *key in customHeader.allKeys) {
                [serializer setValue:customHeader[key] forHTTPHeaderField:key];
            }
        }
    }
    return serializer;
}

- (NSString *)URLStringForRequest:(YBBaseRequest *)request {
    NSString *URLString = [request requestURLString];
    if ([request respondsToSelector:@selector(yb_preprocessURLString:)]) {
        URLString = [request yb_preprocessURLString:URLString];
    }
    return URLString;
}

- (id)parameterForRequest:(YBBaseRequest *)request {
    id parameter = request.requestParameter;
    if ([request respondsToSelector:@selector(yb_preprocessParameter:)]) {
        parameter = [request yb_preprocessParameter:parameter];
    }
    return parameter;
}

- (AFHTTPRequestSerializer *)requestSerializer:(YBBaseRequest *)request {
    AFHTTPRequestSerializer *serializer=[AFHTTPRequestSerializer serializer];
    switch (request.serialization) {
        case YBRequestFormData: {
            serializer = [AFHTTPRequestSerializer serializer];
            break;
        }
        case YBRequestApplicationJson: {
            serializer = [AFJSONRequestSerializer serializer];
            break;
        }
        default:
            break;
    }
    return serializer;
}

- (AFHTTPSessionManager *)sessionManagerForRequest:(YBBaseRequest *)request {
    AFHTTPSessionManager *manager = request.sessionManager;
    
    if (!manager) {
        static AFHTTPSessionManager *defaultManager = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            defaultManager = [AFHTTPSessionManager new];
            defaultManager.completionQueue = dispatch_get_main_queue();
            defaultManager.responseSerializer = self.responseSerializer?:[AFJSONResponseSerializer serializer];
            defaultManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain",@"text/html",@"text/css",@"multipart/form-data",nil];
        });
        manager = defaultManager;
    }
    
    return manager;
}

#pragma mark - getter

- (NSMutableDictionary<NSString *,YBRequestTask *> *)taskRecord {
    if (!_taskRecord) {
        _taskRecord = [NSMutableDictionary dictionary];
    }
    return _taskRecord;
}

@end
