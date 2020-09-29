//
//  TryRelay.m
//  TryRelay
//
//  Created by YLCHUN on 2020/9/17.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import "TryRelay.h"
#include <sys/sysctl.h>

static BOOL tr_isDebugging() {
    static BOOL kDebugging = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        int mib[4];
        struct kinfo_proc info;
        info.kp_proc.p_flag = 0;
        mib[0] = CTL_KERN;
        mib[1] = KERN_PROC;
        mib[2] = KERN_PROC_PID;
        mib[3] = getpid();
        size_t size = sizeof(info);
        int junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
        if (junk == 0) {
            return;
        }
        assert(junk == 0);
        kDebugging = ( (info.kp_proc.p_flag & P_TRACED) != 0 );
    });
    return kDebugging;
}


BOOL tryRelay(NSString *key, void(^block)(void), void(^_Nullable failure)(NSException *_Nullable exception)) {
    if (!block || key.length == 0) return NO;

    if (tr_isDebugging()) {
        block();
        return YES;
    }
    
    NSString *kTryRelay = [NSString stringWithFormat:@"%@_%@", @"kTryRelay", key];
    static NSString *kLastFailure = @"kLastFailure";
    static NSString *kFailureCallback = @"kFailureCallback";
    static NSString *kTryRelayVersion = @"kTryRelayVersion";
    
     
    static NSString *appVersion;
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appVersion = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
        queue = dispatch_queue_create("tryRelay.queue", 0);

    });
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    __block NSMutableDictionary *trLogDict = nil;
    dispatch_sync(queue, ^{
        id obj = [userDefaults objectForKey:kTryRelay];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            trLogDict = [((NSDictionary *)obj) mutableCopy];
        }

        if (!trLogDict || ![trLogDict[kTryRelayVersion] isEqual:appVersion]) {
            trLogDict = [NSMutableDictionary dictionary];
            trLogDict[kTryRelayVersion] = appVersion;
        }
    });
    
    void (^callback)(NSException *_Nullable exception) = ^(NSException *_Nullable exception){
        dispatch_sync(queue, ^{
            if (failure && ![trLogDict[kFailureCallback] boolValue]) {
                trLogDict[kFailureCallback] = @(YES);
                [userDefaults setObject:trLogDict forKey:kTryRelay];
                [userDefaults synchronize];
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(exception);
                });
            }
        });
    };
    
    if (![trLogDict[kLastFailure] boolValue]) {
        dispatch_sync(queue, ^{
            trLogDict[kLastFailure] = @(YES);
            [userDefaults setObject:trLogDict forKey:kTryRelay];
            [userDefaults synchronize];
        });
        @try {
            block();
            dispatch_sync(queue, ^{
                trLogDict[kLastFailure] = @(NO);
                [userDefaults setObject:trLogDict forKey:kTryRelay];
                [userDefaults synchronize];
            });
            return YES;
        }
        @catch (NSException *exception) {
            callback(exception);
        }
    }
    else {
        callback(nil);
    }
    return NO;
}




