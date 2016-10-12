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

@interface LEResumeBrokenDownload ()
@property (nonatomic) LEResumeBrokenDownloadState curDownloadState;
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
    NSString *curFilePath;
    NSString *curURL;
    NSFileManager *fileManager;
}
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier{
    self=[super init];
    fileManager = [NSFileManager defaultManager];
    curDelegate=delegate;
    curIdentifier=identifier;
    curDownloadedFilePath=[LEResumeBrokenDownloadManager sharedInstance].downloadedFilePath;
    reachabilityManager=[AFNetworkReachabilityManager sharedManager];
    [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
        if(status==AFNetworkReachabilityStatusReachableViaWWAN){
            if(self.curDownloadState==LEResumeBrokenDownloadStateDownloading){
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
            if(self.curDownloadState==LEResumeBrokenDownloadStateWaiting||self.curDownloadState==LEResumeBrokenDownloadStatePaused){
                [self leResumeDownload];
            }else if(self.curDownloadState==LEResumeBrokenDownloadStateFailed){
                [self lePauseDownload];
                [self leResumeDownload];
            }
        }else {
            if(self.curDownloadState==LEResumeBrokenDownloadStateDownloading){
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
-(void) setCurDownloadState:(LEResumeBrokenDownloadState)curDownloadState{
    _curDownloadState=curDownloadState;
    if(curDelegate&&[curDelegate respondsToSelector:@selector(leOnDownloadStateChanged:)]){
        [curDelegate leOnDownloadStateChanged:curDownloadState];
    }
}
-(LEResumeBrokenDownloadState) leCurrentDownloadState{
    return self.curDownloadState;
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
            if(!enable&&self.curDownloadState==LEResumeBrokenDownloadStateDownloading&&reachabilityManager.networkReachabilityStatus==AFNetworkReachabilityStatusReachableViaWWAN){
                [self lePauseDownload];
            }else if(self.curDownloadState==LEResumeBrokenDownloadStatePaused&&reachabilityManager.isReachableViaWWAN){
                [self leResumeDownload];
            }
        }
        if([userinfo objectForKey:LEPauseDownloadWhenSwitchedToWWAN]){
            BOOL enable=[[userinfo objectForKey:LEPauseDownloadWhenSwitchedToWWAN] boolValue];
            if(enable&&self.curDownloadState==LEResumeBrokenDownloadStateDownloading&&reachabilityManager.networkReachabilityStatus==AFNetworkReachabilityStatusReachableViaWWAN){
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
    curURL=url;
    NSURL *nsurl =[NSURL URLWithString:url];
//    nsurl=[NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_01.mp4"];
    downloadRequest = [NSURLRequest requestWithURL:nsurl];
    self.curDownloadState=LEResumeBrokenDownloadStateWaiting;
    if(reachabilityManager.isReachableViaWiFi||([LEResumeBrokenDownloadManager sharedInstance].allowNetworkReachViaWWAN&&reachabilityManager.isReachableViaWWAN)){
        [self leResumeDownload];
    }
}
-(void) lePauseDownload{
    if(self.curDownloadState==LEResumeBrokenDownloadStateDownloading){
        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            self.curDownloadState=LEResumeBrokenDownloadStatePaused;
            [resumeData writeToFile:[[self leDownloadedFilePath] stringByAppendingString:LEDownloadSuffix] atomically:YES];
        }];
    }
}
-(void) leResumeDownload{
    if(self.curDownloadState==LEResumeBrokenDownloadStateDownloading){
        return;
    }
    [reachabilityManager startMonitoring];//enabled when last download was failed
    NSData *resumeData=[[NSData alloc] initWithContentsOfFile:[self leDownloadedFilePath]];
    if(resumeData){
        [self onDownloadCompleteWithPath:[self leDownloadedFilePath] Error:nil];
        return;
    }
    resumeData=[[NSData alloc] initWithContentsOfFile:[[self leDownloadedFilePath] stringByAppendingString:LEDownloadSuffix]];
    self.curDownloadState=LEResumeBrokenDownloadStateDownloading;
    if(resumeData&&resumeData.length>0){
        if ([fileManager fileExistsAtPath:[[self leDownloadedFilePath] stringByAppendingString:LEDownloadSuffix]]) {
            [fileManager removeItemAtPath:[[self leDownloadedFilePath] stringByAppendingString:LEDownloadSuffix] error:nil];
        }
        downloadTask = [sessionManager downloadTaskWithResumeData:resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
            [self onDownloadProgressChanged:downloadProgress];
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:[self leDownloadedFilePath]];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [self onDownloadCompleteWithPath:[self leDownloadedFilePath] Error:error];
        }];
    }else{
        downloadTask = [sessionManager downloadTaskWithRequest:downloadRequest progress:^(NSProgress * _Nonnull downloadProgress) {
            [self onDownloadProgressChanged:downloadProgress];
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return [NSURL fileURLWithPath:[self leDownloadedFilePath]];
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            [self onDownloadCompleteWithPath:[self leDownloadedFilePath] Error:error];
        }];
    }
    [downloadTask resume];
}
-(void) onDownloadProgressChanged:(NSProgress *) downloadProgress{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(curDelegate&&[curDelegate respondsToSelector:@selector(leDownloadProgress:Identifier:)]){
            [curDelegate leDownloadProgress:1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount Identifier:curIdentifier];
        }
    });
}
-(NSString *) leDownloadedFilePath{
    return curURL?[curDownloadedFilePath stringByAppendingPathComponent:curURL.lastPathComponent]:nil;
}
-(void) onDownloadCompleteWithPath:(NSString *) filePath Error:(NSError *) error{
    if(curDelegate&&[curDelegate respondsToSelector:@selector(leOnDownloadCompletedWithPath:Error:Identifier:)]){
        [curDelegate leOnDownloadCompletedWithPath:filePath Error:error Identifier:curIdentifier];
    }
    if(error){
        self.curDownloadState=LEResumeBrokenDownloadStateFailed;
    }else{
        self.curDownloadState=LEResumeBrokenDownloadStateCompleted;
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
