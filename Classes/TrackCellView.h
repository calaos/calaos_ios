//
//  TrackCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TrackCellView : UITableViewCell 
{
    NSInteger track_id, player_id;
    
    UILabel *labelName;
    UIView *viewLoad;
    UIView *viewNormal;
    UIActivityIndicatorView *loader;
}

@property (nonatomic, retain) IBOutlet UILabel *labelName;
@property (nonatomic, retain) IBOutlet UIView *viewLoad;
@property (nonatomic, retain) IBOutlet UIView *viewNormal;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loader;

- (void)initCell;
- (void) updateWithTrack:(NSInteger)trackId andPlayer:(NSInteger)playerId;

- (IBAction)buttonPlay:(id) sender;

@end
