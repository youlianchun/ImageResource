# ImageResource

[![CI Status](https://img.shields.io/travis/YLCHUN/BundleImage.svg?style=flat)](https://travis-ci.org/YLCHUN/BundleImage)
[![Version](https://img.shields.io/cocoapods/v/BundleImage.svg?style=flat)](https://cocoapods.org/pods/BundleImage)
[![License](https://img.shields.io/cocoapods/l/BundleImage.svg?style=flat)](https://cocoapods.org/pods/BundleImage)
[![Platform](https://img.shields.io/cocoapods/p/BundleImage.svg?style=flat)](https://cocoapods.org/pods/BundleImage)

```ImageDynamicAsset```  UIImage 暗黑模式适配

```BundleImage```  bundle 内图片访问管理；通过图片名获取图片，支持：目录、倍图、暗黑。

## Example （ImageDynamicAsset）

```
+ (instancetype _Nullable)imageWithLight:(UIImage *)light dark:(UIImage *)dark {
    if (!dark) return light;
    if (!light) return dark;
    
    if (@available(iOS 13.0, *)) {
        return [self imageWithDynamicProvider:^UIImage * _Nullable(UIUserInterfaceStyle style) {
            if (style == UIUserInterfaceStyleDark) {
                return dark;
            }else {
                return light;
            }
        }];
    }
    else {
        return light;
    }
}
```
注意：采用UIImageAsset 实现暗黑适配存在内存泄漏。

## Example （BundleImage）

```
//默认方式 加载图片
+ (UIImage *)imageNamed:(NSString *)name
    NSBundle *bundle = xxx;
    UIImage *image = [BundleImage imageNamed:name type:BundleImageTypePNG inBundle:bundle];
    // UIImage *image = [BundleImage imageNamed:name type:BundleImageTypeJPG inBundle:bundle];
    // UIImage *image = [BundleImage imageNamed:name type:BundleImageTypeGIF inBundle:bundle];
    // UIImage *image = [BundleImage imageNamed:name type:BundleImageTypeWEBP inBundle:bundle];
}
```

```
//自定义 加载图片
+ (void)prepareIfNeed {
    NSBundle *bundle = xxx;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BundleImage setImageProvider:^UIImage * _Nullable(NSString * _Nonnull file, BundleImageType  _Nonnull type) {
            // return UIImage
            return [UIImage imageWithContentsOfFile:file];
        } inBundle:bundle];
        
        if (@available(iOS 13.0, *)) {
            [BundleImage setDynamicAssetHandler:^ImageDynamicAsset * _Nonnull(UIImage * _Nullable (^ _Nonnull imageProviderHandler)(UIUserInterfaceStyle)) {
                // return ImageDynamicAsset
                return [ImageDynamicAsset assetWithImageProvider:imageProviderHandler];
            } inBundle:bundle];
        }
    });
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BundleImage setImageProcess:^UIImage * _Nullable(UIImage * _Nonnull image, NSString * _Nonnull name, BundleImageType  _Nonnull type) {
            if ([name isEqualToString:@"xxx"]) {
                image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)];
            }
            return image;
        } inBundle:bundle];
    });
}

+ (UIImage *)imageNamed:(NSString *)name
    [self prepareIfNeed];
    NSBundle *bundle = xxx;
    UIImage *image = [BundleImage imageNamed:name type:BundleImageTypePNG inBundle:bundle];
    // UIImage *image = [BundleImage imageNamed:name type:BundleImageTypeJPG inBundle:bundle];
    // UIImage *image = [BundleImage imageNamed:name type:BundleImageTypeGIF inBundle:bundle];
    // UIImage *image = [BundleImage imageNamed:name type:BundleImageTypeWEBP inBundle:bundle];
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
###### > $ swift ImageScript.swift
```
$ swift ImageScript.swift
1. imageset 转WebP (cwebp)
   注: 产出增大时候会采用 [-lossless -q 100] 再次转换
2. imageset 文件名矫正
   注: imagesetName@2x.png、imagesetName_darkmode@2x.png
3. imageset 文件名矫正 + 转WebP
4. image 转WebP
5. image 倍图保留
X. 退出
```
###### step 1: > $ swift ImageScript.swift      ```1 or 4```
```
1
请输入*.imageset文件路径:
/xxx/Resource.xcassets 
WebP质量 [0-100] (默认 100): 
95
WebP输出目录 (默认 原图片位置): 
/xxx/ResourceWebP 
转换开始: /xxx/Resource.xcassets
🎉 🎉 Saved output file (-5.69 KB) '/xxx/xxx@2x.webp'
...
转换结束.
```
注意：WebP质量 参考：75 ～ 100；默认带 -lossless 参数，会有较多产出增大情况。

> 输出日志说明：  
> ```🎉 🎉 Saved output file (-5.00 KB) '/xxx/xxx@2x.webp'```转换成功，体积减小  
> ```🎉 ⚠️ Saved output file (+5.00 KB) '/xxx/xxx@2x.webp'```转换成功，体积增大   
> ```⚠️ ♻️ Recoded input file (100.00 KB) 'xxx/xxx@2x.png'```转换失败，转码后再次尝试转换  
> ```❌ ❌  Could not process input file 'xxx/xxx@2x.png'```转换失败  

注意：遇到转换失败后会拷贝原图片到目标位置

###### step 2: > $ swift ImageScript.swift      ```5```
```
5
请输入imsge文件目录:
/xxx/ResourceWebP 
image 倍图保留 [1 2 3]: 
3
清理开始: /xxx/ResourceWebP
    /xxx/ResourceWebP/xxx/xxx@2x.webp
    /xxx/ResourceWebP/xxx/xxx@2x.webp
    ...
清理结束
```
###### step 3: 校验资源转换结果 ```图片质量与大小```

###### step 4: 资源替换
1 将 ```ResourceWebP``` 文件夹拷贝到 ```Resource.xcassets``` 所在目录  
2 删除 ```Resource.xcassets``` 或 采用 ```ABTest``` 控制

###### step 5: 修改图片加载代码
采用 ```BundleImage``` 加载图片

###### step 6: 运行工程校验替换结果

## Installation 

手动安装

## Author

YLCHUN, youlianchunios@163.com

## License

BundleImage is available under the MIT license. See the LICENSE file for more info.
