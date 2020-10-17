//
//  UIImage+ImageDynamicAsset.m
//  ImageDynamicAsset
//
//  Created by YLCHUN on 2020/10/17.
//

#import "UIImage+ImageDynamicAsset.h"
#import "ImageDynamicAsset.h"

API_AVAILABLE(ios(13.0))
@implementation UIImage (ImageDynamicAsset)

+ (instancetype _Nullable)imageWithDynamicProvider:(UIImage *_Nullable(^)(UIUserInterfaceStyle style))dynamicProvider {
    if (!dynamicProvider) return nil;
    ImageDynamicAsset *asset = [[ImageDynamicAsset alloc] initWithImageProvider:dynamicProvider];
    return [asset resolvedImageWithStyle:[UITraitCollection currentTraitCollection].userInterfaceStyle];
}

- (UIImage *)dynamicProviderRawImage {
    return [ImageDynamicAsset rawImageFromDynamicAssetImage:self];
}

- (BOOL)isDynamicAssetImage {
    return [ImageDynamicAsset isDynamicAssetImage:self];
}

@end
