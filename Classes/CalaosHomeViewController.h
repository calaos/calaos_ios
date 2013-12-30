//
//  CalaosHomeViewController.h
//  CalaosHome
//
//  Created by calaos on 28/12/10.
//  Copyright 2010 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsTableViewController.h"
#import "CamerasTableViewController.h"
#import "MusicTableViewController.h"
#import "HomeTableViewController.h"
#import "CellLoader.h"
#import "ASIHTTPRequest.h"

@class KeychainItemWrapper;
@class MBProgressHUD;

@interface CalaosHomeViewController : UIViewController 
							<SettingsTableViewControllerDelegate,
							 CamerasTableViewControllerDelegate,
							 MusicTableViewControllerDelegate,
							 HomeTableViewControllerDelegate,
							 UITableViewDelegate, UITableViewDataSource> 
{
	CellLoader *cellLoader;
	
	UITableView *homeTableView;
	
	KeychainItemWrapper *passwordItem;
	
	MBProgressHUD *LoadingHUD;
    
    UIImageView *camera;
    
    ASIHTTPRequest *cameraRequest;
    BOOL cameraInProgress;
    BOOL cameraRun;
    
    UILabel *labelCamera;
    
    UILabel *audioArtist;
    UILabel *audioTitle;
    UIButton *audioBtPlay;
    UIButton *audioBtStop;
    UIImageView *audioCover;
    UISlider *audioVolume;
}

@property (nonatomic, retain) IBOutlet UITableView *homeTableView;
@property (nonatomic, retain) KeychainItemWrapper *passwordItem;
@property (nonatomic, retain) IBOutlet UIImageView *camera;
@property (nonatomic, retain) IBOutlet UILabel *labelCamera;

@property (nonatomic, retain) IBOutlet UIButton *audioBtStop;
@property (nonatomic, retain) IBOutlet UIButton *audioBtPlay;
@property (nonatomic, retain) IBOutlet UILabel *audioArtist;
@property (nonatomic, retain) IBOutlet UILabel *audioTitle;
@property (nonatomic, retain) IBOutlet UIImageView *audioCover;
@property (nonatomic, retain) IBOutlet UISlider *audioVolume;

- (IBAction)settingClick:(id) sender;
- (IBAction)camerasClick:(id) sender;
- (IBAction)musicClick:(id) sender;
- (IBAction)homeClick:(id) sender;

//Audio button
- (IBAction)audioPrevious:(id)sender;
- (IBAction)audioPlay:(id)sender;
- (IBAction)audioStop:(id)sender;
- (IBAction)audioNext:(id)sender;
- (IBAction)volumeSliderMoved:(id) sender;

- (void)startCameraViewer;
- (void)stopCameraViewer;
- (void)updateCameraViewer;

- (void)updateAudioPlayer;

@end

