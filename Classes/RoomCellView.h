//
//  RoomCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RoomCellView : UITableViewCell 
{
	id delegate;
	
	UIImageView *roomIcon;
    UILabel *labelName;
    UILabel *labelLights;
    UILabel *labelHeat;
    UIButton *buttonHeatPlus;
    UIButton *buttonHeatMin;
    UIView *viewHeat;
    UIImageView *iconLights;
    
    NSDictionary *room;
    NSMutableDictionary *lightsOn;
    int lightsOnCount;
}

@property (nonatomic, retain) IBOutlet UIImageView *roomIcon;
@property (nonatomic, retain) IBOutlet UIImageView *iconLights;
@property (nonatomic, retain) IBOutlet UIView *viewHeat;
@property (nonatomic, retain) IBOutlet UILabel *labelName;
@property (nonatomic, retain) IBOutlet UILabel *labelLights;
@property (nonatomic, retain) IBOutlet UILabel *labelHeat;
@property (nonatomic, retain) NSDictionary *room;
@property (nonatomic, assign) id delegate;

- (void)updateWithRoom:(NSDictionary *)roomDict;
- (void)initCell;

- (IBAction)moreClick:(id) sender;
- (IBAction)buttonHeatPlus:(id) sender;
- (IBAction)buttonHeatMin:(id) sender;

@end

@protocol RoomCellViewDelegate
- (void)wantsMore:(NSDictionary *)theRoom;
@end