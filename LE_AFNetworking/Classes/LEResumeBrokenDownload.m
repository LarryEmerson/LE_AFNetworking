//
//  LEResumeBrokenDownload.m
//  Pods
//
//  Created by emerson larry on 2016/10/11.
//
//

#import "LEResumeBrokenDownload.h"
#import <objc/runtime.h>

#pragma mark runtime 属性获取
#define LEDownloadFileProperty @"downloadFile"
#define LEDownloadFilePathProperty @"path"
#define LEDownloadResumeDataLength @"bytes=%ld-"
#define LEDownloadHttpFieldRange @"Range"
#define LEDownloadKeyBytesReceived @"NSURLSessionResumeBytesReceived"
#define LEDownloadKeyCurrentRequest @"NSURLSessionResumeCurrentRequest"
#define LEDownloadKeyTempFileName @"NSURLSessionResumeInfoTempFileName"
#pragma mark keys
#define LEDownloadProgress @"leprogress" //用于记录下载进度
#define LEDownloadSuggestedFilename @"lesuggestedname" //用于记录下载完成文件的文件名称，主要为了解决url中不带后缀造成的路径问题
#define LEDownloadPath @"lepath" //用于存放tmp及下载完成文件的lastpathcomponent+name
#define LEAllowNetworkReachViaWWAN @"LEAllowNetworkReachViaWWAN"
#define LEPauseDownloadWhenSwitchedToWWAN @"LEPauseDownloadWhenSwitchedToWWAN"

@interface LEResumeBrokenDownloadManager ()
@property (nonatomic,readwrite) AFURLSessionManager *leSessionManager;
@property (nonatomic,readwrite) NSURLSessionConfiguration *leSessionConfiguration;
@property (nonatomic,readwrite) NSFileManager *leFileManager;
@property (nonatomic) NSString *downloadedFilePathDirectory;
/** 所有下载器的内存缓存 */
@property (nonatomic) NSMutableDictionary *leDownloaderCache;
@end

