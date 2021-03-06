//
//  DDPPlayerSlider.m
//  DDPlayMacPlayer
//
//  Created by JimHuang on 2019/7/29.
//  Copyright © 2019 JimHuang. All rights reserved.
//

#import "DDPPlayerSlider.h"
#import "DDPHUD.h"
#import <Masonry/Masonry.h>

@interface DDPPlayerSlider ()
@property (strong, nonatomic) NSTrackingArea *trackingArea;
@property (weak, nonatomic) DDPHUD *hud;
@property (strong, nonatomic) NSView *slider;
@end

@implementation DDPPlayerSlider

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupInit];
}

- (void)dealloc {
    [self removeTrackingArea:self.trackingArea];
}

- (void)mouseExited:(NSEvent *)event {
    if (self.hud != nil) {
        [self.hud dismiss];
    }
}

- (void)mouseMoved:(NSEvent *)event {
    if ([self.delegate respondsToSelector:@selector(playerSliderViewShouldShowTips)] && ![self.delegate playerSliderViewShouldShowTips]) {
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(playerSliderView:didShowTipsAtProgress:)]) {
        let progress = [self progressWithEvent:event];
        
        let str = [self.delegate playerSliderView:self didShowTipsAtProgress:progress];
        DDPHUD *hud = self.hud;
        if (hud == nil) {
            hud = [[DDPHUD alloc] initWithStyle:DDPHUDStyleCompact];
            hud.autoHidden = NO;
            self.hud = hud;
        }
        
        hud.title = str;
        [hud showAtView:self.superview position:DDPHUDPositionCustom];
        
        var frame = CGRectZero;
        frame.size = hud.fittingSize;
        frame.origin.y = frame.size.height * 3 - 2;
        frame.origin.x = event.locationInWindow.x - (frame.size.width / 2);
        
        if (CGRectGetMinX(frame) < 5) {
            frame.origin.x = 5;
        }
        
        let superviewWidth = CGRectGetWidth(self.superview.frame);
        if (CGRectGetMaxX(frame) > superviewWidth - 5) {
            frame.origin.x = superviewWidth - CGRectGetWidth(frame) - 5;
        }
        
        hud.frame = frame;
    }
}

- (void)setCurrentProgress:(float)currentProgress {
    if (isnan(currentProgress)) currentProgress = 0;
    _currentProgress = currentProgress;
    [self layoutSubView];
}

- (void)mouseDragged:(NSEvent *)event {
    _tracking = YES;
    
    let value = [self progressWithEvent:event];
    self.currentProgress = value;
    if ([self.delegate respondsToSelector:@selector(playerSliderView:didDragProgress:)]) {
        [self.delegate playerSliderView:self didDragProgress:value];
    }
    
    [self mouseMoved:event];
}

- (void)mouseDown:(NSEvent *)event {
    [self mouseDragged:event];
}

- (void)mouseUp:(NSEvent *)event {
    _tracking = NO;
    let value = [self progressWithEvent:event];
    self.currentProgress = value;
    if ([self.delegate respondsToSelector:@selector(playerSliderView:didClickProgress:)]) {
        [self.delegate playerSliderView:self didClickProgress:value];
    }
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    [self layoutSubView];
}

- (BOOL)mouseDownCanMoveWindow {
    return NO;
}

#pragma mark - 私有方法
- (void)layoutSubView {
    let width = CGRectGetWidth(self.frame);
    let height = 5;
    self.slider.frame = CGRectMake(0, (CGRectGetHeight(self.bounds) - height) / 2, width * _currentProgress, height);
}

- (void)setupInit {
    self.wantsLayer = YES;
//    self.layer.backgroundColor = [NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.3].CGColor;
    [self addTrackingArea:self.trackingArea];
    
    [self addSubview:self.slider];
}

- (float)progressWithEvent:(NSEvent *)event {
    var point = event.locationInWindow;
    var pointInView = point;
    let contentView = event.window.contentView;
    if (contentView) {
        pointInView = [self convertPoint:point fromView:contentView];
    }
    
    var progress = pointInView.x / CGRectGetWidth(self.frame);
    if (isnan(progress) || progress < 0) {
        progress = 0;
    }
    
    return progress;
}

#pragma mark - 懒加载
- (NSTrackingArea *)trackingArea {
    if(_trackingArea == nil) {
        _trackingArea = [[NSTrackingArea alloc] initWithRect:self.frame options:NSTrackingActiveInKeyWindow | NSTrackingMouseMoved | NSTrackingInVisibleRect | NSTrackingMouseEnteredAndExited owner:self userInfo:nil];
    }
    return _trackingArea;
}

- (NSView *)slider {
    if (_slider == nil) {
        _slider = [[NSView alloc] init];
        _slider.wantsLayer = YES;
        _slider.layer.backgroundColor = NSColor.systemBlueColor.CGColor;
    }
    return _slider;
}

@end
