//
//  MusicTableViewController.h
//  CalaosHome
//
//  Created by calaos on 03/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CellLoader.h"
#import "MusicCellView.h"

@interface MusicTableViewController : UITableViewController <MusicCellViewDelegate>
{
	id delegate;
	
	CellLoader *cellLoader;
}

@property (nonatomic, assign) id delegate;

@end

@protocol MusicTableViewControllerDelegate
- (void)musicViewDidFinish: (MusicTableViewController *)controller;
@end