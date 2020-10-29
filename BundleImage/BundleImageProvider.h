//
//  BundleImageProvider.h
//  BundleImage
//
//  Created by YLCHUN on 2020/10/29.
//

#import <Foundation/Foundation.h>
#import "BundleImageType.h"

NS_ASSUME_NONNULL_BEGIN

@class UIImage;
@class BundleImageCache<KeyType, ObjectType>;
@class BundleImageBundle;

@interface BundleImageProvider : NSObject
{
    __weak BundleImageCache<NSString*, UIImage *> *_cache;
    BundleImageType _type;
    NSString *_key;
    NSString *_path;
    NSString *_name;
    UIImage *_image;
}

@property (nonatomic, strong, readonly) UIImage *image;
@property (nonatomic, copy, nullable) BundleImageProviderHandler provider;
@property (nonatomic, copy, nullable) BundleImageProcessHandler process;

+ (instancetype _Nullable)providerWithImageName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark inBundle:(BundleImageBundle *)bundle cache:(BundleImageCache<NSString*, UIImage *> *)cache;

@end

NS_ASSUME_NONNULL_END
