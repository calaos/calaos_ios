//
//  TrackCellView.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "TrackCellView.h"
#import "CalaosRequest.h"

@implementation TrackCellView

@synthesize labelName, viewLoad, viewNormal, loader;

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
    
    [super dealloc];
}

- (void)doneLoadTrack:(NSString *)title
{
    if (title)
    {
        viewLoad.hidden = YES;
        viewNormal.hidden = NO;
        [loader stopAnimating];
        
        labelName.text = title;
    }
    else
    {
        NSLog(@"Failed to load track: #%d for player %d", track_id, player_id);
    }
}

- (void)updateEvent:(NSNotification *)notif
{
    NSDictionary *userData = [notif userInfo];
    
    if ([[userData objectForKey:@"player_id"] integerValue] != player_id)
        return; //drop event, not for us
    
    if ([[userData objectForKey:@"track_id"] integerValue] != track_id)
        return; //drop event, not for us    
    
    if ([userData objectForKey:@"title"])
        [self doneLoadTrack:[userData objectForKey:@"title"]];
}

- (void)initCell
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(updateEvent:)
               name:CalaosNotificationAudioPlaylistItemUpdated
             object:nil];
}

- (void)updateWithTrack:(NSInteger)trackId andPlayer:(NSInteger)playerId
{
	player_id = playerId;
    track_id = trackId;
    
    viewLoad.hidden = NO;
    viewNormal.hidden = YES;
    [loader startAnimating];
    
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    NSString *title = [calaos getPlaylistTrackTitle:track_id forPlayer:player_id];
    
    if (title)
    {
        [self doneLoadTrack:title];
    }
}

- (void)buttonPlay:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:[NSString stringWithFormat:@"%d", player_id] andValue:[NSString stringWithFormat:@"playlist %d play", track_id]];
}

@end
