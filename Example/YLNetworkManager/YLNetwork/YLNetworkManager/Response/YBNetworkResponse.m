//
//  YBNetworkResponse.m
//  YLNetworkManager
//
//  Created by YL on 2020/1/1.
//

#import "YBNetworkResponse.h"

@implementation YBNetworkResponse

#pragma mark - life cycle

+ (instancetype)responseWithSessionTask:(NSURLSessionTask *)sessionTask responseObject:(id)responseObject error:(NSError *)error {
    YBNetworkResponse *response = [YBNetworkResponse new];
    response->_sessionTask = sessionTask;
    response->_responseObject = responseObject;
    if (error) {
        response->_error = error;
        YBResponseErrorType errorType;
        switch (error.code) {
            case NSURLErrorTimedOut:
                errorType = YBResponseErrorTypeTimedOut;
                break;
            case NSURLErrorCancelled:
                errorType = YBResponseErrorTypeCancelled;
                break;
            case NSURLErrorNotConnectedToInternet:
                errorType =YBResponseErrorTypeNoNetwork;
                break;
            case NSURLErrorUserCancelledAuthentication:
                errorType =YBResponseErrorCancelNetworkPermissions;
                break;
            case NSURLErrorUserAuthenticationRequired:
                errorType =YBResponseErrorNoNetworkPermissions;
                break;
            default:
                errorType = YBResponseErrorTypeOther;
                break;
        }
        response->_errorType = errorType;
    }
    return response;
}

#pragma mark - getter

- (NSHTTPURLResponse *)URLResponse {
    if (!self.sessionTask || ![self.sessionTask.response isKindOfClass:NSHTTPURLResponse.class]) {
        return nil;
    }
    return (NSHTTPURLResponse *)self.sessionTask.response;
}

@end
