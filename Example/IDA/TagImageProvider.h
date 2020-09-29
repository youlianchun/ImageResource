//
//  TagImageProvider.h
//  Example
//
//  Created by YLCHUN on 2020/9/5.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface TagImageProvider : NSObject
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, assign) UIViewContentMode contentMode;
@property (nonatomic, copy) UIImage *(^provider)(void);
@end

NS_ASSUME_NONNULL_END
