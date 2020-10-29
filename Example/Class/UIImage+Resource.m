//
//  UIImage+Resource.m
//  Example
//
//  Created by YLCHUN on 2020/8/30.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import "UIImage+Resource.h"
#import <BundleImage/BundleImage.h>
#import "TryRelay.h"
#import <objc/runtime.h>

#if __has_include(<YYImage/YYImage.h>)
#import "YYAnimatedImageDynamicAsset.h"
#import <YYImage/YYImage.h>
#else
typedef UIImage YYImage;
#endif


@implementation UIImage (Resource)
+ (NSBundle *)resourceBundle {
    return [NSBundle mainBundle];
}

+ (void)prepareIfNeed {
#if 0
#if __has_include(<YYImage/YYImage.h>)
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BundleImage setImageProvider:^UIImage * _Nullable(NSString * _Nonnull file, BundleImageType  _Nonnull type) {
            return [YYImage imageWithContentsOfFile:file];
        } inBundle:self.resourceBundle];
        
        if (@available(iOS 13.0, *)) {
            [BundleImage setDynamicAssetHandler:^ImageDynamicAsset * _Nonnull(UIImage * _Nullable (^ _Nonnull imageProviderHandler)(UIUserInterfaceStyle)) {
                return [YYAnimatedImageDynamicAsset assetWithImageProvider:imageProviderHandler];
            } inBundle:self.resourceBundle];
        }
    });
#endif
#endif
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BundleImage setImageProcess:^UIImage * _Nullable(UIImage * _Nonnull image, NSString * _Nonnull name, BundleImageType  _Nonnull type) {
            if ([name isEqualToString:@"pop_ic_cancel_mute"]) {
                image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
            }
            return image;
        } inBundle:self.resourceBundle];
    });
}


+ (UIImage *)pngImageNamed:(NSString *)name {
    [self prepareIfNeed];
    return [BundleImage imageNamed:name type:BundleImageTypePNG inBundle:self.resourceBundle];
}
+ (UIImage *)webpImageNamed:(NSString *)name {
    [self prepareIfNeed];
    return [BundleImage imageNamed:name type:BundleImageTypeWEBP inBundle:self.resourceBundle];
}
+ (UIImage *)jpgImageNamed:(NSString *)name {
    [self prepareIfNeed];
    return [BundleImage imageNamed:name type:BundleImageTypeJPG inBundle:self.resourceBundle];
}
+ (UIImage *)gifImageNamed:(NSString *)name {
    [self prepareIfNeed];
    return [BundleImage imageNamed:name type:BundleImageTypeGIF inBundle:self.resourceBundle];
}
+ (NSArray *)webpImageNames {
    return [BundleImage imageNamesWithType:BundleImageTypeWEBP inBundle:self.resourceBundle];

}

+ (UIImage*)roundImageOfColor:(UIColor*)color borderColor:(UIColor*)borderColor borderWidth:(CGFloat)borderWidth radius:(CGFloat)radius scale:(CGFloat)scale {
    CGFloat diameter = radius*2;
    CGFloat halfBorderWidth = borderWidth/2;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(diameter, diameter), NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, borderWidth);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextAddEllipseInRect(context, CGRectMake(halfBorderWidth, halfBorderWidth, diameter-borderWidth, diameter-borderWidth));
    if(borderColor && borderWidth > 0){
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    else{
        CGContextDrawPath(context, kCGPathFill);
    }
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage *_Nullable)newImageNamed:(NSString *)name {
    __block UIImage *image = nil;
    tryRelay(@"webp", ^{
        image = [self webpImageNamed:name];
    }, ^(NSException * _Nullable exception) {
        //上报日志
    });
    if (image) return image;
    
    image = [self imageNamed:name];
    
    return image;
}

@end

//@implementation UIImage (imageNamed)
//+ (void)load {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        __swizzling(object_getClass(self), @selector(imageNamed:), @selector(__imageNamed:));
//    });
//}
//
//+ (UIImage *)__imageNamed:(NSString *)name {
//    __block UIImage *image = nil;
//    
//    tryRelay(@"webp", ^{
//        image = [self webpImageNamed:name];
//    }, ^(NSException * _Nullable exception) {
//        //上报日志
//    });
//    if (image) return image;
//    
//    image = [self __imageNamed:name];
//    
//    return image;
//}
//
//static void __swizzling(Class cls, SEL oriSEL,  SEL desSEL) API_AVAILABLE(ios(13.0)) {
//    Method oriMethod = class_getInstanceMethod(cls, oriSEL);
//    Method desMethod = class_getInstanceMethod(cls, desSEL);
//    BOOL addSuccess = class_addMethod(cls, oriSEL, method_getImplementation(desMethod), method_getTypeEncoding(desMethod));
//    if (addSuccess) {
//        class_replaceMethod(cls, desSEL, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
//    }else {
//        method_exchangeImplementations(oriMethod, desMethod);
//    }
//}
//@end
