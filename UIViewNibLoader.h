//
//  UIViewNibLoader.h
//  CalaosHome
//
//  Created by Raoul on 29/04/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIViewNibLoader : NSObject 
{
    UIView *view;
}

@property (nonatomic, retain) IBOutlet UIView *view;

- (BOOL)loadNibFile:(NSString *)nibName;

@end
