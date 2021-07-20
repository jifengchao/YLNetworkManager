//
//  ExampleRequest.m
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import "ExampleRequest.h"

#define kRequestFailureMessage @"网络开小差了"

#define YLResponseCodeSuccess        200
#define YLResponseCodeInvalidToken   10002

//@implementation HttpResponseObject
//
//+ (HttpResponseObject *)createDataWithResp:(id)resp {
//    // 可自行实现
////    HttpResponseObject *obj = [HttpResponseObject mj_objectWithKeyValues:resp];
//    HttpResponseObject *obj = [[HttpResponseObject alloc] init];
//    return obj;
//}
//
//+ (HttpResponseObject *)createErrorDataWithError:(NSError *)error {
//    HttpResponseObject *obj = [[HttpResponseObject alloc] init];
//    obj.success = NO;
////    obj.message = [error getErrorMessageWithCode:error];
//    obj.data = error;
//    return obj;
//}
//
//- (BOOL)success {
//    if (!self.code) return NO;
//    return [self.code integerValue] == YLResponseCodeSuccess;
//}
//
//@end



@implementation ExampleRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        self.baseURI = [self custom_baseURI];
        self.serialization = YBRequestFormData;
        self.requestTimeoutInterval = 10.0f;
        self.cacheHandler.extraCacheKey = [self custom_extraCacheKey];
        self.showRequestError = YES;
        self.cacheHandler.ageSeconds = 60*60*24*7;//7天
        self.releaseStrategy = YBNetworkReleaseStrategyWhenRequestDealloc;
        self.repeatStrategy = YBNetworkRepeatStrategyCancelNewest;
        __weak typeof(self) weakSelf = self;
        [self.cacheHandler setShouldCacheBlock:^BOOL(YBNetworkResponse * _Nonnull response) {
            __strong typeof(weakSelf) self = weakSelf;
            // 检查数据正确性，保证缓存有用的内容
            if ([self checkDataFormat:response] && [self isSuccessData:response]) {
                return YES;
            } else {
                return NO;
            }
        }];
    }
    return self;
}

#pragma mark - override

- (NSString *)yb_preprocessURLString:(NSString *)URLString {
    return URLString;
}

- (void)yb_preprocessFailureInMainThreadWithResponse:(YBNetworkResponse *)response {
    if (self.showRequestError) {
        if(response.errorType == YBResponseErrorTypeNoNetwork ||
           response.errorType == YBResponseErrorNoNetworkPermissions ||
           response.errorType == YBResponseErrorCancelNetworkPermissions) {
            [[self class] custom_showToast:@"请检查网络设置"];
        } else if (response.errorType == YBResponseErrorTypeTimedOut) {
            [[self class] custom_showToast:kRequestFailureMessage];
        } else if (response.errorType == YBResponseErrorTypeOther) {//其他异常
            [self netErrorRecord:response];
            [[self class] custom_showToast:kRequestFailureMessage];
        }
    }
}

- (BOOL)isSuccessData:(YBNetworkResponse * _Nonnull)response {
    if ([response.responseObject[@"code"]integerValue] == YLResponseCodeSuccess) {
        return YES;
    } else {
        return NO;
    }
}

- (void)openCache {
    self.cacheHandler.ageSeconds = 60*60*24*7;//7天
    self.cacheHandler.readMode = YBNetworkCacheReadModeAlsoNetwork;
    self.cacheHandler.writeMode = YBNetworkCacheWriteModeMemoryAndDisk;
}

#pragma mark 需根据项目自行设置的逻辑

+ (void)custom_showToast:(NSString *)message {
//    [UIView showToast:@"网络开小差了"];
}

- (NSString *)custom_baseURI {
    return @"";
//    return safeNullStr(Server_IP).length > 0 ? Server_IP: ServerIpDefault;
}

- (NSString *)custom_extraCacheKey {
    return @"";
//    return appCurrentVersion;
}

/** 添加统一的自定义的请求头*/
- (NSDictionary *)yb_requestCustomHeader {
    NSDictionary *normalHeader = @{
        @"Access-Token": @"==abcdefghigklmn=="
    };
//    NSDictionary *normalHeader = [AppMethod requestHeader];
    NSMutableDictionary *requestHeader = normalHeader ?[NSMutableDictionary dictionaryWithDictionary:normalHeader] :[NSMutableDictionary dictionary];
    if (self.headers &&
        self.headers.allKeys.count) { // 存在自定义header
        [requestHeader addEntriesFromDictionary:self.headers];
    }
    return requestHeader;
}

/** 可以对请求参数做特殊处理(比如统一添加某个参数等)*/
//- (NSDictionary *)yb_preprocessParameter:(NSDictionary *)parameter {
//    if (self.requestMethod == YBRequestMethodGET&&!self.requestConstructingBody) {
//        return [AppMethod processSignParameter:parameter];
//    } else {
//        return parameter;
//    }
//}

