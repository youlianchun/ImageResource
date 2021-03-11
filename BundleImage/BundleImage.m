//
//  BundleImage.m
//  BundleImage
//
//  Created by YLCHUN on 2020/8/31.
//

#import "BundleImage.h"
#import "BundleImageImageProvider.h"
#import <ImageDynamicAsset/ImageDynamicAsset.h>
#import "BundleImageCache.h"
#import "BundleImageBundle.h"
#import "BundleImageHandler.h"
#import "pthread.h"

@implementation BundleImage
{
    BundleImageCache<NSString*, BundleImageBundle *> *_bundleCache;
    NSMutableDictionary<NSString*, BundleImageHandler *> *_handlerCache;
    BundleImageCache<NSString*, UIImage *> *_imageCache;
    pthread_mutex_t _mutex_t;
}

+ (instancetype)shareProvider {
    static BundleImage *kImageProvider = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kImageProvider = [[self alloc] init];
    });
    return kImageProvider;
}

- (instancetype)init {
    self = [super init];
    _bundleCache = [[BundleImageCache alloc] initWithCapacity:5];
    _handlerCache = [NSMutableDictionary dictionary];
    _imageCache = [[BundleImageCache alloc] initWithCapacity:50];
    pthread_mutex_init(&_mutex_t, NULL);
    return self;
}

- (void)dealloc {
    [_imageCache clean];
    _imageCache = nil;
    [_handlerCache removeAllObjects];
    _handlerCache = nil;
    [_bundleCache clean];
    _bundleCache = nil;
    pthread_mutex_destroy(&_mutex_t);
}

- (BundleImageHandler *)imageHandlerWithBundle:(NSBundle *)bundle init:(BOOL)init {
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    NSString *key = bundle.bundlePath;
    if (key.length == 0) return nil;
    
    BundleImageHandler *handler = nil;
    pthread_mutex_lock(&_mutex_t);
    if (key) {
        handler = _handlerCache[key];
        if (!handler && init) {
            handler = [BundleImageHandler new];
            _handlerCache[key] = handler;
        }
    }
    pthread_mutex_unlock(&_mutex_t);
    return handler;
}

- (BundleImageBundle *)imageBundle:(NSBundle *)bundle {
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    NSString *key = bundle.bundlePath;
    if (key.length == 0) return nil;
    BundleImageHandler *handler = [self imageHandlerWithBundle:bundle init:YES];
    BundleImageBundle *imageBundle = [_bundleCache objectForKey:key init:^BundleImageBundle * _Nonnull{
        return [[BundleImageBundle alloc] initWithBundle:bundle];
    }];
    
    if (handler.indirect) {
        __weak typeof(_bundleCache) bundleCache = _bundleCache;
        BOOL needProtect = [imageBundle analysisBundleIfNeed:^{
            [bundleCache unprotect:key];
        }];
        if (needProtect) {
            [_bundleCache protect:key];
        }
    }
    
    return imageBundle;
}

- (void)setIndirect:(BOOL)indirect inBundle:(NSBundle *_Nullable)bundle {
    [self imageHandlerWithBundle:bundle init:YES].indirect = indirect;
}

- (void)setAndCatalog:(BOOL)andCatalog inBundle:(NSBundle *_Nullable)bundle {
    [self imageHandlerWithBundle:bundle init:YES].andCatalog = andCatalog;
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

- (UIImage *_Nullable)imageNamed:(NSString *)name type:(BundleImageType)type inBundle:(NSBundle *)bundle {
    BundleImageBundle *imageBundle = [self imageBundle:bundle];
    if (!imageBundle) {
        return nil;
    }
    BundleImageHandler *handler = [self imageHandlerWithBundle:bundle init:NO];
    
    @autoreleasepool {
        BundleImageImageProvider *lightIndex = [BundleImageImageProvider providerWithImageName:name type:type dark:NO inBundle:imageBundle cache:_imageCache directly:handler.indirect andCatalog:handler.andCatalog];
        lightIndex.provider = handler.imageProvider;
        lightIndex.process = handler.imageProcess;
        if (@available(iOS 13.0, *)) {
            BundleImageImageProvider *darkIndex = [BundleImageImageProvider providerWithImageName:name type:type dark:YES inBundle:imageBundle cache:_imageCache directly:handler.indirect andCatalog:handler.andCatalog];
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
    BundleImageHandler *handler = [self imageHandlerWithBundle:bundle init:NO];
    if (handler.indirect) {
        return [imageBundle indirectImageNamesWithType:type];
    }else {
        return [imageBundle directlyImageNamesWithType:type];
    }
}

- (NSString *_Nullable)imagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(NSBundle *)bundle {
    BundleImageBundle *imageBundle = [self imageBundle:bundle];
    return [imageBundle indirectImagePathForName:name type:type dark:dark];
}


+ (void)setIndirect:(BOOL)indirect inBundle:(NSBundle *_Nullable)bundle {
    [[self shareProvider] setIndirect:indirect inBundle:bundle];
}

+ (void)setAndCatalog:(BOOL)andCatalog inBundle:(NSBundle *_Nullable)bundle {
    [[self shareProvider] setAndCatalog:andCatalog inBundle:bundle];
}

+ (void)setImageProvider:(BundleImageProviderHandler)imageProvider inBundle:(NSBundle *_Nullable)bundle {
    [[self shareProvider] setImageProvider:imageProvider inBundle:bundle];
}

+ (void)setDynamicAssetHandler:(BundleImageyDnamicAssetHandler)dynamicAssetHandler inBundle:(NSBundle *_Nullable)bundle API_AVAILABLE(ios(13.0)) {
    [[self shareProvider] setDynamicAssetHandler:dynamicAssetHandler inBundle:bundle];
}

+ (void)setImageProcess:(BundleImageProcessHandler)imageProcess inBundle:(NSBundle *_Nullable)bundle {
    [[self shareProvider] setImageProcess:imageProcess inBundle:bundle];
}

+ (NSString *_Nullable)imagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(NSBundle *_Nullable)bundle {
    if (name.length == 0 || type.length == 0) return nil;
    return [[self shareProvider] imagePathForName:name type:type dark:dark inBundle:bundle];
}

+ (UIImage *_Nullable)imageNamed:(NSString *)name type:(BundleImageType)type inBundle:(NSBundle *_Nullable)bundle {
    if (name.length == 0 || type.length == 0) return nil;
    return [[self shareProvider] imageNamed:name type:type inBundle:bundle];
}

+ (NSArray<NSString *> *_Nullable)imageNamesWithType:(BundleImageType)type inBundle:(NSBundle *_Nullable)bundle {
    if (type.length == 0) return nil;
    return [[self shareProvider] imageNamesWithType:type inBundle:bundle];
}

@end
