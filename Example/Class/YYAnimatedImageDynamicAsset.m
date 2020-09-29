//
//  YYAnimatedImageDynamicAsset.m
//  Example
//
//  Created by YLCHUN on 2020/9/4.
//

#import "YYAnimatedImageDynamicAsset.h"

API_AVAILABLE(ios(13.0))
@implementation YYAnimatedImageDynamicAsset

- (UIImage *)cloneImageFromImage:(UIImage *)image {
    Class YYImageClass = NSClassFromString(@"YYImage");
    if (YYImageClass && [image isKindOfClass:YYImageClass]) {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([image respondsToSelector:@selector(animatedImageData)]) {
            NSData *data = [image performSelector:@selector(animatedImageData)];
            if (data) {
                //yy动图复制
                return [[YYImageClass alloc] initWithData:data scale:image.scale];
            }
        }
    }
    return [super cloneImageFromImage:image];
}

@end
