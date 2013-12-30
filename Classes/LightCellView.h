//
//  LightCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LightCellView : UITableViewCell 
{
    NSString *output_id;
    
    UIImageView *icon;
    UILabel *label;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIImageView *icon;

- (IBAction)buttonOn:(id) sender;
- (IBAction)buttonOff:(id) sender;

- (void)initCell;

- (void)updateWithId:(NSString *)id;

@end
