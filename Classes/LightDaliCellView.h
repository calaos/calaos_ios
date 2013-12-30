//
//  LightDaliCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LightDaliCellView : UITableViewCell 
{
    NSString *output_id;
    
    UILabel *label;
    UIImageView *icon;
    UISlider *slider;
    UILabel *labelPercent;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UILabel *labelPercent;
@property (nonatomic, retain) IBOutlet UIImageView *icon;
@property (nonatomic, retain) IBOutlet UISlider *slider;

- (IBAction)buttonOn:(id) sender;
- (IBAction)buttonOff:(id) sender;
- (IBAction)sliderMoved:(id) sender;

- (void)initCell;

- (void)updateWithId:(NSString *)id;

@end
