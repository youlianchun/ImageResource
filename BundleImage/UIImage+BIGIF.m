//
//  UIImage+GIF.m
//  BundleImage
//
//  Created by YLCHUN on 2020/8/30.
//  Copyright © 2020 YLCHUN. All rights reserved.
//
// 实现摘自 SDWebImage，原因：SDWebImage GIF未做倍图支持

#import "UIImage+BIGIF.h"

@implementation UIImage (BIGIF)

+ (UIImage *)bi_gifImageWithData:(NSData *)data scale:(CGFloat)scale {
    if (!data) return nil;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage = nil;
    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data scale:scale];
    } else {
        NSMutableArray *images = [NSMutableArray array];
        NSTimeInterval duration = 0.0f;
        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);
            NSTimeInterval frameDuration = [self xmbi_frameDurationAtIndex:i source:source];
            duration += frameDuration;
            [images addObject:[UIImage imageWithCGImage:image scale:scale orientation:UIImageOrientationUp]];
            CFRelease(image);
        }
        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }
        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }
    CFRelease(source);
    
    return animatedImage;
}

+ (float)xmbi_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *gifProperties = frameProperties[(NSString *)kCGImagePropertyGIFDictionary];

    NSNumber *delayTimeUnclampedProp = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTimeUnclampedProp) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    }
    else {
        NSNumber *delayTimeProp = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTimeProp) {
            frameDuration = [delayTimeProp floatValue];
        }
    }

    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }

    CFRelease(cfFrameProperties);
    return frameDuration;
}

@end
