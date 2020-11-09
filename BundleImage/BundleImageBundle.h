//
//  BundleImageBundle.h
//  BundleImage
//
//  Created by YLCHUN on 2020/9/10.
//

#import <Foundation/Foundation.h>
#import "BundleImageType.h"

NS_ASSUME_NONNULL_BEGIN


@interface BundleImageBundle : NSObject
@property (nonatomic, readonly) NSString *bundleKey;
@property (nonatomic, readonly) BOOL didAnalysis;

- (instancetype)initWithBundle:(NSBundle *_Nullable)bundle;
- (void)setDidAnalysisCallback:(void(^)(void))didAnalysisCallback;

- (NSString *_Nullable)imagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark;
- (NSArray<NSString *> *_Nullable)imageNamesWithType:(BundleImageType)type;

+ (void)cleanAsset;
@end

NS_ASSUME_NONNULL_END
