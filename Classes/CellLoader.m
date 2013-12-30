//
//  CellLoader.m
//  CalaosHome
//
//  Created by calaos on 02/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "CellLoader.h"


@implementation CellLoader

@synthesize cell;

- (BOOL)loadNibFile:(NSString *)nibName
{
	if ([[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil] == nil)
	{
		NSLog(@"Error! Could not load %@ file.", nibName);
		return NO;
	}
	
	return YES;
}

- (void)dealloc
{
    [cell release];

	[super dealloc];
}

@end
