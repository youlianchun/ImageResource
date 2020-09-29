//
//  UIImage+Dynamic.h
//  Example
//
//  Created by YLCHUN on 2020/8/30.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Dynamic)

/// 构造动态 image
/// @param dynamicProvider 动态提供图片, style 对应 image 已经存在时不再执行
+ (instancetype _Nullable)imageWithDynamicProvider:(UIImage *_Nullable(^)(UIUserInterfaceStyle style))dynamicProvider API_AVAILABLE(ios(13.0));

/// 构造动态 image
/// @param light lightImage
/// @param dark darkImage
+ (instancetype _Nullable)imageWithLight:(UIImage *_Nullable)light dark:(UIImage *_Nullable)dark;

/// 获取自身原始图片
- (UIImage *_Nullable)dynamicProviderRawImage API_AVAILABLE(ios(13.0));

/// 更改 image 颜色
/// @param color  color
- (UIImage *)blendWithColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
