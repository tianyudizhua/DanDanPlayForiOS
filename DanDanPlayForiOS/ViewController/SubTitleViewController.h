//
//  SubTitleViewController.h
//  DanDanPlayForiOS
//
//  Created by JimHuang on 2017/5/17.
//  Copyright © 2017年 JimHuang. All rights reserved.
//  选择字幕

#import "BaseViewController.h"

@interface SubTitleViewController : BaseViewController
@property (copy, nonatomic) void(^selectedSubTitleCallBack)(NSURL *);
@end