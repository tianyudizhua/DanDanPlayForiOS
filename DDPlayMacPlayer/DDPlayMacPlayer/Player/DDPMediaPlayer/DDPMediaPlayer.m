//
//  DDPMediaPlayer.m
//  test
//
//  Created by JimHuang on 16/3/4.
//  Copyright © 2016年 JimHuang. All rights reserved.
//

#import "DDPMediaPlayer.h"
#import <VLCKit/VLCKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <DDPCategory/NSObject+DDPAddForKVO.h>

@interface VLCMedia(_Private)<DDPMediaItemProtocol>

@end

@implementation VLCMedia(_Private)

- (NSString *)path {
    return self.url.path;
}

- (NSString *)name {
    return [self.path lastPathComponent];
}

@end

@interface _DDPlayerView : VLCVideoView

@end

@implementation _DDPlayerView

- (BOOL)mouseDownCanMoveWindow {
    return YES;
}

@end

//最大音量
#define MAX_VOLUME 200.0

@interface DDPMediaPlayer()<VLCMediaPlayerDelegate, VLCMediaDelegate, VLCMediaListPlayerDelegate>
@property (strong, nonatomic) VLCMediaListPlayer *mediaListPlayer;
@property (nonatomic, strong, readonly) VLCMediaPlayer *localMediaPlayer;
@property (strong, nonatomic) NSView *mediaView;
@property (copy, nonatomic) SnapshotCompleteBlock snapshotCompleteBlock;

@property (nonatomic, strong) NSMutableArray <id<DDPMediaItemProtocol>>*medias;
@end

@implementation DDPMediaPlayer {
    NSTimeInterval _length;
    NSTimeInterval _currentTime;
    DDPMediaPlayerStatus _status;
    BOOL _pauseByUser;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.mediaListPlayer.mediaPlayer removeObserverBlocks];
    [self.mediaView removeFromSuperview];
//    free(_localMediaPlayer.videoAspectRatio);
    self.localMediaPlayer.drawable = nil;
    self.mediaListPlayer = nil;
    self.mediaView = nil;
}

#pragma mark 属性
- (CGSize)videoSize {
    return self.localMediaPlayer.videoSize;
}

- (DDPMediaType)mediaType {
    return [self.localMediaPlayer.media.url isFileURL] ? DDPMediaTypeLocaleMedia : DDPMediaTypeNetMedia;
}

- (NSTimeInterval)length {
    if (_length > 0) return _length;
    
    _length = self.localMediaPlayer.media.length.value.floatValue / 1000.0f;
    return _length;
}

- (NSTimeInterval)currentTime {
    return self.localMediaPlayer.time.value.floatValue / 1000.0f;
}

- (DDPMediaPlayerStatus)status {
    switch (self.localMediaPlayer.state) {
        case VLCMediaPlayerStateStopped:
            if (self.localMediaPlayer.position >= 0.999) {
                _status = DDPMediaPlayerStatusNextEpisode;
            }
            else {
                _status = DDPMediaPlayerStatusStop;
            }
            break;
        case VLCMediaPlayerStatePaused:
            if (!_pauseByUser && self.localMediaPlayer.position >= 0.999) {
                _status = DDPMediaPlayerStatusNextEpisode;
            }
            else {
                _status = DDPMediaPlayerStatusPause;
            }
            break;
        case VLCMediaPlayerStatePlaying:
            _status = DDPMediaPlayerStatusPlaying;
            break;
        case VLCMediaPlayerStateBuffering:
            if (self.localMediaPlayer.isPlaying) {
                _status = DDPMediaPlayerStatusPlaying;
            }
            else {
                _status = DDPMediaPlayerStatusPause;
            }
            break;
        default:
            _status = DDPMediaPlayerStatusUnknow;
            break;
    }
    return _status;
}

- (void)setRepeatMode:(DDPMediaPlayerRepeatMode)repeatMode {
    switch (repeatMode) {
        case DDPMediaPlayerRepeatModeDoNotRepeat:
            self.mediaListPlayer.repeatMode = VLCDoNotRepeat;
            break;
        case DDPMediaPlayerRepeatModeRepeatAllItems:
            self.mediaListPlayer.repeatMode = VLCRepeatAllItems;
            break;
        case DDPMediaPlayerRepeatModeRepeatCurrentItem:
            self.mediaListPlayer.repeatMode = VLCRepeatCurrentItem;
            break;
        default:
            break;
    }
}

