//
//  BIPViewController.m
//  Example
//
//  Created by YLCHUN on 2020/9/6.
//

#import "BIPViewController.h"
#import "UIImage+Dynamic.h"
#import "UIImage+Resource.h"
#import <BundleImage/BundleImageProvider.h>

@interface BIPViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *datas;

@end

@implementation BIPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.datas = [UIImage webpImageNames];
    [self.view addSubview:self.tableView];
    [self pathImage];

    // Do any additional setup after loading the view.
}

- (void)pathImage {
    UIImage *image0 = [BundleImageProvider imageNamed:@"find_btn_publish_article" type:BundleImageTypeWEBP inBundle:nil];
    UIImage *image1 = [BundleImageProvider imageNamed:@"Resource/WebP/duplication/find_btn_publish_article" type:BundleImageTypeWEBP inBundle:nil];
    UIImageView *imageView0 = [[UIImageView alloc] initWithImage:image0];
    UIImageView *imageView1 = [[UIImageView alloc] initWithImage:image1];
    imageView0.center = CGPointMake(50, 200);
    imageView1.center = CGPointMake(100, 200);
    [self.view addSubview:imageView0];
    [self.view addSubview:imageView1];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    }
    NSString *imageName = self.datas[indexPath.section];
    UIImage *image = [UIImage webpImageNamed:imageName];
    cell.imageView.image = image;
    cell.textLabel.text = imageName;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.datas.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
