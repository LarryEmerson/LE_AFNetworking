//
//  LE_DataModel.m
//  LEUIFrameworkDemo
//
//  Created by emerson larry on 16/6/8.
//  Copyright © 2016年 Larry Emerson. All rights reserved. https://github.com/LarryEmerson
//  数据模型转换逻辑来自于吴海超的WHC_DataModel，gitHub:https://github.com/netyouli

#import "LE_DataModel.h"

@implementation LE_DataModel
-(id) initWithDataSource:(NSDictionary *) data {
    return [LE_DataModel handleDataModelEngine:data withClass:[self class]];
}
+(NSMutableArray *) initWithDataSources:(NSArray *) dataArray ClassName:(NSString *) className{
    return [self initWithDataSources:dataArray ClassName:className Prefix:@""];
}
+(NSMutableArray *) initWithDataSources:(NSArray *) dataArray ClassName:(NSString *) className Prefix:(NSString *) prefix{
    className=[className stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[className substringToIndex:1] uppercaseString]];
    NSMutableArray *array=[[NSMutableArray alloc] init];
    if(prefix&&prefix.length>0){
        className=[NSString stringWithFormat:@"%@_%@",prefix,className];
    }
    for (int i=0; i<dataArray.count; i++) {
        id obj=[[NSClassFromString(className) alloc] initWithDataSource:[dataArray objectAtIndex:i]];
        if(obj){
            [array addObject:obj];
        }
    }
    return array;
}
// 下面是数据模型转换的主要逻辑，来自于吴海超的WHC_DataModel，gitHub:https://github.com/netyouli
+ (NSString *)getClassNameString:(const char *)attr{
    NSString * strClassName = nil;
    NSString * attrStr = @(attr);
    NSRange  oneRange = [attrStr rangeOfString:@"T@\""];
    if(oneRange.location != NSNotFound){
        NSRange twoRange = [attrStr rangeOfString:@"\"" options:NSBackwardsSearch];
        if(twoRange.location != NSNotFound){
            NSRange  classRange = NSMakeRange(oneRange.location + oneRange.length, twoRange.location - (oneRange.location + oneRange.length));
            strClassName = [attrStr substringWithRange:classRange];
        }
    }
    return strClassName;
}

+ (BOOL)existproperty:(NSString *)property withObject:(NSObject *)object{
    unsigned int  propertyCount = 0;
    Ivar *vars = class_copyIvarList([object class], &propertyCount);
    for (NSInteger i = 0; i < propertyCount; i++) {
        Ivar var = vars[i];
        NSString * tempProperty = [[NSString stringWithUTF8String:ivar_getName(var)] stringByReplacingOccurrencesOfString:@"_" withString:@""];
        if([property isEqualToString:tempProperty]){
            return YES;
        }
    }
    propertyCount=0;
    vars = class_copyIvarList(class_getSuperclass([object class]), &propertyCount);
    for (NSInteger i = 0; i < propertyCount; i++) {
        Ivar var = vars[i];
        NSString * tempProperty = [[NSString stringWithUTF8String:ivar_getName(var)] stringByReplacingOccurrencesOfString:@"_" withString:@""];
        if([property isEqualToString:tempProperty]){
            return YES;
        }
    }
    return NO;
}

+ (Class)classExistProperty:(NSString *)property withObject:(NSObject *)object{
    Class  class = [NSNull class];
    unsigned int  propertyCount = 0;
    Ivar *vars = class_copyIvarList([object class], &propertyCount);
    for (NSInteger i = 0; i < propertyCount; i++) {
        Ivar var = vars[i];
        NSString * tempProperty = [[NSString stringWithUTF8String:ivar_getName(var)] stringByReplacingOccurrencesOfString:@"_" withString:@""];
        if([property isEqualToString:tempProperty]){
            NSString * type = [NSString stringWithUTF8String:ivar_getTypeEncoding(var)];
            if([type hasPrefix:@"@"]){
                type = [type stringByReplacingOccurrencesOfString:@"@" withString:@""];
                type = [type stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                class = NSClassFromString(type);
                return class;
            }
        }
    }
    propertyCount=0;
    vars = class_copyIvarList(class_getSuperclass([object class]), &propertyCount);
    for (NSInteger i = 0; i < propertyCount; i++) {
        Ivar var = vars[i];
        NSString * tempProperty = [[NSString stringWithUTF8String:ivar_getName(var)] stringByReplacingOccurrencesOfString:@"_" withString:@""];
        if([property isEqualToString:tempProperty]){
            NSString * type = [NSString stringWithUTF8String:ivar_getTypeEncoding(var)];
            if([type hasPrefix:@"@"]){
                type = [type stringByReplacingOccurrencesOfString:@"@" withString:@""];
                type = [type stringByReplacingOccurrencesOfString:@"\"" withString:@""];
                class = NSClassFromString(type);
                return class;
            }
        }
    }
    return class;
}
+ (id)handleDataModelEngine:(id)object withClass:(Class) class{
    if(object){
        LE_DataModel *modelObject = [class new];
        if(modelObject){
            [modelObject setDataSource:object];
            if([object isKindOfClass:[NSDictionary class]]){
                NSDictionary  * dict = object;
                NSInteger       count = dict.count;
                NSArray       * keyArr = [dict allKeys];
                for (NSInteger i = 0; i < count; i++) {
                    id key=keyArr[i];
                    id subObject = dict[key];
                    if(subObject){
                        id propertyExistence=[LE_DataModel classExistProperty:key withObject:modelObject];
                        //                        NSLog(@"%@",propertyExistence);
                        if (propertyExistence == [NSString class]){
                            if([subObject isKindOfClass:[NSNull class]]){
                                [modelObject setValue:@"" forKey:key];
                            }else{
                                [modelObject setValue:subObject forKey:key];
                            }
                        }else if (propertyExistence == [NSNumber class]){
                            if([subObject isKindOfClass:[NSNull class]]){
                                [modelObject setValue:@(0) forKey:key];
                            }else{
                                [modelObject setValue:subObject forKey:key];
                            }
                        }else if(propertyExistence == [NSDictionary class]){
                            if([subObject isKindOfClass:[NSNull class]]){
                                [modelObject setValue:@{} forKey:key];
                            }else{
                                NSString *subClassName=[key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[[key substringToIndex:1] uppercaseString]];
                                subClassName=[NSString stringWithFormat:@"%@_%@", NSStringFromClass(class),subClassName];
                                id subModelObject=[LE_DataModel handleDataModelEngine:subObject withClass:NSClassFromString(subClassName)];
                                [modelObject setValue:subModelObject forKey:key];
                            }
                        }else if (propertyExistence == [NSArray class]){
                            if([subObject isKindOfClass:[NSNull class]]){
                                [modelObject setValue:@[] forKey:key];
                            }else{
                                id subModelObject=[LE_DataModel initWithDataSources:subObject ClassName:key Prefix:NSStringFromClass(class)];
                                [modelObject setValue:subModelObject forKey:key];
                            }
                        }else if(subObject && ![subObject isKindOfClass:[NSNull class]]){
                            id subModelObject = [self handleDataModelEngine:subObject withClass:propertyExistence];
                            [modelObject setValue:subModelObject forKey:key];
                        }
                    }
                }
            }else if([object isKindOfClass:[NSString class]]){
                if(object){
                    return object;
                }else{
                    return @"";
                }
            }else if([object isKindOfClass:[NSNumber class]]){
                if(object){
                    return object;
                }else{
                    return @(0);
                }
            }
            return modelObject;
        }
    }
    return nil;
}
@end