- (DDPMediaPlayerRepeatMode)repeatMode {
    switch (self.mediaListPlayer.repeatMode) {
        case VLCDoNotRepeat:
            return DDPMediaPlayerRepeatModeDoNotRepeat;
        case VLCRepeatAllItems:
            return DDPMediaPlayerRepeatModeRepeatAllItems;
        case VLCRepeatCurrentItem:
            return DDPMediaPlayerRepeatModeRepeatCurrentItem;
        default:
            break;
    }
    return DDPMediaPlayerRepeatModeDoNotRepeat;
}

- (id<DDPMediaItemProtocol>)currentPlayItem {
    return self.localMediaPlayer.media;
}

#pragma mark 音量
- (void)volumeJump:(CGFloat)value {
    [self setVolume: self.volume + value];
}

- (CGFloat)volume {
    return self.localMediaPlayer.audio.volume;
}

- (void)setVolume:(CGFloat)volume {
    if (volume < 0) volume = 0;
    if (volume > MAX_VOLUME) volume = MAX_VOLUME;
    
    self.localMediaPlayer.audio.volume = volume;
}

#pragma mark 播放位置
- (void)jump:(int)value completionHandler:(void(^)(NSTimeInterval time))completionHandler {
    [self setPosition:([self currentTime] + value) / [self length] completionHandler:completionHandler];
}

- (void)setCurrentTime:(int)time completionHandler:(void(^)(NSTimeInterval time))completionHandler {
    [self setPosition:time / [self length] completionHandler:completionHandler];
}

- (void)setPosition:(CGFloat)position completionHandler:(void(^)(NSTimeInterval time))completionHandler {
    if (position < 0) position = 0;
    if (position > 1) position = 1;
    
    self.localMediaPlayer.position = position;
    NSTimeInterval jumpTime = [self length] * position;
    
    if (completionHandler) completionHandler(jumpTime);
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:userJumpWithTime:)]) {
        [self.delegate mediaPlayer:self userJumpWithTime:jumpTime];
    }
}

- (CGFloat)position {
    return self.localMediaPlayer.position;
}

#pragma mark 字幕
- (void)setSubtitleDelay:(NSInteger)subtitleDelay {
    self.localMediaPlayer.currentVideoSubTitleDelay = subtitleDelay;
}

- (NSInteger)subtitleDelay {
    return self.localMediaPlayer.currentVideoSubTitleDelay;
}

- (NSArray *)subtitleIndexs {
    return self.localMediaPlayer.videoSubTitlesIndexes;
}

- (NSArray *)subtitleTitles {
    return self.localMediaPlayer.videoSubTitlesNames;
}

- (void)setCurrentSubtitleIndex:(int)currentSubtitleIndex {
    self.localMediaPlayer.currentVideoSubTitleIndex = currentSubtitleIndex;
}

- (int)currentSubtitleIndex {
    return self.localMediaPlayer.currentVideoSubTitleIndex;
}


- (NSArray<NSNumber *> *)audioChannelIndexs {
    return self.localMediaPlayer.audioTrackIndexes;
}

- (NSArray<NSString *> *)audioChannelTitles {
    return self.localMediaPlayer.audioTrackIndexes;
}

- (void)setCurrentAudioChannelIndex:(int)currentAudioChannelIndex {
    self.localMediaPlayer.currentAudioTrackIndex = currentAudioChannelIndex;
}

- (int)currentAudioChannelIndex {
    return self.localMediaPlayer.currentAudioTrackIndex;
}


- (void)setSpeed:(float)speed {
    self.localMediaPlayer.rate = speed;
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:rateChange:)]) {
        [self.delegate mediaPlayer:self rateChange:self.localMediaPlayer.rate];
    }
}

- (float)speed {
    return self.localMediaPlayer.rate;
}

- (void)setVideoAspectRatio:(CGSize)videoAspectRatio {
    if (CGSizeEqualToSize(videoAspectRatio, CGSizeZero)) {
        self.localMediaPlayer.videoAspectRatio = nil;
    }
    else {
        self.localMediaPlayer.videoAspectRatio = (char *)[NSString stringWithFormat:@"%ld:%ld", (long)videoAspectRatio.width, (long)videoAspectRatio.height].UTF8String;
    }
}

