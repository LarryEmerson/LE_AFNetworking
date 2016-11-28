//
//  LECommon.h
//  LEUIMaker
//
//  Created by emerson larry on 2016/11/1.
//  Copyright © 2016年 LarryEmerson. All rights reserved.
//

#import <UIKit/UIKit.h>



#pragma mark Define Colors
#define LEColorClear          [UIColor clearColor]
#define LEColorWhite          [UIColor whiteColor]
#define LEColorBlack          [UIColor blackColor]
#define LERandomColor         [UIColor colorWithRed:arc4random_uniform(256)/255.0 green:arc4random_uniform(256)/255.0 blue:arc4random_uniform(256)/255.0 alpha:1.0]
#define LEColorTest           [UIColor colorWithRed:0.867 green:0.852 blue:0.539 alpha:1.000]
#define LEColorBlue           [UIColor colorWithRed:0.2071 green:0.467 blue:0.8529 alpha:1.0]
#define LEColorRed 			  [UIColor colorWithRed:0.9337 green:0.2135 blue:0.3201  alpha:1.0]

#pragma mark ColorText
#define LEColorText         LEColorWhite
#define LEColorText9        [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1]
#define LEColorText6        [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1]
#define LEColorText3        [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1]

#define LEColorSplitline    [UIColor colorWithRed:217/255.0 green:217/255.0 blue:217/255.0 alpha:1]

#define LEColorBG           LEColorWhite
#define LEColorBG9          [UIColor colorWithRed:249/255.0 green:249/255.0 blue:249/255.0 alpha:1]
#define LEColorBG5          [UIColor colorWithRed:245/255.0 green:245/255.0 blue:245/255.0 alpha:1]

#pragma mark Color Mask
#define LEColorHighlighted  [UIColor colorWithRed:209/255.0 green:209/255.0 blue:209/255.0 alpha:1]

#define LEColorMaskLight      [[UIColor alloc] initWithWhite:0.906 alpha:1.000]
#define LEColorMask           [[UIColor alloc] initWithRed:0.1 green:0.1 blue:0.1 alpha:0.1]
#define LEColorMask2          [[UIColor alloc] initWithRed:0.1 green:0.1 blue:0.1 alpha:0.2]
#define LEColorMask5          [[UIColor alloc] initWithRed:0.1 green:0.1 blue:0.1 alpha:0.5]
#define LEColorMask8          [[UIColor alloc] initWithRed:0.1 green:0.1 blue:0.1 alpha:0.8]
#pragma mark Sidespace
#define LESideSpace60   60
#define LESideSpace27   27
#define LESideSpace20   20
#define LESideSpace16   16
#define LESideSpace15   15
#define LESideSpace     10
#pragma mark Linespace
#define LELineSpace         12
#define LETextLineSpace     10
#define LESubtextLineSpace  8
#pragma mark AvatarSize
#define LEAvatarSizeBig     60
#define LEAvatarSizeMid     40
#define LEAvatarSize        30
#define LEAvatarSpace       20
#pragma mark Font
#define LEFontLL    (19*[[UIScreen mainScreen] scale])
#define LEFontLS    (18*[[UIScreen mainScreen] scale])
#define LEFontML    (16*[[UIScreen mainScreen] scale])
#define LEFontMS    (14*[[UIScreen mainScreen] scale])
#define LEFontSL    (12*[[UIScreen mainScreen] scale])
#define LEFontSS    (11*[[UIScreen mainScreen] scale])



