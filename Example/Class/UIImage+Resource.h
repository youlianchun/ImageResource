//
//  UIImage+Resource.h
//  Example
//
//  Created by YLCHUN on 2020/8/30.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Resource)
+ (NSBundle *)resourceBundle ;
+ (UIImage *_Nullable)pngImageNamed:(NSString *)name;
+ (UIImage *_Nullable)webpImageNamed:(NSString *)name;
+ (UIImage *_Nullable)jpgImageNamed:(NSString *)name;
+ (UIImage *_Nullable)gifImageNamed:(NSString *)name;

+ (NSArray *)webpImageNames;

+ (UIImage*)roundImageOfColor:(UIColor*)color borderColor:(UIColor*)borderColor borderWidth:(CGFloat)borderWidth radius:(CGFloat)radius scale:(CGFloat)scale;

+ (UIImage *_Nullable)newImageNamed:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
