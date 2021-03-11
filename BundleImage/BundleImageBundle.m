//
//  BundleImageBundle.m
//  BundleImage
//
//  Created by YLCHUN on 2020/9/10.
//

#import "BundleImageBundle.h"
#import "BundleImageCache.h"
#import <UIKit/NSDataAsset.h>
#if __has_include(<XMCategories/XMCategory.h>)
#import <XMCategories/XMCategory.h>
#else
#import <CommonCrypto/CommonDigest.h>
#endif

@implementation BundleImageBundle
{
    NSBundle *_bundle;
    NSString *_bundleKey;
    NSString *_relativePath;
    NSString *_bundleDir;
    BundleImageCache<NSString *, NSDictionary *> *_assetCache;
    NSDictionary *_tmpCache;
    BOOL _needAnalysis;
}
@synthesize bundleKey = _bundleKey;

static NSString *kVersion = @"version";
static NSString *kOwner = @"owner";

- (instancetype)initWithBundle:(NSBundle *_Nullable)bundle {
    self = [super init];
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    _assetCache = [[BundleImageCache alloc] initWithCapacity:10];
    _bundle = bundle;
    _relativePath = relativeBundlePath(_bundle.bundlePath);
    _bundleKey = md5Str(_relativePath);
    _needAnalysis = YES;
    return self;
}

- (instancetype)init {
    return [self initWithBundle:nil];
}


- (NSString *)bundleDir {
    if (!_bundleDir && _bundleKey) {
        NSString *rootDir = [self.class bundleAssetDir];
        _bundleDir = [rootDir stringByAppendingPathComponent:_bundleKey];
        createDirectoryIfNeed(_bundleDir);
    }
    return _bundleDir;
}

- (BOOL)didAnalysis {
    __block BOOL didAnalysis = YES;
    [_assetCache lockBlock:^{
        didAnalysis = self->_tmpCache == nil;
    }];
    return didAnalysis;
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
    return BundleImageDarkModeSuffix;
}

- (NSArray<NSString *> *_Nullable)indirectImageNamesWithType:(BundleImageType)type {
    if (type.length == 0) return nil;
    __block NSDictionary<NSString *, NSDictionary*> *tmpCache = nil;
    [_assetCache lockBlock:^{
        tmpCache = self->_tmpCache;
    }];
    NSArray *names = nil;
    if (tmpCache) {
        names = tmpCache[type].allKeys;
    }
    else {
        NSString *typeDir = [self.bundleDir stringByAppendingPathComponent:type];
        names = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:typeDir error:nil];
    }
    return names;
}

- (NSString *)indirectImagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark {
    
    if (name.length == 0 || type.length == 0) return nil;
    
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
    
    NSDictionary *info = [self infoForName:shotName type:type];
    NSDictionary *styleInfo = info[styleKey(dark)];
    int mainScale = (int)UIScreen.mainScreen.scale;
    NSString *path = [self imagePathForNamePath:namePath scale:mainScale styleInfo:styleInfo];
    if (!path) {
        for (int scale = 3; scale > 0; scale --) {
            if (scale == mainScale) continue;
            path = [self imagePathForNamePath:namePath scale:scale styleInfo:styleInfo];
            if (path.length > 0) break;
        }
    }
    return path;
}

- (NSString *)imagePathForNamePath:(NSString *)namePath scale:(int)scale styleInfo:(NSDictionary *)styleInfo {
    
    NSArray<NSString *> *arr = styleInfo[[NSString stringWithFormat:@"%@", @(scale)]];
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
    NSString *path = [_bundle.bundlePath stringByAppendingPathComponent:relativePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    }else {
        return nil;
    }
}

- (NSDictionary *)infoForName:(NSString *)name type:(BundleImageType)type {
    NSString *key = [NSString stringWithFormat:@"%@.%@", name, type];
    return [_assetCache objectForKey:key init:^NSDictionary * _Nonnull{
        NSDictionary *info = nil;
        NSDictionary *tmpCache = self->_tmpCache;
        if (tmpCache) {
            info = tmpCache[type][name];
        }
        else {
            NSString *typeDir = [self.bundleDir stringByAppendingPathComponent:type];
            NSString *infoPath = [typeDir stringByAppendingPathComponent:name];
            info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
        }
        return info;
    }];
}

- (BOOL)analysisBundleIfNeed:(void(^)(void))callback {
    if (!self.bundleDir) {
        return NO;
    }
    __block BOOL needAnalysis = NO;
    [_assetCache lockBlock:^{
        if (!self->_needAnalysis) {
            return;
        }
        needAnalysis = YES;
        self->_needAnalysis = NO;
        @autoreleasepool {
            NSString *infoPath = [[self.bundleDir stringByAppendingPathComponent:@"info"] stringByAppendingPathExtension:@"plist"];
            NSDictionary *assetInfo = [NSDictionary dictionaryWithContentsOfFile:infoPath];
            
            NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
            
            if (![assetInfo[kVersion] isEqual:version]) {
                cleanDirectoryIfNeed(self.bundleDir);
                createDirectoryIfNeed(self.bundleDir);
                
                NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> *> *dict = [self analysisContentsFromAsset:self->_bundle.bundlePath];
                self->_tmpCache = dict;
                __weak typeof(self) wself = self;
                [self storeAnalysisData:dict version:version path:infoPath callback:^{
                    __strong typeof(self) self = wself;
                    if (!self) return;
                    [self->_assetCache lockBlock:^{
                        self->_tmpCache = nil;
                    }];
                    callback();
                }];
            }
        }
    }];
    return needAnalysis;
}

