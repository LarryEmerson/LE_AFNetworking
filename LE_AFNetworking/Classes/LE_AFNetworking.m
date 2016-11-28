//
//  LE_AFNetworking.m
//  ticket
//
//  Created by emerson larry on 15/11/12.
//  Copyright © 2015年 360cbs. All rights reserved.
//

#import "LE_AFNetworking.h"
#import <objc/runtime.h>

@interface LE_AFNetworking ()
-(int) getNetworkCounter;
@end

@interface LE_AFNetworkingSettings ()
@property (nonatomic, readwrite) int               leRequestCounter;
@property (nonatomic, readwrite) NSString          *leApi;
@property (nonatomic, readwrite) NSString          *leUri;
@property (nonatomic, readwrite) NSDictionary      *leHttpHead;
@property (nonatomic, readwrite) LERequestType     leRequestType;
@property (nonatomic, readwrite) id                leParameter;
@property (nonatomic, readwrite) BOOL              leUseCache;
@property (nonatomic, readwrite) int               leDuration;
@property (nonatomic, readwrite) NSString          *leIdentification;//用于给请求加标签
@property (nonatomic, readwrite) int               leCreateTimestamp; 
@end
@implementation LE_AFNetworkingSettings
-(void) leSetRequestCount:(int) requestCount{
    self.leRequestCounter=requestCount;
}
-(void) leSetApi:(NSString *) api{
    self.leApi=api;
}
-(void) leSetUri:(NSString *) uri{
    self.leUri=uri;
}
-(void) leSetHttpHead:(NSDictionary *) httpHead{
    self.leHttpHead=httpHead;
}
-(void) leSetRequestType:(LERequestType) requestType{
    self.leRequestType=requestType;
}
-(void) leSetParameter:(id) parameter{
    self.leParameter=parameter;
}
-(void) leSetUseCache:(BOOL) useCache{
    self.leUseCache=useCache;
}
-(void) leSetDuration:(int) duration{
    self.leDuration=duration;
}
-(void) leSetIdentification:(NSString *) identification{
    self.leIdentification=identification;
}
-(void) leSetCreateTimeStamp:(int) createTimestamp{
    self.leCreateTimestamp=createTimestamp;
}
-(void) leSetDelegateArray:(NSMutableArray *) delegateArray{
    self.leCurDelegateArray=delegateArray;
}
-(void) leSetExtraObj:(id) extraObj{
    self.leExtraObj=extraObj;
}
//
- (id) initWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate{
    return [self initWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter useCache:useCache duration:duration delegate:delegate Identification:nil];
}
- (id) initWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification{
    self.leCurDelegateArray=[[NSMutableArray alloc] init];
    self=[super init];
    self.leApi=api;
    self.leUri=uri;
    self.leHttpHead=httpHead;
    self.leRequestType=requestType;
    self.leParameter=parameter;
    self.leUseCache=useCache;
    self.leDuration=duration;
    self.leIdentification=identification;
    self.leRequestCounter=[[LE_AFNetworking sharedInstance] getNetworkCounter];
    if(delegate){
        [self.leCurDelegateArray addObject:delegate];
    }
    return self;
}
-(void) leAddUniqueDelegate:(id<LE_AFNetworkingDelegate>) delegate{
    BOOL found=NO;
    for (id<LE_AFNetworkingDelegate> del in self.leCurDelegateArray) {
        if([del isEqual:delegate]){
            found=YES;
            break;
        }
    }
    if(!found){
        [self.leCurDelegateArray addObject:delegate];
    }
}
- (NSString *) leGetURL{
    return [NSString stringWithFormat:@"%@%@/%@",[[LE_AFNetworking sharedInstance] leGetServerHost],self.leApi,self.leUri];
}
- (NSString *) leGetKey{
    NSString *jsonString=@""; 
    if(self.leParameter&&![self.leParameter isKindOfClass:[NSString class]]){
        jsonString=[self.leParameter leObjToJSONString];
    } 
    return [[self leGetURL] stringByAppendingString:jsonString];
}
- (NSString *) leGetRequestType{
    return self.leRequestType==0?@"Get":(self.leRequestType==1?@"Post":(self.leRequestType==2?@"Head":(self.leRequestType==3?@"Put":(self.leRequestType==4?@"Patch":@"Delete"))));
}
+ (NSString *) leGetKeyWithApi:(NSString *) api uri:(NSString *) uri parameter:(id) parameter{
    return [[NSString stringWithFormat:@"%@%@/%@",[[LE_AFNetworking sharedInstance] leGetServerHost],api,uri] stringByAppendingString:parameter?[parameter leObjToJSONString]:@""];
}
@end

