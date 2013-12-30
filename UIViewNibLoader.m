//
//  UIViewNibLoader.m
//  CalaosHome
//
//  Created by Raoul on 29/04/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "UIViewNibLoader.h"

@implementation UIViewNibLoader

@synthesize view;

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
    [view release];
    
	[super dealloc];
}

@end
