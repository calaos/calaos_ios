//
//  ShutterCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ShutterCellView : UITableViewCell 
{
    NSString *output_id;
    
    UILabel *label;
    UIImageView *icon;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIImageView *icon;

- (IBAction)buttonUp:(id) sender;
- (IBAction)buttonDown:(id) sender;
- (IBAction)buttonStop:(id) sender;

- (void)initCell;

- (void)updateWithId:(NSString *)id;

@end
