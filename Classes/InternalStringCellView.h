//
//  InternalStringCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface InternalStringCellView : UITableViewCell 
{
    NSString *output_id;
    
    UILabel *label;
    UIButton *buttonEdit;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIButton *buttonEdit;

- (IBAction)buttonEdit:(id) sender;

- (void)initCell;

- (void)updateWithId:(NSString *)id;

@end