@interface LEResumeBrokenDownload ()
@property (nonatomic) id<LEResumeBrokenDownloadDelegate> curDelegate;
@property (nonatomic, readwrite) LEResumeBrokenDownloadState leDownloadState;
@property (nonatomic, readwrite) NSString *leIdentifier;
@property (nonatomic) NSString *curURL;
@property (nonatomic) NSString *curDownloadTempFilePath;
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
        _instance.leAllowNetworkReachViaWWAN=YES;
        _instance.lePauseDownloadWhenSwitchedToWWAN=YES;
        _instance.leFileManager= [NSFileManager defaultManager];
        _instance.downloadedFilePathDirectory=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        _instance.leSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _instance.leSessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:_instance.leSessionConfiguration];
        [_instance.leSessionManager.reachabilityManager startMonitoring];
        _instance.leDownloaderCache=[NSMutableDictionary new];
    });
    return _instance;
}
- (id)copyWithZone:(NSZone *)zone{
    return _instance;
}
-(void) leReleaseManager{
    for (LEResumeBrokenDownload *downloader in _instance.leDownloaderCache) {
        if(downloader.leDownloadState==LEResumeBrokenDownloadStateDownloading){
            [downloader lePauseDownload];
        }
    }
    [_instance.leDownloaderCache removeAllObjects];
    [_instance.leSessionManager.reachabilityManager stopMonitoring];
    _instance.leSessionManager=nil;
}
-(void) leSetAllowNetworkReachViaWWAN:(BOOL)allowNetworkReachViaWWAN{
    self.leAllowNetworkReachViaWWAN=allowNetworkReachViaWWAN;
}
-(void) setLeAllowNetworkReachViaWWAN:(BOOL)leAllowNetworkReachViaWWAN{
    _instance.leSessionConfiguration.allowsCellularAccess=leAllowNetworkReachViaWWAN;//TODO 这里的设置是否能直接影响设备的蜂窝网络连接需经过测试，如果可行则不需要额外的代码处理蜂窝网络的控制
    [[NSNotificationCenter defaultCenter] postNotificationName:LEAllowNetworkReachViaWWAN object:nil userInfo:@{LEAllowNetworkReachViaWWAN:[NSNumber numberWithBool:leAllowNetworkReachViaWWAN]}];
}
-(void) leSetPauseDownloadWhenSwitchedToWWAN:(BOOL)pauseDownloadWhenSwitchedToWWAN{
    self.lePauseDownloadWhenSwitchedToWWAN=pauseDownloadWhenSwitchedToWWAN;
}
-(void) setLePauseDownloadWhenSwitchedToWWAN:(BOOL)lePauseDownloadWhenSwitchedToWWAN{
    _lePauseDownloadWhenSwitchedToWWAN=lePauseDownloadWhenSwitchedToWWAN;
    [[NSNotificationCenter defaultCenter] postNotificationName:LEPauseDownloadWhenSwitchedToWWAN object:nil userInfo:@{LEPauseDownloadWhenSwitchedToWWAN:[NSNumber numberWithBool:lePauseDownloadWhenSwitchedToWWAN]}];
}
-(NSString *) leDownloadedFilePathDirectory{
    return self.downloadedFilePathDirectory;
}
-(void) leSwitchPathDirectoryFromCacheToDocument:(BOOL) isSwitch SubPathComponent:(NSString *) component{
    if(isSwitch){
        self.downloadedFilePathDirectory=[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] lastPathComponent];
    }else{
        self.downloadedFilePathDirectory=[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] lastPathComponent];
    }
    if(component&&component.length>0){
        self.downloadedFilePathDirectory=[self.downloadedFilePathDirectory stringByAppendingPathComponent:component];
        if (![[LEResumeBrokenDownloadManager sharedInstance].leFileManager fileExistsAtPath:self.downloadedFilePathDirectory]) {
            [[LEResumeBrokenDownloadManager sharedInstance].leFileManager createDirectoryAtPath:self.downloadedFilePathDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
}
-(LEResumeBrokenDownload *) leDownloadWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate URL:(NSString *) url{
    LEResumeBrokenDownload *downloader=[self.leDownloaderCache objectForKey:url];
    if(downloader){
        downloader.curDelegate=delegate;
        downloader.leDownloadState=downloader.leDownloadState;
    }else{
        downloader=[[LEResumeBrokenDownload alloc] initWithDelegate:delegate Identifier:nil];
        [downloader leDownloadWithURL:url];
        [self.leDownloaderCache setObject:downloader forKey:url];
    }
    return downloader;
}
-(BOOL) leIsDownloadExisted:(NSString *) url{
    LEResumeBrokenDownload *download= [self.leDownloaderCache objectForKey:url];
    return download&&download.curDelegate;
}
-(LEResumeBrokenDownload *) leGetDownloadWithUrl:(NSString *) url{
    return [self.leDownloaderCache objectForKey:url];
}
@end


@implementation LEResumeBrokenDownload{
    AFURLSessionManager *sessionManager;//不可以直接调用sessionManager.reachabilityManager，原因是自定义的sessionManager未启用reachabilityManager
    NSURLSessionDownloadTask *downloadTask;
    NSString *curDownloadedFilePath;
}
-(NSString *) leDownloadedFilePath{
    if(!self.curURL||self.curURL.length==0){
        return nil;
    }
    NSString *path=[NSHomeDirectory() stringByAppendingPathComponent:curDownloadedFilePath];
    NSString *name=[self.curURL lastPathComponent];
    if(!name.pathExtension||name.pathExtension.length==0){
        name=[[NSUserDefaults standardUserDefaults] objectForKey:[self.curURL stringByAppendingString:LEDownloadSuggestedFilename]];
    }
    return [path stringByAppendingPathComponent:name];
}
-(void) leSwitchPathDirectoryFromCacheToDocument:(BOOL) isSwitch SubPathComponent:(NSString *) component{
    if(isSwitch){
        curDownloadedFilePath=[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] lastPathComponent];
    }else{
        curDownloadedFilePath=[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] lastPathComponent];
    }
    if(component&&component.length>0){
        curDownloadedFilePath=[curDownloadedFilePath stringByAppendingPathComponent:component];
        if (![[LEResumeBrokenDownloadManager sharedInstance].leFileManager fileExistsAtPath:curDownloadedFilePath]) {
            [[LEResumeBrokenDownloadManager sharedInstance].leFileManager createDirectoryAtPath:curDownloadedFilePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
}
-(void) setLeDownloadState:(LEResumeBrokenDownloadState)leDownloadState{
    _leDownloadState=leDownloadState;
    if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnDownloadStateChanged:Identifier:)]){
        [self.curDelegate leOnDownloadStateChanged:leDownloadState Identifier:self.self.leIdentifier];
    }
}
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier URL:(NSString *) url{
    self=[self initWithDelegate:delegate Identifier:identifier];
    [self leDownloadWithURL:url];
    [self leResumeDownload];
    return self;
}
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier{
    return [self initWithDelegate:delegate Identifier:identifier SessionConfiguration:nil];
}
 
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier SessionConfiguration:(NSURLSessionConfiguration *) config{
    self=[super init];
    self.curDelegate=delegate;
    self.leIdentifier=identifier;
    curDownloadedFilePath=[LEResumeBrokenDownloadManager sharedInstance].downloadedFilePathDirectory;
    if(config){
        sessionManager=[[AFURLSessionManager alloc] initWithSessionConfiguration:config];
    }else{
        sessionManager=[LEResumeBrokenDownloadManager sharedInstance].leSessionManager;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityStatusDidChange:) name:AFNetworkingReachabilityDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationFromLEResumeBrokenDownloadManager:) name:LEAllowNetworkReachViaWWAN object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationFromLEResumeBrokenDownloadManager:) name:LEPauseDownloadWhenSwitchedToWWAN object:nil];
    return self;
}
-(void) leRelease{
    if(self.leDownloadState==LEResumeBrokenDownloadStateDownloading){
        [self lePauseDownload];
    }
    self.curDelegate=nil;
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
            if(self.leDownloadState==LEResumeBrokenDownloadStateDownloading){
                if([LEResumeBrokenDownloadManager sharedInstance].leAllowNetworkReachViaWWAN){
                    if([LEResumeBrokenDownloadManager sharedInstance].lePauseDownloadWhenSwitchedToWWAN){
                        [self pauseDownloadWhenNetworkUnstable];
                        if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnAlertWhenSwitchedToWWANWithIdentifier:)]){
                            [self.curDelegate leOnAlertWhenSwitchedToWWANWithIdentifier:self.self.leIdentifier];
                        }
                    }
                }else{
                    [self pauseDownloadWhenNetworkUnstable];
                    if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnAlertForUnreachableNetworkViaWWANWithIdentifier:)]){
                        [self.curDelegate leOnAlertForUnreachableNetworkViaWWANWithIdentifier:self.self.leIdentifier];
                    }
                }
            }
        }else if(status==AFNetworkReachabilityStatusReachableViaWiFi){
            if(self.leDownloadState==LEResumeBrokenDownloadStatePausedAutomatically||self.leDownloadState==LEResumeBrokenDownloadStateFailed){
                [self leResumeDownload];
            } 
        }else {
            if(self.leDownloadState==LEResumeBrokenDownloadStateDownloading){
                [self pauseDownloadWhenNetworkUnstable];
                if(status==AFNetworkReachabilityStatusNotReachable){
                    if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnAlertForUnreachableNetworkWithIdentifier:)]){
                        [self.curDelegate leOnAlertForUnreachableNetworkWithIdentifier:self.self.leIdentifier];
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
            if(!enable&&self.leDownloadState==LEResumeBrokenDownloadStateDownloading&&[LEResumeBrokenDownloadManager sharedInstance].leSessionManager.reachabilityManager.networkReachabilityStatus==AFNetworkReachabilityStatusReachableViaWWAN){
                [self pauseDownloadWhenNetworkUnstable];
            }else if(self.leDownloadState==LEResumeBrokenDownloadStatePausedAutomatically&&[LEResumeBrokenDownloadManager sharedInstance].leSessionManager.reachabilityManager.isReachableViaWWAN){
                [self leResumeDownload];
            }
        }
        if([userinfo objectForKey:LEPauseDownloadWhenSwitchedToWWAN]){
            BOOL enable=[[userinfo objectForKey:LEPauseDownloadWhenSwitchedToWWAN] boolValue];
            if(enable&&self.leDownloadState==LEResumeBrokenDownloadStateDownloading&&[LEResumeBrokenDownloadManager sharedInstance].leSessionManager.reachabilityManager.networkReachabilityStatus==AFNetworkReachabilityStatusReachableViaWWAN){
                [self pauseDownloadWhenNetworkUnstable];
            }
        }
    }
}
-(void) leDownloadWithURL:(NSString *) url{
    if(url&&url.length>0){
        self.curURL=url;
        self.leDownloadState=LEResumeBrokenDownloadStateWaiting;
        //
        __weak typeof(self) weakSelf=self;
        NSString *urlAsKey=[self.curURL stringByAppendingString:LEDownloadPath];
        NSString *path=[[NSUserDefaults standardUserDefaults] objectForKey:urlAsKey];
        if(path&&path.length>0){
            if([[LEResumeBrokenDownloadManager sharedInstance].leFileManager fileExistsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:path]]){
                if([path hasPrefix:[NSTemporaryDirectory() lastPathComponent]]){//.tmp file found
                    float progress =[[[NSUserDefaults standardUserDefaults] objectForKey:[self.curURL stringByAppendingString:LEDownloadProgress]] floatValue];
                    if(progress>0){
                        [self onDownloadProgressChanged:progress];
                    }
                    NSData *tmpData=[[NSData alloc] initWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:path]];
                    if(tmpData&&tmpData.length>0){
                        NSMutableDictionary *resumeDataDict = [NSMutableDictionary new];
                        NSMutableURLRequest *newResumeRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.curURL]];
                        [newResumeRequest addValue:[NSString stringWithFormat:LEDownloadResumeDataLength,(long)(tmpData.length)] forHTTPHeaderField:LEDownloadHttpFieldRange];
                        NSData *newResumeRequestData = [NSKeyedArchiver archivedDataWithRootObject:newResumeRequest];
                        [resumeDataDict setObject:[NSNumber numberWithInteger:tmpData.length]forKey:LEDownloadKeyBytesReceived];
                        [resumeDataDict setObject:newResumeRequestData forKey:LEDownloadKeyCurrentRequest];
                        [resumeDataDict setObject:[path lastPathComponent]forKey:LEDownloadKeyTempFileName];
                        NSData *resumeData = [NSPropertyListSerialization dataWithPropertyList:resumeDataDict format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
                        [self downLoadWithResumeData:resumeData];
                    }
                }else if([path hasPrefix:curDownloadedFilePath]){//downloaded file found
                    [self onDownloadCompleteWithPath:path Error:nil];
                }else {//curDownloadedFilePath modified maybe
                    path=nil;
                }
            }else{//file not found
                path=nil;
            }
        } 
        if(!path||path.length==0){//new task
            [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:urlAsKey];
            downloadTask = [sessionManager downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.curURL]] progress:^(NSProgress * _Nonnull downloadProgress) {
                [weakSelf onDownloadProgress:downloadProgress];
            } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                return [weakSelf getURLWithResponse:response];
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                [weakSelf onDownloadCompleteWithPath:[weakSelf getURLWithResponse:response].path Error:error];
            }];
            //拉取属性
            unsigned int outCount, i;
            objc_property_t *properties = class_copyPropertyList([downloadTask class], &outCount);
            for (i = 0; i<outCount; i++) {
                objc_property_t property = properties[i];
                const char* char_f =property_getName(property);
                NSString *propertyName = [NSString stringWithUTF8String:char_f];
                if ([LEDownloadFileProperty isEqualToString:propertyName]) {
                    id propertyValue = [downloadTask valueForKey:(NSString *)propertyName];
                    unsigned int downloadFileoutCount, downloadFileIndex;
                    objc_property_t *downloadFileproperties = class_copyPropertyList([propertyValue class], &downloadFileoutCount);
                    for (downloadFileIndex = 0; downloadFileIndex < downloadFileoutCount; downloadFileIndex++) {
                        objc_property_t downloadFileproperty = downloadFileproperties[downloadFileIndex];
                        const char* downloadFilechar_f =property_getName(downloadFileproperty);
                        NSString *downloadFilepropertyName = [NSString stringWithUTF8String:downloadFilechar_f];
                        if([LEDownloadFilePathProperty isEqualToString:downloadFilepropertyName]){
                            id downloadFilepropertyValue = [propertyValue valueForKey:(NSString *)downloadFilepropertyName];
                            if(downloadFilepropertyValue){
                                NSString *path=[[NSTemporaryDirectory() lastPathComponent] stringByAppendingPathComponent:[downloadFilepropertyValue lastPathComponent]];
                                [[NSUserDefaults standardUserDefaults] setValue:path forKey:[self.curURL stringByAppendingString:LEDownloadPath]];
                            }
                            break;
                        }
                    }
                    free(downloadFileproperties);
                }else {
                    continue;
                }
            }
            free(properties);
        }
    }
}
-(void) downLoadWithResumeData:(NSData *) data{
    downloadTask = [sessionManager downloadTaskWithResumeData:data progress:^(NSProgress * _Nonnull downloadProgress) {
        [self onDownloadProgress:downloadProgress];
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [self getURLWithResponse:response];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [self onDownloadCompleteWithPath:[self getURLWithResponse:response].path Error:error];
    }];
}
-(void) lePauseDownload{
    [self pauseDownloadManuallyOrAutomatic:YES];
}
-(void) pauseDownloadWhenNetworkUnstable{
    [self pauseDownloadManuallyOrAutomatic:NO];
}
-(void) pauseDownloadManuallyOrAutomatic:(BOOL) manually{
    if(self.leDownloadState==LEResumeBrokenDownloadStateDownloading){
        self.leDownloadState=manually?LEResumeBrokenDownloadStatePausedManually:LEResumeBrokenDownloadStatePausedAutomatically;
        [downloadTask suspend];
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithFloat:1.0*downloadTask.countOfBytesReceived/downloadTask.countOfBytesExpectedToReceive] forKey:[self.curURL stringByAppendingString:LEDownloadProgress]];
    }
}
-(void) leResumeDownloadViaWWAN{
    [self leResumeDownloadWithUniqueWWANAllowance:[LEResumeBrokenDownloadManager sharedInstance].leSessionManager.reachabilityManager.isReachableViaWWAN];
}
-(void) leResumeDownload{
    [self leResumeDownloadWithUniqueWWANAllowance:[LEResumeBrokenDownloadManager sharedInstance].leAllowNetworkReachViaWWAN&&[LEResumeBrokenDownloadManager sharedInstance].leSessionManager.reachabilityManager.isReachableViaWWAN];
}
-(void) leResumeDownloadWithUniqueWWANAllowance:(BOOL) allow{
    if(self.leDownloadState==LEResumeBrokenDownloadStateDownloading||self.leDownloadState==LEResumeBrokenDownloadStateCompleted){
        return;
    }
    if(!self.curURL||self.curURL.length==0){
        NSLog(@"请检查url是否已经正确设置，如果url无误则建议断点调试downloadTask");
        return;
    }
    BOOL isWifi=[LEResumeBrokenDownloadManager sharedInstance].leSessionManager.reachabilityManager.isReachableViaWiFi;
    BOOL isWWAN=allow;
    if(isWifi||isWWAN){ 
        self.leDownloadState=LEResumeBrokenDownloadStateDownloading; 
        [downloadTask resume];
    }else{
        if(!isWWAN&&[LEResumeBrokenDownloadManager sharedInstance].leSessionManager.reachabilityManager.isReachableViaWWAN){
            if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnAlertForUnreachableNetworkViaWWANWithIdentifier:)]){
                [self.curDelegate leOnAlertForUnreachableNetworkViaWWANWithIdentifier:self.self.leIdentifier];
            }
        }else {
            if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnAlertForUnreachableNetworkWithIdentifier:)]){
                [self.curDelegate leOnAlertForUnreachableNetworkWithIdentifier:self.self.leIdentifier];
            }
        }
    }
}
-(NSURL *) getURLWithResponse:(NSURLResponse *) response{
    return [NSURL fileURLWithPath:[[NSHomeDirectory() stringByAppendingPathComponent:curDownloadedFilePath] stringByAppendingPathComponent:response.suggestedFilename]];
}
-(void) onDownloadProgress:(NSProgress * ) downloadProgress{
    [self onDownloadProgressChanged:1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount];
}
-(void) onDownloadProgressChanged:(float) downloadProgress{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leDownloadProgress:Identifier:)]){  
            [self.curDelegate leDownloadProgress:downloadProgress Identifier:self.self.leIdentifier];
        }
    });
}
-(void) onDownloadCompleteWithPath:(NSString *) filePath Error:(NSError *) error{
    if(error){
        if(error.code!=NSURLErrorCancelled){
            self.leDownloadState=LEResumeBrokenDownloadStateFailed;
        }
    }else{
        self.leDownloadState=LEResumeBrokenDownloadStateCompleted;
        [[NSUserDefaults standardUserDefaults] setValue:filePath.lastPathComponent forKey:[self.curURL stringByAppendingString:LEDownloadSuggestedFilename]];
        [[NSUserDefaults standardUserDefaults] setValue:[curDownloadedFilePath stringByAppendingPathComponent:filePath.lastPathComponent] forKey:[self.curURL stringByAppendingString:LEDownloadPath]];
        downloadTask=nil;
    }
    if(self.leDownloadState!=LEResumeBrokenDownloadStatePausedAutomatically&&self.leDownloadState!=LEResumeBrokenDownloadStatePausedManually){
        if(self.curDelegate&&[self.curDelegate respondsToSelector:@selector(leOnDownloadCompletedWithPath:Error:Identifier:)]){
            [self.curDelegate leOnDownloadCompletedWithPath:filePath Error:error Identifier:self.self.leIdentifier];
        }
    }
}
@end
