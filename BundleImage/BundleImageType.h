//
//  BundleImageType.h
//  BundleImage
//
//  Created by YLCHUN on 2020/9/11.
//

/* 资源命名规则：
    lightImage         darkImage
1x: name.type       name_darkmode.type
2x: name@2x.type    name_darkmode@2x.type
3x: name@3x.type    name_darkmode@3x.type
*/

#import <UIKit/UIKit.h>

typedef NSString * BundleImageType;

static BundleImageType const _Nonnull BundleImageTypePNG = @"PNG";
static BundleImageType const _Nonnull BundleImageTypeWEBP = @"WEBP";
static BundleImageType const _Nonnull BundleImageTypeJPG = @"JPG";
static BundleImageType const _Nonnull BundleImageTypeGIF = @"GIF";

static NSString * const _Nonnull BundleImageDarkMode = @"_DARKMODE";


@class ImageDynamicAsset;
typedef UIImage *_Nullable(^BundleImageProviderHandler)(NSString *_Nonnull file, BundleImageType _Nonnull type);
typedef UIImage *_Nullable(^BundleImageProcessHandler)(UIImage *_Nonnull image, NSString *_Nonnull name, BundleImageType _Nonnull type);

typedef ImageDynamicAsset *_Nonnull(^BundleImageyDnamicAssetHandler)(UIImage *_Nullable(^_Nonnull imageProviderHandler)(UIUserInterfaceStyle style)) API_AVAILABLE(ios(13.0));
