//
//  ViewController.m
//  AVFoundationDemo_1
//
//  Created by Mac on 17/2/22.
//  Copyright © 2017年 APK. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "PlayerView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *controlVideoButton;
@property (weak, nonatomic) IBOutlet UIView *loadingView;

@property (strong,nonatomic) AVPlayer *player;
@property (strong,nonatomic) AVMutableComposition *composition;
@property (strong,nonatomic) AVMutableAudioMix *audioMix;
@property (strong,nonatomic) AVMutableVideoComposition *videoComposition;
@property (strong,nonatomic) CALayer *waterMarkLayer;

@end


@implementation ViewController

- (void)viewDidLoad{
    
    [super viewDidLoad];
    [self setupComposition];
    [self setupPlayer];
}

#pragma mark - getter

- (AVMutableAudioMix *)audioMix{
    
    if (!_audioMix) {
        
        AVMutableCompositionTrack *audioTrack = [[self.composition tracksWithMediaType:AVMediaTypeAudio] firstObject];
        AVMutableAudioMixInputParameters *parameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
        _audioMix = [AVMutableAudioMix audioMix];
        _audioMix.inputParameters = @[parameters];
    }
    
    return _audioMix;
}

- (AVMutableVideoComposition *)videoComposition{
    
    if (!_videoComposition) {
        
        AVMutableCompositionTrack *videoTrack = [[self.composition tracksWithMediaType:AVMediaTypeVideo] firstObject];
        AVMutableVideoCompositionLayerInstruction *compositionLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        AVMutableVideoCompositionInstruction *compositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        compositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.composition.duration);
        compositionInstruction.layerInstructions = @[compositionLayerInstruction];
        
        _videoComposition = [AVMutableVideoComposition videoComposition];
        _videoComposition.instructions = @[compositionInstruction];
        _videoComposition.renderSize = videoTrack.naturalSize;
        _videoComposition.frameDuration = CMTimeMake(1, 30);
    }
    
    return _videoComposition;
}

#pragma mark - actions

- (IBAction)exportVideo:(UIButton *)sender {

    [self exportVideo];
}

- (IBAction)addWatermark:(UISwitch *)sender {
    
    if (sender.isOn) {
        
        CALayer *watermarkLayer =  [CALayer layer];
        watermarkLayer.backgroundColor = [UIColor greenColor].CGColor;
        watermarkLayer.frame = CGRectMake(8, 8, 20, 20);
        [self.playerView.layer addSublayer:watermarkLayer];
        self.waterMarkLayer = watermarkLayer;

    }else{
        
        [self.waterMarkLayer removeFromSuperlayer];
        self.waterMarkLayer = nil;
    }
    
    [self setupPlayer];
}

- (IBAction)audioFadeOut:(UISwitch *)sender {
    
    AVMutableAudioMixInputParameters *parameters = (AVMutableAudioMixInputParameters *)[self.audioMix.inputParameters firstObject];
    CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(self.composition.duration)/2, 600), self.composition.duration);

    if (sender.isOn) {
        [parameters setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:timeRange];
    }else{
        [parameters setVolumeRampFromStartVolume:1 toEndVolume:1 timeRange:timeRange];
    }
    
    [self setupPlayer];
}

- (IBAction)videoFadeOut:(UISwitch *)sender {
    
    AVMutableVideoCompositionInstruction *compositionInstruction = (AVMutableVideoCompositionInstruction *)[self.videoComposition.instructions firstObject];
    AVMutableVideoCompositionLayerInstruction *compositionLayerInstruction = (AVMutableVideoCompositionLayerInstruction *)[compositionInstruction.layerInstructions firstObject];
    CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(self.composition.duration)/2, 600), self.composition.duration);

    if (sender.isOn) {
        [compositionLayerInstruction setOpacityRampFromStartOpacity:1 toEndOpacity:0 timeRange:timeRange];
    }else{
        [compositionLayerInstruction setOpacityRampFromStartOpacity:1 toEndOpacity:1 timeRange:timeRange];
    }
    
    [self setupPlayer];
}

