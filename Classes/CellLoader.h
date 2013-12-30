//
//  CellLoader.h
//  CalaosHome
//
//  Created by calaos on 02/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CellLoader : NSObject
{
	UITableViewCell *cell;
}

@property (nonatomic, retain) IBOutlet UITableViewCell *cell;

- (BOOL)loadNibFile:(NSString *)nibName;

@end
