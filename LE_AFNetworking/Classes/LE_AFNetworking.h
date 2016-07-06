//
//  LE_AFNetworking.h
//  ticket
//
//  Created by emerson larry on 15/11/12.
//  Copyright © 2015年 360cbs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"
#import "AFURLResponseSerialization.h"
//
#import "LE_AFNetworking.h"
#import "LE_DataManager.h"
// 
#import <Foundation/Foundation.h>
#import <Foundation/NSURLRequest.h>
#import "LEAppMessageDelegate.h"




#define mark Attention 注意
//  setServerHost 用于设置全局服务器地址
//  md5Salt md5加密需要的
//  是否开启debug：
//  enableDebug 全局debug
//  enableResponseDebug 回调数据debug
//  enableResponseWithJsonString 回调数据是否包含JSon字符串

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)
//=======================Duration======================
#define AFNetworkDuration       0
#define AFNetworkDuration_2s    2
#define AFNetworkDuration_5s    5
#define AFNetworkDuration_10s   10
#define AFNetworkDuration_20s   20
#define AFNetworkDuration_30s   30
#define AFNetworkDuration_45s   45
#define AFNetworkDuration_1m    10
#define AFNetworkDuration_5m    60*5
#define AFNetworkDuration_10m   60*10
#define AFNetworkDuration_30m   60*30
#define AFNetworkDuration_1h    60*60
#define AFNetworkDuration_3h    60*60*3
#define AFNetworkDuration_5h    60*60*5
#define AFNetworkDuration_12h   60*60*12
#define AFNetworkDuration_24h   60*60*24


#define NSLogFunc   fprintf(stderr,"=> FUNC: %s\n",__FUNCTION__);
#define NSLogObject(...) fprintf(stderr,"=> FUNC: %s %s\n",__FUNCTION__,[[NSString stringWithFormat:@"%@", ##__VA_ARGS__] UTF8String]);
#define NSLogInt(...) fprintf(stderr,"=> FUNC: %s %s\n",__FUNCTION__,[[NSString stringWithFormat:@"%d", ##__VA_ARGS__] UTF8String]);
#define NSLogStringAngInt(...) fprintf(stderr,"=> FUNC: %s %s\n",__FUNCTION__,[[NSString stringWithFormat:@"%@ : %d", ##__VA_ARGS__] UTF8String]);
#define NSLogTwoObjects(...) fprintf(stderr,"=> FUNC: %s %s\n",__FUNCTION__,[[NSString stringWithFormat:@"@@\n-->%@\n-->%@", ##__VA_ARGS__] UTF8String]);
#define NSLog(FORMAT, ...) fprintf(stderr,"=> (Line:%d) %s %s\n",__LINE__,__FUNCTION__,[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);


typedef NS_ENUM(NSInteger, RequestType) {
    RequestTypeGet      = 0,
    RequestTypePost     = 1,
    RequestTypeHead     = 2,
    RequestTypePut      = 3,
    RequestTypePatch    = 4,
    RequestTypeDelete   = 5
};
#define CacheTable  @"caches"
#define CacheKey    @"cachekey"
#define CacheValue  @"cachevalue"

#define KeyOfResponseCount @"Count"
#define KeyOfResponseStatusCode @"statuscode"
#define KeyOfResponseErrormsg   @"errormsg"
#define KeyOfResponseErrorno    @"errorno"
#define KeyOfResponseArray @"arraycontent"
#define KeyOfResponseAsJSON @"KeyOfResponseAsJSON"
#define StatusCode200 200
#define IntToString(num) [NSString stringWithFormat:@"%d", num]
#define NSNumberToString(num) [NSString stringWithFormat:@"%@", num]
@interface NSString (ExtensionAFN)
-(id)JSONValue;
-(NSString *)md5;
-(NSString *)md5WithSalt:(NSString *) salt;
-(NSString *)base64Encoder;
-(NSString *)base64Decoder;
@end
@interface NSObject (ExtensionAFN)
-(NSString*)ObjToJSONString;
@end  

@class LE_AFNetworkingRequestObject;
@protocol LE_AFNetworkingDelegate <NSObject>
@optional
- (void) request:(LE_AFNetworkingRequestObject *) request ResponedWith:(NSDictionary *) response; 
- (void) request:(LE_AFNetworkingRequestObject *) request FailedWithStatusCode:(int) statusCode Message:(NSString *)message;
@end

@interface LE_AFNetworkingSettings : NSObject
@property (nonatomic) int requestCounter;
@property (nonatomic) NSString *api;
@property (nonatomic) NSString *uri;
@property (nonatomic) NSDictionary *httpHead;
@property (nonatomic) RequestType requestType;
@property (nonatomic) id parameter;
@property (nonatomic) BOOL useCache;
@property (nonatomic) int duration;
@property (nonatomic) NSString *identification;//用于给请求加标签
@property (nonatomic) int createTimestamp;
@property (nonatomic) NSMutableArray *curDelegateArray;
- (id) initWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate;
- (id) initWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification;
- (NSString *) getURL;
- (NSString *) getKey;
- (NSString *) getRequestType;
+ (NSString *) getKeyWithApi:(NSString *) api uri:(NSString *) uri parameter:(id) parameter;
-(void) addUniqueDelegate:(id<LE_AFNetworkingDelegate>) delegate;
@property (nonatomic) id extraObj;
@end

@interface LE_AFNetworkingRequestObject : NSObject

@property (nonatomic) LE_AFNetworkingSettings *afnetworkingSettings;
- (id) initWithSettings:(LE_AFNetworkingSettings *) settings;
- (void) execRequest:(BOOL) requestOrNot;
@end 

@interface LE_AFNetworking : NSObject{
    NSString *serverHost;
}
#pragma mark settings b4 using LE_Afnetwoking
@property (nonatomic) BOOL enableDebug;
@property (nonatomic) BOOL enableResponseDebug;
@property (nonatomic) BOOL enableResponseWithJsonString;
@property (nonatomic) NSString *md5Salt;
-(void) setServerHost:(NSString *) host;
@property (nonatomic) id<LEAppMessageDelegate> messageDelegate;
+ (instancetype) sharedInstance;
-(NSString *) getServerHost;
-(void) onShowAppMessageWith:(NSString *) message;
- (LE_AFNetworkingRequestObject *) requestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter delegate:(id<LE_AFNetworkingDelegate>)delegate;
- (LE_AFNetworkingRequestObject *) requestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification;
- (LE_AFNetworkingRequestObject *) requestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate;
- (LE_AFNetworkingRequestObject *) requestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification;
- (LE_AFNetworkingRequestObject *) requestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate  AutoRequest:(BOOL) autoRequest;
- (LE_AFNetworkingRequestObject *) requestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate  AutoRequest:(BOOL) autoRequest Identification:(NSString *) identification;
- (NSDictionary *) getLocalCacheWithApi:(NSString *) api uri:(NSString *) uri parameter:(id) parameter;
- (void) save:(NSString *) value WithKey:(NSString *) key;
- (NSString *) getValueWithKey:(NSString *) key;
+ (NSString *) md5:(NSString *) str;
-(void) removeDelegateWithKey:(NSString *) key Value:(id) value;
+ (int)getTimeStamp ;
+ (NSString *) JSONStringWithObject:(NSObject *) obj;
//字典对象转为实体对象
+ (void) dictionaryToEntity:(NSDictionary *)dict entity:(NSObject*)entity;
//实体对象转为字典对象
+ (NSDictionary *) entityToDictionary:(id)entity;
@end