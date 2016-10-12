//
//  LEResumeBrokenDownload.m
//  Pods
//
//  Created by emerson larry on 2016/10/11.
//
//

#import "LEResumeBrokenDownload.h"

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
        _instance.downloadedFilePath=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    });
    return _instance;
}
- (id)copyWithZone:(NSZone *)zone{
    return _instance;
}
-(void) setAllowNetworkReachViaWWAN:(BOOL)allowNetworkReachViaWWAN{
    _allowNetworkReachViaWWAN=allowNetworkReachViaWWAN;
    [[NSNotificationCenter defaultCenter] postNotificationName:LEAllowNetworkReachViaWWAN object:nil userInfo:@{LEAllowNetworkReachViaWWAN:[NSNumber numberWithBool:allowNetworkReachViaWWAN]}];
}
-(void) setPauseDownloadWhenSwitchedToWWAN:(BOOL)pauseDownloadWhenSwitchedToWWAN{
    _pauseDownloadWhenSwitchedToWWAN=pauseDownloadWhenSwitchedToWWAN;
    [[NSNotificationCenter defaultCenter] postNotificationName:LEPauseDownloadWhenSwitchedToWWAN object:nil userInfo:@{LEPauseDownloadWhenSwitchedToWWAN:[NSNumber numberWithBool:pauseDownloadWhenSwitchedToWWAN]}];
}
@end

