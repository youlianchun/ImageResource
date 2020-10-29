//
//  UIImage+BIGIF.h
//  BundleImage
//
//  Created by YLCHUN on 2020/8/30.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (BIGIF)
+ (UIImage *)gifImageWithContentsOfFile:(NSString *)file;
@end

NS_ASSUME_NONNULL_END
