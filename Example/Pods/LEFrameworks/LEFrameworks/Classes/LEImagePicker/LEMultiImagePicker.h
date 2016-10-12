//
//  LEMultiImagePicker.h
//  LEUIFrameworkDemo
//
//  Created by emerson larry on 16/6/1.
//  Copyright © 2016年 Larry Emerson. All rights reserved.
//

#import "LEBaseViewController.h"
#import "LEBaseCollectionView.h"
@protocol LEMultiImagePickerDelegate<NSObject>
-(void) leOnMultiImagePickedWith:(NSArray *) images;
@end

@interface LEMultiImagePicker : LEBaseViewController
-(id) initWithImagePickerDelegate:(id<LEMultiImagePickerDelegate>) delegate RootVC:(UIViewController *) vc;
-(id) initWithImagePickerDelegate:(id<LEMultiImagePickerDelegate>) delegate RemainCount:(NSInteger) remain MaxCount:(NSInteger) max RootVC:(UIViewController *) vc;
@end
