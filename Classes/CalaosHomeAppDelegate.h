//
//  CalaosHomeAppDelegate.h
//  CalaosHome
//
//  Created by calaos on 28/12/10.
//  Copyright 2010 Calaos. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CalaosHomeViewController;
@class KeychainItemWrapper;

@interface CalaosHomeAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow *window;
    CalaosHomeViewController *viewController;
	
	KeychainItemWrapper *passwordItem;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet CalaosHomeViewController *viewController;
@property (nonatomic, retain) KeychainItemWrapper *passwordItem;

@end