- (void)storeAnalysisData:(NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> *> *)dict version:(NSString *)version path:(NSString *)path callback:(void(^)(void))callback {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __block BOOL allSuccess = YES;
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary<NSString *,NSDictionary *> * _Nonnull obj, BOOL * _Nonnull stop) {
            NSString *typeDir = [self.bundleDir stringByAppendingPathComponent:key];
            createDirectoryIfNeed(typeDir);
            
            [obj enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
                NSString *infoPath = [typeDir stringByAppendingPathComponent:key];

                BOOL b = [obj writeToFile:infoPath atomically:YES];
                if (!b) {
                    allSuccess = NO;
                }
            }];
        }];
        
        if (!allSuccess) {
            return;
        }
        
        NSMutableDictionary *assetInfo = [NSMutableDictionary dictionary];
        assetInfo[kOwner] = self->_relativePath;
        assetInfo[kVersion] = version;
        BOOL b = [assetInfo writeToFile:path atomically:YES];
        if (!b) {
            NSLog(@"");
        }
        callback();
    });

}

- (NSDictionary *)analysisContentsFromAsset:(NSString *)assetDir {
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

    traverseFile(assetDir, ^(NSString *content, NSString *path) {
        [self decodeName:content callback:^(NSString *name, NSString *exten, NSString *scale, BOOL isDark) {
            NSMutableDictionary *extenDict = dictBlock(assetDict, exten);
            NSMutableDictionary *fileDict = dictBlock(extenDict, name);
            
            NSMutableDictionary *styleDict = dictBlock(fileDict, styleKey(isDark));

            NSString *relativePath = [path substringFromIndex:assetDir.length];
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

static BOOL cleanDirectoryIfNeed(NSString *path) {
    if (path.length == 0) return NO;
    BOOL isDir = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    if (isExists && isDir) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (error != nil) {
            __block BOOL hasErr = NO;
            traversePath(path, ^(NSString *content, BOOL isDir, NSString *path) {
                NSError *error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                if (error != nil) {
                    hasErr = YES;
                }
            });
            return hasErr;
        }
    }
    return NO;
}

static BOOL createDirectoryIfNeed(NSString *path) {
    if (path.length == 0) return NO;
    BOOL isDir = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    NSError *error = nil;
    if (!isExists || !isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    }
    return error == nil;
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
        return @"";
    }
    NSUInteger index = range.location + range.length;
    if (index >= path.length) {
        return @"";
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
#if __has_include(<XMCategories/XMCategory.h>)
    return [string hashString];
#else
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (CC_LONG)(data.length), digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
#endif
}

@end

@implementation BundleImageBundle (directly)
- (NSString *_Nullable)directlyImagePathForName:(NSString *)name type:(BundleImageType)type dark:(BOOL)dark {
    if (dark) {
        name = [name stringByAppendingString:[self darkSuffix].lowercaseString];
    }
    
    NSString *path = nil;
    int mainScale = (int)UIScreen.mainScreen.scale;
    path = [self directlyImagePathForName:name type:type.lowercaseString scale:mainScale];
    if (!path) {
        for (int scale = 3; scale > 0; scale --) {
            if (scale == mainScale) continue;
            path = [self directlyImagePathForName:name type:type.lowercaseString scale:scale];
            if (path.length > 0) break;
        }
    }
    return path;
}

- (NSString *)directlyImagePathForName:(NSString *)name type:(NSString *)type scale:(int)scale {
    NSString *path = [_bundle.bundlePath stringByAppendingPathComponent:name];
    if (scale > 1) {
        path = [path stringByAppendingFormat:@"@%dx", scale];
    }
    if (type) {
        path = [path stringByAppendingPathExtension:type];
    }
    if ([[NSFileManager defaultManager] isReadableFileAtPath:path]) {
        return path;
    }
    else {
        return nil;
    }
}
- (NSArray<NSString *> *_Nullable)directlyImageNamesWithType:(BundleImageType)type {
    if (type.length == 0) return nil;
    NSMutableSet *set = [NSMutableSet set];
    traversePath(_bundle.bundlePath, ^(NSString *content, BOOL isDir, NSString *path) {
        if (isDir || ![content.pathExtension isEqualToString:type.lowercaseString]) return;
        [self decodeName:content callback:^(NSString *name, NSString *exten, NSString *scale, BOOL isDark) {
            [set addObject:name];
        }];
    });
    return set.allObjects;
}

@end

@implementation BundleImageBundle (catalog)
- (NSDataAsset *_Nullable)catalogImageAssetForName:(NSString *)name dark:(BOOL)dark {
    if (dark) {
        name = [name stringByAppendingString:[self darkSuffix].lowercaseString];
    }
    NSDataAsset *asset = nil;
    int mainScale = (int)UIScreen.mainScreen.scale;
    asset = [self catalogImageAssetForName:name scale:mainScale];
    if (!asset) {
        for (int scale = 3; scale > 0; scale --) {
            if (scale == mainScale) continue;
            asset = [self catalogImageAssetForName:name scale:scale];
            if (asset > 0) break;
        }
    }
    return asset;
}

- (NSDataAsset *)catalogImageAssetForName:(NSString *)name scale:(int)scale {
    NSString *path = name;
    if (scale > 1) {
        path = [path stringByAppendingFormat:@"@%dx", scale];
    }
    return [[NSDataAsset alloc] initWithName:path bundle:_bundle];
}
@end
