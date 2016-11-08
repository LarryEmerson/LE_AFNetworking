//
//  LEResumeBrokenDownload.h
//  https://github.com/LarryEmerson/LE_AFNetworking
//
//  -断点续传下载器：任务新建后即会在tmp文件夹生成对应的临时文件，断点续传的主要原理就是保存tmp文件的路径，下次重新新建任务时，如果存在tmp文件则采用续传的方式建立任务，否则正常建立任务。
//  -runtime获取tmp路径的思想来源于http://blog.csdn.net/yan_daoqiu/article/details/50469601
//  -下载进度只会在任务暂停时才会记录，用于续传之前显示的进度
//  -如需支持后台下载，需要使用接口initWithDelegate:Identifier:SessionConfiguration:，自定义config实现后台下载。
//  -可以全局设定下载器是否允许蜂窝网络，是否在切换到蜂窝网络时暂停所有下载。不能完全支持后台下载的情况。Check discussion of property discretionary below
//  -前台，可以强制某一个任务绕过蜂窝网络的禁止，执行下载的流程
//  -网络断开提醒、切换蜂窝网络提醒、蜂窝网络被禁用提醒，都是针对于某一个下载任务的。多个任务存在的情况下，需要处理好多个任务同时受到提醒时的兼容处理（比如网络断开提示窗只能出现一次，蜂窝网络被禁用提醒，只能当前活动界面做反馈）
//  -对url中无后缀的情况作了补救，代价是下载完的内容的读取，必须使用下载器中的leDownloadedFilePath来作为路径。原因是下载完成的文件都是带有后缀的，如果url中无后缀，跳过下载器的leDownloadedFilePath，而使用url在拼接路径，会因为无后缀而找不到已下载完成的文件
//
//  Created by emerson larry on 2016/10/11.
//
// -for the discretionary property:When this flag is set, transfers are more likely to occur when plugged into power and on Wi-Fi. This value is false by default. This property is used only if a session’s configuration object was originally constructed by calling the backgroundSessionConfiguration: method, and only for tasks started while the app is in the foreground. If a task is started while the app is in the background, that task is treated as though discretionary were true, regardless of the actual value of this property. For sessions created based on other configurations, this property is ignored.

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <AFNetworking/AFNetworking.h>
/** 下载状态*/
typedef NS_ENUM(NSUInteger, LEResumeBrokenDownloadState) {
    LEResumeBrokenDownloadStateNone =0,                     //0 default 初始状态
    LEResumeBrokenDownloadStateWaiting,                     //1 before start downloading 下载等待
    LEResumeBrokenDownloadStateDownloading,                 //2 downloading 下载中
    LEResumeBrokenDownloadStatePausedManually,              //3 paused manually 手动暂停
    LEResumeBrokenDownloadStatePausedAutomatically,         //4 paused 自动暂停触发情况：网络断开、设置禁用蜂窝、设置了切换蜂窝自动暂停，监听到蜂窝开启且设置了禁用蜂窝或切换蜂窝自动暂停、下载失败
    LEResumeBrokenDownloadStateCompleted,                   //5 download completed 下载完成
    LEResumeBrokenDownloadStateFailed,                      //6 download failed 下载失败
};

#pragma mark Protocol
@protocol LEResumeBrokenDownloadDelegate <NSObject>
/**
 * @brief 下载完成或者失败时回调:error=nil表示成功，否则失败。成功时filePath 表示已下载完成的文件路径。identifier来源于任务初始化用于区分多个任务。
 */
-(void) leOnDownloadCompletedWithPath:(NSString *) filePath Error:(NSError *) error Identifier:(NSString *) identifier;
@optional
/**
 * @brief 下载进度回调 identifier来源于任务初始化用于区分多个任务。
 */
-(void) leDownloadProgress:(float) progress Identifier:(NSString *) identifier;
/**
 * @brief 当前网络切换到 蜂窝移动网络时回调 identifier来源于任务初始化用于区分多个任务。
 */
-(void) leOnAlertWhenSwitchedToWWANWithIdentifier:(NSString *) identifier;
/**
 * @brief 当前网络不可用时回调 identifier来源于任务初始化用于区分多个任务。
 */
-(void) leOnAlertForUnreachableNetworkWithIdentifier:(NSString *) identifier;
/**
 * @brief 当前 蜂窝移动网络已打开，但是设置了禁用而无法使用时回调 identifier来源于任务初始化用于区分多个任务。
 */
-(void) leOnAlertForUnreachableNetworkViaWWANWithIdentifier:(NSString *) identifier;
/**
 * @brief 当前下载状态切换时回调，主要用于UI状态更新 identifier来源于任务初始化用于区分多个任务。
 */
-(void) leOnDownloadStateChanged:(LEResumeBrokenDownloadState) state Identifier:(NSString *) identifier;

@end

#pragma mark Downloader
@interface LEResumeBrokenDownload : NSObject
/**
 * @brief 下载器状态
 */
@property (nonatomic, readonly) LEResumeBrokenDownloadState leDownloadState;
/**
 * @brief 下载器状态特有标识，用于区分多个下载器
 */
