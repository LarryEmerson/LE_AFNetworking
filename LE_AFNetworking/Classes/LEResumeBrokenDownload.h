//
//  LEResumeBrokenDownload.h
//  https://github.com/LarryEmerson/LE_AFNetworking
//  弱断点续传下载器：如果强行关闭应用，当前正在下载的任务进度是无法保存的，只会保留上次下载任务暂停时的进度。下载任务完成前的进度保存都需要通过暂停下载或者在界面关闭前暂停下载来实现。
//  下载过程中，正在下载内容会产生容量占用，同时上次保存的下载任务进度文件也会产生容量占用，如果下载的任务比较大，会出现因为容量占用太大而造成无法下载或者无法保存已下载内容的情况。
//  不支持后台下载。应用前台状态下，在任意界面中创建的下载任务，在没有被暂停的前提下，都会持续下载直至下载完成。
//  可以全局设定下载器是否允许蜂窝网络，是否在切换到蜂窝网络时暂停所有下载
//  可以强制某一个任务绕过蜂窝网络的禁止，执行下载的流程
//  网络断开提醒、切换蜂窝网络提醒、蜂窝网络被禁用提醒，都是针对于某一个下载任务的。多个任务存在的情况下，需要处理好多个任务同时受到提醒时的兼容处理（比如网络断开提示窗只能出现一次，蜂窝网络被禁用提醒，只能当前活动界面做反馈）
//  对url中无后缀的情况作了补救，代价是下载完的内容的读取，必须使用下载器中的leDownloadedFilePath来作为路径。原因是下载完成的文件都是带有后缀的，如果url中无后缀，跳过下载器的leDownloadedFilePath，而使用url在拼接路径，会因为无后缀而找不到已下载完成的文件
//
//  Created by emerson larry on 2016/10/11.
//
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h" 
typedef NS_ENUM(NSUInteger, LEResumeBrokenDownloadState) {
    LEResumeBrokenDownloadStateNone             =0,     /** default */
    LEResumeBrokenDownloadStateWaiting          =1,     /** before start downloading **/
    LEResumeBrokenDownloadStateDownloading      =2,     /** downloading */
    LEResumeBrokenDownloadStatePaused           =3,     /** paused 自动暂停触发情况：网络断开、设置禁用蜂窝、设置了切换蜂窝自动暂停，监听到蜂窝开启且设置了禁用蜂窝或切换蜂窝自动暂停、下载失败*/
    LEResumeBrokenDownloadStatePausedManually   =4,     /** paused manually 手动暂停*/
    LEResumeBrokenDownloadStateCompleted        =5,     /** download completed */
    LEResumeBrokenDownloadStateFailed           =6      /** download failed */
};
#define LEDownloadSuffix @".ledn"
#define LEDownloadProgressKey @"leprogress"
#define LEDownloadSuggestedFilename @"lesuggestedname"
#define LEAllowNetworkReachViaWWAN @"LEAllowNetworkReachViaWWAN"
#define LEPauseDownloadWhenSwitchedToWWAN @"LEPauseDownloadWhenSwitchedToWWAN"

#pragma mark Protocol
@protocol LEResumeBrokenDownloadDelegate <NSObject>
/*
 * @brief 下载完成或者失败时回调
 */
-(void) leOnDownloadCompletedWithPath:(NSString *) filePath Error:(NSError *) error Identifier:(NSString *) identifier;
@optional
/*
 * @brief 下载进度回调
 */
-(void) leDownloadProgress:(float) progress Identifier:(NSString *) identifier;
/*
 * @brief 当前网络切换到 蜂窝移动网络时回调
 */
-(void) leOnAlertWhenSwitchedToWWANWithIdentifier:(NSString *) identifier;
/*
 * @brief 当前网络不可用时回调
 */
-(void) leOnAlertForUnreachableNetworkWithIdentifier:(NSString *) identifier;
/*
 * @brief 当前 蜂窝移动网络已打开，但是设置了禁用而无法使用时回调
 */
-(void) leOnAlertForUnreachableNetworkViaWWANWithIdentifier:(NSString *) identifier;
/*
 * @brief 当前下载状态切换时回调，主要用于UI状态更新
 */
-(void) leOnDownloadStateChanged:(LEResumeBrokenDownloadState) state Identifier:(NSString *) identifier;
@end
#pragma mark Download Manager
@interface LEResumeBrokenDownloadManager : NSObject
+ (LEResumeBrokenDownloadManager *) sharedInstance;
/*
 * @brief 设置是否允许使用 蜂窝移动网络（3G/4G）
 */
@property (nonatomic) BOOL allowNetworkReachViaWWAN;//default YES
/*
 * @brief 是否当切换到 蜂窝移动网络 时，自动暂停正在运行的下载
 */
@property (nonatomic) BOOL pauseDownloadWhenSwitchedToWWAN;//default YES;
/*
 * @brief 设置下载文件的统一路径，无法影响已经创建的下载任务
 */
@property (nonatomic) NSString *downloadedFilePath;//default NSCachesDirectory
@property (nonatomic,readonly) AFURLSessionManager *sessionManager;
@property (nonatomic,readonly) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic,readonly) NSFileManager *fileManager;
-(void) releaseManager;
@end
#pragma mark Downloader
@interface LEResumeBrokenDownload : NSObject
/*
 * @brief 下载器状态
 */
@property (nonatomic, readonly) LEResumeBrokenDownloadState curDownloadState;
/*
 * @brief 下载器状态特有标识，用于区分多个下载器
 */
@property (nonatomic, readonly) NSString *curIdentifier;
/*
 * @brief 初始化
 * Step 1 : 初始化 initWithDelegate:Identifier:
 * Step 2 ：自定义路径 leSetDownloadedFilePath:
 * Step 3 ：设置URL leDownloadWithURL:
 * Step 4 ：开始下载 leResumeDownload
 */
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier;
/*
 * @brief 自定义下载路径，注意在设定URL之前有效，URL设定之后设定会造成已下载内容的丢失或其他问题
 */
-(void) leSetDownloadedFilePath:(NSString *) path;//default [LEResumeBrokenDownloadManager sharedInstance].downloadedFilePath
/*
 * @brief 设置下载URL，不会自动下载
 */
-(void) leDownloadWithURL:(NSString *) url;
/*
 * @brief 手动暂停下载，与自动暂停下载不同，对应于LEResumeBrokenDownloadStatePausedManually。
 * 自动暂停的详情，请移步LEResumeBrokenDownloadStatePaused
 */
-(void) lePauseDownload;
/*
 * @brief 运行下载
 */
-(void) leResumeDownload;
/*
 * @brief 继续下载且绕过禁用蜂窝移动网络的设置。如果禁用了App使用蜂窝移动网络，但是又需要对当前下载器放行，则调用此接口
 */
-(void) leResumeDownloadViaWWAN;//compatible with leOnAlertForUnreachableNetworkViaWWANWithIdentifier(allowNetworkReachViaWWAN=NO, isReachableViaWWAN=YES)
/*
 * @brief 返回文件路径
 * 根据已设定的URL，返回当前文件的文件名称。
 * 如果文件已经完成下载，则文件名称会包含后缀。
 * 如果未完成下载文件名称是否包含后缀由URL中是否存在后缀而决定。
 * 建议读取文件时，使此接口获取文件路径。如果URL中没有后缀，使用URL来拼接路径就没有后缀，与实际已经下载的文件名称存在后缀有冲突
 */
-(NSString *) leDownloadedFilePath;
/*
 * @brief 初始化后会自动运行下载
 */
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier URL:(NSString *) url;
@end
