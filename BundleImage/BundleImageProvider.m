//
//  BundleImageProvider.m
//  BundleImage
//
//  Created by YLCHUN on 2020/10/29.
//

#import "BundleImageProvider.h"
#import "BundleImageCache.h"
#import "BundleImageBundle.h"
#import <ImageDynamicAsset/ImageDynamicAsset.h>
#import "UIImage+BI_GIF.h"
#import "UIImage+BI_WebP.h"

@implementation BundleImageProvider

+ (instancetype _Nullable)indexWithImageName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(BundleImageBundle *)bundle cache:(BundleImageCache<NSString*, UIImage *> *)cache {
    NSString *key = [NSString stringWithFormat:@"%@_%@_%@_%@", bundle.bundleKey, name, type, @(dark)];
    
    UIImage *image = cache[key];
    
    NSString *path = nil;
    if (!image) {
        path = [bundle imagePathForName:name type:type dark:dark];
    }
    
    BundleImageProvider *index = nil;
    if (image || path) {
        index = [self new];
        index->_cache = cache;
        index->_type = type;
        index->_key = key;
        index->_image = image;
        index->_path = path;
        index->_name = name;
    }
    return index;
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
        _cache[_key] = _image;
    }
    return _image;
}

@end
