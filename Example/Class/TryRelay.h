//
//  TryRelay.h
//  TryRelay
//
//  Created by YLCHUN on 2020/9/17.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 同步代码同错函数，当次tryBlock执行失败后将不再执行
/// @param key 唯一标识符
/// @param tryBlock block同步执行
/// @param failure 异常回调，仅一次，exception 为try catch 数据，其他异常请检查项目崩溃日志
FOUNDATION_EXTERN BOOL tryRelay(NSString *key, void(^tryBlock)(void), void(^_Nullable failure)(NSException *_Nullable exception));

NS_ASSUME_NONNULL_END