@implementation LE_AFNetworkingRequestObject{
    NSDictionary *responseObjectCache;
    AFHTTPSessionManager *manager;
}
- (id) initWithSettings:(LE_AFNetworkingSettings *) settings{
    if([LE_AFNetworking sharedInstance].leEnableDebug){
        LELogObject(@"===============================>");
        LELog(@"URL=%@",settings.leGetURL);
        LELog(@"Head=%@",settings.leHttpHead);
        LELog(@"Type=%@",settings.leGetRequestType);
        LELog(@"Param=%@",settings.leParameter);
    }
    self=[super init];
    self.leAfnetworkingSettings=settings;
    return self;
}
-(void) dealloc{ 
    [self.leAfnetworkingSettings.leCurDelegateArray removeAllObjects];
    self.leAfnetworkingSettings=nil;
    responseObjectCache=nil;
    manager=nil;
}
- (void) leExecRequest:(BOOL) requestOrNot{
    if(!requestOrNot){
        return;
    }
    LE_AFNetworkingSettings *settings=self.leAfnetworkingSettings;
    manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //
    [manager.responseSerializer setAcceptableStatusCodes:[[LE_AFNetworking sharedInstance] leStatusCode]];
    [manager.responseSerializer setAcceptableContentTypes:[[LE_AFNetworking sharedInstance] leContentType]];
    if(settings.leHttpHead&&settings.leHttpHead.count>0){//HTTPHEAD
        manager.requestSerializer=[AFJSONRequestSerializer serializer];
        for (NSString *key in settings.leHttpHead.allKeys) {
            [manager.requestSerializer setValue:[settings.leHttpHead objectForKey:key] forHTTPHeaderField:key];
        }
    }
    
    LE_AFNetworkingRequestObject *weakSelf=self;
    //    __weak typeof(self) weakSelf = self;
    switch (settings.leRequestType) {
        case 0://Get
        {
            [manager GET:settings.leGetURL parameters:settings.leParameter progress:^(NSProgress * _Nonnull downloadProgress) {
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf onRespondedWithRequest:task responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf onRespondedWithRequest:task responseObject:nil error:error];
            }];
        }
            break;
        case 1://Post
        {
            [manager POST:settings.leGetURL parameters:settings.leParameter progress:^(NSProgress * _Nonnull downloadProgress){
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf onRespondedWithRequest:task responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf onRespondedWithRequest:task responseObject:nil error:error];
            }];
        }
            break;
        case 2://Head
        {
            [manager HEAD:settings.leGetURL parameters:settings.leParameter success:^(NSURLSessionDataTask * _Nonnull task) {
                [weakSelf onRespondedWithRequest:task responseObject:task];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf onRespondedWithRequest:task responseObject:nil error:error];
            }];
        }
            break;
        case 3://Put
        {
            [manager PUT:settings.leGetURL parameters:settings.leParameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf onRespondedWithRequest:task responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf onRespondedWithRequest:task responseObject:nil error:error];
            }];
        }
            break;
        case 4://Patch
        {
            [manager PATCH:settings.leGetURL parameters:settings.leParameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [weakSelf onRespondedWithRequest:task responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [weakSelf onRespondedWithRequest:task responseObject:nil error:error];
            }];
            
        }
            break;
        case 5://Delete
        {
            [manager DELETE:settings.leGetURL parameters:settings.leParameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject){
                [weakSelf onRespondedWithRequest:task responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)  {
                [weakSelf onRespondedWithRequest:task responseObject:nil error:error];
            }];
        }
            break;
        default:
            break;
    }
}
- (void) onRespondedWithRequest:(NSURLSessionDataTask *) operation responseObject:(id) responseObject {
    [self onRespondedWithRequest:operation responseObject:responseObject error:nil];
    [manager invalidateSessionCancelingTasks:YES];
}
- (void) onRespondedWithRequest:(NSURLSessionDataTask *) operation responseObject:(id) responseObject error:(NSError *) error {
    if(error||!responseObject){
        if(error.code==-1001){
            [[LE_AFNetworking sharedInstance] leOnShowAppMessageWith:@"网络请求超时"];
        }
        //        else
        {
            if((self.leAfnetworkingSettings.leRequestType==LERequestTypeGet )){
                NSString *json=[[LE_DataManager sharedInstanceOfStorage] leGetDataWithTable:LECacheTable Key:self.leAfnetworkingSettings.leGetKey];
                if(json){
                    NSDictionary *response=[json leJSONValue];
                    responseObjectCache=response;
                    if(response&&self.leAfnetworkingSettings.leCurDelegateArray){
                        [self onRespondWithResponse:responseObjectCache];
                        //                        NSMutableArray *list=[[NSMutableArray alloc] init];
                        //                        for(int i=0;i<self.leAfnetworkingSettings.curDelegateArray.count;++i){
                        //                            id<LE_AFNetworkingDelegate> delegate=[self.leAfnetworkingSettings.curDelegateArray objectAtIndex:i];
                        //                            if(delegate){
                        //                                [list addObject:delegate];
                        //                                [delegate leRequest:self ResponedWith:response];
                        //                            }
                        //                        }
                        //                        [self.leAfnetworkingSettings setCurDelegateArray:list];
                    }
                }
            }else if(self.leAfnetworkingSettings.leRequestType==LERequestTypeHead){
                NSHTTPURLResponse *res = (NSHTTPURLResponse *)operation.response;
                id obj=[[res allHeaderFields] objectForKey:LEKeyOfResponseCount];
                if(self.leAfnetworkingSettings.leCurDelegateArray){
                    NSMutableDictionary *muta=[[NSMutableDictionary alloc] init];
                    if(obj){
                        [muta setObject:obj forKey:LEKeyOfResponseCount];
                    }else{
                        [muta setObject:@"0" forKey:LEKeyOfResponseCount];
                    }
                    responseObjectCache=muta;
                    [self onRespondWithResponse:responseObjectCache];
                    //                    NSMutableArray *list=[[NSMutableArray alloc] init];
                    //                    for(int i=0;i<self.leAfnetworkingSettings.curDelegateArray.count;++i){
                    //                        id<LE_AFNetworkingDelegate> delegate=[self.leAfnetworkingSettings.curDelegateArray objectAtIndex:i];
                    //                        if(delegate){
                    //                            [list addObject:delegate];
                    //                            [delegate leRequest:self ResponedWith:muta];
                    //                        }
                    //                    }
                    //                    [self.leAfnetworkingSettings setCurDelegateArray:list];
                }
            }
        }
        return;
    }
    NSMutableDictionary *response=[[NSMutableDictionary alloc] init];
    if(responseObject){//成功
        NSString *responseToJSONString=nil;
        if([responseObject respondsToSelector:@selector(length)]){
            NSInteger length=[responseObject length];
            if(length>0){
                responseToJSONString=[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            }
        }
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)operation.response;
        if([LE_AFNetworking sharedInstance].leEnableResponseDebug){
            LELogTwoObjects(self.leAfnetworkingSettings.leGetURL,responseToJSONString);
        }
        id dataToObj=nil;
        if(responseToJSONString){
            dataToObj= [responseToJSONString leJSONValue];
        }
        if([dataToObj isKindOfClass:[NSDictionary class]]){
            response =[dataToObj mutableCopy];
        }else if([dataToObj isKindOfClass:[NSArray class]]){ 
            [response setObject:dataToObj forKey:LEKeyOfResponseArray];
        }
        if(self.leAfnetworkingSettings.leRequestType==LERequestTypeHead){
            NSDictionary *header=[res allHeaderFields];
            if(header&&[header objectForKey:LEKeyOfResponseCount]){
                [response setObject:[header objectForKey:LEKeyOfResponseCount] forKey:LEKeyOfResponseCount];
            }
        }
        if([LE_AFNetworking sharedInstance].leEnableResponseWithJsonString){
            if(responseToJSONString){
                [response setObject:responseToJSONString forKey:LEKeyOfResponseAsJSON];
            }
            [response setObject:[self.leAfnetworkingSettings leGetKey] forKey:@"URL"];
        }
        [response setObject:[NSNumber numberWithInteger:[res statusCode]] forKey:LEKeyOfResponseStatusCode];
        if(response&&self.leAfnetworkingSettings.leCurDelegateArray){
            if((self.leAfnetworkingSettings.leRequestType==LERequestTypeGet||self.leAfnetworkingSettings.leRequestType==LERequestTypeHead)){
                NSString *json=[LE_AFNetworking leJSONStringWithObject:response];
                if(json){
                    [[LE_DataManager sharedInstanceOfStorage] leAddOrUpdateWithKey:self.leAfnetworkingSettings.leGetKey Value:json ToTable:LECacheTable];
                }
            }
            responseObjectCache=response;
            [self onRespondWithResponse:responseObjectCache];
            //            NSMutableArray *list=[[NSMutableArray alloc] init];
            //            for(int i=0;i<self.leAfnetworkingSettings.curDelegateArray.count;++i){
            //                id<LE_AFNetworkingDelegate> delegate=[self.leAfnetworkingSettings.curDelegateArray objectAtIndex:i];
            //                if(delegate){
            //                    [list addObject:delegate];
            //                    [delegate leRequest:self ResponedWith:response];
            //                }
            //            }
            //            [self.leAfnetworkingSettings setCurDelegateArray:list];
        }
    }
}
- (void) returnCachedResponse{
    if(responseObjectCache&&self.leAfnetworkingSettings.leCurDelegateArray){
        [self onRespondWithResponse:responseObjectCache];
        //        NSMutableArray *list=[[NSMutableArray alloc] init];
        //        for(int i=0;i<self.leAfnetworkingSettings.curDelegateArray.count;++i){
        //            id<LE_AFNetworkingDelegate> delegate=[self.leAfnetworkingSettings.curDelegateArray objectAtIndex:i];
        //            if(delegate){
        //                [list addObject:delegate];
        //                [delegate leRequest:self ResponedWith:responseObjectCache];
        //            }
        //        }
        //        [self.leAfnetworkingSettings setCurDelegateArray:list];
    }
}
-(void) onRespondWithResponse:(NSDictionary *) response{
    int statusCode=[[response objectForKey:LEKeyOfResponseStatusCode] intValue];
    BOOL requestFailed=statusCode/100!=2;
    NSString *errormsg=nil;
    if(requestFailed){
        if(statusCode!=500){
            errormsg=[response objectForKey:LEKeyOfResponseErrormsg];
            [[LE_AFNetworking sharedInstance] leOnShowAppMessageWith:errormsg];
        }
    }
    NSMutableArray *list=[[NSMutableArray alloc] init];
    for(int i=0;i<self.leAfnetworkingSettings.leCurDelegateArray.count;++i){
        id<LE_AFNetworkingDelegate> delegate=[self.leAfnetworkingSettings.leCurDelegateArray objectAtIndex:i];
        if(delegate){
            [list addObject:delegate];
            if(requestFailed){
                if([delegate respondsToSelector:@selector(leRequest:FailedWithStatusCode:Message:)]){
                    [delegate leRequest:self FailedWithStatusCode:statusCode Message:errormsg];
                }
            }else{
                if([delegate respondsToSelector:@selector(leRequest:ResponedWith:)]){
                    [delegate leRequest:self ResponedWith:responseObjectCache];
                }
            }
        }
    }
    [self.leAfnetworkingSettings leSetDelegateArray:list];
}
@end