- (IBAction)videoTransform:(UISwitch *)sender {
    
    AVMutableVideoCompositionInstruction *compositionInstruction = (AVMutableVideoCompositionInstruction *)[self.videoComposition.instructions firstObject];
    AVMutableVideoCompositionLayerInstruction *compositionLayerInstruction = (AVMutableVideoCompositionLayerInstruction *)[compositionInstruction.layerInstructions firstObject];
    CMTimeRange timeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(self.composition.duration)/2, 600), self.composition.duration);
    
    AVMutableCompositionTrack *videoTrack = [[self.composition tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGAffineTransform currentTransform = videoTrack.preferredTransform;
    CGAffineTransform newTransform  = CGAffineTransformTranslate(currentTransform, 0, videoTrack.naturalSize.height);
    
    if (sender.isOn) {
        [compositionLayerInstruction setTransformRampFromStartTransform:currentTransform toEndTransform:newTransform timeRange:timeRange];
    }else{
        [compositionLayerInstruction setTransformRampFromStartTransform:currentTransform toEndTransform:currentTransform timeRange:timeRange];
    }
    
    [self setupPlayer];
}

- (IBAction)videoBackgroundColor:(UISwitch *)sender {

    AVMutableVideoCompositionInstruction *compositionInstruction = (AVMutableVideoCompositionInstruction *)[self.videoComposition.instructions firstObject];
    if (sender.isOn) {
        compositionInstruction.backgroundColor = [UIColor redColor].CGColor;
    }else{
        compositionInstruction.backgroundColor = [UIColor clearColor].CGColor;
    }
    
    [self setupPlayer];
}

- (IBAction)controlVideo:(UIBarButtonItem *)sender {
    
    sender.enabled = NO;
    [self.player play];
}

#pragma mark - private method

- (void)exportVideo{
    
    if (self.player) [self.player pause];
    
    self.loadingView.hidden = NO;
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:self.composition presetName:AVAssetExportPresetHighestQuality];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *videoUrl = [[fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] URLByAppendingPathComponent:@"1234.mp4"];
    if ([fileManager fileExistsAtPath:videoUrl.path]) {
        [fileManager removeItemAtURL:videoUrl error:nil];
    }
    
    if (self.waterMarkLayer) {
        
        CGSize videoSize = self.videoComposition.renderSize;
        CALayer *waterMark = [self getWaterMarkWithSource:self.waterMarkLayer videoSize:videoSize playerViewSize:self.playerView.frame.size];
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
        [parentLayer addSublayer:videoLayer];
        [parentLayer addSublayer:waterMark];
        self.videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }
    
    exportSession.outputURL = videoUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.audioMix = self.audioMix;
    exportSession.videoComposition = self.videoComposition;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            self.loadingView.hidden = YES;
            
            NSString *message = nil;
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                
                message = @"Export success";
                [self saveVideoWithUrl:videoUrl];
                
            }else{
                message = @"Export failure";
            }
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            }];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:cancel];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }];
}

#pragma mark  setup video player

- (void)setupPlayerWithUrl:(NSURL *)url{
    
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    if (self.player) {
        
        [self.player replaceCurrentItemWithPlayerItem:item];
        
    }else{
        
        self.player = [[AVPlayer alloc] initWithPlayerItem:item];
        self.playerView.player = self.player;
        [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self.player seekToTime:kCMTimeZero];
            self.controlVideoButton.enabled = YES;
        }];
    }
    
    self.controlVideoButton.enabled = YES;
}

- (void)setupPlayer{
    
    self.videoComposition.animationTool = NULL;
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.composition];
    item.audioMix = self.audioMix;
    item.videoComposition = self.videoComposition;
    
    if (self.player) {
        
        [self.player pause];
        [self.player replaceCurrentItemWithPlayerItem:item];
        
    }else{
        
        self.player = [[AVPlayer alloc] initWithPlayerItem:item];
        self.playerView.player = self.player;
        [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self.player seekToTime:kCMTimeZero];
            self.controlVideoButton.enabled = YES;
        }];
    }
    
    self.controlVideoButton.enabled = YES;
}

