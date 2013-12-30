//
//  RoomViewController.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellLoader.h"

@interface RoomViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	UITableView *elementTableView;
	
	CellLoader *cellLoader;
    
    UILabel *labelName;
    UIImageView *iconRoom;
    
    NSDictionary *room;
    
    NSMutableArray *cacheItems;
}

@property (nonatomic, retain) IBOutlet UITableView *elementTableView;
@property (nonatomic, retain) IBOutlet UILabel *labelName;
@property (nonatomic, retain) IBOutlet UIImageView *iconRoom;

- (void)setRoom:(NSDictionary *)theRoom;

@end
