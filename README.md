# LE_AFNetworking

### #import "LE_AFNetworkings.h"
### LE_AFNetworking主要是针对于AFNetworking做了进一步的封装。

####Demo工程演示了LE_AFNetworking的使用及NSDictionary字典内容直接转自定义数据模型对象。
#####主要代码
###### 请求 
    [[LE_AFNetworking sharedInstance] leRequestWithApi:@"http://git.oschina.net/larryemerson/ybs/raw/master/README.md" uri:@"" httpHead:nil requestType:requestTypeGet parameter:nil delegate:self];
###### 回调内容 
    -(void) leRequest:(LE_AFNetworkingRequestObject *)request ResponedWith:(NSDictionary *)response{
        LELogObject(response);
        [self onTestDataModelWithData:[response objectForKey:@"data"]];
    }
###### 回调转对象并打印对象内容
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
#####请求内容
#####![](https://github.com/LarryEmerson/LE_AFNetworking/blob/master/Example/IMG/LE_AFNetworkingRequestLog.png)
#####请求回调主要内容
#####![](https://github.com/LarryEmerson/LE_AFNetworking/blob/master/Example/IMG/LE_AFNetworkingResponseLog.png)
#####数据模型对象内容打印
#####![](https://github.com/LarryEmerson/LE_AFNetworking/blob/master/Example/IMG/LE_AFNetworkingTestLog.png)

### LE_AFNetworking 主要说明
#### 1-提供了统一的请求接口：api，uri，httphead，requestType，parameter，delegate，identification（用于区分相同请求条件）。
#### 2-对Get&Head请求做了离线硬缓存，并且Get&Head请求支持自定义时间的内存缓存，避免重复请求。
#### 3-回调数据统一为NSDictionary格式，可进一步通过key（LEKeyOfResponseArray）取到具体的数组格式的数据。
#### 4-另外设定leSetEnableResponseWithJsonString:YES后，可以在请求回调中返回Json格式的回调内容。使用工具JsonToObjCClassFile可以直接根据json数据生成需要的数据模型类文件。对应的key为LEKeyOfResponseAsJSON
#### 5-[[LE_AFNetworking sharedInstance] leSetEnableDebug:YES];用于控制是否打印请求内容
#### 6-[[LE_AFNetworking sharedInstance] leSetEnableResponseDebug:YES];用于控制是否打印请求的回调内容
#### 7-[[LE_AFNetworking sharedInstance] leSetEnableResponseWithJsonString:YES];请求回调内容中是否返回json格式用于数据模型转换
#### 8-leSetMD5Salt 用于[LE_AFNetworking leMd5:str]时是否添加salt
#### 9-leSetServerHost 设置请求统一的Host（目前不支持多个host的情况，如果需要可以host=空，然后通过api&uri的组合来适配）
#### 10-leSetMessageDelegate 统一处理请求出现异常时需要显示全局提示信息时调用并提示消息。如果没有设定，需要自行在失败的回调中对message进行处理。
#### 11-回调接口分为成功和失败
#####- (void) leRequest:(LE_AFNetworkingRequestObject *) request ResponedWith:(NSDictionary *) response; 成功返回回调内容response
#####- (void) leRequest:(LE_AFNetworkingRequestObject *) request FailedWithStatusCode:(int) statusCode Message:(NSString *)message;失败返回statuscode，message提示信息
#### 12-区分请求时可以使用
#####request.afnetworkingSettings.leRequestCounter当前请求的唯一id，请求条件相同时无法区分 
#####request.afnetworkingSettings.leIdentification当前请求的自行设定的标签，请求条件相同时如果需要区分请求，请自行设定标签

[![Version](https://img.shields.io/cocoapods/v/LE_AFNetworking.svg?style=flat)](http://cocoapods.org/pods/LE_AFNetworking)
[![License](https://img.shields.io/cocoapods/l/LE_AFNetworking.svg?style=flat)](http://cocoapods.org/pods/LE_AFNetworking)
[![Platform](https://img.shields.io/cocoapods/p/LE_AFNetworking.svg?style=flat)](http://cocoapods.org/pods/LE_AFNetworking)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
ios 7.0
## Installation

LE_AFNetworking is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "LE_AFNetworking"
```

## Author

LarryEmerson, larryemerson@163.com

## License

LE_AFNetworking is available under the MIT license. See the LICENSE file for more info.


