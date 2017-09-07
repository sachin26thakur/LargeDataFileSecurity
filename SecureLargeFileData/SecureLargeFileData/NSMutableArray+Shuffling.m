//
//  NSMutableArray+Shuffling.m
//  SecureLargeFileData
//
//  Created by Sachin on 24/08/17.
//  Copyright © 2017 SachinVsSachin. All rights reserved.
//

#import "NSMutableArray+Shuffling.h"

@implementation NSMutableArray (Shuffling)

- (void)shuffle
{
    NSUInteger count = [self count];
    if (count <= 1) return;
    for (NSUInteger i = 0; i < count - 1; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [self exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}


//- (void)playVideo{
//    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"shutter_island.mp4" ofType:nil];
//
//    NSURL *videoURL = [NSURL fileURLWithPath:filepath];
//
//    AVPlayer *player = [AVPlayer playerWithURL:videoURL];
//    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
//    playerViewController.player = player;
//    [playerViewController.player play];//Used to Play On start
//    [self presentViewController:playerViewController animated:YES completion:nil];
//}


@end
