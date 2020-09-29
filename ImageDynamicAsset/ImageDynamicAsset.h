//
//  ImageDynamicAsset.h
//  ImageDynamicAsset
//
//  Created by YLCHUN on 2020/9/4.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(13.0))
@interface ImageDynamicAsset : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype _Nullable)initWithImageProvider:(UIImage *_Nullable(^)(UIUserInterfaceStyle style))provider NS_REQUIRES_SUPER;

- (UIImage *_Nullable)resolvedImageWithStyle:(UIUserInterfaceStyle)style NS_REQUIRES_SUPER;

- (UIImage *)cloneImageFromImage:(UIImage *)image;

+ (instancetype)assetWithImageProvider:(UIImage *_Nullable(^)(UIUserInterfaceStyle style))provider NS_REQUIRES_SUPER;

+ (BOOL)isDynamicAssetImage:(UIImage *)image;
+ (UIImage *_Nullable)rawImageFromDynamicAssetImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
