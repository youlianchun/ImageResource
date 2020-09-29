//
//  AppDelegate.m
//  Example
//
//  Created by YLCHUN on 2020/9/6.
//

#import "AppDelegate.h"
#import <BundleImage/BundleImageProvider.h>
#import "YYAnimatedImageDynamicAsset.h"

typedef UIImage YYImage;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)configImageProvider {
    //采用YYImage
//    [BundleImageProvider setImageProvider:^UIImage * _Nullable(NSString * _Nonnull file, BundleImageType  _Nonnull type) {
//        return [YYImage imageWithContentsOfFile:file];
//    }];
//    [BundleImageProvider setDynamicAssetHandler:^ImageDynamicAsset * _Nonnull(UIImage * _Nullable (^ _Nonnull imageProviderHandler)(UIUserInterfaceStyle)) {
//        return [YYAnimatedImageDynamicAsset assetWithImageProvider:imageProviderHandler];
//    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self configImageProvider];
    // Override point for customization after application launch.
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
