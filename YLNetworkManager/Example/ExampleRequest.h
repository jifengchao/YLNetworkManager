//
//  ExampleRequest.h
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import "YBBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

//#import <MJExtension.h>
//
///** 可根据实际服务器接口返回数据进行调整*/
//@interface HttpResponseObject : NSObject
//
///** 错误码 */
//@property (nonatomic, strong) NSString *code;
//
///** 错误信息 */
//@property (nonatomic, copy) NSString *message;
//
///** 返回具体结果 */
//@property (nonatomic, strong) id data;
//
///** 服务器时间戳*/
//@property (nonatomic, assign) long long timestamp;
//
///** 是否请求成功*/
//@property (nonatomic, assign) BOOL success;
//
//+ (HttpResponseObject *)createDataWithResp:(id)resp;
//+ (HttpResponseObject *)createErrorDataWithError:(NSError *)error;
//
//@end
//
//typedef void(^HttpRespComp)(HttpResponseObject *respObj);
///**
// *  BaseComWithResponse
// *
// *  @param success 结果
// *  @param msg     信息文案
// *  @param data    数据
// */
//typedef void (^BaseComWithResponse)(BOOL success , NSString *msg, id data);
//
///**
// *  BaseComWithoutRes
// *
// *  @param success 结果
// *  @param msg     信息文案
// */
//typedef void (^BaseComWithoutRes)(BOOL success , NSString *msg);
//
///**
// *  BaseComWithHttpRes
// */
//typedef void (^BaseComWithHttpRes)(HttpResponseObject *httpRes);
//
///**
// BaseComWithResAndPage
//
// @param success    结果
// @param msg        信息文案
// @param data       数据
// @param noMoreData   是否有下一个数据（分页请求使用）
// */
//typedef void (^BaseComWithResAndPage)(BOOL success , NSString *msg, id data, BOOL noMoreData);


@interface ExampleRequest : YBBaseRequest

/** loading菊花显示的view*/
@property(nonatomic, weak, nullable) UIView *loadingView;
/** 是否统一展示请求错误时信息 默认YES*/
@property(nonatomic, assign) BOOL showRequestError;
/** 自定义请求头*/
@property (nonatomic, strong) NSDictionary *headers;

/** 如果是组请求统一回调 设置该属性**/
- (BOOL)isSuccessData:(YBNetworkResponse * _Nonnull)response;
- (BOOL)checkDataFormat:(YBNetworkResponse * _Nonnull)response;
- (void)openCache;

/** 接口请求*/
//- (NSString *)requestByMethod:(YBRequestMethod)method url:(NSString *)url parameters:(NSDictionary *)parameters headers:(nullable NSDictionary <NSString *, NSString *> *)headers completion:(HttpRespComp)comp;

@end

NS_ASSUME_NONNULL_END
