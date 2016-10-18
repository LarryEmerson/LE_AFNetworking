//
//  ViewController.m
//  LE_AFNetworking_Test
//
//  Created by emerson larry on 16/7/5.
//  Copyright © 2016年 LarryEmerson. All rights reserved.
//

#import "ViewController.h"
#import "LE_AFNetworkings.h"
//数据模型的类可以使用工具JsonToObjCClassFile 一键生成。https://github.com/LarryEmerson/JsonToObjCClassFile
@interface DM_Test_Images :LE_DataModel
@property (nonatomic , strong) NSNumber              * timestamp;
@property (nonatomic , strong) NSString              * imagename;
@end
@interface DM_Test_Messages_Details_Extra :LE_DataModel
@property (nonatomic , strong) NSString              * a;
@property (nonatomic , strong) NSNumber              * c;
@property (nonatomic , strong) NSString              * d;
@end
@interface DM_Test_Messages_Details :LE_DataModel
@property (nonatomic , strong) NSString              * content;
@property (nonatomic , strong) DM_Test_Messages_Details_Extra              * extra;
@end
@interface DM_Test_Messages :LE_DataModel
@property (nonatomic , strong) NSString              * message;
@property (nonatomic , strong) NSArray               * details;
@end
@interface DM_Test :LE_DataModel
@property (nonatomic , strong) NSArray               * images;
@property (nonatomic , strong) NSArray               * messages;
@end

@implementation DM_Test_Images @end
@implementation DM_Test_Messages_Details_Extra @end
@implementation DM_Test_Messages_Details @end
@implementation DM_Test_Messages @end
@implementation DM_Test @end


//#define DownloadTest @"http://120.25.226.186:32812/resources/videos/minion_01.mp4"
//#define DownloadTest @"http://occqxazgx.bkt.clouddn.com/lsldOaaukGErLH7nb1Of1PFu9VjE"
#define DownloadTest @"http://files.git.oschina.net/group1/M00/00/7B/PaAvDFf8q9-AcIKkAXxIN9d8yJg332.pdf"
@interface ViewController ()<LE_AFNetworkingDelegate,LENavigationDelegate,LEResumeBrokenDownloadDelegate>
@end
@implementation ViewController{
    LEBaseView *view;
    //
    LEResumeBrokenDownload *curDownloader;
    UISwitch *switchWWAN;
    UISwitch *switchPause;
    UILabel *labelProgress;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //    [self onTestDataModel];
    [[LE_AFNetworking sharedInstance] leSetEnableDebug:YES];
    [[LE_AFNetworking sharedInstance] leSetEnableResponseDebug:YES];
    [[LE_AFNetworking sharedInstance] leSetEnableResponseWithJsonString:YES];
    view=[[LEBaseView alloc] initWithViewController:self];
    LEBaseNavigation *navi=[[LEBaseNavigation alloc] initWithDelegate:self ViewController:self SuperView:view Offset:LEStatusBarHeight BackgroundImage:[LEColorWhite leImageStrechedFromSizeOne] TitleColor:LEColorTextBlack LeftItemImage:nil];
    [navi leSetNavigationTitle:@"LE_AFNetworking"];
    [navi leSetRightNavigationItemWith:@"测试" Image:nil];
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"pdfspath"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

}

