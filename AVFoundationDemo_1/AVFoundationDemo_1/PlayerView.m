
//
//  PlayerView.m
//  AVFoundationDemo_1
//
//  Created by Mac on 17/2/23.
//  Copyright © 2017年 APK. All rights reserved.
//

#import "PlayerView.h"

@implementation PlayerView

+ (Class)layerClass{
    
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer *)player{
    
    AVPlayerLayer *layer = (AVPlayerLayer *)self.layer;
    layer.player = player;
}

- (AVPlayer *)player{
    
    AVPlayerLayer *layer = (AVPlayerLayer *)self.layer;
    return layer.player;
}


@end