#pragma mark  edit video

- (void)setupComposition{
    
    NSURL *video1Url = [[NSBundle mainBundle] URLForResource:@"video1" withExtension:@"m4v"];
    NSURL *video2Url = [[NSBundle mainBundle] URLForResource:@"video2" withExtension:@"mov"];
    NSURL *audioUrl = [[NSBundle mainBundle] URLForResource:@"audio" withExtension:@"mp3"];
    AVAssetTrack *video1Track = [self getAssetTrackWithAssetUrl:video1Url mediaType:AVMediaTypeVideo];
    AVAssetTrack *video2Track = [self getAssetTrackWithAssetUrl:video2Url mediaType:AVMediaTypeVideo];
    AVAssetTrack *audioTrack = [self getAssetTrackWithAssetUrl:audioUrl mediaType:AVMediaTypeAudio];
    NSAssert(video1Track && video2Track && audioTrack, @"无法读取视频或音频材料");
    
    self.composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioCompositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    Float64 videoCutTime = 3;
    CMTimeRange videoCutRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(videoCutTime, 600));
    
    NSError *error = nil;
    [videoCompositionTrack insertTimeRange:videoCutRange ofTrack:video1Track atTime:self.composition.duration error:&error];
    NSAssert(!error, @"插入视频轨道失败");
    [videoCompositionTrack insertTimeRange:videoCutRange ofTrack:video2Track atTime:self.composition.duration error:&error];
    NSAssert(!error, @"插入视频轨道失败");
    
    CMTimeRange audioCutRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(videoCutTime * 2, 600));
    [audioCompositionTrack insertTimeRange:audioCutRange ofTrack:audioTrack atTime:kCMTimeZero error:&error];
    NSAssert(!error, @"插入音频轨道失败");
}

#pragma mark Utilities

- (AVAssetTrack *)getAssetTrackWithAssetUrl:(NSURL *)url mediaType:(NSString *)mediaType{
    
    AVAssetTrack *track = nil;
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:url];
    NSArray *trackArray = [asset tracksWithMediaType:mediaType];
    if (trackArray.count > 0) {
        track = [trackArray firstObject];
    }

    return track;
}

- (void)saveVideoWithUrl:(NSURL *)url{
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
       
        [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:url];
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
       
        if (success) {
            NSLog(@"save video success");
        }else{
            NSLog(@"save video failure");
        }
    }];
}

- (CALayer *)getWaterMarkWithSource:(CALayer *)sourceWaterMark videoSize:(CGSize)videoSize playerViewSize:(CGSize)videoViewSize{
    
    CGFloat scale = videoSize.width / videoViewSize.width;
    CGRect sourceFrame = sourceWaterMark.frame;
    CGFloat width = sourceFrame.size.width * scale;
    CGFloat height = sourceFrame.size.height * scale;
    CGFloat x = sourceFrame.origin.x * scale;
    CGFloat y = (videoViewSize.height - sourceFrame.size.height - sourceFrame.origin.y) * scale;
    
    CALayer *waterMark = [CALayer layer];
    waterMark.backgroundColor = sourceWaterMark.backgroundColor;
    waterMark.frame = CGRectMake(x, y, width, height);
    return waterMark;
}

- (BOOL)isVideoPortrait:(AVAssetTrack *)videoTrack{
    
    BOOL isPortrait = NO;
    CGAffineTransform transform = videoTrack.preferredTransform;
    if (transform.a == 0 && transform.d == 0 && (transform.b == 1.0 || transform.b == -1.0) && (transform.c == 1.0 || transform.c == -1.0)) {
        isPortrait = YES;
    }
    
    return isPortrait;
}

@end
