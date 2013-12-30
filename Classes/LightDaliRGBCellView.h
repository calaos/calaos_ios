//
//  LightDaliRGBCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LightDaliRGBCellView : UITableViewCell 
{
    NSString *output_id;
    
    IBOutlet UILabel *label;
    IBOutlet UILabel *text_red;
    IBOutlet UILabel *text_green;
    IBOutlet UILabel *text_blue;
    IBOutlet UIImageView *icon;
    IBOutlet UIImageView *icon_color;
    IBOutlet UISlider *slider_red;
    IBOutlet UISlider *slider_green;
    IBOutlet UISlider *slider_blue;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIImageView *icon;
@property (nonatomic, retain) IBOutlet UILabel *text_red;
@property (nonatomic, retain) IBOutlet UILabel *text_green;
@property (nonatomic, retain) IBOutlet UILabel *text_blue;
@property (nonatomic, retain) IBOutlet UIImageView *icon_color;
@property (nonatomic, retain) IBOutlet UISlider *slider_red;
@property (nonatomic, retain) IBOutlet UISlider *slider_green;
@property (nonatomic, retain) IBOutlet UISlider *slider_blue;

- (IBAction)buttonOn:(id) sender;
- (IBAction)buttonOff:(id) sender;
- (IBAction) sliderRedChange:(id) sender;
- (IBAction) sliderGreenChange:(id) sender;
- (IBAction) sliderBlueChange:(id) sender;

- (void)initCell;

- (void)updateWithId:(NSString *)id;

@end