@property (nonatomic, readonly) NSString *leIdentifier;
/**
 * @brief 初始化
 Step 1 : 初始化 initWithDelegate:Identifier: 或者initWithDelegate:Identifier:SessionConfiguration:(用于自定义，可实现后台下载)
 Step 2 ：自定义路径 leSwitchPathDirectoryFromCacheToDocument:SubPathComponent:(可以不设置启用默认配置)
 Step 3 ：设置URL leDownloadWithURL:
 Step 4 ：开始下载 leResumeDownload
 */
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier;
/** 自定义SessionConfig的初始化*/
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier SessionConfiguration:(NSURLSessionConfiguration *) config;
/**
 * @brief 快速初始化，完成后自动下载
 */
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier URL:(NSString *) url;
/**
 * @brief 自定义下载路径，注意在设定URL之前有效，URL设定之后设定会造成已下载内容的丢失或其他问题。未配置默认使用[LEResumeBrokenDownloadManager sharedInstance].downloadedFilePath（Cache）
 * isSwitch=YES表示使用Document否则使用Cache，component可以为nil可以为多级
 */
-(void) leSwitchPathDirectoryFromCacheToDocument:(BOOL) isSwitch SubPathComponent:(NSString *) component;//default
/**
 * @brief 设置下载URL，不会自动下载
 */
-(void) leDownloadWithURL:(NSString *) url;
/**
 * @brief 手动暂停下载，与自动暂停下载不同，对应于LEResumeBrokenDownloadStatePausedManually。
 * 自动暂停的详情，请移步LEResumeBrokenDownloadStatePausedAutomatically
 */
-(void) lePauseDownload;
/**
 * @brief 运行下载
 */
-(void) leResumeDownload;
/**
 * @brief 继续下载且绕过禁用蜂窝移动网络的设置。如果禁用了App使用蜂窝移动网络，但是又需要对当前下载器放行，则调用此接口
 */
-(void) leResumeDownloadViaWWAN;//compatible with leOnAlertForUnreachableNetworkViaWWANWithIdentifier(allowNetworkReachViaWWAN=NO, isReachableViaWWAN=YES)
/**
 * @brief 返回文件路径
 * 根据已设定的URL，返回当前文件的文件名称。
 * 如果文件已经完成下载，则文件名称会包含后缀。
 * 如果未完成下载文件名称是否包含后缀由URL中是否存在后缀而决定。
 * 建议读取文件时，使此接口获取文件路径。如果URL中没有后缀，使用URL来拼接路径就没有后缀，与实际已经下载的文件名称存在后缀有冲突
 */
-(NSString *) leDownloadedFilePath;

@end
#pragma mark Download Manager
@interface LEResumeBrokenDownloadManager : NSObject
+ (LEResumeBrokenDownloadManager *) sharedInstance;
/**
 * @brief 设置是否允许使用 蜂窝移动网络（3G/4G）
 */
@property (nonatomic) BOOL leAllowNetworkReachViaWWAN;//default YES
-(void) leSetAllowNetworkReachViaWWAN:(BOOL)allowNetworkReachViaWWAN;
/**
 * @brief 是否当切换到 蜂窝移动网络 时，自动暂停正在运行的下载
 */
@property (nonatomic) BOOL lePauseDownloadWhenSwitchedToWWAN;//default YES;
-(void) leSetPauseDownloadWhenSwitchedToWWAN:(BOOL)pauseDownloadWhenSwitchedToWWAN;
/**
 * @brief 默认常驻内存的全局Session
 */
@property (nonatomic,readonly) AFURLSessionManager *leSessionManager;
/**
 * @brief 默认常驻内存的全局defaultSessionConfiguration
 */
@property (nonatomic,readonly) NSURLSessionConfiguration *leSessionConfiguration;
/**
 * @brief 默认常驻内存的全局文件管理器
 */
@property (nonatomic,readonly) NSFileManager *leFileManager;

/**
 * @brief 获取下载文件的统一路径
 */
@property (nonatomic) NSString *leDownloadedFilePathDirectory;//default NSCachesDirectory
/**
 * @brief 设置下载文件的统一路径，无法影响已经创建的下载任务。isSwitch=YES表示使用Document否则使用Cache，component可以为nil可以为多级
 */
-(void) leSwitchPathDirectoryFromCacheToDocument:(BOOL) isSwitch SubPathComponent:(NSString *) component;
/**
 * @brief manager必要的释放（停止网络状态监测）
 */
-(void) leReleaseManager;

/** 该接口生成的下载器由manager管理，避免重复下载且相同url对应唯一一个下载器，回调使用最新的delegate */
-(LEResumeBrokenDownload *) leDownloadWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate URL:(NSString *) url;
/** 是否存在url对应的下载器*/
-(BOOL) leIsDownloadExisted:(NSString *) url;
/** 根据url获取download*/
-(LEResumeBrokenDownload *) leGetDownloadWithUrl:(NSString *) url;
@end