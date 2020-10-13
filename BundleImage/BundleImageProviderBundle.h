//
//  BundleImageProviderBundle.h
//  BundleImage
//
//  Created by YLCHUN on 2020/10/13.
//

#import "BundleImageBundle.h"

NS_ASSUME_NONNULL_BEGIN

@interface BundleImageProviderBundle : BundleImageBundle
@property (nonatomic, copy, nullable) BundleImageProviderHandler imageProvider;
@property (nonatomic, copy, nullable) BundleImageyDnamicAssetHandler dynamicAssetHandler API_AVAILABLE(ios(13.0));
@end

NS_ASSUME_NONNULL_END
