//
//  UIImage+WebP.m
//  BundleImage
//
//  Created by YLCHUN on 2020/9/5.
//

#import "UIImage+WebP.h"
#import <WebP/decode.h>

// Callback for CGDataProviderRelease
static void FreeImageData(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation UIImage (WebP)

+ (UIImage *)webpImageWithContentsOfFile:(NSString *)file {
    NSData *data = [NSData dataWithContentsOfFile:file];
    return [self webpImageWithData:data scale:scaleFromImageFile(file)];
}
+ (UIImage *)webpImageWithData:(NSData *)data scale:(CGFloat)scale {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }

    if (WebPGetFeatures(data.bytes, data.length, &config.input) != VP8_STATUS_OK) {
        return nil;
    }

    config.output.colorspace = config.input.has_alpha ? MODE_rgbA : MODE_RGB;
    config.options.use_threads = 1;

    // Decode the WebP image data into a RGBA value array.
    if (WebPDecode(data.bytes, data.length, &config) != VP8_STATUS_OK) {
        return nil;
    }

    int width = config.input.width;
    int height = config.input.height;
    if (config.options.use_scaling) {
        width = config.options.scaled_width;
        height = config.options.scaled_height;
    }

    // Construct a UIImage from the decoded RGBA value array.
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, FreeImageData);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = config.input.has_alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast : 0;
    size_t components = config.input.has_alpha ? 4 : 3;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);

    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);

    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);

    return image;
}

static CGFloat scaleFromImageFile(NSString *string) {
    NSString *regex = @"(?<=@)(\\d.\\d)|(\\d)(?=x\\..*)";
    NSError *error = NULL;
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
     NSArray<NSTextCheckingResult *> *matches = [regularExpression matchesInString:string options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators range:NSMakeRange(0, string.length)];
    NSString *str = [string substringWithRange:matches.lastObject.range];
    if (str.length == 0) {
        str = @"1";
    }
    return str.intValue;
}
@end


