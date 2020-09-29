//
//  UIImage+Resource.m
//  Example
//
//  Created by YLCHUN on 2020/8/30.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import "UIImage+Resource.h"
#import <BundleImage/BundleImageProvider.h>
#import "TryRelay.h"
#import <objc/runtime.h>

@implementation UIImage (Resource)
+ (NSBundle *)resourceBundle {
    return [NSBundle mainBundle];
}

+ (UIImage *)pngImageNamed:(NSString *)name {
    return [BundleImageProvider imageNamed:name type:BundleImageTypePNG inBundle:self.resourceBundle];
}
+ (UIImage *)webpImageNamed:(NSString *)name {
    return [BundleImageProvider imageNamed:name type:BundleImageTypeWEBP inBundle:self.resourceBundle];
}
+ (UIImage *)jpgImageNamed:(NSString *)name {
    return [BundleImageProvider imageNamed:name type:BundleImageTypeJPG inBundle:self.resourceBundle];
}
+ (UIImage *)gifImageNamed:(NSString *)name {
    return [BundleImageProvider imageNamed:name type:BundleImageTypeGIF inBundle:self.resourceBundle];
}
+ (NSArray *)webpImageNames {
    return [BundleImageProvider imageNamesWithType:BundleImageTypeWEBP inBundle:self.resourceBundle];

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