@implementation LEResumeBrokenDownload{
    NSString *curIdentifier;
    id<LEResumeBrokenDownloadDelegate> curDelegate;
    NSString *curDownloadedFilePath;
    //
    AFURLSessionManager *sessionManager;
    AFNetworkReachabilityManager *reachabilityManager;
    
    NSURLRequest *downloadRequest;
    NSURLSessionDownloadTask *downloadTask;
    //
    LEResumeBrokenDownloadState curDownloadState;
}
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier{
    self=[super init];
    curDelegate=delegate;
    curIdentifier=identifier;
    curDownloadedFilePath=[LEResumeBrokenDownloadManager sharedInstance].downloadedFilePath;
    reachabilityManager=[AFNetworkReachabilityManager sharedManager];
    [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
        if(status==AFNetworkReachabilityStatusReachableViaWWAN){
            if(curDownloadState==LEResumeBrokenDownloadStateDownloading){
                if([LEResumeBrokenDownloadManager sharedInstance].allowNetworkReachViaWWAN){
                    if([LEResumeBrokenDownloadManager sharedInstance].pauseDownloadWhenSwitchedToWWAN){
                        [self lePauseDownload];
                        if(curDelegate&&[curDelegate respondsToSelector:@selector(leOnAlertWhenSwitchedToWWANWithIdentifier:)]){
                            [curDelegate leOnAlertWhenSwitchedToWWANWithIdentifier:curIdentifier];
                        }
                    }
                }
            }
        }else if(status==AFNetworkReachabilityStatusReachableViaWiFi){
            if(curDownloadState==LEResumeBrokenDownloadStateWaiting||curDownloadState==LEResumeBrokenDownloadStatePaused){
                [self leResumeDownload];
            }else if(curDownloadState==LEResumeBrokenDownloadStateFailed){
                [self lePauseDownload];
                [self leResumeDownload];
            }
        }else {
            if(curDownloadState==LEResumeBrokenDownloadStateDownloading){
                [self lePauseDownload];
            }
        }
    }];
    [reachabilityManager startMonitoring];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationFromLEResumeBrokenDownloadManager:) name:LEAllowNetworkReachViaWWAN object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationFromLEResumeBrokenDownloadManager:) name:LEPauseDownloadWhenSwitchedToWWAN object:nil];
    return self;
}
-(void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LEAllowNetworkReachViaWWAN object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LEPauseDownloadWhenSwitchedToWWAN object:nil];
}
-(void) notificationFromLEResumeBrokenDownloadManager:(NSNotification *) noti{
    if(noti.userInfo){
        NSDictionary *userinfo=noti.userInfo;
        if([userinfo objectForKey:LEAllowNetworkReachViaWWAN]){
            BOOL enable=[[userinfo objectForKey:LEAllowNetworkReachViaWWAN] boolValue];
            if(!enable&&curDownloadState==LEResumeBrokenDownloadStateDownloading&&reachabilityManager.networkReachabilityStatus==AFNetworkReachabilityStatusReachableViaWWAN){
                [self lePauseDownload];
            }else if(curDownloadState==LEResumeBrokenDownloadStatePaused&&reachabilityManager.isReachableViaWWAN){
                [self leResumeDownload];
            }
        }
        if([userinfo objectForKey:LEPauseDownloadWhenSwitchedToWWAN]){
            BOOL enable=[[userinfo objectForKey:LEPauseDownloadWhenSwitchedToWWAN] boolValue];
            if(enable&&curDownloadState==LEResumeBrokenDownloadStateDownloading&&reachabilityManager.networkReachabilityStatus==AFNetworkReachabilityStatusReachableViaWWAN){
                [self lePauseDownload];
            }
        }
    }
}
-(void) leSetDownloadedFilePath:(NSString *) path{
    curDownloadedFilePath=path;
}
//
-(void) leDownloadWithURL:(NSString *) url{
    NSURL *nsurl =[NSURL URLWithString:url];
    nsurl=[NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"];
    downloadRequest = [NSURLRequest requestWithURL:nsurl];
    curDownloadState=LEResumeBrokenDownloadStateWaiting;
    if(reachabilityManager.isReachableViaWiFi||([LEResumeBrokenDownloadManager sharedInstance].allowNetworkReachViaWWAN&&reachabilityManager.isReachableViaWWAN)){
        [self leResumeDownload];
    }
}
-(void) lePauseDownload{
    [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        curDownloadState=LEResumeBrokenDownloadStatePaused;
        NSString * downloadPath = [curDownloadedFilePath stringByAppendingPathComponent:downloadTask.currentRequest.URL.absoluteString.lastPathComponent];
        [resumeData writeToFile:downloadPath atomically:YES];
    }];
}
-(void) leResumeDownload{
    [reachabilityManager startMonitoring];//enabled when last download was failed
    NSString * downloadPath = [curDownloadedFilePath stringByAppendingPathComponent:downloadRequest.URL.absoluteString.lastPathComponent];
    NSData *resumeData=[[NSData alloc] initWithContentsOfFile:downloadPath];
    if(resumeData&&resumeData.length>0){
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        if ([fileMgr fileExistsAtPath:downloadPath]) {
            [fileMgr removeItemAtPath:downloadPath error:nil];
        }
        downloadTask = [sessionManager downloadTaskWithResumeData:resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
            [self onDownloadProgressChanged:downloadProgress];
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [self getDestinationWithResponse:response];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [self onDownloadCompleteWithResponse:response Path:filePath Error:error];
        }];
    }else{
        downloadTask = [sessionManager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
            [self onDownloadProgressChanged:downloadProgress];
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [self getDestinationWithResponse:response];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [self onDownloadCompleteWithResponse:response Path:filePath Error:error];
        }];
    }
    [downloadTask resume];
}
-(void) onDownloadProgressChanged:(NSProgress *) downloadProgress{
    curDownloadState=LEResumeBrokenDownloadStateDownloading;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(curDelegate&&[curDelegate respondsToSelector:@selector(leDownloadProgress:Identifier:)]){
            [curDelegate leDownloadProgress:1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount Identifier:curIdentifier];
        }
    });
}
-(NSURL *) getDestinationWithResponse:(NSURLResponse *) response{
    return [NSURL fileURLWithPath:[curDownloadedFilePath stringByAppendingPathComponent:response.suggestedFilename]];
}
-(void) onDownloadCompleteWithResponse:(NSURLResponse *) response Path:(NSURL *) filePath Error:(NSError *) error{
    if(curDelegate&&[curDelegate respondsToSelector:@selector(leOnDownloadCompletedWithResponse:Path:Error:Identifier:)]){
        [curDelegate leOnDownloadCompletedWithResponse:response Path:filePath Error:error Identifier:curIdentifier];
    }
    if(error){
        curDownloadState=LEResumeBrokenDownloadStateFailed;
    }else{
        curDownloadState=LEResumeBrokenDownloadStateCompleted;
    }
    [reachabilityManager stopMonitoring];
}
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier URL:(NSString *) url{
    self=[self initWithDelegate:delegate Identifier:identifier];
    [self leDownloadWithURL:url];
    [self leResumeDownload];
    return self;
}
@end
