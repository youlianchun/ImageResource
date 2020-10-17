//
//  UIImage+Dynamic.m
//  Example
//
//  Created by YLCHUN on 2020/8/30.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import "UIImage+Dynamic.h"

#pragma mark -

@implementation UIImage (Dynamic)

+ (instancetype _Nullable)imageWithLight:(UIImage *)light dark:(UIImage *)dark {
    if (!dark) return light;
    if (!light) return dark;
    
    if (@available(iOS 13.0, *)) {
        return [self imageWithDynamicProvider:^UIImage * _Nullable(UIUserInterfaceStyle style) {
            if (style == UIUserInterfaceStyleDark) {
                return dark;
            }else {
                return light;
            }
        }];
    }
    else {
        return light;
    }
}

- (UIImage *)blendWithColor:(UIColor *)color {
    if (!color) return self;
    UIImage *(^blendBlock)(UIColor *) = ^UIImage *(UIColor *color) {
        if (!color) return self;
        UIImage *(^block)(UIImage *, UIColor *) = ^UIImage *(UIImage *image, UIColor *color) {
            UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextTranslateCTM(context, 0, image.size.height);
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextSetBlendMode(context, kCGBlendModeNormal);
            CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
            CGContextClipToMask(context, rect, image.CGImage);
            [color setFill];
            CGContextFillRect(context, rect);
            UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            return img;
        };
        if (self.images.count > 0) {
            NSMutableArray *arr = [NSMutableArray array];
            for (UIImage *image in self.images) {
                [arr addObject:block(image, color)];
            }
            return [UIImage animatedImageWithImages:arr duration:self.duration];
        }else {
            return block(self, color);
        }
    };
    
    if (@available(iOS 13.0, *)) {
        UIColor *lightColor = [color resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        UIColor *darkColor = [color resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
        UIImage *light = [blendBlock(lightColor) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        UIImage *dark = [blendBlock(darkColor) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        return [UIImage imageWithLight:light dark:dark];
    }
    else {
        return [blendBlock(color) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
}

@end
