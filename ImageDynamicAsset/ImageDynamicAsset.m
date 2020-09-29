//
//  ImageDynamicAsset.m
//  ImageDynamicAsset
//
//  Created by YLCHUN on 2020/9/4.
//

#import "ImageDynamicAsset.h"
#import <objc/runtime.h>
#import "pthread.h"

API_AVAILABLE(ios(13.0))
@interface _IDATrait : NSObject
@property (nonatomic, strong) ImageDynamicAsset *imageDynamicAsset;
@property (nonatomic, assign) UIUserInterfaceStyle userInterfaceStyle;
@property (nonatomic, strong) UIImage *image;
@end

API_AVAILABLE(ios(13.0))
@implementation _IDATrait
@end

#pragma mark -

API_AVAILABLE(ios(13.0))
@interface UIImage (_IDATrait)
@property (nonatomic, nullable) _IDATrait *_idaTrait;
@end

API_AVAILABLE(ios(13.0))
@implementation UIImage(_IDATrait)
- (_IDATrait *)_idaTrait {
    return objc_getAssociatedObject(self, @selector(_idaTrait));
}
- (void)set_idaTrait:(_IDATrait *)_idaTrait {
    objc_setAssociatedObject(self, @selector(_idaTrait), _idaTrait, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

#pragma mark -

API_AVAILABLE(ios(13.0))
@implementation ImageDynamicAsset
{
    UIImage *_Nullable(^_rawImageProvider)(UIUserInterfaceStyle style);
}

- (instancetype _Nullable)initWithImageProvider:(UIImage *_Nullable(^)(UIUserInterfaceStyle style))provider {
    if (!provider) return nil;
    self = [super init];
    _rawImageProvider = provider;
    return self;
}

- (UIImage *_Nullable)rawImageWithStyle:(UIUserInterfaceStyle)style {
    if (_rawImageProvider) {
        return _rawImageProvider(style);
    }else {
        return nil;
    }
}

- (UIImage *)cloneImageFromImage:(UIImage *)image {
    if (image.images.count > 0) {
        return [UIImage animatedImageWithImages:image.images duration:image.duration];
    }else {
        UIImage *newImage = nil;
        @autoreleasepool {
            newImage = [image imageWithBaselineOffsetFromBottom:image.baselineOffsetFromBottom + 10];
            if (image.hasBaseline) {
                newImage = [newImage imageWithBaselineOffsetFromBottom:image.baselineOffsetFromBottom];
            }else {
                newImage = [newImage imageWithoutBaseline];
            }
        }
        return newImage;
    }
}

- (UIImage *_Nullable)imageWithStyle:(UIUserInterfaceStyle)style {
    UIImage *image = [self rawImageWithStyle:style];
    if (!image) return nil;
    
    UIImage *newImage = [self cloneImageFromImage:image];
    if (!newImage) return nil;
    
    if (newImage == image) {
        NSAssert(false, @"-[%@ %@] Must return a brand new image here!", NSStringFromClass(self.class), NSStringFromSelector(@selector(cloneImageFromImage:)));
    }
    
    _IDATrait *trait = [_IDATrait new];
    trait.imageDynamicAsset = self;
    trait.userInterfaceStyle = style;
    trait.image = image;
    
    newImage._idaTrait = trait;
    
    [self setDynamicClassToImage:newImage];

    return newImage;
}

- (UIImage *_Nullable)resolvedImageWithStyle:(UIUserInterfaceStyle)style {
    UIImage *image = [self imageWithStyle:style];
    if (!image) {
        if (style == UIUserInterfaceStyleDark) {
            style = UIUserInterfaceStyleLight;
        }else {
            style = UIUserInterfaceStyleDark;
        }
        image = [self imageWithStyle:style];
    }
    return image;
}

- (void)setDynamicClassToImage:(UIImage *)image {
    Class originClass = object_getClass(image);
    Class subClass = class_getDynamicSubClass(originClass, YES, ^(__unsafe_unretained Class subClass) {
        SEL sel = @selector(imageWithConfiguration:);
        class_addMethod(subClass, sel, imp_implementationWithBlock(^UIImage *_Nullable(UIImage *self, UIImageConfiguration *ic) {
            _IDATrait *trait = self._idaTrait;
            if (!trait) {
                IMP imp = class_getMethodImplementation([self class], sel);
                return ((UIImage*(*)(UIImage *, UIImageConfiguration *))imp)(self, ic);
            }
            else {
                UIUserInterfaceStyle style = ic.traitCollection.userInterfaceStyle;
                if (trait.userInterfaceStyle == style) {
                    return self;
                }else {
                    UIImage *img = [trait.imageDynamicAsset resolvedImageWithStyle:style];
                    if (img) {
                        return img;
                    }
                    else {
                        return self;
                    }
                }
            }
        }), method_getTypeEncoding(class_getInstanceMethod(originClass, sel)));
     });
     
     if (subClass && originClass != subClass) {
         object_setClass(image, subClass);
     }
}

static Class _Nullable class_getDynamicSubClass(Class originClass, BOOL initIfNil, void(^initBlock)(Class subClass)) {
    NSString *suffix = @".IDA.dynamic";
    NSString *orignClassName = NSStringFromClass(originClass);
    if ([orignClassName hasSuffix:suffix]) {
        return originClass;
    }
    else {
        const char *subClassName = [orignClassName stringByAppendingString:suffix].UTF8String;
        
        static pthread_mutex_t mutex_t = PTHREAD_MUTEX_INITIALIZER;
        pthread_mutex_lock(&mutex_t);
        
        Class subClass = objc_getClass(subClassName);
        if (subClass == nil && initIfNil) {
            
            subClass = objc_allocateClassPair(originClass, subClassName, 0);

            SEL sel = @selector(class);
            const char *te = method_getTypeEncoding(class_getInstanceMethod(subClass, sel));
            class_addMethod(subClass, sel, imp_implementationWithBlock(^Class(id self) {
                return originClass;
            }), te);

            initBlock(subClass);
            
            objc_registerClassPair(subClass);
        }
        
        pthread_mutex_unlock(&mutex_t);

        return subClass;
    }
}

+ (instancetype)assetWithImageProvider:(UIImage *_Nullable(^)(UIUserInterfaceStyle style))provider {
    return [[self alloc] initWithImageProvider:provider];
}

+ (BOOL)isDynamicAssetImage:(UIImage *)image {
    return image._idaTrait != nil;
}

+ (UIImage *_Nullable)rawImageFromDynamicAssetImage:(UIImage *)image {
    _IDATrait *trait = image._idaTrait;
    if (trait) {
        return trait.image;
    }else {
        return nil;
    }
}

@end

//
//API_AVAILABLE(ios(13.0))
//@implementation UIImage (ImageDynamicAsset)
//+ (void)load {
//    if (@available(iOS 13.0, *)) {
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//            _ida_swizzling(self, @selector(imageWithConfiguration:), @selector(_ida_imageWithConfiguration:));
//        });
//    }
//}
//
//- (UIImage *)_ida_imageWithConfiguration:(UIImageConfiguration *)configuration {
//    _IDATrait *trait = self._idaTrait;
//    if (!trait) {
//        return [self _ida_imageWithConfiguration:configuration];
//    }
//    else {
//        UIUserInterfaceStyle style = configuration.traitCollection.userInterfaceStyle;
//        if (style == trait.userInterfaceStyle) {
//            return self;
//        }
//        else {
//            UIImage *image = [trait.imageDynamicAsset imageWithStyle:style];
//            if (image) {
//                return image;
//            }
//            else {
//                return self;
//            }
//        }
//    }
//}
//
//static void _ida_swizzling(Class cls, SEL oriSEL,  SEL desSEL) API_AVAILABLE(ios(13.0)) {
//    Method oriMethod = class_getInstanceMethod(cls, oriSEL);
//    Method desMethod = class_getInstanceMethod(cls, desSEL);
//    BOOL addSuccess = class_addMethod(cls, oriSEL, method_getImplementation(desMethod), method_getTypeEncoding(desMethod));
//    if (addSuccess) {
//        class_replaceMethod(cls, desSEL, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
//    }else {
//        method_exchangeImplementations(oriMethod, desMethod);
//    }
//}
//
//@end
