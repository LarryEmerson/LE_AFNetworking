//
//  LE_AFNetworking.m
//  ticket
//
//  Created by emerson larry on 15/11/12.
//  Copyright © 2015年 360cbs. All rights reserved.
//

#import "LE_AFNetworking.h"
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
@implementation NSString(ExtensionAFN)
-(id)JSONValue {
    NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error != nil) return nil;
    return result;
}
-(NSString *)md5{
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}
-(NSString *)md5WithSalt:(NSString *) salt{
    return [[[self md5] stringByAppendingString:salt] md5];
}
-(NSString *)base64Encoder{
    NSData *data=[self dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}
-(NSString *)base64Decoder{
    NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:self options:0];
    return [[NSString alloc] initWithData:nsdataFromBase64String encoding:NSUTF8StringEncoding];
}
@end

@implementation NSObject (ExtensionAFN)
-(NSString *) ObjToJSONString{
    return [LE_AFNetworking JSONStringWithObject:self];
}
@end
@implementation LE_AFNetworkingSettings
- (id) initWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate{
    return [self initWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter useCache:useCache duration:duration delegate:delegate Identification:nil];
}
- (id) initWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification{
    self.curDelegateArray=[[NSMutableArray alloc] init];
    self=[super init];
    self.api=api;
    self.uri=uri;
    self.httpHead=httpHead;
    self.requestType=requestType;
    self.parameter=parameter;
    self.useCache=useCache;
    self.duration=duration;
    self.identification=identification; 
    self.requestCounter=[LE_AFNetworking getNetworkCounter];
    if(delegate){
        [self.curDelegateArray addObject:delegate];
    }
    return self;
}
-(void) addUniqueDelegate:(id<LE_AFNetworkingDelegate>) delegate{
    BOOL found=NO;
    for (id<LE_AFNetworkingDelegate> del in self.curDelegateArray) {
        if([del isEqual:delegate]){
            found=YES;
            break;
        }
    }
    if(!found){
        [self.curDelegateArray addObject:delegate];
    }
}
- (NSString *) getURL{
    return [NSString stringWithFormat:@"%@%@/api/v1/%@",[[LE_AFNetworking sharedInstance] getServerHost],self.api,self.uri];
}
- (NSString *) getKey{
    NSString *jsonString=@""; 
    if(self.parameter&&![self.parameter isKindOfClass:[NSString class]]){
        jsonString=[self.parameter ObjToJSONString];
    } 
    return [[self getURL] stringByAppendingString:jsonString];
}
- (NSString *) getRequestType{
    return self.requestType==0?@"Get":(self.requestType==1?@"Post":(self.requestType==2?@"Head":(self.requestType==3?@"Put":(self.requestType==4?@"Patch":@"Delete"))));
}
+ (NSString *) getKeyWithApi:(NSString *) api uri:(NSString *) uri parameter:(id) parameter{
    return [[NSString stringWithFormat:@"%@%@/api/v1/%@",[[LE_AFNetworking sharedInstance] getServerHost],api,uri] stringByAppendingString:parameter?[parameter ObjToJSONString]:@""];
}
@end

