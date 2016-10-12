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

@interface ViewController ()<LE_AFNetworkingDelegate,LENavigationDelegate>
@end
@implementation ViewController{

}
- (void)viewDidLoad {
    [super viewDidLoad];
    //    [self onTestDataModel];
    [[LE_AFNetworking sharedInstance] leSetEnableDebug:YES];
    [[LE_AFNetworking sharedInstance] leSetEnableResponseDebug:YES];
    [[LE_AFNetworking sharedInstance] leSetEnableResponseWithJsonString:YES];
    LEBaseView *view=[[LEBaseView alloc] initWithViewController:self];
    LEBaseNavigation *navi=[[LEBaseNavigation alloc] initWithDelegate:self ViewController:self SuperView:view Offset:LEStatusBarHeight BackgroundImage:[LEColorWhite leImageStrechedFromSizeOne] TitleColor:LEColorTextBlack LeftItemImage:nil];
    [navi leSetNavigationTitle:@"LE_AFNetworking"];
    [navi leSetRightNavigationItemWith:@"测试" Image:nil];
}
-(void) leNavigationRightButtonTapped{
    [self onTestLE_AFNetworking];
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
