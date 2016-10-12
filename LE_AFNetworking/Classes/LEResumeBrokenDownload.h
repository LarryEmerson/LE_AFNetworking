//
//  LEResumeBrokenDownload.h
//  Pods
//
//  Created by emerson larry on 2016/10/11.
//
//

#import <Foundation/Foundation.h>
#import "AFNetworking.h"

typedef NS_ENUM(NSUInteger, LEResumeBrokenDownloadState) {
    LEResumeBrokenDownloadStateNone=0,           /** default */
    LEResumeBrokenDownloadStateWaiting,         /** before start downloading **/
    LEResumeBrokenDownloadStateDownloading,    /** downloading */
    LEResumeBrokenDownloadStatePaused,       /** paused */
    LEResumeBrokenDownloadStateCompleted,      /** download completed */
    LEResumeBrokenDownloadStateFailed          /** download failed */
};

#define LEAllowNetworkReachViaWWAN @"LEAllowNetworkReachViaWWAN"
#define LEPauseDownloadWhenSwitchedToWWAN @"LEPauseDownloadWhenSwitchedToWWAN"

#pragma mark Protocol
@protocol LEResumeBrokenDownloadDelegate <NSObject>
-(void) leDownloadProgress:(float) progress Identifier:(NSString *) identifier;
-(void) leOnDownloadCompletedWithResponse:(NSURLResponse *) response Path:(NSURL *) filePath Error:(NSError *) error Identifier:(NSString *) identifier;
-(void) leOnAlertWhenSwitchedToWWANWithIdentifier:(NSString *) identifier; 
@end
#pragma mark Download Manager
@interface LEResumeBrokenDownloadManager : NSObject
+ (LEResumeBrokenDownloadManager *) sharedInstance;
@property (nonatomic) BOOL allowNetworkReachViaWWAN;//default YES
@property (nonatomic) BOOL pauseDownloadWhenSwitchedToWWAN;//default YES;
@property (nonatomic) NSString *downloadedFilePath;//default NSCachesDirectory
@end
#pragma mark Downloader
@interface LEResumeBrokenDownload : NSObject
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier;
-(void) leSetDownloadedFilePath:(NSString *) path;//default [LEResumeBrokenDownloadManager sharedInstance].downloadedFilePath
-(void) leDownloadWithURL:(NSString *) url;
-(void) lePauseDownload;
-(void) leResumeDownload;
//
-(id) initWithDelegate:(id<LEResumeBrokenDownloadDelegate>) delegate Identifier:(NSString *) identifier URL:(NSString *) url;
@end