@interface LE_AFNetworking ()
@property (nonatomic) BOOL enableDebug;
@property (nonatomic) BOOL enableResponseDebug;
@property (nonatomic) BOOL enableResponseWithJsonString;
@property (nonatomic) NSString *md5Salt;
@property (nonatomic) id<LEAppMessageDelegate> messageDelegate;
@property (nonatomic) NSSet *contentType;
@property (nonatomic) NSIndexSet *statusCode;
@end
@implementation LE_AFNetworking{
    NSMutableDictionary *afnetworkingCache;
}
-(void) leSetStatusCode:(NSIndexSet *) status{
    self.statusCode=status;
}
-(NSIndexSet *) leStatusCode{
    return self.statusCode;
}
-(NSIndexSet *) statusCode{
    if(_statusCode==nil){
        _statusCode=[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 400)];
    }
    return _statusCode;
}

-(void) leSetContentType:(NSSet *) type{
    self.contentType=type;
}
-(NSSet *) leContentType{
    return self.contentType;
}
-(NSSet *) contentType{
    if(_contentType==nil){
        _contentType=[[NSSet alloc] initWithObjects:@"text/javascript",@"application/json",@"text/json",@"text/html",@"text/plain", nil];
    }
    return _contentType;
}
-(BOOL) leEnableDebug{
    return self.enableDebug;
}
-(BOOL) leEnableResponseDebug{
    return self.enableResponseDebug;
}
-(BOOL) leEnableResponseWithJsonString{
    return self.enableResponseWithJsonString;
}
-(NSString *) leMd5Salt{
    return self.md5Salt;
}
-(void) leSetEnableDebug:(BOOL) enable{
    self.enableDebug=enable;
}
-(void) leSetEnableResponseDebug:(BOOL) enable{
    self.enableResponseDebug=enable;
}
-(void) leSetEnableResponseWithJsonString:(BOOL) enable{
    self.enableResponseWithJsonString=enable;
}
-(void) leSetServerHost:(NSString *) host{
    self->serverHost=host;
}
-(void) leSetMD5Salt:(NSString *) salt{
    self.md5Salt=salt;
}
-(void) leSetMessageDelegate:(id<LEAppMessageDelegate>) delegate{
    self.messageDelegate=delegate;
}
static BOOL enableNetWorkAlert;
static AFNetworkReachabilityStatus currentNetworkStatus;
static LE_AFNetworking *theSharedInstance = nil;
static NSUserDefaults *currentUserDefalts;
static int networkCounter;
- (int) getNetworkCounter{return ++networkCounter;}
+ (instancetype) sharedInstance { @synchronized(self) { if (theSharedInstance == nil) {
    theSharedInstance = [[self alloc] init];
    currentUserDefalts = [NSUserDefaults standardUserDefaults];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        currentNetworkStatus=status;
        [NSTimer scheduledTimerWithTimeInterval:1 target:theSharedInstance selector:@selector(onEnableNetworkAlert) userInfo:nil repeats:NO];
        if(enableNetWorkAlert){
            switch (status) {
                case AFNetworkReachabilityStatusNotReachable:{
                    [[LE_AFNetworking sharedInstance] leOnShowAppMessageWith:@"当前网络不可用，请检查网络"];
                    break;
                }
                    //                case AFNetworkReachabilityStatusReachableViaWiFi:{ break; }
                    //                case AFNetworkReachabilityStatusReachableViaWWAN:{ break; }
                default:
                    break;
            }
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
} } return theSharedInstance; }
-(NSString *) leGetServerHost{
    if(self->serverHost)return self->serverHost;
    return @"";
}

-(void) leOnShowAppMessageWith:(NSString *) message{
    if(self.messageDelegate&&[self.messageDelegate respondsToSelector:@selector(leOnShowAppMessageWith:)]){
        [self.messageDelegate leOnShowAppMessageWith:message];
    }
}
- (void) onEnableNetworkAlert{ enableNetWorkAlert=YES; }

- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter delegate:(id<LE_AFNetworkingDelegate>)delegate{
    return [self leRequestWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter delegate:delegate Identification:nil];
}

- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification{
    return [self leRequestWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter useCache:NO duration:0 delegate:delegate Identification:identification];
}
- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate{
    return [self leRequestWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter useCache:useCache duration:duration delegate:delegate Identification:nil];
}
- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification{
    return [self leRequestWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter useCache:useCache duration:duration delegate:delegate AutoRequest:YES Identification:identification];
}
- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate  AutoRequest:(BOOL) autoRequest{
    return [self leRequestWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter useCache:useCache duration:duration delegate:delegate AutoRequest:autoRequest Identification:nil];
}
- (LE_AFNetworkingRequestObject *) leRequestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(LERequestType) leRequestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate  AutoRequest:(BOOL) autoRequest Identification:(NSString *) identification{
    if(!afnetworkingCache){
        afnetworkingCache=[[NSMutableDictionary alloc] init];
    }
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    LE_AFNetworkingSettings *settings=[[LE_AFNetworkingSettings alloc] initWithApi:api uri:uri httpHead:httpHead requestType:leRequestType parameter:parameter useCache:useCache duration:duration delegate:delegate Identification:identification];
    [settings leSetCreateTimeStamp:[LE_AFNetworking leGetTimeStamp]];
    if(settings.leUseCache&&(leRequestType==LERequestTypeGet||leRequestType==LERequestTypeHead)){
        LE_AFNetworkingRequestObject *requestObject=[afnetworkingCache objectForKey:settings.leGetKey];
        if(requestObject){
            if(([LE_AFNetworking leGetTimeStamp]-requestObject.leAfnetworkingSettings.leCreateTimestamp-requestObject.leAfnetworkingSettings.leDuration)>0){
                requestObject=nil;
            }
        }
        if(requestObject){
            settings=nil;
            [requestObject.leAfnetworkingSettings leAddUniqueDelegate:delegate];
            [NSTimer scheduledTimerWithTimeInterval:0.01 target:requestObject selector:@selector(returnCachedResponse) userInfo:nil repeats:NO];
            return requestObject;
        }else {
            requestObject=[[LE_AFNetworkingRequestObject alloc] initWithSettings:settings];
            [requestObject leExecRequest:autoRequest];
            LE_AFNetworkingRequestObject *ori=[afnetworkingCache objectForKey:requestObject.leAfnetworkingSettings.leGetKey];
            [afnetworkingCache setObject:requestObject forKey:requestObject.leAfnetworkingSettings.leGetKey];
            ori=nil;
            return requestObject;
        }
    }else{
        LE_AFNetworkingRequestObject *requestObject= [[LE_AFNetworkingRequestObject alloc] initWithSettings:settings];
        [requestObject leExecRequest:autoRequest];
        return requestObject;
    }
}
-(void) leRemoveDelegate:(id) delegate{
    for (LE_AFNetworkingRequestObject *requestObject in afnetworkingCache.allValues) {
        if(requestObject&&requestObject.leAfnetworkingSettings){
            for (NSInteger i=requestObject.leAfnetworkingSettings.leCurDelegateArray.count-1; i>=0; i--) {
                id<LE_AFNetworkingDelegate> delegate=[requestObject.leAfnetworkingSettings.leCurDelegateArray objectAtIndex:i];
                if([delegate isEqual:delegate]){
                    [requestObject.leAfnetworkingSettings.leCurDelegateArray removeObjectAtIndex:i];
                }
            }
        }
    }
}
-(void) leRemoveDelegateWithKey:(NSString *) key Value:(id) value{
    LE_AFNetworkingRequestObject *requestObject=[afnetworkingCache objectForKey:key];
    if(requestObject){
        if(requestObject&&requestObject.leAfnetworkingSettings){
            for (NSInteger i=requestObject.leAfnetworkingSettings.leCurDelegateArray.count-1; i>=0; i--) {
                id<LE_AFNetworkingDelegate> delegate=[requestObject.leAfnetworkingSettings.leCurDelegateArray objectAtIndex:i];
                if([delegate isEqual:delegate]){
                    [requestObject.leAfnetworkingSettings.leCurDelegateArray removeObjectAtIndex:i];
                }
            }
        }
    }
} 
- (void) leSave:(NSString *) value WithKey:(NSString *) key{
    if(value&&key){
        [currentUserDefalts setObject:value forKey:key];
        [currentUserDefalts synchronize];
    }
}
- (NSString *) leGetValueWithKey:(NSString *) key{
    NSString *value=nil;
    if(key){
        value = [currentUserDefalts objectForKey:key];
    }
    return value;
}

- (NSDictionary *) leGetLocalCacheWithApi:(NSString *) api uri:(NSString *) uri parameter:(id) parameter{
    NSString *key=[LE_AFNetworkingSettings leGetKeyWithApi:api uri:uri parameter:parameter];
    if(key){
        NSString *json=[[LE_DataManager sharedInstanceOfStorage] leGetDataWithTable:LECacheTable Key:key];
        if(json){
            return [json leJSONValue];
        }
    }
    return nil;
}
+ (int)leGetTimeStamp:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy.MM.dd";
    NSString *sdate = [formatter stringFromDate:date];
    NSDate *ndate = [formatter dateFromString:sdate];
    return (int)ndate.timeIntervalSince1970;
}
+ (int)leGetTimeStamp {
    return [[NSDate date] timeIntervalSince1970];
}
+(NSString*) JSONStringWithDictionary:(NSDictionary *) dic {
    NSMutableString *jsonString=[[NSMutableString alloc] initWithString:@""];
    NSString *value=nil;
    for (NSString *key in dic.allKeys) {
        if(value){
            if(jsonString.length>0){
                [jsonString appendString:@","];
            }
        }
        id obj=[dic objectForKey:key];
        if([obj isKindOfClass:[NSDictionary class]]){
            value=[LE_AFNetworking JSONStringWithDictionary:obj];
            [jsonString appendFormat:@" \"%@\":%@", key, value];
        }else if([obj isKindOfClass:[NSArray class]]){
            value=[LE_AFNetworking JSONStringWithArray:obj];
            [jsonString appendFormat:@" \"%@\":%@", key, value];
        }else {
            value=[NSString stringWithFormat:@"%@",obj];
            value=[value stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            value=[value stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
            value=[value stringByReplacingOccurrencesOfString:@"\t" withString:@""];
            value=[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [jsonString appendFormat:@" \"%@\":\"%@\"", key, value];
        }
    }
    [jsonString insertString:@"{" atIndex:0];
    [jsonString appendString:@"}"];
    return jsonString;
}
+(NSString*) JSONStringWithArray:(NSArray *) array {
    NSMutableString *jsonString=[[NSMutableString alloc] initWithString:@""];
    for (int i=0; i<array.count; i++) {
        id obj=[array objectAtIndex:i];
        if([obj isKindOfClass:[NSDictionary class]]||[obj isKindOfClass:[NSMutableDictionary class]]){
            if(jsonString.length>0){
                [jsonString appendFormat:@",%@",[(NSDictionary *)obj leObjToJSONString]];
            }else{
                [jsonString appendString:[(NSDictionary *)obj leObjToJSONString]];
            }
        }else {
            if(jsonString.length>0){
                [jsonString appendFormat:@",\"%@\"",obj];
            }else {
                [jsonString appendFormat:@"\"%@\"",obj];
            }
        }
    }
    [jsonString insertString:@"[" atIndex:0];
    [jsonString appendString:@"]"];
    return jsonString;
}
+ (NSString *) leJSONStringWithObject:(id) obj{
    NSString *jsonString = @"";
    if([[[UIDevice currentDevice].name lowercaseString] rangeOfString:@"simulator"].location !=NSNotFound){
        if([obj isKindOfClass:[NSDictionary class]]||[obj isMemberOfClass:[NSDictionary class]]){
            jsonString = [self JSONStringWithDictionary:obj];
        }else if([obj isKindOfClass:[NSArray class]]||[obj isMemberOfClass:[NSArray class]]){
            jsonString = [self JSONStringWithArray:obj];
        }
    }else{
        NSError *error=nil;
        if([NSJSONSerialization isValidJSONObject:obj]){
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj options:NSJSONWritingPrettyPrinted error:&error];
            if (jsonData) {
                jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            }
        }
    }
    if(jsonString){
        jsonString=[jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    }
    return jsonString;
}
+ (NSString *) leMd5:(NSString *) str{
    return [str leMd5WithSalt:[LE_AFNetworking sharedInstance].leMd5Salt?[LE_AFNetworking sharedInstance].leMd5Salt:@""];
}
+ (void) leDictionaryToEntity:(NSDictionary *)dict entity:(NSObject*)entity{
    if (dict && entity) {
        for (NSString *keyName in [dict allKeys]) {//构建出属性的set方法
            NSString *destMethodName = [NSString stringWithFormat:@"set%@:",[keyName capitalizedString]]; //capitalizedString返回每个单词首字母大写的字符串（每个单词的其余字母转换为小写）
            SEL destMethodSelector = NSSelectorFromString(destMethodName);
            if ([entity respondsToSelector:destMethodSelector]) {
                LESuppressPerformSelectorLeakWarning(
                                                   [entity performSelector:destMethodSelector withObject:[dict objectForKey:keyName]];
                                                   );
            }
        }
    }
}
+ (NSDictionary *) leEntityToDictionary:(id)entity{
    NSString *className=[NSString stringWithUTF8String:object_getClassName(entity)];
    Class clazz =  NSClassFromString(className);
    unsigned int count;
    objc_property_t* properties = class_copyPropertyList(clazz, &count);
    NSMutableArray* propertyArray = [NSMutableArray arrayWithCapacity:count];
    NSMutableArray* valueArray = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count ; i++){
        objc_property_t prop=properties[i];
        const char* propertyName = property_getName(prop);
        [propertyArray addObject:[NSString stringWithCString:propertyName encoding:NSUTF8StringEncoding]];
        //      const char* attributeName = property_getAttributes(prop);
        //      LELog(@"%@",[NSString stringWithUTF8String:propertyName]);
        //      LELog(@"%@",[NSString stringWithUTF8String:attributeName]);
        id value =nil;
        LESuppressPerformSelectorLeakWarning(
                                           value=[entity performSelector:NSSelectorFromString([NSString stringWithUTF8String:propertyName])];
                                           );
        if(value ==nil){
            [valueArray addObject:@""];
        }else {
            [valueArray addObject:value];
        }
    }
    free(properties);
    NSDictionary* returnDic = [NSDictionary dictionaryWithObjects:valueArray forKeys:propertyArray];
    return returnDic;
}
@end
