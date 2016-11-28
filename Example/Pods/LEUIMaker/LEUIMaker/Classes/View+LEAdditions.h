//
//  View+LEAdditions.h
//  LEUIMaker
//
//  Created by emerson larry on 2016/11/1.
//  Copyright © 2016年 LarryEmerson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sys/sysctl.h"
#import <objc/runtime.h>

#pragma mark Screen
#define LESCREEN_BOUNDS     ([[UIScreen mainScreen] bounds])
#define LESCREEN_SCALE      ([[UIScreen mainScreen] scale])
#define LESCREEN_WIDTH      ([[UIScreen mainScreen] bounds].size.width)
#define LESCREEN_HEIGHT     ([[UIScreen mainScreen] bounds].size.height)
//#define LESCREEN_SCALE_INT  ((int)[[UIScreen mainScreen] scale])
//#define LESCREEN_MAX_LENGTH (MAX(LESCREEN_WIDTH, LESCREEN_HEIGHT))
//#define LESCREEN_MIN_LENGTH (MIN(LESCREEN_WIDTH, LESCREEN_HEIGHT))

#pragma mark Font
#define LEFont(size) [UIFont systemFontOfSize:size]
#define LEBoldFont(size) [UIFont boldSystemFontOfSize:size]
#pragma mark 
#define LESquareSize(__integer)         CGSizeMake(__integer,__integer)
#define LEDegreesToRadian(x) (M_PI * (x) / 180.0)
#define LERadianToDegrees(radian) (radian*180.0)/(M_PI)

#pragma mark LEStackAlignment
/** 栈的对齐方式 */
typedef NS_ENUM(NSInteger, LEStackAlignment) {
    /** 居中 */
    LECenterAlign = 0,
    /** 纵向栈 左对齐 */
    LELeftAlign = 1,
    /** 纵向栈 右对齐 */
    LERightAlign =2,
    /** 横向栈 上对齐 */
    LETopAlign=3,
    /** 横向栈 下对齐 */
    LEBottomAlign=4,
#pragma mark LEStackAlignment Shorthands
    LE_CA=LECenterAlign,
    LE_LA=LELeftAlign,
    LE_RA=LERightAlign,
    LE_TA=LETopAlign,
    LE_BA=LEBottomAlign
};

#pragma mark LEAnchors
/** View的对齐方式：相对于参考View分为内部对齐和外部对齐（Inside与Outside） */
typedef NS_ENUM(NSInteger, LEAnchors) {
    LEInsideTopLeft = 0,
    LEInsideTopCenter = 1,
    LEInsideTopRight =2,
    //
    LEInsideLeftCenter = 3,
    LEInsideCenter = 4,
    LEInsideRightCenter = 5,
    //
    LEInsideBottomLeft = 6,
    LEInsideBottomCenter = 7,
    LEInsideBottomRight = 8,
    //
    LEOutside1 = 9,
    LEOutside2 = 10,
    LEOutside3 = 11,
    LEOutside4 = 12,
    //
    LEOutsideTopLeft = 13,
    LEOutsideTopCenter = 14,
    LEOutsideTopRight = 15,
    //
    LEOutsideLeftTop = 16,
    LEOutsideLeftCenter = 17,
    LEOutsideLeftBottom = 18,
    //
    LEOutsideRightTop = 19,
    LEOutsideRightCenter = 20,
    LEOutsideRightBottom =21,
    //
    LEOutsideBottomLeft = 22,
    LEOutsideBottomCenter = 23,
    LEOutsideBottomRight =24,
#pragma mark LEAnchors Shorthands
    LEI_TL=LEInsideTopLeft,
    LEI_TC=LEInsideTopCenter,
    LEI_TR=LEInsideTopRight,
    LEI_LC=LEInsideLeftCenter,
    LEI_C =LEInsideCenter,
    LEI_RC=LEInsideRightCenter,
    LEI_BL=LEInsideBottomLeft,
    LEI_BC=LEInsideBottomCenter,
    LEI_BR=LEInsideBottomRight,
    LEO_1 =LEOutside1,
    LEO_2 =LEOutside2,
    LEO_3 =LEOutside3,
    LEO_4 =LEOutside4,
    LEO_TL=LEOutsideTopLeft,
    LEO_TC=LEOutsideTopCenter,
    LEO_TR=LEOutsideTopRight,
    LEO_LT=LEOutsideLeftTop,
    LEO_LC=LEOutsideLeftCenter,
    LEO_LB=LEOutsideLeftBottom,
    LEO_RT=LEOutsideRightTop,
    LEO_RC=LEOutsideRightCenter,
    LEO_RB=LEOutsideRightBottom,
    LEO_BL=LEOutsideBottomLeft,
    LEO_BC=LEOutsideBottomCenter,
    LEO_BR=LEOutsideBottomRight
};

