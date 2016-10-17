# LE_AFNetworking

### #import "LE_AFNetworkings.h"
### LE_AFNetworking主要是针对于AFNetworking做了进一步的封装。

## 新增LEResumeBrokenDownload（0.3.2 v2, 0.3.1 v1） 断点续传，支持强制关闭应用续传。
##### v1-使用的是周期性下载量达到指定量后的自动进度保存，需要写入当前进度信息（4kb），比较低效。
##### v2-不再做进度信息保存的工作，而是最直接的缓存未下载任务的.tmp文件的路径，续传只需使用.tmp文件构建任务。

## v2 说明：
```
-断点续传下载器：任务新建后即会在tmp文件夹生成对应的临时文件(.tmp)，断点续传的主要原理就是保存.tmp文件的路径，下次重新新建任务时，如果存在.tmp文件则采用续传的方式建立任务，否则正常建立任务。
-runtime获取.tmp路径的思想来源于http://blog.csdn.net/yan_daoqiu/article/details/50469601
-下载进度只会在任务暂停时才会记录，用于续传之前显示任务进度
-如需支持后台下载，需要使用接口initWithDelegate:Identifier:SessionConfiguration: 自定义config实现后台下载。
-可以全局设定下载器是否允许蜂窝网络，是否在切换到蜂窝网络时暂停所有下载。不能完全支持后台下载的情况。Check discussion of property discretionary below
-前台，可以强制某一个任务绕过app内部蜂窝网络的禁止，执行下载的流程
-网络断开提醒、切换蜂窝网络提醒、蜂窝网络被禁用提醒，都是针对于某一个下载任务的。多个任务存在的情况下，需要处理好多个任务同时受到提醒时的兼容处理（比如网络断开提示窗只能出现一次，蜂窝网络被禁用提醒，只能当前活动界面做反馈）
-对url中无后缀的情况作了补救，代价是下载完的内容的读取，必须使用下载器中的leDownloadedFilePath来作为路径。原因是下载完成的文件都是带有后缀的，如果url中无后缀，跳过下载器的leDownloadedFilePath，而使用url在拼接路径，会因为无后缀而找不到已下载完成的文件 
```
```
for the discretionary property:
When this flag is set, 
transfers are more likely to occur when plugged into power and on Wi-Fi. 
This value is false by default. 
This property is used only if a session’s configuration object was 
originally constructed by calling the backgroundSessionConfiguration: method, 
and only for tasks started while the app is in the foreground. 
If a task is started while the app is in the background, 
that task is treated as though discretionary were true, 
regardless of the actual value of this property. 
For sessions created based on other configurations, this property is ignored.
```

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

```
1-提供了统一的请求接口：api，uri，httphead，requestType，parameter，delegate，identification（用于区分相同请求条件）。
2-对Get&Head请求做了离线硬缓存，并且Get&Head请求支持自定义时间的内存缓存，避免重复请求。
3-回调数据统一为NSDictionary格式，可进一步通过key（LEKeyOfResponseArray）取到具体的数组格式的数据。
4-另外设定leSetEnableResponseWithJsonString:YES后，可以在请求回调中返回Json格式的回调内容。使用工具JsonToObjCClassFile可以直接根据json数据生成需要的数据模型类文件。对应的key为LEKeyOfResponseAsJSON
5-[[LE_AFNetworking sharedInstance] leSetEnableDebug:YES];用于控制是否打印请求内容
6-[[LE_AFNetworking sharedInstance] leSetEnableResponseDebug:YES];用于控制是否打印请求的回调内容
7-[[LE_AFNetworking sharedInstance] leSetEnableResponseWithJsonString:YES];请求回调内容中是否返回json格式用于数据模型转换
8-leSetMD5Salt 用于[LE_AFNetworking leMd5:str]时是否添加salt
9-leSetServerHost 设置请求统一的Host（目前不支持多个host的情况，如果需要可以host=空，然后通过api&uri的组合来适配）
10-leSetMessageDelegate 统一处理请求出现异常时需要显示全局提示信息时调用并提示消息。如果没有设定，需要自行在失败的回调中对message进行处理。
11-回调接口分为成功和失败
    - (void) leRequest:(LE_AFNetworkingRequestObject *) request ResponedWith:(NSDictionary *) response; 成功返回回调内容response
    - (void) leRequest:(LE_AFNetworkingRequestObject *) request FailedWithStatusCode:(int) statusCode Message:(NSString *)message;失败返回statuscode，message提示信息
12-区分请求时可以使用
    request.afnetworkingSettings.leRequestCounter当前请求的唯一id，请求条件相同时无法区分 
    request.afnetworkingSettings.leIdentification当前请求的自行设定的标签，请求条件相同时如果需要区分请求，请自行设定标签
```
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


