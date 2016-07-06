# LE_AFNetworking

### #import "LE_AFNetworkings.h"
### LE_AFNetworking主要是针对于AFNetworking做了进一步的封装。
#### 1-提供了统一的请求接口：api，uri，httphead，requesttype，parameter，delegate，identification（用于区分相同请求条件）。
#### 2-对Get&Head请求做了离线硬缓存，并且Get&Head请求支持自定义时间的内存缓存，避免重复请求。
#### 3-回调数据统一为NSDictionary格式，可进一步通过key（KeyOfResponseArray）取到具体的数组格式的数据。
#### 4-另外设定enableResponseWithJsonString=YES后，可以在请求回调中返回Json格式的回调内容。使用工具JsonToObjCClassFile可以直接根据json数据生成需要的数据模型类文件。对应的key为KeyOfResponseAsJSON
#### 5-[[LE_AFNetworking sharedInstance] setEnableDebug:YES];用于控制是否打印请求内容
#### 6-[[LE_AFNetworking sharedInstance] setEnableResponseDebug:YES];用于控制是否打印请求的回调内容
#### 7-[[LE_AFNetworking sharedInstance] setEnableResponseWithJsonString:YES];请求回调内容中是否返回json格式用于数据模型转换
#### 8-md5Salt 用于[LE_AFNetworking md5:str]时是否添加salt
#### 9-setServerHost 设置请求统一的Host（目前不支持多个host的情况，如果需要可以host=空，然后通过api&uri的组合来适配）
#### 10-messageDelegate 统一处理请求出现异常时需要显示全局提示信息时调用并提示消息。如果没有设定，需要自行在失败的回调中对message进行处理。
#### 11-回调接口分为成功和失败
#####- (void) request:(LE_AFNetworkingRequestObject *) request ResponedWith:(NSDictionary *) response; 成功返回回调内容response
#####- (void) request:(LE_AFNetworkingRequestObject *) request FailedWithStatusCode:(int) statusCode Message:(NSString *)message;失败返回statuscode，message提示信息
#### 12-区分请求时可以使用
#####request.afnetworkingSettings.requestCounter当前请求的唯一id，请求条件相同时无法区分 
#####request.afnetworkingSettings.identification当前请求的自行设定的标签，请求条件相同时如果需要区分请求，请自行设定标签

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


