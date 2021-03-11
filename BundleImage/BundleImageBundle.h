//
//  BundleImageBundle.h
//  BundleImage
//
//  Created by YLCHUN on 2020/9/10.
//

#import <Foundation/Foundation.h>
#import "BundleImageType.h"
@class NSDataAsset;

NS_ASSUME_NONNULL_BEGIN

@interface BundleImageBundle : NSObject
@property (nonatomic, readonly) NSString *bundleKey;
@property (nonatomic, readonly) BOOL didAnalysis;

- (instancetype)initWithBundle:(NSBundle *_Nullable)bundle;

- (BOOL)analysisBundleIfNeed:(void(^)(void))callback;

- (NSString *_Nullable)indirectImagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark;
- (NSArray<NSString *> *_Nullable)indirectImageNamesWithType:(BundleImageType)type;
+ (void)cleanAsset;
@end

@interface BundleImageBundle (directly)
- (NSString *_Nullable)directlyImagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark;
- (NSArray<NSString *> *_Nullable)directlyImageNamesWithType:(BundleImageType)type;
@end

@interface BundleImageBundle (catalog)
- (NSDataAsset *_Nullable)catalogImageAssetForName:(NSString *)name dark:(BOOL)dark;
@end
NS_ASSUME_NONNULL_END
