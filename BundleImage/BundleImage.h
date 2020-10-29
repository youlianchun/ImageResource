//
//  BundleImage.h
//  BundleImage
//
//  Created by YLCHUN on 2020/8/31.
//

#import <UIKit/UIKit.h>
#import "BundleImageType.h"

NS_ASSUME_NONNULL_BEGIN
@class BundleImageBundle, BundleImageHandler, BundleImageCache<KeyType, ObjectType>;

@interface BundleImage : NSObject
{
    @protected
    BundleImageCache<NSString*, BundleImageBundle *> *_bundleCache;
    NSMutableDictionary<NSString*, BundleImageHandler *> *_handlerCache;
    BundleImageCache<NSString*, UIImage *> *_imageCache;
    pthread_mutex_t _mutex_t;
}

/// 设置Image构造block
/// @param imageProvider image构建block，file 为资源完整地址，type 为文件名上的 type
/// @param bundle image所在bundle
+ (void)setImageProvider:(BundleImageProviderHandler)imageProvider inBundle:(NSBundle *_Nullable)bundle;

/// 设置Image加工block
/// @param imageProcess image加工block
/// @param bundle image所在bundle
+ (void)setImageProcess:(BundleImageProcessHandler)imageProcess inBundle:(NSBundle *_Nullable)bundle;


/// 设置 ImageDynamicAsset，自定义动态图适配
/// @param dynamicAssetHandler 动态 image处理
/// @param bundle image所在bundle
+ (void)setDynamicAssetHandler:(BundleImageyDnamicAssetHandler)dynamicAssetHandler inBundle:(NSBundle *_Nullable)bundle API_AVAILABLE(ios(13.0));

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

@interface BundleImage (debug)
+ (void)debug;
@end

NS_ASSUME_NONNULL_END
