//
//  BundleImageBundle.m
//  BundleImage
//
//  Created by YLCHUN on 2020/9/10.
//

#import "BundleImageBundle.h"
#import <UIKit/UIScreen.h>
#import <CommonCrypto/CommonDigest.h>

@implementation BundleImageBundle
{
    NSString *_resourceDir;
    NSDictionary *_assetDict;
    NSString *_bundleKey;
}
@synthesize bundleKey = _bundleKey;

- (instancetype)initWithBundle:(NSBundle *_Nullable)bundle {
    self = [super init];
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    _resourceDir = bundle.resourcePath;
    _assetDict = [self loadAssetBundle:_resourceDir];
    return self;
}

- (instancetype)init {
    return [self initWithBundle:nil];
}

- (NSArray<NSString *> *_Nullable)imageNamesWithType:(BundleImageType)type {
    if (type.length == 0) return nil;
    return [[_assetDict[type] allKeys] copy];
}

- (NSArray *)extenCheckArr {
    static NSArray *extenCheckArr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        extenCheckArr = @[BundleImageTypePNG, BundleImageTypeWEBP, BundleImageTypeJPG, BundleImageTypeGIF];
    });
    return extenCheckArr;
}

- (NSString *)darkSuffix {
    return BundleImageDarkMode;
}

- (NSString *)imagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark {
    
    if (name.length == 0 || type.length == 0) return nil;
    type = type.uppercaseString;
    int mainScale = (int)UIScreen.mainScreen.scale;
    NSString *path = [self imagePathForName:name type:type scale:mainScale dark:dark];
    if (!path) {
        for (int scale = 3; scale > 0; scale --) {
            if (scale == mainScale) continue;
            path = [self imagePathForName:name type:type scale:scale dark:dark];
            if (path.length > 0) break;
        }
    }
    
    return path;
}

- (NSString *)imagePathForName:(NSString *)name type:(BundleImageType)type scale:(int)scale dark:(BOOL)dark {
    NSString *shotName = nil;
    NSString *namePath = nil;
    if ([name containsString:@"/"]) {
        shotName = name.lastPathComponent;
        namePath = [name stringByDeletingLastPathComponent];
        if (![namePath hasPrefix:@"/"]) {
            namePath = [@"/" stringByAppendingString:namePath];
        }
    }
    else {
        shotName = name;
    }
    
    NSArray<NSString *> *arr = _assetDict[type][shotName][styleKey(dark)][[NSString stringWithFormat:@"%@", @(scale)]];
    NSString *relativePath = nil;
    if (namePath) {
        for (NSString *path in arr) {
            NSString *str = [path stringByDeletingLastPathComponent];
            if ([str isEqualToString:namePath]) {
                relativePath = path;
                break;
            }
        }
    }
    else {
        relativePath = arr.firstObject;
    }
    
    if (relativePath.length == 0) return nil;
    NSString *path = [_resourceDir stringByAppendingPathComponent:relativePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    }else {
        return nil;
    }
}


- (NSDictionary *)loadAssetBundle:(NSString *)resourceDir {
    NSString *relativePath = relativeBundlePath(resourceDir);
    if (relativePath.length == 0) {
        return nil;
    }
    NSString *bundleKey = md5Str(relativePath);
    _bundleKey = bundleKey;
    
    NSString *dir = [self.class bundleAssetDir];
    
    BOOL isDir = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDir];
    if (!isExists || !isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    
    NSString *assetPath = [[dir stringByAppendingPathComponent:bundleKey] stringByAppendingPathExtension:@"plist"];
    
    static NSString *kContent = @"content";
    static NSString *kVersion = @"version";
    static NSString *kOwnerPath = @"ownerpath";
    NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
    
    NSDictionary *asset = [NSDictionary dictionaryWithContentsOfFile:assetPath];
    if (![asset[kVersion] isEqual:version]) {
        NSMutableDictionary *newAsset = [NSMutableDictionary dictionary];
        newAsset[kOwnerPath] = relativePath;
        newAsset[kContent] = [self loadAsset:resourceDir];
        newAsset[kVersion] = version;
        asset = [newAsset copy];
        BOOL b = [asset writeToFile:assetPath atomically:YES];
        if (!b) {
            NSLog(@"");
        }
    }
    
    return asset[kContent];
}

