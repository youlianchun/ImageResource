//
//  UIImage+ImageDynamicAsset.h
//  ImageDynamicAsset
//
//  Created by YLCHUN on 2020/10/17.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface UIImage (ImageDynamicAsset)

+ (instancetype _Nullable)imageWithDynamicProvider:(UIImage *_Nullable(^)(UIUserInterfaceStyle style))dynamicProvider;

- (UIImage *_Nullable)dynamicProviderRawImage;

- (BOOL)isDynamicAssetImage;

@end

NS_ASSUME_NONNULL_END
