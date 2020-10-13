# BundleImage

[![CI Status](https://img.shields.io/travis/YLCHUN/BundleImage.svg?style=flat)](https://travis-ci.org/YLCHUN/BundleImage)
[![Version](https://img.shields.io/cocoapods/v/BundleImage.svg?style=flat)](https://cocoapods.org/pods/BundleImage)
[![License](https://img.shields.io/cocoapods/l/BundleImage.svg?style=flat)](https://cocoapods.org/pods/BundleImage)
[![Platform](https://img.shields.io/cocoapods/p/BundleImage.svg?style=flat)](https://cocoapods.org/pods/BundleImage)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```
//默认方式 加载图片
+ (UIImage *)webpImageNamed:(NSString *)name
    NSBundle *bundle = xxx;
    UIImage *image = [BundleImageProvider imageNamed:name type:BundleImageTypeWEBP inBundle:bundle];
}
```
```
//YYImage 加载图片
+ (UIImage *)webpImageNamed:(NSString *)name
    NSBundle *bundle = xxx;
    UIImage *image = [BundleImageProvider yy_imageNamed:name type:BundleImageTypeWEBP inBundle:bundle];
} 
```
```
//自定义 加载图片
+ (void)prepareIfNeed {
    NSBundle *bundle = xxx;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BundleImageProvider setImageProvider:^UIImage * _Nullable(NSString * _Nonnull file, BundleImageType  _Nonnull type) {
            // return UIImage
            return [UIImage imageWithContentsOfFile:file];
        } inBundle:bundle];
        
        if (@available(iOS 13.0, *)) {
            [BundleImageProvider setDynamicAssetHandler:^ImageDynamicAsset * _Nonnull(UIImage * _Nullable (^ _Nonnull imageProviderHandler)(UIUserInterfaceStyle)) {
                // return ImageDynamicAsset
                return [ImageDynamicAsset assetWithImageProvider:imageProviderHandler];
            } inBundle:bundle];
        }
    });
}

+ (UIImage *)webpImageNamed:(NSString *)name
    [self prepareIfNeed];
    NSBundle *bundle = xxx;
    UIImage *image = [BundleImageProvider imageNamed:name type:BundleImageTypeWEBP inBundle:bundle];
}
```
## Requirements

#### 资源命名规则

|       | lightImage     | darkImage     |
---- | ----- | ------ 
| 1x     | name.type     | name_darkmode.type     |
| 2x     | name@2x.type     | name_darkmode@2x.type     |
| 3x     | name@3x.type     | name_darkmode@3x.type     |

#### webp脚本处理
###### >$ swift ImageScript.swift
注意：遇到转换失败后会拷贝原图片到目标位置

## Author

YLCHUN, youlianchunios@163.com

## License

BundleImage is available under the MIT license. See the LICENSE file for more info.
