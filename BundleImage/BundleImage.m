//
//  BundleImage.m
//  BundleImage
//
//  Created by YLCHUN on 2020/8/31.
//

#import "BundleImage.h"
#import "BundleImageBundle.h"
#import "BundleImageHandler.h"
#import "BundleImageProvider.h"
#import "BundleImageCache.h"
#import <ImageDynamicAsset/ImageDynamicAsset.h>
#import "pthread.h"

@implementation BundleImage

static NSUInteger const kBIBundleCacheCapacity = 5;
static NSUInteger const kBIImageCacheCapacity = 50;

static BundleImage *_kBundleImageShareInstance = nil;
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _kBundleImageShareInstance = [super allocWithZone:zone];
    });
    return _kBundleImageShareInstance;
}

+ (instancetype)shareInstance {
    if (!_kBundleImageShareInstance) {
        _kBundleImageShareInstance = [self new];
    }
    return _kBundleImageShareInstance;
}

- (instancetype)init {
    self = [super init];
    _bundleCache = [[BundleImageCache alloc] initWithCapacity:kBIBundleCacheCapacity];
    _imageCache = [[BundleImageCache alloc] initWithCapacity:kBIImageCacheCapacity];
    _handlerCache = [NSMutableDictionary dictionary];
    pthread_mutex_init(&_mutex_t, NULL);
    return self;
}

- (void)setImageProvider:(BundleImageProviderHandler)imageProvider inBundle:(NSBundle *_Nullable)bundle {
    [self imageHandlerWithBundle:bundle init:YES].imageProvider = imageProvider;
}

- (void)setImageProcess:(BundleImageProcessHandler)imageProcess inBundle:(NSBundle *_Nullable)bundle {
    [self imageHandlerWithBundle:bundle init:YES].imageProcess = imageProcess;

}

- (void)setDynamicAssetHandler:(BundleImageyDnamicAssetHandler)dynamicAssetHandler inBundle:(NSBundle *_Nullable)bundle API_AVAILABLE(ios(13.0)) {
    [self imageHandlerWithBundle:bundle init:YES].dynamicAssetHandler = dynamicAssetHandler;
}

- (BundleImageHandler *)imageHandlerWithBundle:(NSBundle *)bundle init:(BOOL)init {
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    pthread_mutex_lock(&_mutex_t);
    BundleImageHandler *handler = _handlerCache[bundle.resourcePath];
    if (!handler && init) {
        handler = [BundleImageHandler new];
        _handlerCache[bundle.resourcePath] = handler;
    }
    pthread_mutex_unlock(&_mutex_t);
    return handler;
}

- (BundleImageBundle *)imageBundle:(NSBundle *)bundle {
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    BundleImageBundle *imageBundle = [_bundleCache objectForKey:bundle.resourcePath init:^BundleImageBundle * _Nonnull{
        return [[BundleImageBundle alloc] initWithBundle:bundle];
    }];
    return imageBundle;
}

- (UIImage *_Nullable)imageNamed:(NSString *)name type:(BundleImageType)type inBundle:(NSBundle *)bundle {
    BundleImageBundle *imageBundle = [self imageBundle:bundle];
    
    BundleImageHandler *handler = [self imageHandlerWithBundle:bundle init:NO];
    
    @autoreleasepool {
        BundleImageProvider *lightIndex = [BundleImageProvider providerWithImageName:name type:type dark:NO inBundle:imageBundle cache:_imageCache];
        lightIndex.provider = handler.imageProvider;
        lightIndex.process = handler.imageProcess;
        if (@available(iOS 13.0, *)) {
            BundleImageProvider *darkIndex = [BundleImageProvider providerWithImageName:name type:type dark:YES inBundle:imageBundle cache:_imageCache];
            darkIndex.provider = handler.imageProvider;
            darkIndex.process = handler.imageProcess;

            if (lightIndex && darkIndex) {
                ImageDynamicAsset *ida = nil;
                UIImage *_Nullable(^imageProviderHandler)(UIUserInterfaceStyle style) = ^UIImage *_Nullable(UIUserInterfaceStyle style){
                    UIImage *image = nil;
                    if (style == UIUserInterfaceStyleDark) {
                        image = darkIndex.image;
                    }else {
                        image = lightIndex.image;
                    }
                    return image;
                };
                BundleImageyDnamicAssetHandler dynamicAssetHandler = handler.dynamicAssetHandler;
                if (dynamicAssetHandler) {
                    ida = dynamicAssetHandler(imageProviderHandler);
                }
                else {
                    ida = [ImageDynamicAsset assetWithImageProvider:imageProviderHandler];
                }
                return [ida resolvedImageWithStyle:[UITraitCollection currentTraitCollection].userInterfaceStyle];
            }
            else if (lightIndex) {
                return lightIndex.image;
            }
            else if (darkIndex) {
                return darkIndex.image;
            }
            else {
                return nil;
            }
        }
        else {
            return lightIndex.image;
        }
    }
}

- (NSArray<NSString *> *_Nullable)imageNamesWithType:(BundleImageType)type inBundle:(NSBundle *)bundle {
    BundleImageBundle *imageBundle = [self imageBundle:bundle];
    return [imageBundle imageNamesWithType:type];
}

- (NSString *_Nullable)imagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(NSBundle *)bundle {
    BundleImageBundle *imageBundle = [self imageBundle:bundle];
    return [imageBundle imagePathForName:name type:type dark:dark];
}

+ (void)setImageProvider:(BundleImageProviderHandler)imageProvider inBundle:(NSBundle *_Nullable)bundle {
    [[self shareInstance] setImageProvider:imageProvider inBundle:bundle];
}

+ (void)setImageProcess:(BundleImageProcessHandler)imageProcess inBundle:(NSBundle *_Nullable)bundle {
    [[self shareInstance] setImageProcess:imageProcess inBundle:bundle];
}

+ (void)setDynamicAssetHandler:(BundleImageyDnamicAssetHandler)dynamicAssetHandler inBundle:(NSBundle *_Nullable)bundle API_AVAILABLE(ios(13.0)) {
    [[self shareInstance] setDynamicAssetHandler:dynamicAssetHandler inBundle:bundle];
}

+ (NSString *_Nullable)imagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(NSBundle *)bundle {
    return [[self shareInstance] imagePathForName:name type:type dark:dark inBundle:bundle];
}

+ (UIImage *_Nullable)imageNamed:(NSString *)name type:(BundleImageType)type inBundle:(NSBundle *)bundle {
    return [[self shareInstance] imageNamed:name type:type inBundle:bundle];
}

+ (NSArray<NSString *> *_Nullable)imageNamesWithType:(BundleImageType)type inBundle:(NSBundle *)bundle {
    return [[self shareInstance] imageNamesWithType:type inBundle:bundle];
}
@end


@implementation BundleImage (debug)

+ (void)debug {
    [BundleImageBundle cleanAsset];
}

@end
