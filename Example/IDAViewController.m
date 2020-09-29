//
//  ViewController.m
//  Example
//
//  Created by YLCHUN on 2020/9/5.
//  Copyright © 2020 YLCHUN. All rights reserved.
//

#import "IDAViewController.h"
#import "UIImage+Dynamic.h"
#import "UIImage+Resource.h"
#import "TagImageProvider.h"
#import "CollectionViewCell.h"

@interface IDAViewController ()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>
@property (nonatomic, strong) NSArray *datas;
@property (nonatomic, strong) UICollectionView *collectionView;
@end

@implementation IDAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.datas = [self loadData];
    [self setupSubviews];
//    [self memoryCase];
}

- (void)memoryCase {
    loopHandler(0.01, ^{
        for (TagImageProvider *tip in self.datas) {
            UIImage *image = tip.provider();
        }
    });
}



static void loopHandler(NSTimeInterval ti, void(^handler)(void)) {
    if (!handler) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ti * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        loopHandler(ti, handler);
    });
    handler();
}

- (void)setupSubviews {
    [self.view addSubview:self.collectionView];
    [self.collectionView registerNib:[UINib nibWithNibName:@"CollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"CollectionViewCell"];
    [self.collectionView reloadData];
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        CGFloat sw = UIScreen.mainScreen.bounds.size.width;
        CGFloat spacing = 5;
        int column = 4;
        CGFloat len = (sw - (column + 1) * spacing) / column;
        
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.minimumLineSpacing = spacing;
        layout.minimumInteritemSpacing = spacing;
        layout.itemSize = CGSizeMake(len, len + 12);
        layout.sectionInset = UIEdgeInsetsMake(spacing, spacing, spacing, spacing);
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
    }
    return _collectionView;
}

#pragma mark -
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionViewCell" forIndexPath:indexPath];
    TagImageProvider *tip = self.datas[indexPath.item];
    @autoreleasepool {
        cell.imageView.image = tip.provider();
    }
    cell.imageView.contentMode = tip.contentMode;
    cell.textLabel.text = tip.tag;
    cell.textLabel.textColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor whiteColor];
        }else {
            return [UIColor blackColor];
        }
    }];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.datas.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 10000;
}
#pragma mark -

- (NSArray<TagImageProvider *> *)loadData {
    UIImage *light = [UIImage pngImageNamed:@"light"];
    UIImage *dark = [UIImage pngImageNamed:@"dark"];
    
    TagImageProvider *tip = nil;
    NSMutableArray *arr = [NSMutableArray array];
    
    tip = [TagImageProvider new];
    tip.tag = @"Origin";
    tip.contentMode = UIViewContentModeCenter;
    tip.provider = ^id _Nonnull{
        return [UIImage imageWithDynamicProvider:^UIImage * _Nullable(UIUserInterfaceStyle style) {
            if (style == UIUserInterfaceStyleDark) {
                return dark;
            }else {
                return light;
            }
        }];
    };
    [arr addObject:tip];
    
    tip = [TagImageProvider new];
    tip.tag = @"CapInsets";
    tip.provider = ^id _Nonnull{
        return [UIImage imageWithDynamicProvider:^UIImage * _Nullable(UIUserInterfaceStyle style) {
            if (style == UIUserInterfaceStyleDark) {
                return [dark resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
            }else {
                return [light resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
            }
        }];
    };
    [arr addObject:tip];
    
    tip = [TagImageProvider new];
    tip.tag = @"Stretchable";
    tip.provider = ^id _Nonnull{
        return [UIImage imageWithDynamicProvider:^UIImage * _Nullable(UIUserInterfaceStyle style) {
            if (style == UIUserInterfaceStyleDark) {
                return [dark stretchableImageWithLeftCapWidth:25 topCapHeight:25];
            }else {
                return [light stretchableImageWithLeftCapWidth:25 topCapHeight:25];
            }
        }];
    };
    [arr addObject:tip];

    tip = [TagImageProvider new];
    tip.tag = @"Orientation";
    tip.contentMode = UIViewContentModeCenter;
    tip.provider = ^id _Nonnull{
        return [UIImage imageWithDynamicProvider:^UIImage * _Nullable(UIUserInterfaceStyle style) {
            if (style == UIUserInterfaceStyleDark) {
                return [dark imageWithHorizontallyFlippedOrientation];
            }else {
                return [light imageWithHorizontallyFlippedOrientation];
            }
        }];
    };
    [arr addObject:tip];
    
    tip = [TagImageProvider new];
    tip.tag = @"RenderingMode";
    tip.contentMode = UIViewContentModeCenter;
    tip.provider = ^id _Nonnull{
        return [UIImage imageWithDynamicProvider:^UIImage * _Nullable(UIUserInterfaceStyle style) {
            if (style == UIUserInterfaceStyleDark) {
                return [dark imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }else {
                return [light imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
        }];
    };
    [arr addObject:tip];
    
    tip = [TagImageProvider new];
    tip.tag = @"AlignmentRectInsets";
    tip.provider = ^id _Nonnull{
        return [UIImage imageWithDynamicProvider:^UIImage * _Nullable(UIUserInterfaceStyle style) {
            if (style == UIUserInterfaceStyleDark) {
                return [dark imageWithAlignmentRectInsets:UIEdgeInsetsMake(20, 20, -20, -20)];
            }else {
                return [light imageWithAlignmentRectInsets:UIEdgeInsetsMake(20, 20, -20, -20)];
            }
        }];
    };
    [arr addObject:tip];
    
    tip = [TagImageProvider new];
    tip.tag = @"Baseline";
    tip.contentMode = UIViewContentModeCenter;
    tip.provider = ^id _Nonnull{
        return [UIImage imageWithDynamicProvider:^UIImage * _Nullable(UIUserInterfaceStyle style) {
            if (style == UIUserInterfaceStyleDark) {
                return [dark imageWithBaselineOffsetFromBottom:20];
            }else {
                return [light imageWithBaselineOffsetFromBottom:20];
            }
        }];
    };
    [arr addObject:tip];

    tip = [TagImageProvider new];
    tip.tag = @"Symbol";
    tip.provider = ^id _Nonnull{
        return [UIImage imageWithDynamicProvider:^UIImage * _Nullable(UIUserInterfaceStyle style) {
            if (style == UIUserInterfaceStyleDark) {
                return [UIImage systemImageNamed:@"bag.fill"];
            }else {
                return [UIImage systemImageNamed:@"bag"];
            }
        }];
    };
    [arr addObject:tip];
    
    tip = [TagImageProvider new];
    tip.tag = @"Gif";
    tip.contentMode = UIViewContentModeCenter;
    tip.provider = ^id _Nonnull{
        UIColor *color = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor whiteColor];
            }else {
                return [UIColor blackColor];
            }
        }];
        return [[UIImage gifImageNamed:@"animation"] blendWithColor:color];
    };
    [arr addObject:tip];
    return arr;
}

@end
