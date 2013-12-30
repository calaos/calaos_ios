//
//  HomeScenarioCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HomeScenarioCellView : UITableViewCell 
{
    NSString *input_id;
    
    UILabel *label;
    UIImageView *icon;
    
    UIButton *play;
    UIButton *stop;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIImageView *icon;
@property (nonatomic, retain) IBOutlet UIButton *play;
@property (nonatomic, retain) IBOutlet UIButton *stop;

- (IBAction)buttonRun:(id) sender;
- (IBAction)buttonStop:(id) sender;

- (void)initCell;

- (void)updateWithId:(NSString *)id;

@end
