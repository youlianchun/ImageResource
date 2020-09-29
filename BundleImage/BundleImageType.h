//
//  BundleImageType.h
//  BundleImage
//
//  Created by YLCHUN on 2020/9/11.
//

/* 资源命名规则：
    lightImage         darkImage
1x: name.type       name_darkmode.type
2x: name@2x.type    name_darkmode@2x.type
3x: name@3x.type    name_darkmode@3x.type
*/

#import <Foundation/Foundation.h>

typedef NSString * BundleImageType;

static BundleImageType const BundleImageTypePNG = @"PNG";
static BundleImageType const BundleImageTypeWEBP = @"WEBP";
static BundleImageType const BundleImageTypeJPG = @"JPG";
static BundleImageType const BundleImageTypeGIF = @"GIF";

static NSString * const BundleImageDarkMode = @"_DARKMODE";
