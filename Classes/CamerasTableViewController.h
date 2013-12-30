//
//  CamerasTableViewController.h
//  CalaosHome
//
//  Created by calaos on 30/12/10.
//  Copyright 2010 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellLoader.h"

@interface CamerasTableViewController : UITableViewController 
{
	id delegate;
	
	CellLoader *cellLoader;
}

@property (nonatomic, assign) id delegate;

@end


@protocol CamerasTableViewControllerDelegate
- (void)camerasViewDidFinish: (CamerasTableViewController *)controller;
@end