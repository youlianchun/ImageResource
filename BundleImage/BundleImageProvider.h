//
//  XMImageProvider.h
//  BundleImage
//
//  Created by YLCHUN on 2020/8/31.
//

#import <UIKit/UIKit.h>
#import "BundleImageType.h"

NS_ASSUME_NONNULL_BEGIN
@class ImageDynamicAsset;

@interface BundleImageProvider : NSObject

/// 设置Image构造block
/// @param imageProvider image构建block，file 为资源完整地址，type 为文件名上的 type
+ (void)setImageProvider:(UIImage *_Nullable(^_Nullable)(NSString *file, BundleImageType type))imageProvider;

/// 设置 ImageDynamicAsset，自定义动态图适配
/// @param dynamicAssetHandler 动态 image处理
+ (void)setDynamicAssetHandler:(ImageDynamicAsset *(^_Nullable)(UIImage *_Nullable(^imageProviderHandler)(UIUserInterfaceStyle style)))dynamicAssetHandler API_AVAILABLE(ios(13.0));

/// 获取图片完整地址
/// @param name image name、path/name
/// @param type 类型
/// @param dark 是否是dark mode
/// @param bundle image所在bundle
+ (NSString *_Nullable)imagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(NSBundle *_Nullable)bundle;

/// 读取图片
/// @param name image name、path/name
/// @param type 类型
/// @param bundle image所在bundle
+ (UIImage *_Nullable)imageNamed:(NSString *)name type:(BundleImageType)type inBundle:(NSBundle *_Nullable)bundle;

+ (NSArray<NSString *> *_Nullable)imageNamesWithType:(BundleImageType)type inBundle:(NSBundle *_Nullable)bundle;

@end

NS_ASSUME_NONNULL_END