#pragma mark 播放器控制
- (BOOL)isPlaying {
    return [self.localMediaPlayer isPlaying];
}

- (void)play {
    [self.mediaListPlayer play];
}

- (void)playNext {
    let item = [self nextItem];
    if (item) {
        [self playWithItem:item];
    }
}

- (id<DDPMediaItemProtocol>)nextItem {
    var index = [self indexWithItem:self.currentPlayItem];
    if (index != NSNotFound && index + 1 < self.playerLists.count) {
        index = index + 1;
    } else {
        index = 0;
    }
    
    if (index < self.playerLists.count) {
        return self.playerLists[index];
    }
    return nil;
}

- (void)pause {
    _pauseByUser = YES;
    [self.mediaListPlayer pause];
}

- (void)stop {
    [self.mediaListPlayer stop];
}


#pragma mark 功能
- (void)saveVideoSnapshotwithSize:(CGSize)size completionHandler:(SnapshotCompleteBlock)completion {
    //vlc截图方式
    NSError *error = nil;
    NSString *directoryPath = [NSString stringWithFormat:@"%@/VLC_snapshot", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:directoryPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    //创建文件错误
    if (error) {
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    self.snapshotCompleteBlock = completion;
    
    NSString *aPath = [directoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%lu", (unsigned long)[NSDate date].hash]];
    [self.localMediaPlayer saveVideoSnapshotAt:aPath withWidth:size.width andHeight:size.height];
}

- (int)openVideoSubTitlesFromFile:(NSURL *)path {
    //    if (self.mediaType == DDPMediaTypeLocaleMedia) {
    return [self.localMediaPlayer addPlaybackSlave:path type:VLCMediaPlaybackSlaveTypeSubtitle enforce:YES];
    //    }
    
    //    return [_localMediaPlayer openVideoSubTitlesFromFile:a];
}

- (void)setPlayerLists:(NSArray<id<DDPMediaItemProtocol>> *)playerLists {
    
    NSMutableArray <VLCMedia *>*arr = [NSMutableArray arrayWithCapacity:playerLists.count];
    
    [playerLists enumerateObjectsUsingBlock:^(id<DDPMediaItemProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        let m = [VLCMedia mediaWithPath:obj.path];
        [arr addObject:m];
    }];
    
    self.medias = [playerLists mutableCopy];
    
    self.mediaListPlayer.mediaList = [[VLCMediaList alloc] initWithArray:arr];
    _length = -1;
}

- (NSArray<id<DDPMediaItemProtocol>> *)playerLists {
    return self.medias;
}

- (void)addMediaItems:(NSArray <id<DDPMediaItemProtocol>>*)items {
    
    let mediaList = self.mediaListPlayer.mediaList;
    __block NSInteger index = NSNotFound;
    [items enumerateObjectsUsingBlock:^(id<DDPMediaItemProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        index = [self indexWithItem:obj];
        
        if (index == NSNotFound) {
            let m = [VLCMedia mediaWithPath:obj.path];
            [self.medias addObject:m];
            [mediaList addMedia:m];
        }
        
    }];
    
}

- (void)removeMediaItem:(id<DDPMediaItemProtocol>)item {
    let index = [self indexWithItem:item];
    if (index != NSNotFound) {
        let mediaList = self.mediaListPlayer.mediaList;
        [mediaList removeMediaAtIndex:index];
        [self.medias removeObjectAtIndex:index];
    }
}

- (void)removeMediaAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.medias.count) {
        let mediaList = self.mediaListPlayer.mediaList;
        [mediaList removeMediaAtIndex:index];
        [self.medias removeObjectAtIndex:index];
    }
}

- (void)removeMediaWithIndexSet:(NSIndexSet *)indexSet {
    NSMutableArray <id<DDPMediaItemProtocol>>*arr = [NSMutableArray arrayWithCapacity:indexSet.count];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx >= 0 && idx < self.medias.count) {
            [arr addObject:self.medias[idx]];
        }
    }];
    
    [arr enumerateObjectsUsingBlock:^(id<DDPMediaItemProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeMediaItem:obj];
    }];
}

