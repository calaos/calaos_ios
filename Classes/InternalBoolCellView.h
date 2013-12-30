//
//  InternalBoolCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface InternalBoolCellView : UITableViewCell 
{
    NSString *output_id;
    
    UILabel *label;
    UIImageView *icon;
    UIButton *buttonOn;
    UIButton *buttonOff;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIImageView *icon;
@property (nonatomic, retain) IBOutlet UIButton *buttonOn;
@property (nonatomic, retain) IBOutlet UIButton *buttonOff;

- (IBAction)buttonOn:(id) sender;
- (IBAction)buttonOff:(id) sender;

- (void)initCell;

- (void)updateWithId:(NSString *)id;

@end
