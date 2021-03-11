//
//  UIImage+BIWebP.m
//  BundleImage
//
//  Created by YLCHUN on 2020/9/5.
//

#import "UIImage+BIWebP.h"
#import <WebP/decode.h>
#import <WebP/encode.h>
#import <WebP/demux.h>
#import <WebP/mux.h>

// Callback for CGDataProviderRelease
static void FreeImageData(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation UIImage (BIWebP)

+ (UIImage *)bi_webpImageWithData:(NSData *)data scale:(CGFloat)scale {
    if (!data || data.length == 0) return NULL;
    
    WebPData webpData = {0};
    webpData.bytes = data.bytes;
    webpData.size = data.length;
    
    WebPDemuxer *demuxer = WebPDemux(&webpData);
    if (!demuxer) {
        return nil;
    }
    
    int frameCount = WebPDemuxGetI(demuxer, WEBP_FF_FRAME_COUNT);
    if (frameCount == 0) {
        WebPDemuxDelete(demuxer);
        return nil;
    }
    else if (frameCount == 1) {
        WebPDemuxDelete(demuxer);
        return [self _bi_webpImageWithData:data scale:scale];
    }
    else {
        int canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
        int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
        CGColorSpaceRef colorSpace = WebPDemuxGetColorSpace(demuxer);
        if (!colorSpace) {
            colorSpace = CGColorSpaceCreateDeviceRGB();
        }
 
        NSTimeInterval duration = 0.0f;
        NSMutableArray *images = [NSMutableArray array];
        WebPIterator iter = {0};
        if (WebPDemuxGetFrame(demuxer, 1, &iter)) {
            do {
                CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
                        bitmapInfo |= iter.has_alpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
                CGContextRef canvas = CGBitmapContextCreate(NULL, canvasWidth, canvasHeight, 8, 0, colorSpace, bitmapInfo);
                
                duration += iter.duration;
                CGImageRef cgimage = [self _bi_drawnWebpImageWithCanvas:canvas iterator:iter colorSpace:colorSpace];
                UIImage *image = [UIImage imageWithCGImage:cgimage];

                [images addObject:image];
            } while (WebPDemuxNextFrame(&iter));
            WebPDemuxReleaseIterator(&iter);
        }
        WebPDemuxDelete(demuxer);
        return [UIImage animatedImageWithImages:images duration:duration/1000.0];

    }
}

+ (UIImage *)_bi_webpImageWithData:(NSData *)data scale:(CGFloat)scale {
    WebPDecoderConfig config = {0};
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


+(nullable CGImageRef)_bi_drawnWebpImageWithCanvas:(CGContextRef)canvas iterator:(WebPIterator)iter colorSpace:(nonnull CGColorSpaceRef)colorSpaceRef CF_RETURNS_RETAINED {
   CGImageRef imageRef = [self _bi_webpImageRefWithData:iter.fragment colorSpace:colorSpaceRef];
   if (!imageRef) {
       return nil;
   }
   
   size_t canvasHeight = CGBitmapContextGetHeight(canvas);
   CGFloat tmpX = iter.x_offset;
   CGFloat tmpY = canvasHeight - iter.height - iter.y_offset;
   CGRect imageRect = CGRectMake(tmpX, tmpY, iter.width, iter.height);
   BOOL shouldBlend = iter.blend_method == WEBP_MUX_BLEND;
   
   // If not blend, cover the target image rect. (firstly clear then draw)
   if (!shouldBlend) {
       CGContextClearRect(canvas, imageRect);
   }
   CGContextDrawImage(canvas, imageRect, imageRef);
   CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
   
   CGImageRelease(imageRef);
   
   if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
       CGContextClearRect(canvas, imageRect);
   }
   
   return newImageRef;
}

+ (nullable CGImageRef)_bi_webpImageRefWithData:(WebPData)webpData colorSpace:(nonnull CGColorSpaceRef)colorSpaceRef CF_RETURNS_RETAINED {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }
    
    if (WebPGetFeatures(webpData.bytes, webpData.size, &config.input) != VP8_STATUS_OK) {
        return nil;
    }
    
    BOOL hasAlpha = config.input.has_alpha;
    // iOS prefer BGRA8888 (premultiplied) or BGRX8888 bitmapInfo for screen rendering, which is same as `UIGraphicsBeginImageContext()` or `- [CALayer drawInContext:]`
    // use this bitmapInfo, combined with right colorspace, even without decode, can still avoid extra CA::Render::copy_image(which marked `Color Copied Images` from Instruments)
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    config.options.use_threads = 1;
    config.output.colorspace = MODE_bgrA;
    
    // Decode the WebP image data into a RGBA value array
    if (WebPDecode(webpData.bytes, webpData.size, &config) != VP8_STATUS_OK) {
        return nil;
    }
    
    int width = config.input.width;
    int height = config.input.height;
    if (config.options.use_scaling) {
        width = config.options.scaled_width;
        height = config.options.scaled_height;
    }
    
    // Construct a UIImage from the decoded RGBA value array
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, FreeImageData);
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = config.output.u.RGBA.stride;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGDataProviderRelease(provider);
    
    return imageRef;
}

static CGColorSpaceRef WebPDemuxGetColorSpace(WebPDemuxer *demuxer) CF_RETURNS_RETAINED {
    // WebP contains ICC Profile should use the desired colorspace, instead of default device colorspace
    // See: https://developers.google.com/speed/webp/docs/riff_container#color_profile
    
    CGColorSpaceRef colorSpaceRef = NULL;
    uint32_t flags = WebPDemuxGetI(demuxer, WEBP_FF_FORMAT_FLAGS);
    
    if (flags & ICCP_FLAG) {
        WebPChunkIterator chunk_iter;
        int result = WebPDemuxGetChunk(demuxer, "ICCP", 1, &chunk_iter);
        if (result) {
            // See #2618, the `CGColorSpaceCreateWithICCProfile` does not copy ICC Profile data, it only retain `CFDataRef`.
            // When the libwebp `WebPDemuxer` dealloc, all chunks will be freed. So we must copy the ICC data (really cheap, less than 10KB)
            NSData *profileData = [NSData dataWithBytes:chunk_iter.chunk.bytes length:chunk_iter.chunk.size];
//            colorSpaceRef = CGColorSpaceCreateWithICCData((__bridge CFTypeRef _Nullable)(profileData));
            colorSpaceRef = CGColorSpaceCreateWithICCProfile((__bridge CFDataRef)profileData);
            WebPDemuxReleaseChunkIterator(&chunk_iter);
            if (colorSpaceRef) {
                // We use RGB color model to decode WebP images currently, so we must filter out other colorSpace
                CGColorSpaceModel model = CGColorSpaceGetModel(colorSpaceRef);
                if (model != kCGColorSpaceModelRGB) {
                    CGColorSpaceRelease(colorSpaceRef);
                    colorSpaceRef = NULL;
                }
            }
        }
    }
    return colorSpaceRef;
}


@end


