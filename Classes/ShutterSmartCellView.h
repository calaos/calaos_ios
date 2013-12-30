//
//  ShutterSmartCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ShutterSmartCellView : UITableViewCell 
{
    NSString *output_id;
    
    UILabel *label;
    UILabel *labelStatus;
    UILabel *labelStatus2;
    UIImageView *icon;
    UIImageView *imageShutter;
    
    CGRect closed_rect;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UILabel *labelStatus;
@property (nonatomic, retain) IBOutlet UILabel *labelStatus2;
@property (nonatomic, retain) IBOutlet UIImageView *icon;
@property (nonatomic, retain) IBOutlet UIImageView *imageShutter;

- (IBAction)buttonUp:(id) sender;
- (IBAction)buttonDown:(id) sender;
- (IBAction)buttonStop:(id) sender;

- (void)initCell;

- (void)updateWithId:(NSString *)id;

@end
