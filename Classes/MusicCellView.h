//
//  MusicCellView.h
//  CalaosHome
//
//  Created by calaos on 03/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MusicCellView : UITableViewCell 
{
	id delegate;
    
    UILabel *playerName;
    UIImageView *playerCover;
    UILabel *songTitle;
    UILabel *songArtist;
    UIButton *buttonPlay;
    UIButton *buttonStop;
    UISlider *sliderVolume;
    
    NSInteger player_id;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) IBOutlet UILabel *playerName;
@property (nonatomic, retain) IBOutlet UIImageView *playerCover;
@property (nonatomic, retain) IBOutlet UILabel *songTitle;
@property (nonatomic, retain) IBOutlet UILabel *songArtist;
@property (nonatomic, retain) IBOutlet UIButton *buttonPlay;
@property (nonatomic, retain) IBOutlet UIButton *buttonStop;
@property (nonatomic, retain) IBOutlet UISlider *sliderVolume;

- (void)initCell;
- (void)updateWithPlayer:(NSInteger)thePlayer;

- (IBAction)moreClick:(id) sender;
- (IBAction)buttonPrevious:(id) sender;
- (IBAction)buttonPlay:(id) sender;
- (IBAction)buttonStop:(id) sender;
- (IBAction)buttonNext:(id) sender;
- (IBAction)volumeChanged:(id) sender;

@end


@protocol MusicCellViewDelegate
- (void)wantsMore:(NSInteger)player_id;
@end