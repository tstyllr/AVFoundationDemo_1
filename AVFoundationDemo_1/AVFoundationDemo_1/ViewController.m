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
@property (strong,nonatomic) AVMutableComposition *composition;
@property (strong,nonatomic) AVPlayer *player;
@property (strong,nonatomic) AVMutableAudioMix *audioMix;
@property (strong,nonatomic) AVMutableVideoComposition *videoComposition;
@property (strong,nonatomic) CALayer *waterMarkLayer;

@end


@implementation ViewController

- (void)viewDidLoad{
    
    [super viewDidLoad];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"video1" withExtension:@"MOV"];
    [self appendVideoWithUrl:url];
    url = [[NSBundle mainBundle] URLForResource:@"video2" withExtension:@"MOV"];
    [self appendVideoWithUrl:url];
    [self setupPlayer];
}

#pragma mark - getter

- (AVMutableComposition *)composition{
    
    if (!_composition) {
        _composition = [AVMutableComposition composition];
    }
    return _composition;
}

#pragma mark - actions

- (IBAction)exportVideo:(UIButton *)sender {

    [self exportVideo];
}

- (IBAction)addWatermark:(UIButton *)sender {
    
    sender.enabled = NO;
    [self addWaterMark];
    [self setupPlayer];
}

- (IBAction)addBackgroundMusic:(UIButton *)sender {
    
    sender.enabled = NO;
    [self updateMusic];
    [self setupPlayer];
}

- (IBAction)processVideo:(UIButton *)sender {
    
    sender.enabled = NO;
    [self addVideoEffect];
    [self setupPlayer];
}

- (IBAction)controlVideo:(UIBarButtonItem *)sender {
    
    sender.enabled = NO;
    [self.player play];
}

#pragma mark - private method

- (void)exportVideo{
    
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

#pragma mark  play video

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
        
        [self.player replaceCurrentItemWithPlayerItem:item];
        
    }else{
        
        self.player = [[AVPlayer alloc] initWithPlayerItem:item];
        self.playerView.player = self.player;
        [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self.player seekToTime:kCMTimeZero];
            self.controlVideoButton.enabled = YES;
        }];
    }
    
    if(self.waterMarkLayer) {
         [self.playerView.layer addSublayer:self.waterMarkLayer];
    }
    
    self.controlVideoButton.enabled = YES;
}

#pragma mark  edit video

- (void)addWaterMark{
    
    if (!self.waterMarkLayer) {
        
        CALayer *watermarkLayer =  [CALayer layer];
        watermarkLayer.backgroundColor = [UIColor greenColor].CGColor;
        watermarkLayer.frame = CGRectMake(8, 8, 20, 20);
        self.waterMarkLayer = watermarkLayer;
    }
}

- (void)addVideoEffect{
    
    AVMutableCompositionTrack *videoTrack = [self getCompositionTrackWithMediaType:AVMediaTypeVideo];
    AVMutableVideoCompositionLayerInstruction *videoLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    CGAffineTransform currentTransform = videoTrack.preferredTransform;
    CGAffineTransform newTransform  = CGAffineTransformTranslate(currentTransform, 0, videoTrack.naturalSize.height);
    CMTimeRange effectTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(CMTimeGetSeconds(self.composition.duration)/2, 600), self.composition.duration);
    [videoLayerInstruction setOpacityRampFromStartOpacity:1 toEndOpacity:0 timeRange:effectTimeRange];
    [videoLayerInstruction setTransformRampFromStartTransform:currentTransform toEndTransform:newTransform timeRange:effectTimeRange];
    
    AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.composition.duration);
    videoCompositionInstruction.layerInstructions = @[videoLayerInstruction];
    videoCompositionInstruction.backgroundColor = [UIColor redColor].CGColor;

    self.videoComposition = [AVMutableVideoComposition videoComposition];
    self.videoComposition.instructions = @[videoCompositionInstruction];
    self.videoComposition.renderSize = videoTrack.naturalSize;
    self.videoComposition.frameDuration = CMTimeMake(1, 30);
}

- (void)updateMusic{
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"audio" withExtension:@"mp3"];
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    AVMutableCompositionTrack *compositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,self.composition.duration) ofTrack:track atTime:kCMTimeZero error:nil];
    AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionTrack];
    [mixParameters setVolumeRampFromStartVolume:1 toEndVolume:0 timeRange:CMTimeRangeMake(kCMTimeZero, self.composition.duration)];
    self.audioMix = [AVMutableAudioMix audioMix];
    self.audioMix.inputParameters = @[mixParameters];
}

- (void)appendVideoWithUrl:(NSURL *)url{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    if ([self isVideoPortrait:track]) {
        NSLog(@"video is portrait");
    }else{
        NSLog(@"video is not portrait");
    }
    
    AVMutableCompositionTrack *compositionTrack = [self getCompositionTrackWithMediaType:AVMediaTypeVideo];
    if (!compositionTrack) {
        compositionTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    }

    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(3, 600)) ofTrack:track atTime:self.composition.duration error:nil];
}

- (void)createComposition{
    
    self.composition = [AVMutableComposition composition];
    [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [self.composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
}

#pragma mark Utilities

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

- (AVMutableCompositionTrack *)getCompositionTrackWithMediaType:(NSString *)mediaType{
    
    AVMutableCompositionTrack *compositionTrack = nil;
    NSArray *compositionTracks = [self.composition tracksWithMediaType:mediaType];
    if (compositionTracks.count > 0) {
        compositionTrack = [compositionTracks firstObject];
    }
    return compositionTrack;
}

@end
