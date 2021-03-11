//
//  BundleImageProvider.m
//  BundleImage
//
//  Created by YLCHUN on 2020/10/29.
//

#import "BundleImageImageProvider.h"
#import "BundleImageCache.h"
#import "BundleImageBundle.h"
#import "UIImage+BIGIF.h"
#import "UIImage+BIWebP.h"

#define YY_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))
#define YY_TWO_CC(c1,c2) ((uint16_t)(((c2) << 8) | (c1)))

typedef NS_ENUM(NSUInteger, BIImageType) {
    BIImageTypeUnknown = 0, ///< unknown
    BIImageTypeJPEG,        ///< jpeg, jpg
    BIImageTypeJPEG2000,    ///< jp2
    BIImageTypeTIFF,        ///< tiff, tif
    BIImageTypeBMP,         ///< bmp
    BIImageTypeICO,         ///< ico
    BIImageTypeICNS,        ///< icns
    BIImageTypeGIF,         ///< gif
    BIImageTypePNG,         ///< png
    BIImageTypeWebP,        ///< webp
    BIImageTypeOther,       ///< other image format
};

static BIImageType BIImageDetectType(CFDataRef data) {
    if (!data) return BIImageTypeUnknown;
    uint64_t length = CFDataGetLength(data);
    if (length < 16) return BIImageTypeUnknown;
    
    const char *bytes = (char *)CFDataGetBytePtr(data);
    
    uint32_t magic4 = *((uint32_t *)bytes);
    switch (magic4) {
        case YY_FOUR_CC(0x4D, 0x4D, 0x00, 0x2A): { // big endian TIFF
            return BIImageTypeTIFF;
        } break;
            
        case YY_FOUR_CC(0x49, 0x49, 0x2A, 0x00): { // little endian TIFF
            return BIImageTypeTIFF;
        } break;
            
        case YY_FOUR_CC(0x00, 0x00, 0x01, 0x00): { // ICO
            return BIImageTypeICO;
        } break;
            
        case YY_FOUR_CC(0x00, 0x00, 0x02, 0x00): { // CUR
            return BIImageTypeICO;
        } break;
            
        case YY_FOUR_CC('i', 'c', 'n', 's'): { // ICNS
            return BIImageTypeICNS;
        } break;
            
        case YY_FOUR_CC('G', 'I', 'F', '8'): { // GIF
            return BIImageTypeGIF;
        } break;
            
        case YY_FOUR_CC(0x89, 'P', 'N', 'G'): {  // PNG
            uint32_t tmp = *((uint32_t *)(bytes + 4));
            if (tmp == YY_FOUR_CC('\r', '\n', 0x1A, '\n')) {
                return BIImageTypePNG;
            }
        } break;
            
        case YY_FOUR_CC('R', 'I', 'F', 'F'): { // WebP
            uint32_t tmp = *((uint32_t *)(bytes + 8));
            if (tmp == YY_FOUR_CC('W', 'E', 'B', 'P')) {
                return BIImageTypeWebP;
            }
        } break;
        /*
        case YY_FOUR_CC('B', 'P', 'G', 0xFB): { // BPG
            return BIImageTypeBPG;
        } break;
        */
    }
    
    uint16_t magic2 = *((uint16_t *)bytes);
    switch (magic2) {
        case YY_TWO_CC('B', 'A'):
        case YY_TWO_CC('B', 'M'):
        case YY_TWO_CC('I', 'C'):
        case YY_TWO_CC('P', 'I'):
        case YY_TWO_CC('C', 'I'):
        case YY_TWO_CC('C', 'P'): { // BMP
            return BIImageTypeBMP;
        }
        case YY_TWO_CC(0xFF, 0x4F): { // JPEG2000
            return BIImageTypeJPEG2000;
        }
    }
    
    // JPG             FF D8 FF
    if (memcmp(bytes,"\377\330\377",3) == 0) return BIImageTypeJPEG;
    
    // JP2
    if (memcmp(bytes + 4, "\152\120\040\040\015", 5) == 0) return BIImageTypeJPEG2000;
    
    return BIImageTypeUnknown;
}


@implementation BundleImageImageProvider
{
    __weak BundleImageCache<NSString*, UIImage *> *_cache;
    BundleImageType _type;
    NSString *_key;
    NSString *_path;
    NSDataAsset *_dataAsset;
    NSString *_name;
    UIImage *_image;
}

