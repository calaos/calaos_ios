//
//  TempCellView.h
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TempCellView : UITableViewCell 
{
    NSString *input_id;
    NSString *consigne_id;
    
    UILabel *label;
    UILabel *labelTemp;
    UILabel *labelConsigne;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UILabel *labelTemp;
@property (nonatomic, retain) IBOutlet UILabel *labelConsigne;

- (void)initCell;

- (void)updateWithId:(NSString *)id;

@end
