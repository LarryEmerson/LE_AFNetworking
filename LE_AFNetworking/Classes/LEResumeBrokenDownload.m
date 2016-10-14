//
//  LEResumeBrokenDownload.m
//  Pods
//
//  Created by emerson larry on 2016/10/11.
//
//

#import "LEResumeBrokenDownload.h"

@interface LEResumeBrokenDownloadManager ()
@property (nonatomic,readwrite) AFURLSessionManager *sessionManager;
@property (nonatomic,readwrite) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic,readwrite) NSFileManager *fileManager;
@end
@implementation LEResumeBrokenDownloadManager
static LEResumeBrokenDownloadManager *_instance;
+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        _instance.allowNetworkReachViaWWAN=YES;
        _instance.pauseDownloadWhenSwitchedToWWAN=YES;
        _instance.fileManager= [NSFileManager defaultManager];
        _instance.downloadedFilePath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        _instance.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _instance.sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:_instance.sessionConfiguration];
        [_instance.sessionManager.reachabilityManager startMonitoring];
    });
    return _instance;
}
- (id)copyWithZone:(NSZone *)zone{
    return _instance;
}
-(void) releaseManager{
    [_instance.sessionManager.reachabilityManager stopMonitoring];
    _instance.sessionManager=nil;
}
-(void) setAllowNetworkReachViaWWAN:(BOOL)allowNetworkReachViaWWAN{
    _allowNetworkReachViaWWAN=allowNetworkReachViaWWAN;
    _instance.sessionConfiguration.allowsCellularAccess=allowNetworkReachViaWWAN;//TODO 这里的设置是否能直接影响设备的蜂窝网络连接需经过测试，如果可行则不需要额外的代码处理蜂窝网络的控制
    [[NSNotificationCenter defaultCenter] postNotificationName:LEAllowNetworkReachViaWWAN object:nil userInfo:@{LEAllowNetworkReachViaWWAN:[NSNumber numberWithBool:allowNetworkReachViaWWAN]}];
}
-(void) setPauseDownloadWhenSwitchedToWWAN:(BOOL)pauseDownloadWhenSwitchedToWWAN{
    _pauseDownloadWhenSwitchedToWWAN=pauseDownloadWhenSwitchedToWWAN;
    [[NSNotificationCenter defaultCenter] postNotificationName:LEPauseDownloadWhenSwitchedToWWAN object:nil userInfo:@{LEPauseDownloadWhenSwitchedToWWAN:[NSNumber numberWithBool:pauseDownloadWhenSwitchedToWWAN]}];
}
@end

