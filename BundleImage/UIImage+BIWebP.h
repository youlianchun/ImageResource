//
//  UIImage+BIWebP.h
//  BundleImage
//
//  Created by YLCHUN on 2020/9/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (BIWebP)
+ (UIImage *)webpImageWithContentsOfFile:(NSString *)file;
@end

NS_ASSUME_NONNULL_END