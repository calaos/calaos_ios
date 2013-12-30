//
//  MusicCellView.m
//  CalaosHome
//
//  Created by calaos on 03/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "MusicCellView.h"
#import "CalaosRequest.h"
#import "UIImageAdditions.h"

@implementation MusicCellView

@synthesize delegate, playerName, playerCover, songTitle, songArtist, buttonPlay, buttonStop, sliderVolume;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}

- (void)dealloc 
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    
    self.playerCover = nil;
    self.playerName = nil;
    self.songArtist = nil;
    self.songTitle = nil;
    self.buttonStop = nil;
    self.buttonPlay = nil;
    self.sliderVolume = nil;
    
    [super dealloc];
}

- (void)audioCoverDone:(NSData *)pictureData
{   
    if (!pictureData)
    {
        NSLog(@"Failed to get audio cover picture");
    }
    else
    {
        self.playerCover.image = [[UIImage imageWithData:pictureData] imageByScalingAndCroppingForSize:self.playerCover.frame.size];
    }
}

- (void)updateAudioPlayer
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    NSDictionary *player = [calaos getAudioWithId:0];
    
    if (!player)
        return;
    
    playerName.text = [player objectForKey:@"name"];
    songArtist.text = [[player objectForKey:@"current_track"] objectForKey:@"artist"];
    songTitle.text = [[player objectForKey:@"current_track"] objectForKey:@"title"];
    sliderVolume.value = [[player objectForKey:@"volume"] doubleValue] / 100.0;
    
    if ([[player objectForKey:@"status"] isEqualToString:@"play"] ||
        [[player objectForKey:@"status"] isEqualToString:@"playing"])
    {
        buttonPlay.hidden = YES;
        buttonStop.hidden = NO;
    }
    else
    {
        buttonPlay.hidden = NO;
        buttonStop.hidden = YES;
    }
    
    [calaos getCoverForAudio:0 withDelegate:self andDoneSelector:@selector(audioCoverDone:)];
}

- (void)updateAudioPlayerNotif:(NSNotification *)n
{
    [self updateAudioPlayer];
}

- (void)initCell
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    //Audio notifications
    [nc addObserver:self
		   selector:@selector(updateAudioPlayerNotif:)
			   name:CalaosNotificationAudioVolumeChanged
			 object:nil];
    [nc addObserver:self
		   selector:@selector(updateAudioPlayerNotif:)
			   name:CalaosNotificationAudioStatusChanged
			 object:nil];
    [nc addObserver:self
		   selector:@selector(updateAudioPlayerNotif:)
			   name:CalaosNotificationAudioPlayerChanged
			 object:nil];
}

- (void)updateWithPlayer:(NSInteger)thePlayer
{
	player_id = thePlayer;
    
    [self updateAudioPlayer];
}

- (IBAction)moreClick:(id) sender
{
	if (delegate != nil && [delegate respondsToSelector:@selector(wantsMore:)])
		[delegate wantsMore:player_id];
}

- (IBAction)buttonPrevious:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"previous"];
}

- (IBAction)buttonPlay:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"play"];
}

- (IBAction)buttonStop:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"pause"];
}

- (IBAction)buttonNext:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"next"];
}

- (IBAction)volumeChanged:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:[NSString stringWithFormat:@"volume %d", (int)(sliderVolume.value * 100.0)]];
}


@end