-(void) leNavigationRightButtonTapped{
//    [self onTestLE_AFNetworking];
    [self onTestResumeBrokenDownload];
}
//===========================测试 LEResumeBrokenDownload
-(void) onTestResumeBrokenDownloadInits{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"pdfspath"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    [[LEResumeBrokenDownloadManager sharedInstance] leSwitchPathDirectoryFromCacheToDocument:YES SubPathComponent:dataPath.lastPathComponent];
    LELogObject([[documentsDirectory lastPathComponent] stringByAppendingPathComponent:dataPath.lastPathComponent])
//    [LEResumeBrokenDownloadManager sharedInstance].bytesForPeriodicDataWriting=1024*1024;
    // 
    //
    labelProgress=[UILabel new];
    switchWWAN=[UISwitch new];
    switchPause=[UISwitch new];
    [view.leViewBelowCustomizedNavigation addSubview:labelProgress];
    [view.leViewBelowCustomizedNavigation addSubview:switchWWAN];
    [view.leViewBelowCustomizedNavigation addSubview:switchPause];
    [switchWWAN setFrame:CGRectMake(0, 0, switchWWAN.bounds.size.width, switchWWAN.bounds.size.height)];
    [switchPause setFrame:CGRectMake(switchWWAN.bounds.size.width, 0, switchPause.bounds.size.width, switchPause.bounds.size.height)];
    [labelProgress setFrame:CGRectMake(switchWWAN.bounds.size.width+switchPause.bounds.size.width, 0, LESCREEN_WIDTH-switchWWAN.bounds.size.width-switchPause.bounds.size.width, switchWWAN.bounds.size.height)];
    //
    [switchWWAN addTarget:self action:@selector(onDownloadSwitch:) forControlEvents:UIControlEventTouchUpInside];
    [LEResumeBrokenDownloadManager sharedInstance].leAllowNetworkReachViaWWAN=switchWWAN.on;
    [LEResumeBrokenDownloadManager sharedInstance].lePauseDownloadWhenSwitchedToWWAN=switchPause.on;
    LELog(@"WWAN:%@ , Pause:%@",switchWWAN.on?@"ON":@"OFF",switchPause.on?@"ON":@"OFF")
    UILabel *labelWWAN=[UILabel new].leSuperView(view.leViewBelowCustomizedNavigation).leAnchor(LEAnchorOutsideBottomCenter).leRelativeView(switchWWAN).leAutoLayout.leType;
    [labelWWAN.leText(@"WWAN").leAlignment(NSTextAlignmentCenter) leLabelLayout];
    UILabel *labelPause=[UILabel new].leSuperView(view.leViewBelowCustomizedNavigation).leAnchor(LEAnchorOutsideBottomCenter).leRelativeView(switchPause).leAutoLayout.leType;
    [labelPause.leText(@"Pause").leAlignment(NSTextAlignmentCenter) leLabelLayout];
    
}
-(void) onDownloadSwitch:(UISwitch *) swi{
    if([swi isEqual:switchWWAN]){
        [LEResumeBrokenDownloadManager sharedInstance].leAllowNetworkReachViaWWAN=swi.on;
    }else if([swi isEqual:switchPause]){
        [LEResumeBrokenDownloadManager sharedInstance].lePauseDownloadWhenSwitchedToWWAN=swi.on;
    }
    LELog(@"WWAN:%@ , Pause:%@",switchWWAN.on?@"ON":@"OFF",switchPause.on?@"ON":@"OFF")
}
-(void) onTestResumeBrokenDownload{
    if(!curDownloader){
        [self onTestResumeBrokenDownloadInits];
        int rnd=arc4random()%10+1;
        rnd=1;
//        curDownloader=[[LEResumeBrokenDownload alloc] initWithDelegate:self Identifier:nil SessionConfiguration:[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"back"]];
//        [curDownloader leDownloadWithURL:[NSString stringWithFormat:@"http://120.25.226.186:32812/resources/videos/minion_%02d.mp4",rnd]];
//        [curDownloader leResumeDownload];
        
        curDownloader=[[LEResumeBrokenDownload alloc] initWithDelegate:self Identifier:nil];
        [curDownloader leDownloadWithURL:[NSString stringWithFormat:@"http://120.25.226.186:32812/resources/videos/minion_%02d.mp4",rnd]];
        
//        LEResumeBrokenDownload *d=[[LEResumeBrokenDownload alloc] ini];
//        LEResumeBrokenDownload *downloader=[[LEResumeBrokenDownload alloc] initWithDelegate:self Identifier:nil URL:@""];//快速初始化，初始化后立即下载
//        [downloader lePauseDownload];//暂停
//        [downloader leResumeDownload];//继续
//        if(downloader.leDownloadState==LEResumeBrokenDownloadStateCompleted){//完成下载后打开文件
//            NSString *path=[downloader leDownloadedFilePath];
//            NSLog(@"open file at %@",path);
//        }
    }else{ 
        switch (curDownloader.leDownloadState) {
            case LEResumeBrokenDownloadStateDownloading:
                [curDownloader lePauseDownload];
                break;
            case LEResumeBrokenDownloadStateCompleted:
                LELog(@"open")
                break;
            case LEResumeBrokenDownloadStateNone:
            case LEResumeBrokenDownloadStateWaiting:
            case LEResumeBrokenDownloadStatePausedAutomatically:
            case LEResumeBrokenDownloadStatePausedManually:
            case LEResumeBrokenDownloadStateFailed:
                [curDownloader leResumeDownload];
                break;
            default:
                break;
        }
    }
}
-(void) leOnDownloadCompletedWithPath:(NSString *)filePath Error:(NSError *)error Identifier:(NSString *)identifier{
    LELogObject(filePath)
}
-(void) leOnDownloadStateChanged:(LEResumeBrokenDownloadState)state Identifier:(NSString *)identifier{
    LELog(@"LEResumeBrokenDownloadState %zd",state)
}
-(void) leDownloadProgress:(float)progress Identifier:(NSString *)identifier{
//    LELog(@"progress %f",progress)
    [labelProgress setText:[NSString stringWithFormat:@"下载进度：%f",progress]];
}
-(void) leOnAlertForUnreachableNetworkWithIdentifier:(NSString *)identifier{
    LELogFunc
}
-(void) leOnAlertWhenSwitchedToWWANWithIdentifier:(NSString *)identifier{
    LELogFunc
}





















