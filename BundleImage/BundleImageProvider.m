//
//  XMImageProvider.m
//  BundleImage
//
//  Created by YLCHUN on 2020/8/31.
//

#import "BundleImageProvider.h"
#import "BundleImageProviderBundle.h"
#import "BundleImageCache.h"
#import <ImageDynamicAsset/ImageDynamicAsset.h>
#import "UIImage+GIF.h"
#import "UIImage+WebP.h"
#import "pthread.h"

@implementation BundleImageProvider

static BundleImageProvider *kImageProvider = nil;
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kImageProvider = [super allocWithZone:zone];
    });
    return kImageProvider;
}

+ (instancetype)shareProvider {
    if (!kImageProvider) {
        kImageProvider = [self new];
    }
    return kImageProvider;
}

- (instancetype)init {
    self = [super init];
    _bundleDict = [NSMutableDictionary dictionary];
    _cache = [[BundleImageCache alloc] initWithCapacity:50];
    pthread_mutex_init(&_mutex_t, NULL);
    return self;
}

- (void)setImageProvider:(BundleImageProviderHandler)imageProvider inBundle:(NSBundle *_Nullable)bundle {

}

- (void)setDynamicAssetHandler:(BundleImageyDnamicAssetHandler)dynamicAssetHandler inBundle:(NSBundle *_Nullable)bundle API_AVAILABLE(ios(13.0)) {

}

- (BundleImageProviderBundle *)imageBundle:(NSBundle *)bundle {
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    pthread_mutex_lock(&_mutex_t);
    BundleImageProviderBundle *imageBundle = _bundleDict[bundle.resourcePath];
    if (!imageBundle) {
        imageBundle = [[BundleImageProviderBundle alloc] initWithBundle:bundle];
        _bundleDict[bundle.resourcePath] = imageBundle;
    }
    pthread_mutex_unlock(&_mutex_t);
    return imageBundle;
}


- (NSString *_Nullable)imagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(NSBundle *)bundle {
    BundleImageProviderBundle *imageBundle = [self imageBundle:bundle];
    return [imageBundle imagePathForName:name type:type dark:dark];
}

- (UIImage *_Nullable)imageNamed:(NSString *)name type:(BundleImageType)type inBundle:(NSBundle *)bundle {
    BundleImageProviderBundle *imageBundle = [self imageBundle:bundle];
    if (@available(iOS 13.0, *)) {
        __weak typeof(self) wself = self;
        ImageDynamicAsset *ida = nil;
        UIImage *_Nullable(^imageProviderHandler)(UIUserInterfaceStyle style) = ^UIImage *_Nullable(UIUserInterfaceStyle style){
            return [wself imageNamed:name type:type dark:style == UIUserInterfaceStyleDark inBundle: imageBundle];
        };
        BundleImageyDnamicAssetHandler dynamicAssetHandler = imageBundle.dynamicAssetHandler;
        if (dynamicAssetHandler) {
            ida = dynamicAssetHandler(imageProviderHandler);
        }
        else {
            ida = [ImageDynamicAsset assetWithImageProvider:imageProviderHandler];
        }
        return [ida resolvedImageWithStyle:[UITraitCollection currentTraitCollection].userInterfaceStyle];
    } else {
        return [self imageNamed:name type:type dark:NO inBundle: imageBundle];
    }
}

- (UIImage *_Nullable)imageNamed:(NSString *)name type:(BundleImageType)type dark:(BOOL) dark inBundle:(BundleImageProviderBundle *)bundle {
    NSString *key =  [NSString stringWithFormat:@"%@_%@", bundle.bundleKey, name];
    UIImage *image = _cache[key];
    if (!image) {
        NSString *path = [bundle imagePathForName:name type:type dark:dark];
        if (path.length > 0) {
            image = [self imageWithContentsOfFile:path type:type inBundle:bundle];
            _cache[key] = image;
        }
    }
    return image;
}

- (UIImage *_Nullable)imageWithContentsOfFile:(NSString *)file type:(BundleImageType)type inBundle:(BundleImageProviderBundle *)bundle {
    BundleImageProviderHandler imageProvider = bundle.imageProvider;
    if (imageProvider) {
        return imageProvider(file, type);
    }
    else {
        if ([type isEqualToString:BundleImageTypeGIF]) {
           return [UIImage gifImageWithContentsOfFile:file];
        }
        else if ([type isEqualToString:BundleImageTypeWEBP]) {
           return [UIImage webpImageWithContentsOfFile:file];
        }
        else {
            return [UIImage imageWithContentsOfFile:file];
        }
    }
}

- (NSArray<NSString *> *_Nullable)imageNamesWithType:(BundleImageType)type inBundle:(NSBundle *)bundle {
    BundleImageProviderBundle *imageBundle = [self imageBundle:bundle];
    return [imageBundle imageNamesWithType:type];
}

+ (void)setImageProvider:(BundleImageProviderHandler)imageProvider inBundle:(NSBundle *_Nullable)bundle {
    [[self shareProvider] setImageProvider:imageProvider inBundle:bundle];
}

+ (void)setDynamicAssetHandler:(BundleImageyDnamicAssetHandler)dynamicAssetHandler inBundle:(NSBundle *_Nullable)bundle API_AVAILABLE(ios(13.0)) {
    [[self shareProvider] setDynamicAssetHandler:dynamicAssetHandler inBundle:bundle];
}

+ (NSString *_Nullable)imagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(NSBundle *)bundle {
    return [[self shareProvider] imagePathForName:name type:type dark:dark inBundle:bundle];
}

+ (UIImage *_Nullable)imageNamed:(NSString *)name type:(BundleImageType)type inBundle:(NSBundle *)bundle {
    return [[self shareProvider] imageNamed:name type:type inBundle:bundle];
}

+ (NSArray<NSString *> *_Nullable)imageNamesWithType:(BundleImageType)type inBundle:(NSBundle *)bundle {
    return [[self shareProvider] imageNamesWithType:type inBundle:bundle];
}
@end
