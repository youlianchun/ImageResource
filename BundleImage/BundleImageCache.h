//
//  BundleImageCache.h
//  BundleImage
//
//  Created by YLCHUN on 2020/2/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BundleImageCache<KeyType, ObjectType> : NSObject

@property (nonatomic, readonly, assign) NSUInteger capacity;//def 10;
- (instancetype)initWithCapacity:(NSUInteger)capacity;

- (void)setObject:(nullable ObjectType)object forKey:(KeyType<NSCopying>)key;
- (nullable ObjectType)objectForKey:(KeyType<NSCopying>)key;
- (void)clean;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType <NSCopying>)key;
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;

- (void)protect:(KeyType)key;
- (void)unprotect:(KeyType)key;
@end

@interface BundleImageCache<KeyType, ObjectType>(init)
- (nullable ObjectType)objectForKey:(KeyType<NSCopying>)key init:(nullable ObjectType(^)(void))init;
@end

@interface BundleImageCache(patrol)
- (void)patrolTime:(NSTimeInterval)time;
@end

@interface BundleImageCache(lock)
- (void)lockBlock:(void(^)(void))block;
@end

NS_ASSUME_NONNULL_END
