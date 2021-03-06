//
//  DDPHttpReceiveTableViewCell.m
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/11/15.
//  Copyright © 2017年 JimHuang. All rights reserved.
//

#import "DDPHttpReceiveTableViewCell.h"

@implementation DDPHttpReceiveTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.mas_equalTo(0);
        }];
    }
    return self;
}

#pragma mark - 懒加载
- (UIProgressView *)progressView {
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.progressTintColor = [UIColor ddp_mainColor];
        [self.contentView addSubview:_progressView];
    }
    return _progressView;
}

@end
