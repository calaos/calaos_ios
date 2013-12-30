//
//  CameraCellView.m
//  CalaosHome
//
//  Created by calaos on 01/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "CameraCellView.h"
#import "CalaosRequest.h"
#import "UIImageAdditions.h"

@implementation CameraCellView

@synthesize zoomingView, buttonUp, buttonDown, buttonLeft, buttonRight, buttonZoomIn, buttonZoomOut, cameraName, cameraView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{	
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}

- (void)cameraPictureDone:(NSData *)pictureData
{
    cameraInProgress = NO;
    
    if (!pictureData)
    {
        NSLog(@"Failed to get camera picture");
    }
    else
    {
        self.cameraView.image = [[UIImage imageWithData:pictureData] imageByScalingAndCroppingForSize:self.cameraView.frame.size];
    }
    
    [self startCameraViewer];
}

- (void)startCameraViewer
{
    if (cameraInProgress)
        return;
    
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos getPictureForCamera:camera_id withDelegate:self andDoneSelector:@selector(cameraPictureDone:)];
    
    cameraInProgress = YES;
}

- (void)initCell
{
    zoomingViewController = [[ZoomingViewController alloc] init];
	zoomingViewController.view = zoomingView;
}

- (void)updateWithCamera:(NSInteger)cam
{
    camera_id = cam;
    
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
	NSDictionary *camera = [[calaos getCameras] objectAtIndex:camera_id];
    
    cameraName.text = [camera objectForKey:@"name"];
    
    if ([[camera objectForKey:@"ptz"] isEqualToString:@"true"])
    {
        buttonDown.hidden = NO;
        buttonUp.hidden = NO;
        buttonLeft.hidden = NO;
        buttonRight.hidden = NO;
        buttonZoomIn.hidden = NO;
        buttonZoomOut.hidden = NO;        
    }
    else
    {
        buttonDown.hidden = YES;
        buttonUp.hidden = YES;
        buttonLeft.hidden = YES;
        buttonRight.hidden = YES;
        buttonZoomIn.hidden = YES;
        buttonZoomOut.hidden = YES;
    }
    
    [self startCameraViewer];
}

- (void)dealloc 
{
	[zoomingViewController release];
	self.zoomingView = nil;
	
    [super dealloc];
}


@end
