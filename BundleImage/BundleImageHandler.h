//
//  BundleImageHandler.h
//  BundleImage
//
//  Created by YLCHUN on 2020/10/29.
//

#import <Foundation/Foundation.h>
#import "BundleImageType.h"

NS_ASSUME_NONNULL_BEGIN

@interface BundleImageHandler : NSObject
@property (nonatomic, copy, nullable) BundleImageProviderHandler imageProvider;
@property (nonatomic, copy, nullable) BundleImageProcessHandler imageProcess;
@property (nonatomic, copy, nullable) BundleImageyDnamicAssetHandler dynamicAssetHandler API_AVAILABLE(ios(13.0));
@end

NS_ASSUME_NONNULL_END
