//
//  BundleImageBundle.m
//  BundleImage
//
//  Created by YLCHUN on 2020/9/10.
//

#import "BundleImageBundle.h"
#import <UIKit/UIScreen.h>
#import "BundleImageCache.h"
#import <CommonCrypto/CommonDigest.h>
#import <pthread/pthread.h>

@implementation BundleImageBundle
{
    NSString *_resourceDir;
    NSString *_bundleKey;
    NSString *_relativePath;
    NSString *_bundleDir;
    BundleImageCache<NSString *, NSDictionary *> *_assetCache;
}

@synthesize bundleKey = _bundleKey;

- (instancetype)initWithBundle:(NSBundle *_Nullable)bundle {
    self = [super init];
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    _assetCache = [[BundleImageCache alloc] initWithCapacity:10];
    _resourceDir = bundle.resourcePath;
    _relativePath = relativeBundlePath(_resourceDir);
    _bundleKey = md5Str(_relativePath);
    [self analysisBundleIfNeed];
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

- (NSArray<NSString *> *_Nullable)imageNamesWithType:(BundleImageType)type {
    if (type.length == 0) return nil;
    NSString *typeDir = [self.bundleDir stringByAppendingPathComponent:type];
    NSArray<NSString *> *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:typeDir error:nil];
    return contents;
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
    NSString *path = [_resourceDir stringByAppendingPathComponent:relativePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    }else {
        return nil;
    }
}

- (NSDictionary *)infoForName:(NSString *)name type:(BundleImageType)type {
    NSString *key = [NSString stringWithFormat:@"%@.%@", name, type];
    return [_assetCache objectForKey:key init:^NSDictionary * _Nonnull{
        NSString *typeDir = [self.bundleDir stringByAppendingPathComponent:type];
        NSString *infoPath = [typeDir stringByAppendingPathComponent:name];
        return [NSDictionary dictionaryWithContentsOfFile:infoPath];
    }];
}


- (void)analysisBundleIfNeed {
    if (!self.bundleDir) {
        return;
    }
    @autoreleasepool {
        NSString *infoPath = [[self.bundleDir stringByAppendingPathComponent:@"info"] stringByAppendingPathExtension:@"plist"];
        NSDictionary *assetInfo = [NSDictionary dictionaryWithContentsOfFile:infoPath];
        
        static NSString *kVersion = @"version";
        static NSString *kOwner = @"owner";
        NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
        
        if (![assetInfo[kVersion] isEqual:version]) {
            cleanDirectoryIfNeed(self.bundleDir);
            createDirectoryIfNeed(self.bundleDir);
            NSTimeInterval t0 = [NSProcessInfo processInfo].systemUptime / 1000.0;

            NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> *> *dict = [self analysisContentsFromAsset:_resourceDir];
            
            NSTimeInterval t1 = [NSProcessInfo processInfo].systemUptime / 1000.0;

            [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary<NSString *,NSDictionary *> * _Nonnull obj, BOOL * _Nonnull stop) {
                NSString *typeDir = [self.bundleDir stringByAppendingPathComponent:key];
                createDirectoryIfNeed(typeDir);
                
                [obj enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
                    NSString *infoPath = [typeDir stringByAppendingPathComponent:key];

                    BOOL b = [obj writeToFile:infoPath atomically:YES];
                    if (!b) {
                        
                    }
                }];
            }];
            NSTimeInterval t2 = [NSProcessInfo processInfo].systemUptime / 1000.0;

            NSLog(@"time %@, %@", @(t1 - t0), @(t2 - t1));
            NSMutableDictionary *assetInfo = [NSMutableDictionary dictionary];
            assetInfo[kOwner] = _relativePath;
            assetInfo[kVersion] = version;
            BOOL b = [assetInfo writeToFile:infoPath atomically:YES];
            if (!b) {
                NSLog(@"");
            }
        }
    }
}

