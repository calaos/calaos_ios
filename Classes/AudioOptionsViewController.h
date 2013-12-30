//
//  AudioOptionsViewController.h
//  CalaosHome
//
//  Created by Raoul on 02/05/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioOptionsViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
{
    UIButton *buttonPlay;
    UIButton *buttonStop;
    UIButton *buttonRecord;
    UIButton *buttonSend;
    
    UIProgressView *progress;
    UIActivityIndicatorView *loader;
    
    AVAudioRecorder *audioRecorder;
    AVAudioPlayer *audioPlayer;
    NSTimer *timerProgress;
    
    NSInteger playerId;
    
    BOOL encodingDone;
}

@property (nonatomic, retain) IBOutlet UIButton *buttonPlay;
@property (nonatomic, retain) IBOutlet UIButton *buttonStop;
@property (nonatomic, retain) IBOutlet UIButton *buttonRecord;
@property (nonatomic, retain) IBOutlet UIButton *buttonSend;
@property (nonatomic, retain) IBOutlet UIProgressView *progress;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loader;
@property (nonatomic, assign) NSInteger playerId;

- (IBAction)buttonPlay:(id) sender;
- (IBAction)buttonStop:(id) sender;
- (IBAction)buttonRecord:(id) sender;
- (IBAction)buttonSend:(id) sender;

@end
