//
//  SettingsTableViewController.h
//  CalaosHome
//
//  Created by calaos on 29/12/10.
//  Copyright 2010 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KeychainItemWrapper;
@class MBProgressHUD;

@interface SettingsTableViewController : UITableViewController <UITextFieldDelegate,
																UIActionSheetDelegate>
{
	id delegate;
	
	UIView *headerView;
	UITableViewCell *emailCell, *passCell;
	
	UITextField *emailField, *passField;
	
	KeychainItemWrapper *passwordItem;
	
	MBProgressHUD *LoadingHUD;
	
	BOOL connectionInProgress;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) IBOutlet UIView *headerView;
@property (nonatomic, retain) IBOutlet UITableViewCell *emailCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *passCell;
@property (nonatomic, retain) IBOutlet UITextField *emailField;
@property (nonatomic, retain) IBOutlet UITextField *passField;
@property (nonatomic, retain) KeychainItemWrapper *passwordItem;

@end


@protocol SettingsTableViewControllerDelegate
- (void)settingsViewDidFinish: (SettingsTableViewController *)controller;
@end