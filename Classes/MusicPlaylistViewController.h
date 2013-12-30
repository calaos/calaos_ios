//
//  MusicPlaylistViewController.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellLoader.h"
#import "AudioOptionsViewController.h"

@interface MusicPlaylistViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	UITableView *playlistTableView;
	
	CellLoader *cellLoader;
    
    NSInteger player_id;
    
    UILabel *playerName;
    UIImageView *playerCover;
    UILabel *songTitle;
    UILabel *songArtist;
    UIButton *buttonPlay;
    UIButton *buttonStop;
    UISlider *sliderVolume;
    
    AudioOptionsViewController *audioOptionsController;
    
    UIView *animationView;
    
    NSInteger cellHeightCache;
}

@property (nonatomic, retain) IBOutlet UITableView *playlistTableView;
@property (nonatomic, retain) IBOutlet UIView *animationView;
@property (nonatomic, retain) IBOutlet UILabel *playerName;
@property (nonatomic, retain) IBOutlet UIImageView *playerCover;
@property (nonatomic, retain) IBOutlet UILabel *songTitle;
@property (nonatomic, retain) IBOutlet UILabel *songArtist;
@property (nonatomic, retain) IBOutlet UIButton *buttonPlay;
@property (nonatomic, retain) IBOutlet UIButton *buttonStop;
@property (nonatomic, retain) IBOutlet UISlider *sliderVolume;

- (void)setPlayerId:(NSInteger)thePlayer;

- (void)updateAudioPlayer;

- (IBAction)buttonPrevious:(id) sender;
- (IBAction)buttonPlay:(id) sender;
- (IBAction)buttonStop:(id) sender;
- (IBAction)buttonNext:(id) sender;
- (IBAction)volumeChanged:(id) sender;

@end