//===========================测试 LE_AFNetworking
-(void) onTestLE_AFNetworking{
    [[LE_AFNetworking sharedInstance] leRequestWithApi:@"http://git.oschina.net/larryemerson/ybs/raw/master/README.md" uri:@"" httpHead:nil requestType:LERequestTypeGet parameter:nil delegate:self];
}
-(void) leRequest:(LE_AFNetworkingRequestObject *)request ResponedWith:(NSDictionary *)response{
    LELogObject(response);
    [self onTestDataModelWithData:[response objectForKey:@"data"]];
}
-(void) leRequest:(LE_AFNetworkingRequestObject *)request FailedWithStatusCode:(int)statusCode Message:(NSString *)message{
    LELogObject(message);
}
//===========================测试 数据模型 复杂的内嵌数组Json
-(void) onTestDataModel{
    NSString *data=@"{\"id\":14,\"images\":[{\"id\":42,\"imagename\":\"moment_2_1457332231368\",\"timestamp\":1457332149},{\"id\":44,\"imagename\":\"moment_2_1457332231355\",\"timestamp\":1457332145}],\"messages\":[{\"id\":42,\"message\":\"iOS\\u56de\\u590d\\u65b0\\u8bc4\\u8bba\\u7684\\u56de\\u590d\",\"details\":[{\"id\":42,\"content\":\"content\",\"extra\":{\"a\":\"b\",\"c\":44,\"d\":\"e\"}},{\"id\":42,\"content\":\"content\"}]},{\"id\":42,\"message\":\"\\u56de\\u590d\\u65b0\\u8bc4\\u8bba\",\"details\":[{\"id\":42,\"content\":\"content\"},{\"id\":42,\"content\":\"content\",\"extra\":{\"a\":\"b\",\"c\":44,\"d\":\"e\"}}]}]}";
    //    NSArray *array=[LE_DataModel initWithDataSources:[data leJSONValue] ClassName:@"DM_Test"];
    [self onTestDataModelWithData:[data leJSONValue]];
}
-(void) onTestDataModelWithData:(NSDictionary *) data{
    DM_Test *dmTest=[[DM_Test alloc] initWithDataSource:data];
    if(dmTest){
        for (NSInteger i=0; i<dmTest.images.count; i++) {
            DM_Test_Images *image=[dmTest.images objectAtIndex:i];
            LELog(@"dmTest.image.timestamp=%@",image.timestamp);
            LELog(@"dmTest.image.imagename=%@",image.imagename);
        }
        for (NSInteger i=0; i<dmTest.messages.count; i++) {
            DM_Test_Messages *msg=[dmTest.messages objectAtIndex:i];
            LELog(@"dmTest.message.message=%@",msg.message);
            for (NSInteger j=0; j<msg.details.count; ++j) {
                DM_Test_Messages_Details *details=[msg.details objectAtIndex:i];
                LELog(@"dmTest.message.details.content=%@",details.content);
                LELog(@"dmTest.message.details.extra.a=%@",details.extra.a);
                LELog(@"dmTest.message.details.extra.c=%@",details.extra.c);
                LELog(@"dmTest.message.details.extra.d=%@",details.extra.d);
            }
        }
    }
}
@end