- (void)playWithItem:(id<DDPMediaItemProtocol>)item {
    VLCMedia *media = [self mediaWithItem:item];
    if (media == nil) {
        media = [VLCMedia mediaWithPath:item.path];
        [self addMediaItems:@[media]];
    }
    
    [self.mediaListPlayer playMedia:media];
}

- (NSInteger)indexWithItem:(id<DDPMediaItemProtocol>)item {
    __block NSInteger index = NSNotFound;
    [self.playerLists enumerateObjectsUsingBlock:^(id<DDPMediaItemProtocol>  _Nonnull obj1, NSUInteger idx1, BOOL * _Nonnull stop1) {
        if ([obj1.path isEqualTo:item.path]) {
            index = idx1;
            *stop1 = YES;
        }
    }];
    
    return index;
}

#pragma mark - VLCMediaPlayerDelegate
- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification {
    if ([self.delegate respondsToSelector:@selector(mediaPlayer:currentTime:totalTime:)]) {
        NSTimeInterval nowTime = [self currentTime];
        NSTimeInterval videoTime = [self length];
        [self.delegate mediaPlayer:self currentTime:nowTime totalTime:videoTime];
    }
}

- (void)mediaPlayerSnapshot:(NSNotification *)aNotification {
    NSImage *tempImage = self.localMediaPlayer.lastSnapshot;
    [self saveImage:tempImage];
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification {
    JHLog(@"状态 %@", VLCMediaPlayerStateToString(self.localMediaPlayer.state));

    if ([self.delegate respondsToSelector:@selector(mediaPlayer:statusChange:)]) {
        if (self.localMediaPlayer.state == VLCMediaPlayerStatePaused) {
            _pauseByUser = NO;
        }
        DDPMediaPlayerStatus status = [self status];
        [self.delegate mediaPlayer:self statusChange:status];
    }
}


#pragma mark - 私有方法
- (void)saveImage:(NSImage *)image {
    
}

- (VLCMedia *)mediaWithItem:(id<DDPMediaItemProtocol>)item {
    NSInteger index = [self indexWithItem:item];
    if (index != NSNotFound) {
        return [self.mediaListPlayer.mediaList mediaAtIndex:index];
    }
    return nil;
}

#pragma mark 播放结束
- (void)playEnd:(NSNotification *)sender {
    if (self.mediaType == DDPMediaTypeNetMedia) {
        _status = DDPMediaPlayerStatusStop;
        if ([self.delegate respondsToSelector:@selector(mediaPlayer:statusChange:)]) {
            [self.delegate mediaPlayer:self statusChange:DDPMediaPlayerStatusStop];
        }
    }
}

#pragma mark - 懒加载
- (VLCMediaListPlayer *)mediaListPlayer {
    if(_mediaListPlayer == nil) {
        _mediaListPlayer = [[VLCMediaListPlayer alloc] initWithDrawable:self.mediaView];
        _mediaListPlayer.delegate = self;
        _mediaListPlayer.mediaList = [[VLCMediaList alloc] init];
        _mediaListPlayer.mediaPlayer.drawable = self.mediaView;
        _mediaListPlayer.mediaPlayer.delegate = self;
        @weakify(self)
        [_mediaListPlayer.mediaPlayer addObserverBlockForKeyPath:DDP_KEYPATH(_mediaListPlayer.mediaPlayer, media) block:^(id  _Nonnull obj, id  _Nonnull oldVal, VLCMedia * _Nonnull newVal) {
            @strongify(self)
            if (![self.delegate respondsToSelector:@selector(mediaPlayer:mediaDidChange:)]) {
                return;
            }
            
            [self.delegate mediaPlayer:self mediaDidChange:newVal];
        }];
    }
    return _mediaListPlayer;
}

- (NSView *)mediaView {
    if (_mediaView == nil) {
        VLCVideoView *mediaView = [[_DDPlayerView alloc] init];
        mediaView.fillScreen = YES;
        mediaView.wantsLayer = YES;
        _mediaView = mediaView;
    }
    return _mediaView;
}

- (VLCMediaPlayer *)localMediaPlayer {
    return self.mediaListPlayer.mediaPlayer;
}

- (NSMutableArray *)medias {
    if (_medias == nil) {
        _medias = [NSMutableArray array];
    }
    return _medias;
}

@end
