//
//  DDPDanmakuSelectedFontViewController.m
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/4/26.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import "DDPDanmakuSelectedFontViewController.h"
#import "DDPBaseTableView.h"
#import "DDPSelectedTableViewCell.h"
#import "UIFont+Tools.h"
#import "DDPTextHeaderView.h"

@interface DDPDanmakuSelectedFontViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) DDPBaseTableView *tableView;
@property (strong, nonatomic) NSArray <NSDictionary <NSString *, NSArray *>*>*fonts;
@end

@implementation DDPDanmakuSelectedFontViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"选择弹幕字体";
    
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    
    if (self.tableView.mj_header.refreshingBlock) {
        self.tableView.mj_header.refreshingBlock();
    }
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIFont *danmakuFont = [DDPCacheManager shareCacheManager].danmakuFont;
    if (indexPath.section == 0) {
        UIFont *tempFont = [UIFont systemFontOfSize:danmakuFont.pointSize];
        tempFont.isSystemFont = YES;
        [DDPCacheManager shareCacheManager].danmakuFont = tempFont;
    }
    else {
        NSDictionary *dic = self.fonts[indexPath.section - 1];
        NSArray *arr = dic.allValues.firstObject;
        UIFont *tempFont = [UIFont fontWithName:arr[indexPath.row] size:danmakuFont.pointSize];
        tempFont.isSystemFont = NO;
        [DDPCacheManager shareCacheManager].danmakuFont = tempFont;
    }
    
    [tableView reloadData];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    DDPTextHeaderView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"DDPTextHeaderView"];
    if (section == 0) {
        view.titleLabel.text = @"系统字体";
    }
    else {
        view.titleLabel.text = self.fonts[section - 1].allKeys.firstObject;
    }
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1 + self.fonts.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    NSDictionary *dic = self.fonts[section - 1];
    NSArray *arr = dic.allValues.firstObject;
    return arr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DDPSelectedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DDPSelectedTableViewCell" forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        cell.titleLabel.text = @"系统字体";
        cell.titleLabel.font = [UIFont ddp_normalSizeFont];
    }
    else {
        NSDictionary *dic = self.fonts[indexPath.section - 1];
        NSArray *arr = dic.allValues.firstObject;
        
        UIFont *font = [UIFont fontWithName:arr[indexPath.row] size:[UIFont ddp_normalSizeFont].pointSize];
        cell.titleLabel.text = font.fontName;
        cell.titleLabel.font = font;
    }
    
    UIFont *danmakuFont = [DDPCacheManager shareCacheManager].danmakuFont;
    
    if (indexPath.section == 0) {
        cell.iconImgView.hidden = !danmakuFont.isSystemFont;
    }
    else {
        NSDictionary *dic = self.fonts[indexPath.section - 1];
        NSArray *arr = dic.allValues.firstObject;
        
        cell.iconImgView.hidden = ![danmakuFont.fontName isEqualToString:arr[indexPath.row]];
    }
    
    return cell;
    
}

#pragma mark - 懒加载
- (DDPBaseTableView *)tableView {
    if (_tableView == nil) {
        _tableView = [[DDPBaseTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.allowScroll = YES;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        _tableView.estimatedRowHeight = 44;
        
        [_tableView registerClass:[DDPSelectedTableViewCell class] forCellReuseIdentifier:@"DDPSelectedTableViewCell"];
        [_tableView registerClass:[DDPTextHeaderView class] forHeaderFooterViewReuseIdentifier:@"DDPTextHeaderView"];
        
        _tableView.separatorStyle = UITableViewCellSelectionStyleNone;
        _tableView.tableFooterView = [[UIView alloc] init];
        
        @weakify(self)
        _tableView.mj_header = [MJRefreshNormalHeader ddp_headerRefreshingCompletionHandler:^{
            @strongify(self)
            if (!self) return;
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSMutableArray <NSMutableDictionary *>*fonts = [NSMutableArray array];
                NSArray<NSString *> *familyNames = [UIFont familyNames];
                [familyNames enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSArray *arr = [UIFont fontNamesForFamilyName:obj];
                    if (arr.count) {
                        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
                        dic[obj] = arr;
                        [fonts addObject:dic];
                    }
                }];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView.mj_header endRefreshing];
                    self.fonts = fonts;
                    [self.tableView reloadData];
                });
            });
        }];
        
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

@end
