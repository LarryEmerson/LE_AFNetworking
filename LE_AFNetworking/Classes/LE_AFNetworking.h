//
//  LE_AFNetworking.h
//  ticket
//
//  Created by emerson larry on 15/11/12.
//  Copyright © 2015年 360cbs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <AFNetworking/AFURLResponseSerialization.h>
#import "LE_AFNetworking.h"
#import "LE_DataManager.h"
#import <Foundation/NSURLRequest.h>
#import <LEFoundation/LEFoundation.h>
#define mark Attention 注意
//  leSetServerHost 用于设置全局服务器地址
//  leMd5Salt leMd5加密需要的
//  是否开启debug：
//  enableDebug 全局debug
//  enableResponseDebug 回调数据debug
//  enableResponseWithJsonString 回调数据是否包含JSon字符串

//=======================Duration======================
#define LENetworkDuration       0
#define LENetworkDuration_2s    2
#define LENetworkDuration_5s    5
#define LENetworkDuration_10s   10
#define LENetworkDuration_20s   20
#define LENetworkDuration_30s   30
#define LENetworkDuration_45s   45
#define LENetworkDuration_1m    10
#define LENetworkDuration_5m    60*5
#define LENetworkDuration_10m   60*10
#define LENetworkDuration_30m   60*30
#define LENetworkDuration_1h    60*60
#define LENetworkDuration_3h    60*60*3
#define LENetworkDuration_5h    60*60*5
#define LENetworkDuration_12h   60*60*12
#define LENetworkDuration_24h   60*60*24

typedef NS_ENUM(NSInteger, LERequestType) {
    LERequestTypeGet      = 0,
    LERequestTypePost     = 1,
    LERequestTypeHead     = 2,
    LERequestTypePut      = 3,
    LERequestTypePatch    = 4,
    LERequestTypeDelete   = 5
};
#define LECacheTable                @"caches"
#define LECacheKey                  @"cachekey"
#define LECacheValue                @"cachevalue"

#define LEKeyOfResponseCount        @"Count"
#define LEKeyOfResponseStatusCode   @"statuscode"
#define LEKeyOfResponseErrormsg     @"errormsg"
#define LEKeyOfResponseErrorno      @"errorno"
#define LEKeyOfResponseArray        @"arraycontent"
#define LEKeyOfResponseAsJSON       @"LEKeyOfResponseAsJSON"
#define LEStatusCode200             200 

@class LE_AFNetworkingRequestObject;
@protocol LE_AFNetworkingDelegate <NSObject>
@optional
- (void) leRequest:(LE_AFNetworkingRequestObject *) request ResponedWith:(NSDictionary *) response; 
- (void) leRequest:(LE_AFNetworkingRequestObject *) request FailedWithStatusCode:(int) statusCode Message:(NSString *)message;
@end

@interface LE_AFNetworkingSettings : NSObject
@property (nonatomic, readonly) int               leRequestCounter;
@property (nonatomic, readonly) NSString          *leApi;
@property (nonatomic, readonly) NSString          *leUri;
@property (nonatomic, readonly) NSDictionary      *leHttpHead;
@property (nonatomic, readonly) LERequestType     leRequestType;
@property (nonatomic, readonly) id                leParameter;
@property (nonatomic, readonly) BOOL              leUseCache;
@property (nonatomic, readonly) int               leDuration;
@property (nonatomic, readonly) NSString          *leIdentification;//用于给请求加标签
@property (nonatomic, readonly) int               leCreateTimestamp;
@property (nonatomic) NSMutableArray    *leCurDelegateArray;
//
@property (nonatomic) id                leExtraObj;
//
-(void) leSetRequestCount:(int) requestCount;
-(void) leSetApi:(NSString *) api;
-(void) leSetUri:(NSString *) uri;
-(void) leSetHttpHead:(NSDictionary *) httpHead;
-(void) leSetRequestType:(LERequestType) requestType;
-(void) leSetParameter:(id) parameter;
-(void) leSetUseCache:(BOOL) useCache;
-(void) leSetDuration:(int) duration;
-(void) leSetIdentification:(NSString *) identification;
-(void) leSetCreateTimeStamp:(int) createTimestamp;
-(void) leSetDelegateArray:(NSMutableArray *) delegateArray;
-(void) leSetExtraObj:(id) extraObj;
//
- (id) initWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate;
- (id) initWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification;
- (NSString *)  leGetURL;
- (NSString *)  leGetKey;
- (NSString *)  leGetRequestType;
+ (NSString *)  leGetKeyWithApi:(NSString *) api uri:(NSString *) uri parameter:(id) parameter;
- (void)        leAddUniqueDelegate:(id<LE_AFNetworkingDelegate>) delegate;
@end

@interface LE_AFNetworkingRequestObject : NSObject
@property (nonatomic) LE_AFNetworkingSettings               *leAfnetworkingSettings;
- (id)      initWithSettings:(LE_AFNetworkingSettings *)    settings;
- (void)    leExecRequest:(BOOL)                            requestOrNot;
@end 

@interface LE_AFNetworking : NSObject{
    NSString *serverHost;
}
#pragma mark settings b4 using LE_Afnetwoking
//SET
- (void)         leSetEnableDebug:(BOOL) enable;
- (void)         leSetEnableResponseDebug:(BOOL) enable;
- (void)         leSetEnableResponseWithJsonString:(BOOL) enable;
- (void)         leSetServerHost:(NSString *) host;
- (void)         leSetMD5Salt:(NSString *) salt;
- (void)         leSetMessageDelegate:(id<LEAppMessageDelegate>) delegate;
- (void)         leOnShowAppMessageWith:(NSString *) message;
- (void)         leSetContentType:(NSSet *) type;
- (void)         leSetStatusCode:(NSIndexSet *) status;
//GET
- (BOOL)         leEnableDebug;
- (BOOL)         leEnableResponseDebug;
- (BOOL)         leEnableResponseWithJsonString;
- (NSIndexSet *) leStatusCode;
- (NSSet *)      leContentType;
- (NSString *)   leMd5Salt;
- (NSString *)   leGetServerHost;

+ (instancetype) sharedInstance;
//
- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter delegate:(id<LE_AFNetworkingDelegate>)delegate;
- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification;
- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate;
- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification;
- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate  AutoRequest:(BOOL) autoRequest;
- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate  AutoRequest:(BOOL) autoRequest Identification:(NSString *) identification;
//
- (NSDictionary *)  leGetLocalCacheWithApi:(NSString *) api uri:(NSString *) uri parameter:(id) parameter;
- (void)            leSave:(NSString *) value WithKey:(NSString *) key;
- (NSString *)      leGetValueWithKey:(NSString *) key;
+ (NSString *)      leMd5:(NSString *) str;
- (void)            leRemoveDelegate:(id) delegate;
- (void)            leRemoveDelegateWithKey:(NSString *) key Value:(id) value;
+ (int)             leGetTimeStamp ;
+ (NSString *)      leJSONStringWithObject:(NSObject *) obj;
//字典对象转为实体对象
+ (void)            leDictionaryToEntity:(NSDictionary *)dict entity:(NSObject*)entity;
//实体对象转为字典对象
+ (NSDictionary *)  leEntityToDictionary:(id)entity;
@end