- (NSDictionary *)loadAsset:(NSString *)dir {
    NSMutableDictionary *(^dictBlock)(NSMutableDictionary *dict, NSString *key) = ^NSMutableDictionary *(NSMutableDictionary *dict, NSString *key){
        if (!key) return nil;
        NSMutableDictionary *newDict = dict[key];
        if (!newDict) {
            newDict = [NSMutableDictionary dictionary];
            dict[key] = newDict;
        }
        return newDict;
    };
    NSMutableArray *(^arrBlock)(NSMutableDictionary *dict, NSString *key) = ^NSMutableArray *(NSMutableDictionary *dict, NSString *key){
        if (!key) return nil;
        NSMutableArray *new = dict[key];
        if (!new) {
            new = [NSMutableArray array];
            dict[key] = new;
        }
        return new;
    };
    NSMutableDictionary *assetDict = [NSMutableDictionary dictionary];

    traverseFile(dir, ^(NSString *content, NSString *path) {
        [self decodeName:content callback:^(NSString *name, NSString *exten, NSString *scale, BOOL isDark) {
            NSMutableDictionary *extenDict = dictBlock(assetDict, exten);
            NSMutableDictionary *fileDict = dictBlock(extenDict, name);
            NSMutableDictionary *styleDict = dictBlock(fileDict, styleKey(isDark));

            NSString *relativePath = [path substringFromIndex:dir.length];
            NSMutableArray *scaleArr = arrBlock(styleDict, scale);
            [scaleArr addObject:relativePath];
        }];
    }, ^BOOL(NSString *dir) {
        return YES;
    });
    
    return [assetDict copy];
}

- (void)decodeName:(NSString *)fullName callback:(void(^)(NSString *name, NSString *exten, NSString *scale, BOOL isDark)) callback {
    if (!callback) return;
    NSString *exten = [fullName.pathExtension uppercaseString];
    if (exten.length == 0) return;

    if (![[self extenCheckArr] containsObject:exten]) return;
    
    NSString *scale = matcheRegex(fullName, @"(?<=@)(\\d.\\d)|(\\d)(?=x\\..*)").firstObject;
    NSString *nameRegex = nil;
    if (scale.length == 0) {
        scale = @"1";
        nameRegex = @"^.*(?=\\..*)";
    }
    else {
        nameRegex = @"^.*(?=(@((\\d)|(\\d.\\d))x)\\..*)";
    }
    
    NSString *name = matcheRegex(fullName, nameRegex).firstObject;
    NSString *darkSuffix = [self darkSuffix];
    BOOL isDark = [name.uppercaseString hasSuffix:darkSuffix];
    if (isDark) {
        name = [name substringToIndex:name.length - darkSuffix.length];
    }
    if (!name) {
        return;
    }
    
    callback(name, exten, scale, isDark);
}

+ (NSString *)bundleAssetDir {
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    dir = [dir stringByAppendingPathComponent:@"BundleImageAsset"];
    return dir;
}

+ (void)cleanAsset {
    NSString *dir = [self bundleAssetDir];
    [[NSFileManager defaultManager] removeItemAtPath:dir error:nil];
}

static NSString *styleKey(BOOL isDark) {
    return isDark?@"dark":@"light";
}

static void traversePath(NSString *path, void(^callback)(NSString *content, BOOL isDir, NSString *path)) {
    NSError *err;
    NSArray <NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&err];
    NSMutableArray<void(^)(void)> *fileArr = [NSMutableArray array];
    NSMutableArray<void(^)(void)> *dirArr = [NSMutableArray array];

    for (NSString *content in contents) {
        NSString *p = [path stringByAppendingPathComponent:content];
        BOOL isDir = NO;
        BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:p isDirectory:&isDir];
        if (isExist) {
            if (isDir) {
                [dirArr addObject:^void{
                    callback(content, isDir, p);
                }];
            }else {
                [fileArr addObject:^void{
                    callback(content, isDir, p);
                }];
            }
        }
    }
    for (void(^callback)(void) in fileArr) {
        callback();
    }
    for (void(^callback)(void) in dirArr) {
        callback();
    }
}

static void traverseFile(NSString *path, void(^callback)(NSString *content, NSString *path), BOOL(^atDir)(NSString *dir)) {
    if (atDir && !atDir(path)) return;
    traversePath(path, ^(NSString *content, BOOL isDir, NSString *path) {
        if (isDir) {
            traverseFile(path, callback, atDir);
        }else {
            callback(content, path);
        }
    });
}

static NSString *relativeBundlePath(NSString *path) {
    NSString *mainPath = NSBundle.mainBundle.bundlePath;
    if ([path isEqualToString:mainPath]) {
        return @"./";
    }
    NSString *referencePath = [[mainPath stringByDeletingLastPathComponent].lastPathComponent stringByAppendingPathComponent:mainPath.lastPathComponent];
    NSRange range = [path rangeOfString:referencePath];
    if(range.location == NSNotFound) {
        return nil;
    }
    NSUInteger index = range.location + range.length;
    if (index >= path.length) {
        return nil;
    }
    NSString *relativePath = [path substringFromIndex:index];
    if (relativePath.length == 0) {
        relativePath = @"./";
    }
    return relativePath;
}


static NSArray<NSString *> *matcheRegex(NSString *string, NSString *regex) {
    NSError *error = NULL;
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regularExpression matchesInString:string options:kNilOptions range:NSMakeRange(0, string.length)];
    NSMutableArray *arr = [NSMutableArray array];
    for (NSTextCheckingResult *matche in matches) {
        NSString *str = [string substringWithRange:matche.range];
        [arr addObject:str];
    }
    return [arr copy];
}

static NSString *md5Str(NSString *string) {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)(data.length), digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

@end
