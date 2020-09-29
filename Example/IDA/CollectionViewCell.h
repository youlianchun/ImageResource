//
//  CollectionViewCell.h
//  Example
//
//  Created by YLCHUN on 2020/9/5.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

NS_ASSUME_NONNULL_END
