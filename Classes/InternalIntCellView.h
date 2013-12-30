//
//  InternalIntCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface InternalIntCellView : UITableViewCell 
{
    NSString *output_id;
    
    UILabel *label;
    UILabel *labelValue;
    UIImageView *icon;
    UIButton *buttonPlus;
    UIButton *buttonMin;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UILabel *labelValue;
@property (nonatomic, retain) IBOutlet UIImageView *icon;
@property (nonatomic, retain) IBOutlet UIButton *buttonPlus;
@property (nonatomic, retain) IBOutlet UIButton *buttonMin;

- (IBAction)buttonPlus:(id) sender;
- (IBAction)buttonMin:(id) sender;

- (void)initCell;

- (void)updateWithId:(NSString *)id;

@end