+ (instancetype _Nullable)providerWithImageName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(BundleImageBundle *)bundle cache:(BundleImageCache<NSString*, UIImage *> *)cache key:(NSString *)key indirect:(BOOL)indirect andCatalog:(BOOL)andCatalog {
    UIImage *image = nil;
    if (key) {
        image = cache[key];
    }

    NSString *path = nil;
    NSDataAsset *dataAsset = nil;
    if (!image) {
        if ([type isEqualToString:BundleImageTypeCatalog]) {
            NSDataAsset *asset = [bundle catalogImageAssetForName:name dark:dark];
            if (asset.data.length > 0) {
                BIImageType assetType = BIImageDetectType((__bridge CFDataRef)(asset.data));
                if ((assetType != BIImageTypeUnknown) && (assetType != BIImageTypeOther)) {
                    if (assetType == BIImageTypeGIF) {
                        type = BundleImageTypeGIF;
                    }
                    dataAsset = asset;
                }else {
                    // 其他类型数据，不做处理
                }
            }
        }
        else {
            if (indirect) {
                path = [bundle indirectImagePathForName:name type:type dark:dark];
            }else {
                path = [bundle directlyImagePathForName:name type:type dark:dark];
            }
            if (path.length == 0 && andCatalog) {
                NSDataAsset *asset = [bundle catalogImageAssetForName:name dark:dark];
                if (asset.data.length > 0) {
                    BIImageType assetType = BIImageDetectType((__bridge CFDataRef)(asset.data));
                    if ((assetType == BIImageTypePNG && [type isEqualToString:BundleImageTypePNG]) ||
                        (assetType == BIImageTypeWebP && [type isEqualToString:BundleImageTypeWEBP]) ||
                        (assetType == BIImageTypeGIF && [type isEqualToString:BundleImageTypeGIF]) ||
                        (assetType == BIImageTypeJPEG && [type isEqualToString:BundleImageTypeJPG])) {
                        dataAsset = asset;
                    }else {
                        // 类型不一致，不做处理
                    }
                }
            }
        }
        
    }
    
    BundleImageImageProvider *provider = nil;
    if (image || path || dataAsset) {
        provider = [self new];
        provider->_cache = cache;
        provider->_type = type;
        provider->_key = key;
        provider->_image = image;
        provider->_dataAsset = dataAsset;
        provider->_path = path;
        provider->_name = name;
    }
    return provider;
}

+ (instancetype _Nullable)providerWithImageName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(BundleImageBundle *)bundle cache:(BundleImageCache<NSString*, UIImage *> *)cache directly:(BOOL)directly andCatalog:(BOOL)andCatalog {
    NSString *key = [NSString stringWithFormat:@"%@_%@_%@_%@", bundle.bundleKey, name, type, @(dark)];
    BundleImageImageProvider *provider = [self providerWithImageName:name type:type dark:dark inBundle:bundle cache:cache key:key indirect:directly andCatalog:andCatalog];
    return provider;
}

- (UIImage *_Nullable)imageWithContents {
    UIImage *image = nil;
    NSString *identifier = nil;
    CGFloat scale = 1;
    NSData *data = nil;
    if (_path.length > 0) {
        identifier = _path;
        scale = scaleFromImageFile(_path);
        data = [NSData dataWithContentsOfFile:_path];
    }
    else if (_dataAsset) {
        identifier = _dataAsset.name;
        scale = scaleFromImageFile(_dataAsset.name);
        data = _dataAsset.data;
    }
    
    BundleImageProviderHandler provider = self.provider;
    if (provider) {
        image = provider(identifier, _type, data, _name, scale);
    }
    else {
        image = [self imageWithData:data scale:scale];
    }
    
    BundleImageProcessHandler process = self.process;
    if (image && process) {
        image = process(image, _name, _type);
    }
    return image;
}

- (UIImage *)imageWithData:(NSData *)data scale:(CGFloat)scale {
    if ([_type isEqualToString:BundleImageTypeGIF]) {
        return [UIImage bi_gifImageWithData:data scale:scale];
    }
    else if ([_type isEqualToString:BundleImageTypeWEBP]) {
        return [UIImage bi_webpImageWithData:data scale:scale];
    }
    else {
        return [UIImage imageWithData:data scale:scale];
    }
}

- (UIImage *)image {
    if (!_image) {
        _image = [self imageWithContents];
        if (_key) {
            _cache[_key] = _image;
        }
    }
    return _image;
}

static CGFloat scaleFromImageFile(NSString *string) {
    if (string.length == 0 || [string hasSuffix:@"/"]) return 1;
    NSString *name = string.stringByDeletingPathExtension;
    __block CGFloat scale = 1;
    
    NSRegularExpression *pattern = [NSRegularExpression regularExpressionWithPattern:@"@[0-9]+\\.?[0-9]*x$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [pattern enumerateMatchesInString:name options:kNilOptions range:NSMakeRange(0, name.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.range.location >= 3) {
            scale = [string substringWithRange:NSMakeRange(result.range.location + 1, result.range.length - 2)].doubleValue;
        }
    }];
    
    return scale;
}

@end
