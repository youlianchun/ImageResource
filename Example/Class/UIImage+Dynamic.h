//
//  UIImage+Dynamic.h
//  Example
//
//  Created by YLCHUN on 2020/8/30.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+ImageDynamicAsset.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (Dynamic)

/// 构造动态 image
/// @param light lightImage
/// @param dark darkImage
+ (instancetype _Nullable)imageWithLight:(UIImage *_Nullable)light dark:(UIImage *_Nullable)dark;

/// 更改 image 颜色
/// @param color  color
- (UIImage *)blendWithColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
