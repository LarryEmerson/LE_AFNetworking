//
//  LE_DataModel.h
//  LEUIFrameworkDemo
//
//  Created by emerson larry on 16/6/8.
//  Copyright © 2016年 Larry Emerson. All rights reserved. https://github.com/LarryEmerson
//  数据模型转换逻辑来自于吴海超的WHC_DataModel，gitHub:https://github.com/netyouli

#import <Foundation/Foundation.h>
#import <objc/runtime.h> 

@interface LE_DataModel : NSObject
@property (nonatomic)          NSDictionary          * dataSource;
@property (nonatomic , strong) NSNumber              * id;
-(id) initWithDataSource:(NSDictionary *) data;
+(NSMutableArray *) initWithDataSources:(NSArray *) dataArray ClassName:(NSString *) className;
@end