/** 可统一监听接口的请求(开始、结束)，做统一操作*/
//- (void)startProcessRequest {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if(self.loadingView) {
//            self.hud = [MBProgressHUD showHUDAddedTo:self.loadingView animated:YES];
//        }
//    });
//}
//
//- (void)endProcessRequest {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (self.hud) {
//            [self.hud hide];
//        }
//    });
//}

/** 可追踪请求失败并记录*/
- (void)netErrorRecord:(YBNetworkResponse *)response {
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    // ----------设置你想要的格式,hh与HH的区别:分别表示12小时制,24小时制
//    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
//    //现在时间,你可以输出来看下是什么格式
//    NSDate *datenow = [NSDate date];
//    //----------将nsdate按formatter格式转成nsstring
//    NSString *currentTimeString = [formatter stringFromDate:datenow];
//    NSString *error = [NSString stringWithFormat:@"%@",response.error];
//    error = (error.length == 0) ?@"": error;
    
//    [TalkingData trackEvent:@"网络异常" label:[NSString stringWithFormat:@"%@  %@",currentTimeString,response.URLResponse.URL.absoluteString] parameters:@{@"errorLog":error,@"用户网络":    [TheGlobalMethod networkCondition]}];
}

/** 数据监测，可根据服务器定义的返回参数自行调整*/
- (BOOL)checkDataFormat:(YBNetworkResponse * _Nonnull)response {
    id data = response.responseObject;
    if (!response.responseObject) {
        return NO;
    } else if (![response.responseObject isKindOfClass:[NSDictionary class]]) {
        return NO;
    } else if ([((NSDictionary *)data).allKeys containsObject:@"code"] &&
            [((NSDictionary *)data).allKeys containsObject:@"message"] &&
            [((NSDictionary *)data).allKeys containsObject:@"data"]) {
        return YES;
    } else {
        return NO;
    }
}

/** 请求正常，根据情况做自定义处理*/
- (void)yb_preprocessSuccessInMainThreadWithResponse:(YBNetworkResponse *)response {
    if (![self checkDataFormat:response]) {
        response.responseObject = @{
            @"code" :@(0),
            @"data" :@{},
            @"message" :@"服务器异常"
        };
    }
    id result = response.responseObject;
    @try {
        // 可追踪请求异常并记录
        if ([result[@"code"] integerValue] != 1) {
//            [TalkingData trackEvent:[NSString stringWithFormat:@"%@-%@",result[@"code"],result[@"message"]] label:self.requestURI parameters:self.requestParameter];
        }
    } @catch (NSException *exception) {
        // 可统一处理异常
//        [AppMethod errorLogCollect:exception];
    } @finally {
    }
    
    NSInteger result_code = [result[@"code"] integerValue];
    // 存在优先级
    if (result_code == YLResponseCodeInvalidToken) { // 单点登录
//        [AppMethod logout:result isHome:NO];
    }
    // else if ....
    else if (result_code != YLResponseCodeSuccess) { // 请求结果不正确
#ifdef DEBUG //开发环境
//        if (self.showRequestError) {
//          NSString *msg = [NSString stringWithFormat:@"Debug：%@", result[@"message"]];
//          [[self class] custom_showToast:msg];
//        }
#endif
        if (self.showRequestError) {
            [[self class] custom_showToast:kRequestFailureMessage];
        }
    }
    // else if ....
}

//- (NSString *)requestByMethod:(YBRequestMethod)method url:(NSString *)url parameters:(NSDictionary *)parameters headers:(nullable NSDictionary <NSString *, NSString *> *)headers completion:(HttpRespComp)comp {
//    // 打印信息
////    if (gUserInfoManager.gUserInfo.accessToken.length) {
////        NSLog(@"accessToken = %@", gUserInfoManager.gUserInfo.accessToken);
////    }
//
//    self.requestMethod = method;
//    self.requestParameter = parameters;
//    self.requestURI = url;
//    return [self startWithUploadProgress:^(NSProgress * _Nonnull progress) {
//
//    } downloadProgress:^(NSProgress * _Nonnull progress) {
//
//    } cache:^(YBNetworkResponse * _Nonnull response) {
//        if (comp) {
//            comp([HttpResponseObject createDataWithResp:response.responseObject]);
//        }
//    } success:^(YBNetworkResponse * _Nonnull response) {
//        if (comp) {
//            comp([HttpResponseObject createDataWithResp:response.responseObject]);
//        }
//    } failure:^(YBNetworkResponse * _Nonnull response) {
//        // todo 失败返回
//        if (comp) {
//            HttpResponseObject *resData = [[HttpResponseObject alloc] init];
//            resData.success = NO;
//            if (response.errorType == YBResponseErrorTypeTimedOut) { // 超时
//                resData.code = @(NSURLErrorTimedOut).stringValue;
//            }
//            comp(resData);
//        }
//    }];
//}

@end
