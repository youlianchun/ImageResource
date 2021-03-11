//
//  BundleImage.h
//  BundleImage
//
//  Created by YLCHUN on 2020/8/31.
//

#import <UIKit/UIKit.h>
#import "BundleImageType.h"

NS_ASSUME_NONNULL_BEGIN

@interface BundleImage : NSObject

/// 文件资源获取不到时候查找Catalog
/// @param andCatalog def NO YES 文件资源获取不到时候查找Catalog
/// @param bundle image所在bundle nil: mianBundle
+ (void)setAndCatalog:(BOOL)andCatalog inBundle:(NSBundle *_Nullable)bundle;

/// 设置 imageProvider，image构造block
/// @param imageProvider image构建block，file 为资源完整地址，type为文件名上的type
/// @param bundle image所在bundle nil: mianBundle
+ (void)setImageProvider:(BundleImageProviderHandler _Nullable)imageProvider inBundle:(NSBundle *_Nullable)bundle;

/// 设置 imageProcess image处理block
/// @param imageProcess 用于处理拉伸等asset里的图片操作
/// @param bundle image所在bundle nil: mianBundle
+ (void)setImageProcess:(BundleImageProcessHandler)imageProcess inBundle:(NSBundle *_Nullable)bundle;

/// 设置 dynamicAssetHandler，自定义动态图适配
/// @param dynamicAssetHandler 动态 image处理
/// @param bundle image所在bundle nil: mianBundle
+ (void)setDynamicAssetHandler:(BundleImageyDnamicAssetHandler _Nullable)dynamicAssetHandler inBundle:(NSBundle *_Nullable)bundle API_AVAILABLE(ios(13.0));

/// 获取图片完整地址
/// @param name image name、path/name
/// @param type 类型
/// @param dark 是否是dark mode
/// @param bundle image所在bundle nil: mianBundle
+ (NSString *_Nullable)imagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(NSBundle *_Nullable)bundle;

/// 读取图片
/// @param name image name
/// @param type 类型(资源扩展名为 BundleImageType 小写)
/// @param bundle 资源目录
+ (UIImage *_Nullable)imageNamed:(NSString *)name type:(BundleImageType)type inBundle:(NSBundle *_Nullable)bundle;

/// 读取图片名称数组
/// @param type 类型
/// @param bundle image所在bundle nil: mianBundle
+ (NSArray<NSString *> *_Nullable)imageNamesWithType:(BundleImageType)type inBundle:(NSBundle *_Nullable)bundle;

@end


NS_ASSUME_NONNULL_END
