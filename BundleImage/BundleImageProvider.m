//
//  BundleImageProvider.m
//  BundleImage
//
//  Created by YLCHUN on 2020/10/29.
//

#import "BundleImageProvider.h"
#import "BundleImageCache.h"
#import "BundleImageBundle.h"
#import "UIImage+BIGIF.h"
#import "UIImage+BIWebP.h"

@implementation BundleImageProvider

+ (instancetype _Nullable)providerWithImageName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(BundleImageBundle *)bundle cache:(BundleImageCache<NSString*, UIImage *> *)cache {
    NSString *key = [NSString stringWithFormat:@"%@_%@_%@_%@", bundle.bundleKey, name, type, @(dark)];
    
    UIImage *image = cache[key];
    
    NSString *path = nil;
    if (!image) {
        path = [bundle imagePathForName:name type:type dark:dark];
    }
    
    BundleImageProvider *provider = nil;
    if (image || path) {
        provider = [self new];
        provider->_cache = cache;
        provider->_type = type;
        provider->_key = key;
        provider->_image = image;
        provider->_path = path;
        provider->_name = name;
    }
    return provider;
}

- (UIImage *_Nullable)imageWithContents {
    BundleImageProviderHandler imageProvider = self.provider;
    UIImage *image = nil;
    if (imageProvider) {
        image = imageProvider(_path, _type);
    }
    else {
        if ([_type isEqualToString:BundleImageTypeGIF]) {
            image = [UIImage gifImageWithContentsOfFile:_path];
        }
        else if ([_type isEqualToString:BundleImageTypeWEBP]) {
            image = [UIImage webpImageWithContentsOfFile:_path];
        }
        else {
            image = [UIImage imageWithContentsOfFile:_path];
        }
    }
    BundleImageProcessHandler process = self.process;
    if (image && process) {
        image = process(image, _name, _type);
    }
    return image;
}

- (UIImage *)image {
    if (!_image && _path) {
        _image = [self imageWithContents];
        if (_key) {
            _cache[_key] = _image;
        }
    }
    return _image;
}

@end
