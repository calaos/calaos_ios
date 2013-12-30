//
//  CameraCellView.h
//  CalaosHome
//
//  Created by calaos on 01/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZoomingViewController.h"

@interface CameraCellView : UITableViewCell 
{
	ZoomingViewController *zoomingViewController;
	
	UIView *zoomingView;
    UIButton *buttonUp;
    UIButton *buttonDown;
    UIButton *buttonLeft;
    UIButton *buttonRight;
    UIButton *buttonZoomIn;
    UIButton *buttonZoomOut;
    UILabel *cameraName;
    UIImageView *cameraView;

    NSInteger camera_id;
    
    BOOL cameraInProgress;
}

@property (nonatomic, retain) IBOutlet UIView *zoomingView;
@property (nonatomic, retain) IBOutlet UIButton *buttonUp;
@property (nonatomic, retain) IBOutlet UIButton *buttonDown;
@property (nonatomic, retain) IBOutlet UIButton *buttonLeft;
@property (nonatomic, retain) IBOutlet UIButton *buttonRight;
@property (nonatomic, retain) IBOutlet UIButton *buttonZoomIn;
@property (nonatomic, retain) IBOutlet UIButton *buttonZoomOut;
@property (nonatomic, retain) IBOutlet UILabel *cameraName;
@property (nonatomic, retain) IBOutlet UIImageView *cameraView;

- (void)initCell;
- (void)updateWithCamera:(NSInteger)cam;

- (void)startCameraViewer;

@end