@implementation LE_AFNetworkingRequestObject{
    NSDictionary *responseObjectCache;
}
- (id) initWithSettings:(LE_AFNetworkingSettings *) settings{
    if([LE_AFNetworking sharedInstance].enableDebug){
        NSLogObject(@"===============================>");
        NSLogObject(settings.getURL);
        NSLogObject(settings.httpHead);
        NSLogObject(settings.getRequestType);
        NSLogObject(settings.parameter);
    }
    self.afnetworkingSettings=settings;
    self=[super init];
    return self;
}
- (void) execRequest:(BOOL) requestOrNot{
    if(!requestOrNot){
        return;
    }
    LE_AFNetworkingSettings *settings=self.afnetworkingSettings;
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //
    [manager.responseSerializer setAcceptableStatusCodes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 400)]];
    [manager.responseSerializer setAcceptableContentTypes:[[NSSet alloc] initWithObjects:@"text/javascript",@"application/json",@"text/json",@"text/html", nil]];
    if(settings.httpHead&&settings.httpHead.count>0){//HTTPHEAD
        manager.requestSerializer=[AFJSONRequestSerializer serializer];
        for (NSString *key in settings.httpHead.allKeys) {
            [manager.requestSerializer setValue:[settings.httpHead objectForKey:key] forHTTPHeaderField:key];
        }
    }
    switch (settings.requestType) {
        case 0://Get
        {
            [manager GET:settings.getURL parameters:settings.parameter progress:^(NSProgress * _Nonnull downloadProgress) {
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self onRespondedWithRequest:task responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self onRespondedWithRequest:task responseObject:nil error:error];
            }];
        }
            break;
        case 1://Post
        {
            [manager POST:settings.getURL parameters:settings.parameter progress:^(NSProgress * _Nonnull downloadProgress){
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self onRespondedWithRequest:task responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self onRespondedWithRequest:task responseObject:nil error:error];
            }];
        }
            break;
        case 2://Head
        {
            [manager HEAD:settings.getURL parameters:settings.parameter success:^(NSURLSessionDataTask * _Nonnull task) {
                [self onRespondedWithRequest:task responseObject:task];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self onRespondedWithRequest:task responseObject:nil error:error];
            }];
        }
            break;
        case 3://Put
        {
            [manager PUT:settings.getURL parameters:settings.parameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self onRespondedWithRequest:task responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self onRespondedWithRequest:task responseObject:nil error:error];
            }];
        }
            break;
        case 4://Patch
        {
            [manager PATCH:settings.getURL parameters:settings.parameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [self onRespondedWithRequest:task responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [self onRespondedWithRequest:task responseObject:nil error:error];
            }];
            
        }
            break;
        case 5://Delete
        {
            [manager DELETE:settings.getURL parameters:settings.parameter success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject){
                [self onRespondedWithRequest:task responseObject:responseObject];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)  {
                [self onRespondedWithRequest:task responseObject:nil error:error];
            }];
        }
            break;
        default:
            break;
    }
}
- (void) onRespondedWithRequest:(NSURLSessionDataTask *) operation responseObject:(id) responseObject {
    [self onRespondedWithRequest:operation responseObject:responseObject error:nil];
}
- (void) onRespondedWithRequest:(NSURLSessionDataTask *) operation responseObject:(id) responseObject error:(NSError *) error {
    if(error||!responseObject){
        if(error.code==-1001){
            [[LE_AFNetworking sharedInstance] onShowAppMessageWith:@"网络请求超时"];
        }
        //        else
        {
            if((self.afnetworkingSettings.requestType==RequestTypeGet )){
                NSString *json=[[LE_DataManager instanceOfStorage] getDataWithTable:CacheTable Key:self.afnetworkingSettings.getKey];
                if(json){
                    NSDictionary *response=[json JSONValue];
                    responseObjectCache=response;
                    if(response&&self.afnetworkingSettings.curDelegateArray){
                        [self onRespondWithResponse:responseObjectCache];
                        //                        NSMutableArray *list=[[NSMutableArray alloc] init];
                        //                        for(int i=0;i<self.afnetworkingSettings.curDelegateArray.count;++i){
                        //                            id<LE_AFNetworkingDelegate> delegate=[self.afnetworkingSettings.curDelegateArray objectAtIndex:i];
                        //                            if(delegate){
                        //                                [list addObject:delegate];
                        //                                [delegate request:self ResponedWith:response];
                        //                            }
                        //                        }
                        //                        [self.afnetworkingSettings setCurDelegateArray:list];
                    }
                }
            }else if(self.afnetworkingSettings.requestType==RequestTypeHead){
                NSHTTPURLResponse *res = (NSHTTPURLResponse *)operation.response;
                id obj=[[res allHeaderFields] objectForKey:KeyOfResponseCount];
                if(self.afnetworkingSettings.curDelegateArray){
                    NSMutableDictionary *muta=[[NSMutableDictionary alloc] init];
                    if(obj){
                        [muta setObject:obj forKey:KeyOfResponseCount];
                    }else{
                        [muta setObject:@"0" forKey:KeyOfResponseCount];
                    }
                    responseObjectCache=muta;
                    [self onRespondWithResponse:responseObjectCache];
                    //                    NSMutableArray *list=[[NSMutableArray alloc] init];
                    //                    for(int i=0;i<self.afnetworkingSettings.curDelegateArray.count;++i){
                    //                        id<LE_AFNetworkingDelegate> delegate=[self.afnetworkingSettings.curDelegateArray objectAtIndex:i];
                    //                        if(delegate){
                    //                            [list addObject:delegate];
                    //                            [delegate request:self ResponedWith:muta];
                    //                        }
                    //                    }
                    //                    [self.afnetworkingSettings setCurDelegateArray:list];
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
        if([LE_AFNetworking sharedInstance].enableDebug){
            NSLogTwoObjects(self.afnetworkingSettings.getURL,responseToJSONString);
        }
        id dataToObj=nil;
        if(responseToJSONString){
            dataToObj= [responseToJSONString JSONValue];
        }
        if([dataToObj isKindOfClass:[NSDictionary class]]){
            response =[dataToObj mutableCopy];
        }else if([dataToObj isKindOfClass:[NSArray class]]){
            [response setObject:dataToObj forKey:KeyOfResponseArray];
        }
        if(self.afnetworkingSettings.requestType==RequestTypeHead){
            NSDictionary *header=[res allHeaderFields];
            if(header&&[header objectForKey:KeyOfResponseCount]){
                [response setObject:[header objectForKey:KeyOfResponseCount] forKey:KeyOfResponseCount];
            }
        }
        if([LE_AFNetworking sharedInstance].enableResponseWithJsonString){
            if(responseToJSONString){
                [response setObject:responseToJSONString forKey:KeyOfResponseAsJSON];
            }
            [response setObject:[self.afnetworkingSettings getKey] forKey:@"URL"];
        }
        [response setObject:[NSNumber numberWithInteger:[res statusCode]] forKey:KeyOfResponseStatusCode];
        if(response&&self.afnetworkingSettings.curDelegateArray){
            if((self.afnetworkingSettings.requestType==RequestTypeGet||self.afnetworkingSettings.requestType==RequestTypeHead)){
                NSString *json=[LE_AFNetworking JSONStringWithObject:response];
                if(json){
                    [[LE_DataManager instanceOfStorage] addOrUpdateWithKey:self.afnetworkingSettings.getKey Value:json ToTable:CacheTable];
                }
            }
            responseObjectCache=response;
            [self onRespondWithResponse:responseObjectCache];
            //            NSMutableArray *list=[[NSMutableArray alloc] init];
            //            for(int i=0;i<self.afnetworkingSettings.curDelegateArray.count;++i){
            //                id<LE_AFNetworkingDelegate> delegate=[self.afnetworkingSettings.curDelegateArray objectAtIndex:i];
            //                if(delegate){
            //                    [list addObject:delegate];
            //                    [delegate request:self ResponedWith:response];
            //                }
            //            }
            //            [self.afnetworkingSettings setCurDelegateArray:list];
        }
    }
}
- (void) returnCachedResponse{
    if(responseObjectCache&&self.afnetworkingSettings.curDelegateArray){
        [self onRespondWithResponse:responseObjectCache];
        //        NSMutableArray *list=[[NSMutableArray alloc] init];
        //        for(int i=0;i<self.afnetworkingSettings.curDelegateArray.count;++i){
        //            id<LE_AFNetworkingDelegate> delegate=[self.afnetworkingSettings.curDelegateArray objectAtIndex:i];
        //            if(delegate){
        //                [list addObject:delegate];
        //                [delegate request:self ResponedWith:responseObjectCache];
        //            }
        //        }
        //        [self.afnetworkingSettings setCurDelegateArray:list];
    }
}
-(void) onRespondWithResponse:(NSDictionary *) response{
    int statusCode=[[response objectForKey:KeyOfResponseStatusCode] intValue];
    BOOL requestFailed=statusCode/100!=2;
    NSString *errormsg=nil;
    if(requestFailed){
        if(statusCode!=500){
            errormsg=[response objectForKey:KeyOfResponseErrormsg];
            [[LE_AFNetworking sharedInstance] onShowAppMessageWith:errormsg];
        }
    }
    NSMutableArray *list=[[NSMutableArray alloc] init];
    for(int i=0;i<self.afnetworkingSettings.curDelegateArray.count;++i){
        id<LE_AFNetworkingDelegate> delegate=[self.afnetworkingSettings.curDelegateArray objectAtIndex:i];
        if(delegate){
            [list addObject:delegate];
            if(requestFailed){
                if([delegate respondsToSelector:@selector(request:FailedWithStatusCode:Message:)]){
                    [delegate request:self FailedWithStatusCode:statusCode Message:errormsg];
                }
            }else{
                if([delegate respondsToSelector:@selector(request:ResponedWith:)]){
                    [delegate request:self ResponedWith:responseObjectCache];
                }
            }
        }
    }
    [self.afnetworkingSettings setCurDelegateArray:list];
}
@end

@implementation LE_AFNetworking{
    NSMutableDictionary *afnetworkingCache;
}
static BOOL enableNetWorkAlert;
static AFNetworkReachabilityStatus currentNetworkStatus;
static LE_AFNetworking *theSharedInstance = nil;
static NSUserDefaults *currentUserDefalts;
static int networkCounter;
+ (int) getNetworkCounter{return ++networkCounter;}
+ (instancetype) sharedInstance { @synchronized(self) { if (theSharedInstance == nil) {
    theSharedInstance = [[self alloc] init];
    currentUserDefalts = [NSUserDefaults standardUserDefaults];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        currentNetworkStatus=status;
        [NSTimer scheduledTimerWithTimeInterval:1 target:theSharedInstance selector:@selector(onEnableNetworkAlert) userInfo:nil repeats:NO];
        if(enableNetWorkAlert){
            switch (status) {
                case AFNetworkReachabilityStatusNotReachable:{
                    [[LE_AFNetworking sharedInstance] onShowAppMessageWith:@"当前网络不可用，请检查网络"];
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
-(NSString *) getServerHost{
    if(self->serverHost)return self->serverHost;
    return @"";
}
-(void) setServerHost:(NSString *) host{
    self->serverHost=host;
}
-(void) onShowAppMessageWith:(NSString *) message{
    if(self.messageDelegate&&[self.messageDelegate respondsToSelector:@selector(onShowAppMessageWith:)]){
        [self.messageDelegate onShowAppMessageWith:message];
    }
}

- (void) onEnableNetworkAlert{ enableNetWorkAlert=YES; }
- (LE_AFNetworkingRequestObject *) requestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate{
    return [self requestWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter useCache:useCache duration:duration delegate:delegate Identification:nil];
}
- (LE_AFNetworkingRequestObject *) requestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate Identification:(NSString *) identification{
    return [self requestWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter useCache:useCache duration:duration delegate:delegate AutoRequest:YES Identification:identification];
}
- (LE_AFNetworkingRequestObject *) requestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate  AutoRequest:(BOOL) autoRequest{
    return [self requestWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter useCache:useCache duration:duration delegate:delegate AutoRequest:autoRequest Identification:nil];
}
- (LE_AFNetworkingRequestObject *) requestWithApi:(NSString *) api uri:(NSString *) uri httpHead:(NSDictionary *) httpHead requestType:(RequestType) requestType parameter:(id) parameter useCache:(BOOL) useCache duration:(int) duration delegate:(id<LE_AFNetworkingDelegate>)delegate  AutoRequest:(BOOL) autoRequest Identification:(NSString *) identification{
    if(!afnetworkingCache){
        afnetworkingCache=[[NSMutableDictionary alloc] init];
    }
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    LE_AFNetworkingSettings *settings=[[LE_AFNetworkingSettings alloc] initWithApi:api uri:uri httpHead:httpHead requestType:requestType parameter:parameter useCache:useCache duration:duration delegate:delegate Identification:identification];
    [settings setCreateTimestamp:[LE_AFNetworking getTimeStamp]];
    if(settings.useCache&&(requestType==RequestTypeGet||requestType==RequestTypeHead)){
        LE_AFNetworkingRequestObject *requestObject=[afnetworkingCache objectForKey:settings.getKey];
        if(requestObject){
            if(([LE_AFNetworking getTimeStamp]-requestObject.afnetworkingSettings.createTimestamp-requestObject.afnetworkingSettings.duration)>0){
                requestObject=nil;
            }
        }
        if(requestObject){
            settings=nil;
            [requestObject.afnetworkingSettings addUniqueDelegate:delegate];
            [NSTimer scheduledTimerWithTimeInterval:0.01 target:requestObject selector:@selector(returnCachedResponse) userInfo:nil repeats:NO];
            return requestObject;
        }else {
            requestObject=[[LE_AFNetworkingRequestObject alloc] initWithSettings:settings];
            [requestObject execRequest:autoRequest];
            [afnetworkingCache setObject:requestObject forKey:requestObject.afnetworkingSettings.getKey];
            return requestObject;
        }
    }else{
        LE_AFNetworkingRequestObject *requestObject= [[LE_AFNetworkingRequestObject alloc] initWithSettings:settings];
        [requestObject execRequest:autoRequest];
        return requestObject;
    }
}
-(void) removeDelegateWithKey:(NSString *) key Value:(id) value{
    LE_AFNetworkingRequestObject *requestObject=[afnetworkingCache objectForKey:key];
    if(requestObject){
        if(requestObject&&requestObject.afnetworkingSettings){
            NSMutableArray *list=[[NSMutableArray alloc] init];
            for(int i=0;i<requestObject.afnetworkingSettings.curDelegateArray.count;++i){
                id<LE_AFNetworkingDelegate> delegate=[requestObject.afnetworkingSettings.curDelegateArray objectAtIndex:i];
                if([delegate isEqual:value]){
                    [requestObject.afnetworkingSettings.curDelegateArray removeObjectAtIndex:i];
                }else if(delegate){
                    [list addObject:delegate];
                }
            }
            [requestObject.afnetworkingSettings setCurDelegateArray:list];
        }
    }
} 
- (void) save:(NSString *) value WithKey:(NSString *) key{
    if(value&&key){
        [currentUserDefalts setObject:value forKey:key];
        [currentUserDefalts synchronize];
    }
}
- (NSString *) getValueWithKey:(NSString *) key{
    NSString *value=nil;
    if(key){
        value = [currentUserDefalts objectForKey:key];
    }
    return value;
}

- (NSDictionary *) getLocalCacheWithApi:(NSString *) api uri:(NSString *) uri parameter:(id) parameter{
    NSString *key=[LE_AFNetworkingSettings getKeyWithApi:api uri:uri parameter:parameter];
    if(key){
        NSString *json=[[LE_DataManager instanceOfStorage] getDataWithTable:CacheTable Key:key];
        if(json){
            return [json JSONValue];
        }
    }
    return nil;
}
+ (int)getTimeStamp:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy.MM.dd";
    NSString *sdate = [formatter stringFromDate:date];
    NSDate *ndate = [formatter dateFromString:sdate];
    return (int)ndate.timeIntervalSince1970;
}
+ (int)getTimeStamp {
    return [[NSDate date] timeIntervalSince1970];
}
+(NSString*) JSONStringWithDictionary:(NSDictionary *) dic {
    NSString *jsonString=@"";
    NSString *value=nil;
    for (NSString *key in dic.allKeys) {
        if(value){
            if(!jsonString){
                jsonString=@"";
            }
            jsonString=[jsonString stringByAppendingString:@","];
        }
        value=[NSString stringWithFormat:@"%@",[dic objectForKey:key]];
        jsonString=[NSString stringWithFormat:@"%@ \"%@\":\"%@\"",jsonString, key, value];
    }
    jsonString=[NSString stringWithFormat:@"{%@}",jsonString];
    return jsonString;
}
+(NSString*) JSONStringWithArray:(NSArray *) array {
    NSString *jsonString=@"";
    for (int i=0; i<array.count; i++) {
        id obj=[array objectAtIndex:i];
        if([obj isKindOfClass:[NSDictionary class]]||[obj isKindOfClass:[NSMutableDictionary class]]){
            if(!jsonString){
                jsonString=[(NSDictionary *)obj ObjToJSONString];
            }else{
                jsonString=[NSString stringWithFormat:@"%@,%@",jsonString,[(NSDictionary *)obj ObjToJSONString]];
            }
        }
    }
    jsonString=[NSString stringWithFormat:@"[%@]",jsonString];
    return jsonString;
}
+ (NSString *) JSONStringWithObject:(id) obj{
    NSString *jsonString = @"";
    if([[[UIDevice currentDevice].name lowercaseString] rangeOfString:@"simulator"].location !=NSNotFound){
        if([obj isKindOfClass:[NSDictionary class]]||[obj isSubclassOfClass:[NSDictionary class]]){
            jsonString = [self JSONStringWithDictionary:obj];
        }else if([obj isKindOfClass:[NSArray class]]||[obj isSubclassOfClass:[NSArray class]]){
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
+ (NSString *) md5:(NSString *) str{
    return [str md5WithSalt:[LE_AFNetworking sharedInstance].md5Salt?[LE_AFNetworking sharedInstance].md5Salt:@""];
}
+ (void) dictionaryToEntity:(NSDictionary *)dict entity:(NSObject*)entity{
    if (dict && entity) {
        for (NSString *keyName in [dict allKeys]) {//构建出属性的set方法
            NSString *destMethodName = [NSString stringWithFormat:@"set%@:",[keyName capitalizedString]]; //capitalizedString返回每个单词首字母大写的字符串（每个单词的其余字母转换为小写）
            SEL destMethodSelector = NSSelectorFromString(destMethodName);
            if ([entity respondsToSelector:destMethodSelector]) {
                SuppressPerformSelectorLeakWarning(
                                                   [entity performSelector:destMethodSelector withObject:[dict objectForKey:keyName]];
                                                   );
            }
        }
    }
}
+ (NSDictionary *) entityToDictionary:(id)entity{
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
        //      NSLog(@"%@",[NSString stringWithUTF8String:propertyName]);
        //      NSLog(@"%@",[NSString stringWithUTF8String:attributeName]);
        id value =nil;
        SuppressPerformSelectorLeakWarning(
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