- (NSDictionary *)analysisContentsFromAsset:(NSString *)assetDir {
    __block pthread_mutex_t mutex_t = PTHREAD_MUTEX_INITIALIZER;
    NSMutableDictionary *(^dictBlock)(NSMutableDictionary *dict, NSString *key) = ^NSMutableDictionary *(NSMutableDictionary *dict, NSString *key){
        if (!key) return nil;
        pthread_mutex_lock(&mutex_t);
        NSMutableDictionary *newDict = dict[key];
        if (!newDict) {
            newDict = [NSMutableDictionary dictionary];
            dict[key] = newDict;
        }
        pthread_mutex_unlock(&mutex_t);
        return newDict;
    };
    NSMutableArray *(^arrBlock)(NSMutableDictionary *dict, NSString *key) = ^NSMutableArray *(NSMutableDictionary *dict, NSString *key){
        if (!key) return nil;
        pthread_mutex_lock(&mutex_t);
        NSMutableArray *new = dict[key];
        if (!new) {
            new = [NSMutableArray array];
            dict[key] = new;
        }
        pthread_mutex_unlock(&mutex_t);
        return new;
    };
    NSMutableDictionary *assetDict = [NSMutableDictionary dictionary];
    NSTimeInterval t0 = [NSProcessInfo processInfo].systemUptime / 1000.0;
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 5;
    traverseFile(assetDir, ^(NSString *content, NSString *path) {
        [queue addOperationWithBlock:^{
            [self decodeName:content callback:^(NSString *name, NSString *exten, NSString *scale, BOOL isDark) {
                NSMutableDictionary *extenDict = dictBlock(assetDict, exten);
                NSMutableDictionary *fileDict = dictBlock(extenDict, name);

                NSMutableDictionary *styleDict = dictBlock(fileDict, styleKey(isDark));

                NSString *relativePath = [path substringFromIndex:assetDir.length];
                NSMutableArray *scaleArr = arrBlock(styleDict, scale);
                [scaleArr addObject:relativePath];
            }];
        }];
    }, ^BOOL(NSString *dir) {
        return YES;
    });
    [queue waitUntilAllOperationsAreFinished];
    NSTimeInterval t1 = [NSProcessInfo processInfo].systemUptime / 1000.0;
    NSLog(@"time %@", @(t1 - t0));
    return [assetDict copy];
}

- (void)decodeName:(NSString *)fullName callback:(void(^)(NSString *name, NSString *exten, NSString *scale, BOOL isDark)) callback {
    if (!callback) return;
    NSString *exten = [fullName.pathExtension uppercaseString];
    if (exten.length == 0) return;

    if (![[self extenCheckArr] containsObject:exten]) return;
    
    NSString *nameWithoutExtension = fullName.stringByDeletingPathExtension;
    int s = scaleFromNameNoExtension(nameWithoutExtension);
    
    NSString *name = nil;
    NSString *scale = nil;
    if (s < 0) {
        name = nameWithoutExtension;
        scale = @"1";
    }
    else if (s == 0) {
        scale = @"1";
        name = [nameWithoutExtension substringToIndex:nameWithoutExtension.length - 3];
    }
    else {
        scale = [NSString stringWithFormat:@"%d", s];
        name = [nameWithoutExtension substringToIndex:nameWithoutExtension.length - 3];
    }

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
    @autoreleasepool {
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

static int scaleFromNameNoExtension(NSString *name) {
    //不带扩展名
    //name@2x
    //name
    int scale = -1;
    if (name.length > 1) {
        char c = [name characterAtIndex:name.length - 1];
        if (c == 'x' || c == 'X') {
            if (name.length > 3) {
                if ([name characterAtIndex:name.length - 3] == '@') {
                    int s = [name characterAtIndex:name.length - 2] - '0';
                    if (s < 9) {
                        scale = s;
                    }
                }
            }
        }
    }
    return scale;
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