#pragma mark UIView
@interface UIView (LEAdditions)
/** 退出键盘输入模式 */
-(void) leEndEdit;
/** 重新刷新布局：可用于屏幕旋转后的布局处理 */
-(void) leUpdateLayout;
/** 内存释放，子类重写需要super */
-(void) leRelease NS_REQUIRES_SUPER;
#pragma mark shorthands
/** 将自身添加到父View */
-(__kindof UIView *(^)(UIView *)) leAddTo;
/** 自身对齐的参考对象，可以是父View、可以是兄弟View */
-(__kindof UIView *(^)(UIView *)) leRelativeTo;
/** 对齐方式 */
-(__kindof UIView *(^)(LEAnchors)) leAnchor;
/** 设置顶部间距 */
-(__kindof UIView *(^)(CGFloat)) leTop;
/** 设置左侧间距 */
-(__kindof UIView *(^)(CGFloat)) leLeft;
/** 设置底部间距 */
-(__kindof UIView *(^)(CGFloat)) leBottom;
/** 设置右侧间距 */
-(__kindof UIView *(^)(CGFloat)) leRight;
/** 设置上下左右间距 */
-(__kindof UIView *(^)(UIEdgeInsets)) leMargins;
/** 设置宽度 */
-(__kindof UIView *(^)(CGFloat)) leWidth;
/** 设置高度 */
-(__kindof UIView *(^)(CGFloat)) leHeight;
/** 设置背景色 */
-(__kindof UIView *(^)(UIColor *)) leBgColor;
/** 设置是否开启点击事件 */
-(__kindof UIView *(^)(BOOL)) leEnableTouch;
/** 设置点击事件：除Button使用addTarget方式外，其他view使用Tap事件 */
-(__kindof UIView *(^)(SEL sel, id target)) leTouchEvent;
/** 设置圆角 */
-(__kindof UIView *(^)(CGFloat)) leCorner;
/** 设置外描边 */
-(__kindof UIView *(^)(CGFloat width, UIColor *color)) leBoard;
#pragma Container:wrapper
/** 设置后自动根据所有子View的对齐计算自身大小并重新对齐*/
-(__kindof UIView *(^)()) leWrapper;
#pragma Stacks (Vertical & Horizontal)
/** 设置栈的整体对齐方式，纵向：左、中、右，横向：上、中、下，默认居中对齐 */
-(__kindof UIView *(^)()) leStackAlignmnet;
/** 设置为纵向的栈，配合lePushToStack入栈，子View调用lePopFromStack出栈 */
-(__kindof UIView *(^)()) leVerticalStack;
/** 设置为横向的栈，配合lePushToStack入栈，子View调用lePopFromStack出栈 */
-(__kindof UIView *(^)()) leHorizontalStack;
/** 为ScrollView量身定做的自动根据所有子view的对齐计算ContentSize并实时设定*/
-(__kindof UIView *(^)()) leAutoResizeContentView;
/** 入栈，入栈前需要设定为纵向或横向的栈，入栈参数可以单个或多个view，以nil结尾*/
-(void) lePushToStack:(__kindof UIView *) view,...;
/** 出栈，请确保已入栈 */
-(void) lePopFromStack;
#pragma mark Equal
/** 宽度等于父View(superView)宽度*float */
-(__kindof UIView *(^)(CGFloat)) leEqualSuperViewWidth;
/** 宽度等于父View(superView)高度*float */
-(__kindof UIView *(^)(CGFloat)) leEqualSuperViewHeight;
/** 宽度等于参考View(relativeView)宽度*float */
-(__kindof UIView *(^)(CGFloat)) leEqualRelativeViewWidth;
/** 宽度等于参考View(relativeView)高度*float */
-(__kindof UIView *(^)(CGFloat)) leEqualRelativeViewHeight;
/** 高度等于父View(superView)宽度*float */
-(__kindof UIView *(^)(CGFloat)) leHeightEqualSuperViewWidth;
/** 高度等于参考View(relativeView)宽度*float */
-(__kindof UIView *(^)(CGFloat)) leHeightEqualRelativeViewWidth;
/** 宽度等于高度*float */
-(__kindof UIView *(^)(CGFloat)) leWidthEqualHeight;
/** 高度等于宽度*float */
-(__kindof UIView *(^)(CGFloat)) leHeightEqualWidth;
/** 顶部间距等于高度*float */
-(__kindof UIView *(^)(CGFloat)) leTopEqualHeight;
/** 底部间距等于高度*float */
-(__kindof UIView *(^)(CGFloat)) leBottomEqualHeight;
/** 左侧间距等于宽度*float */
-(__kindof UIView *(^)(CGFloat)) leLeftEqualWidth;
/** 右侧间距等于宽度*float */
-(__kindof UIView *(^)(CGFloat)) leRightEqualWidth;
#pragma mark common
/** 设置label、textfield、button的titlelabel的font */
-(__kindof UIView *(^)(UIFont *)) leFont;
/** 设置最大宽度，适用于Label、Button、UIImageView, 按钮的固定宽度使用leBtnFixedWidth */
-(__kindof UIView *(^)(CGFloat)) leMaxWidth;
/** 设置最大高度，适用于Label、Button、UIImageView, 按钮的固定宽度使用leBtnFixedHeight */
-(__kindof UIView *(^)(CGFloat)) leMaxHeight;
/** 设置label、textfield、button的文字颜色 */
-(__kindof UIView *(^)(UIColor *)) leColor;
/** 设置label、textfield的文字对其方式 */
-(__kindof UIView *(^)(NSTextAlignment)) leAlignment;
/** 设置label、textfield的文字对其方式为左对齐 */
-(__kindof UIView *) leLeftAlign;
/** 设置label、textfield的文字对其方式为右对齐 */
-(__kindof UIView *) leRightAlign;
/** 设置label、textfield的文字对其方式为居中对齐 */
-(__kindof UIView *) leCenterAlign;
#pragma mark Label
/** 设置Label及Button的titleLabel的行数，0表示多行，默认为1行 */
-(__kindof UIView *(^)(NSInteger)) leLine;
/** 设置label的行间距 */
-(__kindof UIView *(^)(CGFloat)) leLineSpace;
#pragma mark Button
/** 设置button是否垂直排列 */
-(__kindof UIView *(^)(BOOL)) leBtnVerticalLayout;
/** 设置button固定宽 */
-(__kindof UIView *(^)(CGFloat)) leBtnFixedWidth;
/** 设置button固定高 */
-(__kindof UIView *(^)(CGFloat)) leBtnFixedHeight;
/** 设置button固定宽高 */
-(__kindof UIView *(^)(CGSize)) leBtnFixedSize;
/** 设置button的图片 */
-(__kindof UIView *(^)(UIImage *, UIControlState state)) leBtnImg;
/** 设置button的背景图片 */
-(__kindof UIView *(^)(UIImage *, UIControlState state)) leBtnBGImg;
/** 设置button的文字颜色 */
-(__kindof UIView *(^)(UIColor *, UIControlState state)) leBtnColor;
/** 设置button的图片 Normal状态 */
-(__kindof UIView *(^)(UIImage *)) leBtnImg_N;
/** 设置button的图片 Highlighted状态 */
-(__kindof UIView *(^)(UIImage *)) leBtnImg_H;
/** 设置button的背景图片 Normal状态 */
-(__kindof UIView *(^)(UIImage *)) leBtnBGImgN;
/** 设置button的背景图片 Highlighted状态 */
-(__kindof UIView *(^)(UIImage *)) leBtnBGImgH;
/** 设置button的文字颜色 Normal状态 */
-(__kindof UIView *(^)(UIColor *)) leBtnColorN;
/** 设置button的文字颜色 Highlighted状态 */
-(__kindof UIView *(^)(UIColor *)) leBtnColorH;
/** 设置button的纵向间距 */
-(__kindof UIView *(^)(CGFloat)) leBtnVInsect;
/** 设置button的横向间距 */
-(__kindof UIView *(^)(CGFloat)) leBtnHInsect;
#pragma mark Textfield
/** 设置textfield的占位字符 */
-(__kindof UIView *(^)(NSString *)) leTextPlaceHolder;
/** 设置textfield的按钮类型 */
-(__kindof UIView *(^)(UIReturnKeyType)) leReturnType;
/** 设置textfield的回调 */
-(__kindof UIView *(^)(id<UITextFieldDelegate>)) leTextDelegate;
#pragma mark 内容设置，需要放置到方法末尾，之前的设置才有效
/**（内容设置需放到末尾执行）设置label和textfield的text，button的title */
-(__kindof UIView *(^)(NSString *)) leText;
/**（内容设置需放到末尾执行）设置UIImage、button的图片 */
-(__kindof UIView *(^)(UIImage *)) leImage;
#pragma mark Split line
/** 添加顶部分割线 颜色、偏移量、宽度 */
-(__kindof UIView *(^)(UIColor *color, CGFloat offset, CGFloat width)) leAddTopSplitline;
/** 添加底部分割线 颜色、偏移量、宽度 */
-(__kindof UIView *(^)(UIColor *color, CGFloat offset, CGFloat width)) leAddBottomSplitline;
/** 添加左侧分割线 颜色、偏移量、高度 */
-(__kindof UIView *(^)(UIColor *color, CGFloat offset, CGFloat height)) leAddLeftSplitline;
/** 添加右侧分割线 颜色、偏移量、高度 */
-(__kindof UIView *(^)(UIColor *color, CGFloat offset, CGFloat height)) leAddRightSplitline;
@end
@interface UIViewController (LEExtension)
-(void) lePush:(UIViewController *) vc;
-(void) lePop;
@end
@interface UIImage (LEExtension)
-(UIImage *)leStreched;
@end
@interface UIColor (LEExtension)
-(UIImage *) leImage;
-(UIImage *) leImageWithSize:(CGSize)size;
@end
@interface UILabel (LEExtension)
-(CGSize) leSizeWithMaxSize:(CGSize) size;
@end
@interface NSAttributedString (LEExtension)
-(CGRect) leRectWithMaxSize:(CGSize) size;
@end


