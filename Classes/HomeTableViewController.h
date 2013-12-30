//
//  HomeTableViewController.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellLoader.h"
#import "RoomCellView.h"

@interface HomeTableViewController : UITableViewController <RoomCellViewDelegate>
{
	id delegate;
	
	CellLoader *cellLoader;
}

@property (nonatomic, assign) id delegate;

@end

@protocol HomeTableViewControllerDelegate
- (void)homeViewDidFinish: (HomeTableViewController *)controller;
@end