@interface LEResumeBrokenDownload ()
@property (nonatomic) id<LEResumeBrokenDownloadDelegate> curDelegate;
@property (nonatomic, readwrite) LEResumeBrokenDownloadState curDownloadState;
@property (nonatomic, readwrite) NSString *curIdentifier;
@end
@implementation LEResumeBrokenDownload{
    NSURLSessionDownloadTask *downloadTask;
    NSString *curDownloadedFilePath;
    NSString *curURL;
}
-(NSString *) leDownloadedFilePath{
    if(!curURL||curURL.length==0){
        return nil;
    }
    NSString *path=[[NSUserDefaults standardUserDefaults] objectForKey:[curURL stringByAppendingString:LEDownloadSuggestedFilename]];
    if(path&&path.length>0){
        return [curDownloadedFilePath stringByAppendingPathComponent:path];
    }
    return [curDownloadedFilePath stringByAppendingPathComponent:curURL.lastPathComponent];
}
-(void) leSetDownloadedFilePath:(NSString *) path{
    curDownloadedFilePath=path;
}
-(void) setCurDownloadState:(LEResumeBrokenDownloadState)curDownloadState{
    _curDownloadState=curDownloadState;
    if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnDownloadStateChanged:Identifier:)]){
        [self.curDelegate leOnDownloadStateChanged:curDownloadState Identifier:self.curIdentifier];
    }
}
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier URL:(NSString *) url{
    self=[self initWithDelegate:delegate Identifier:identifier];
    [self leDownloadWithURL:url];
    [self leResumeDownload];
    return self;
}
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier{
    self=[super init];
    self.curDelegate=delegate;
    self.curIdentifier=identifier;
    curDownloadedFilePath=[LEResumeBrokenDownloadManager sharedInstance].downloadedFilePath;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityStatusDidChange:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationFromLEResumeBrokenDownloadManager:) name:LEAllowNetworkReachViaWWAN object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationFromLEResumeBrokenDownloadManager:) name:LEPauseDownloadWhenSwitchedToWWAN object:nil];
    return self;
}
-(void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LEAllowNetworkReachViaWWAN object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LEPauseDownloadWhenSwitchedToWWAN object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AFNetworkingReachabilityDidChangeNotification object:nil];
}
-(void) reachabilityStatusDidChange:(NSNotification *) noti{
    if(noti&&noti.userInfo){
        NSDictionary *userinfo=noti.userInfo; 
        int status=[[userinfo objectForKey:AFNetworkingReachabilityNotificationStatusItem] intValue];
        if(status==AFNetworkReachabilityStatusReachableViaWWAN){
            if(self.curDownloadState==LEResumeBrokenDownloadStateDownloading){
                if([LEResumeBrokenDownloadManager sharedInstance].allowNetworkReachViaWWAN){
                    if([LEResumeBrokenDownloadManager sharedInstance].pauseDownloadWhenSwitchedToWWAN){
                        [self pauseDownloadWhenNetworkUnstable];
                        if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnAlertWhenSwitchedToWWANWithIdentifier:)]){
                            [self.curDelegate leOnAlertWhenSwitchedToWWANWithIdentifier:self.curIdentifier];
                        }
                    }
                }else{
                    [self pauseDownloadWhenNetworkUnstable];
                    if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnAlertForUnreachableNetworkViaWWANWithIdentifier:)]){
                        [self.curDelegate leOnAlertForUnreachableNetworkViaWWANWithIdentifier:self.curIdentifier];
                    }
                }
            }
        }else if(status==AFNetworkReachabilityStatusReachableViaWiFi){
            if(self.curDownloadState==LEResumeBrokenDownloadStatePaused||self.curDownloadState==LEResumeBrokenDownloadStateFailed){
                [self leResumeDownload];
            } 
        }else {
            if(self.curDownloadState==LEResumeBrokenDownloadStateDownloading){
                [self pauseDownloadWhenNetworkUnstable];
                if(status==AFNetworkReachabilityStatusNotReachable){
                    if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnAlertForUnreachableNetworkWithIdentifier:)]){
                        [self.curDelegate leOnAlertForUnreachableNetworkWithIdentifier:self.curIdentifier];
                    }
                }
            }
        }
    }
}
-(void) notificationFromLEResumeBrokenDownloadManager:(NSNotification *) noti{
    if(noti.userInfo){
        NSDictionary *userinfo=noti.userInfo;
        if([userinfo objectForKey:LEAllowNetworkReachViaWWAN]){
            BOOL enable=[[userinfo objectForKey:LEAllowNetworkReachViaWWAN] boolValue];
            if(!enable&&self.curDownloadState==LEResumeBrokenDownloadStateDownloading&&[LEResumeBrokenDownloadManager sharedInstance].sessionManager.reachabilityManager.networkReachabilityStatus==AFNetworkReachabilityStatusReachableViaWWAN){
                [self pauseDownloadWhenNetworkUnstable];
            }else if(self.curDownloadState==LEResumeBrokenDownloadStatePaused&&[LEResumeBrokenDownloadManager sharedInstance].sessionManager.reachabilityManager.isReachableViaWWAN){
                [self leResumeDownload];
            }
        }
        if([userinfo objectForKey:LEPauseDownloadWhenSwitchedToWWAN]){
            BOOL enable=[[userinfo objectForKey:LEPauseDownloadWhenSwitchedToWWAN] boolValue];
            if(enable&&self.curDownloadState==LEResumeBrokenDownloadStateDownloading&&[LEResumeBrokenDownloadManager sharedInstance].sessionManager.reachabilityManager.networkReachabilityStatus==AFNetworkReachabilityStatusReachableViaWWAN){
                [self pauseDownloadWhenNetworkUnstable];
            }
        }
    }
}
-(void) leDownloadWithURL:(NSString *) url{
    if(url&&url.length>0){
        curURL=url;
        self.curDownloadState=LEResumeBrokenDownloadStateWaiting;
        if([[NSData alloc] initWithContentsOfFile:[self leDownloadedFilePath]]){
            [self onDownloadCompleteWithPath:[self leDownloadedFilePath] Error:nil];
        }else{
            NSData *resumeData=[[NSData alloc] initWithContentsOfFile:[[self leDownloadedFilePath] stringByAppendingString:LEDownloadSuffix]];
            if(resumeData&&resumeData.length>0){
                float progress =[[[NSUserDefaults standardUserDefaults] objectForKey:[curURL stringByAppendingString:LEDownloadProgressKey]] floatValue];
                if(progress>0){
                    [self onDownloadProgressChanged:progress];
                }
            }
        }
    }
}
-(void) lePauseDownload{
    [self pauseDownloadManuallyOrAutomatic:YES];
}
-(void) pauseDownloadWhenNetworkUnstable{
    [self pauseDownloadManuallyOrAutomatic:NO];
}
-(void) pauseDownloadManuallyOrAutomatic:(BOOL) manually{
    if(self.curDownloadState==LEResumeBrokenDownloadStateDownloading){
        self.curDownloadState=manually?LEResumeBrokenDownloadStatePausedManually:LEResumeBrokenDownloadStatePaused;
        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            [resumeData writeToFile:[[self leDownloadedFilePath] stringByAppendingString:LEDownloadSuffix] atomically:YES];
            [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithFloat:1.0*downloadTask.countOfBytesReceived/downloadTask.countOfBytesExpectedToReceive] forKey:[curURL stringByAppendingString:LEDownloadProgressKey]];
        }];
    }
}
-(void) leResumeDownloadViaWWAN{
    [self leResumeDownloadWithUniqueWWANAllowance:[LEResumeBrokenDownloadManager sharedInstance].sessionManager.reachabilityManager.isReachableViaWWAN];
}
-(void) leResumeDownload{
    [self leResumeDownloadWithUniqueWWANAllowance:[LEResumeBrokenDownloadManager sharedInstance].allowNetworkReachViaWWAN&&[LEResumeBrokenDownloadManager sharedInstance].sessionManager.reachabilityManager.isReachableViaWWAN];
}
-(void) leResumeDownloadWithUniqueWWANAllowance:(BOOL) allow{
    if(self.curDownloadState==LEResumeBrokenDownloadStateDownloading||self.curDownloadState==LEResumeBrokenDownloadStateCompleted){
        return;
    }
    BOOL isWifi=[LEResumeBrokenDownloadManager sharedInstance].sessionManager.reachabilityManager.isReachableViaWiFi;
    BOOL isWWAN=allow;
    if(isWifi||isWWAN){
        self.curDownloadState=LEResumeBrokenDownloadStateDownloading;
        NSData *resumeData=[[NSData alloc] initWithContentsOfFile:[[self leDownloadedFilePath] stringByAppendingString:LEDownloadSuffix]];
        if(resumeData&&resumeData.length>0){
            downloadTask = [[LEResumeBrokenDownloadManager sharedInstance].sessionManager downloadTaskWithResumeData:resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
                [self onDownloadProgressChanged:1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount];
            } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                return [self getURLWithResponse:response];
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                [self onDownloadCompleteWithPath:[self getURLWithResponse:response].path Error:error];
            }];
        }else{
            downloadTask = [[LEResumeBrokenDownloadManager sharedInstance].sessionManager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:curURL]] progress:^(NSProgress * _Nonnull downloadProgress) {
                [self onDownloadProgressChanged:1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount];
            } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                return [self getURLWithResponse:response];
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                [self onDownloadCompleteWithPath:[self getURLWithResponse:response].path Error:error];
            }];
        }
        [downloadTask resume];
    }else{
        if(!isWWAN&&[LEResumeBrokenDownloadManager sharedInstance].sessionManager.reachabilityManager.isReachableViaWWAN){
            if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnAlertForUnreachableNetworkViaWWANWithIdentifier:)]){
                [self.curDelegate leOnAlertForUnreachableNetworkViaWWANWithIdentifier:self.curIdentifier];
            }
        }else {
            if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnAlertForUnreachableNetworkWithIdentifier:)]){
                [self.curDelegate leOnAlertForUnreachableNetworkWithIdentifier:self.curIdentifier];
            }
        }
    }
}
-(NSURL *) getURLWithResponse:(NSURLResponse *) response{
    return [NSURL fileURLWithPath:[curDownloadedFilePath stringByAppendingPathComponent:response.suggestedFilename]];
}
-(void) onDownloadProgressChanged:(float) downloadProgress{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leDownloadProgress:Identifier:)]){
            [self.curDelegate leDownloadProgress:downloadProgress Identifier:self.curIdentifier];
        }
    });
}
-(void) onDownloadCompleteWithPath:(NSString *) filePath Error:(NSError *) error{
    if(error){
        if(error.userInfo){
            NSData *resumeData=[error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            if(resumeData&&resumeData.length>0){
                [resumeData writeToFile:[[self leDownloadedFilePath] stringByAppendingString:LEDownloadSuffix] atomically:YES];
            }
        }
        if(error.code!=NSURLErrorCancelled){
            self.curDownloadState=LEResumeBrokenDownloadStateFailed;
        }
    }else{
        self.curDownloadState=LEResumeBrokenDownloadStateCompleted;
        [[LEResumeBrokenDownloadManager sharedInstance].fileManager removeItemAtPath:[[self leDownloadedFilePath] stringByAppendingString:LEDownloadSuffix] error:nil];
        [[NSUserDefaults standardUserDefaults] setValue:filePath.lastPathComponent forKey:[curURL stringByAppendingString:LEDownloadSuggestedFilename]];
    }
    if(self.curDownloadState!=LEResumeBrokenDownloadStatePaused&&self.curDownloadState!=LEResumeBrokenDownloadStatePausedManually){
        if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnDownloadCompletedWithPath:Error:Identifier:)]){
            [self.curDelegate leOnDownloadCompletedWithPath:filePath Error:error Identifier:self.curIdentifier];
        }
    }
}
@end
