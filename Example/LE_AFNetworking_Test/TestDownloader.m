//
//  TestDownloader.m
//  LE_AFNetworking
//
//  Created by emerson larry on 2016/11/8.
//  Copyright © 2016年 LarryEmerson. All rights reserved.
//

#import "TestDownloader.h"
static int Tags=1;
@interface TestDownloaderCell : LEBaseTableViewDisplayCell<LEResumeBrokenDownloadDelegate>
@end
@implementation TestDownloaderCell{
    UILabel *labelIndex;
    UILabel *labelProgress;
    UIButton *btn;
    LEResumeBrokenDownload *curDownloader;
}
-(void) leExtraInits{
    self.tag=Tags++;
    labelIndex =[UILabel new].leSuperView(self).leAnchor(LEAnchorInsideLeftCenter).leOffset(CGPointMake(LELayoutSideSpace, 0)).leAutoLayout;
    labelProgress=[UILabel new].leSuperView(self).leRelativeView(labelIndex).leOffset(CGPointMake(LELayoutSideSpace, 0)).leAnchor(LEAnchorOutsideRightCenter).leAutoLayout;
    btn=[UIButton new].leSuperView(self).leAnchor(LEAnchorInsideRightCenter).leOffset(CGPointMake(-LELayoutSideSpace, 0)).leTapEvent(@selector(onTap),self).leBackgroundImage([LEColorBlue leImageStrechedFromSizeOne]).leColor(LEColorWhite).leText(@"创建").leAutoLayout; 
    [UIButton new].leSuperView(self).leRelativeView(btn).leAnchor(LEAnchorOutsideLeftCenter).leOffset(CGPointMake(-LELayoutSideSpace, 0)).leTapEvent(@selector(onRelease),self).leBackgroundImage([LEColorRed leImageStrechedFromSizeOne]).leColor(LEColorWhite).leText(@"释放").leAutoLayout;
}
-(void) onRelease{
    [curDownloader leRelease];
}
-(void) onTap{
    switch (curDownloader.leDownloadState) {
        case LEResumeBrokenDownloadStateDownloading:
            [curDownloader lePauseDownload];
            break;
        case LEResumeBrokenDownloadStateCompleted:
            LELog(@"下载完成 文件路径：%@",curDownloader.leDownloadedFilePath)
            
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
#pragma mark delegate
-(void) leDownloadProgress:(float)progress Identifier:(NSString *)identifier{
    [labelProgress leSetText:[NSString stringWithFormat:@"%@----%f%%",curDownloader.leDownloadedFilePath.lastPathComponent,progress]];
}
-(void) leOnDownloadStateChanged:(LEResumeBrokenDownloadState)state Identifier:(NSString *)identifier{
    switch (state) {
        case LEResumeBrokenDownloadStateDownloading:
            btn=btn.leText(@"暂停").leAutoLayout;
            break;
        case LEResumeBrokenDownloadStateCompleted:
            btn=btn.leText(@"打开").leAutoLayout;
            break;
        case LEResumeBrokenDownloadStateNone:
        case LEResumeBrokenDownloadStateWaiting:
        case LEResumeBrokenDownloadStatePausedAutomatically:
        case LEResumeBrokenDownloadStatePausedManually:
        case LEResumeBrokenDownloadStateFailed:
            btn=btn.leText(@"下载").leAutoLayout;
            break;
        default:
            break;
    }
    
}
-(void) leOnDownloadCompletedWithPath:(NSString *)filePath Error:(NSError *)error Identifier:(NSString *)identifier{
    [labelProgress leSetText:[NSString stringWithFormat:@"%@",filePath.lastPathComponent]];
}
-(void) leOnIndexSet{
    [labelIndex leSetText:LEIntegerToString(self.leIndexPath.row+1)];
    NSString *url=[NSString stringWithFormat:@"http://120.25.226.186:32812/resources/videos/minion_%02d.mp4",(int)(self.leIndexPath.row%10+1)];
    if([[LEResumeBrokenDownloadManager sharedInstance] leIsDownloadExisted:url]){
        if(!curDownloader){
            [labelProgress leSetText:[NSString stringWithFormat:@"检测到已存在下载：%@",url.lastPathComponent]];
        }
    }else{
        curDownloader=[[LEResumeBrokenDownloadManager sharedInstance] leDownloadWithDelegate:self URL:url];
        [labelProgress leSetText:[NSString stringWithFormat:@"%@",curDownloader.leDownloadedFilePath.lastPathComponent]];
    }
}
@end

@interface TestDownloaderPage : LEBaseView<LENavigationDelegate>
@end
@implementation TestDownloaderPage{
    LEBaseTableViewV2 *tableView;
}
-(void) leExtraInits{
    LEBaseNavigation *navi=[[LEBaseNavigation alloc] initWithDelegate:self SuperView:self Title:@"测试断点下载"];
    [navi leSetRightNavigationItemWith:@"新增" Image:nil];
    tableView=[[LEBaseTableViewV2 alloc] initWithSettings:[[LETableViewSettings alloc] initWithSuperView:self.leViewBelowCustomizedNavigation TableViewCell:@"TestDownloaderCell" EmptyTableViewCell:nil GetDataDelegate:nil TableViewCellSelectionDelegate:nil TapEvent:NO]];
}
-(void) leNavigationRightButtonTapped{
    [tableView leOnLoadedMoreWithData:[[NSMutableArray alloc] initWithObjects:@"", nil]];
}
@end
@implementation TestDownloader
@end
