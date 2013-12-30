//
//  InternalBoolCellView.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "InternalBoolCellView.h"
#import "CalaosRequest.h"

@implementation InternalBoolCellView

@synthesize label, icon, buttonOn, buttonOff;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}


- (void)dealloc 
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    
    self.label = nil;
    self.icon = nil;
    self.buttonOn = nil;
    self.buttonOff = nil;
    
    [super dealloc];
}

- (void)updateState:(NSString *)stateString
{
    BOOL state = FALSE;
    
    if ([stateString isEqualToString:@"true"])
    {
        state = TRUE;
    }
    else if ([stateString isEqualToString:@"false"])
    {
        state = FALSE;
    }
    else
    {
        double value = [stateString doubleValue];
        if (value > 0)
            state = TRUE;
        else
            state = FALSE;
    }
    
    if (state)
    {
        icon.image = [UIImage imageNamed: @"icon_bool_on.png"];
        label.textColor = [UIColor colorWithRed:1.0 green:217.0/255.0 blue:78.0/255.0 alpha:1.0];
    }
    else
    {
        icon.image = [UIImage imageNamed: @"icon_bool_off.png"];
        label.textColor = [UIColor colorWithRed:231.0/255.0 green:231.0/255.0 blue:231.0/255.0 alpha:1.0];
    }
}

- (void)updateEvent:(NSNotification *)notif
{
    NSDictionary *userData = [notif userInfo];
    
    if (![[userData objectForKey:@"id"] isEqualToString:output_id])
        return; //drop event, not for us
    
    NSArray *tokens = [[userData objectForKey:@"change"] componentsSeparatedByString: @":"];
    if ([tokens count] < 2)
        return;
    
    if ([[tokens objectAtIndex:0] isEqualToString:@"name"])
    {
        label.text = [tokens objectAtIndex:1];
    }
    else if ([[tokens objectAtIndex:0] isEqualToString:@"state"])
    {
        [self updateState:[tokens objectAtIndex:1]];
    }
}

- (void)initCell
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(updateEvent:)
               name:CalaosNotificationIOChanged
             object:nil];
}

- (void)updateWithId:(NSString *)id
{ 
	output_id = [NSString stringWithString:id];
    
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    label.text = [[[calaos getOutputs] objectForKey:output_id] objectForKey:@"name"];
    
    if ([[[[calaos getOutputs] objectForKey:output_id] objectForKey:@"rw"] isEqualToString:@"true"])
    {
        buttonOn.hidden = NO;
        buttonOff.hidden = NO;
    }
    else
    {
        buttonOn.hidden = YES;
        buttonOff.hidden = YES;
    }
    
    [self updateState:[[[calaos getOutputs] objectForKey:output_id] objectForKey:@"state"]];
}

- (IBAction)buttonOn:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"output" withId:output_id andValue:@"true"];
}

- (IBAction)buttonOff:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"output" withId:output_id andValue:@"false"];
}

@end