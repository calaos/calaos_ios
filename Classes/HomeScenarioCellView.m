//
//  HomeScenarioCellView.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "HomeScenarioCellView.h"
#import "CalaosRequest.h"

@implementation HomeScenarioCellView

@synthesize label, icon, play, stop;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {
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
    self.play = nil;
    self.stop = nil;
    
    [super dealloc];
}

- (void)updateState:(NSString *)stateString
{   
    if ([stateString isEqualToString:@"true"])
    {
//        label.textColor = [UIColor colorWithRed:1.0 green:217.0/255.0 blue:78.0/255.0 alpha:1.0];
        label.textColor = [UIColor colorWithRed:231.0/255.0 green:231.0/255.0 blue:231.0/255.0 alpha:1.0];
        play.hidden = YES;
        stop.hidden = NO;
    }
    else if ([stateString isEqualToString:@"false"])
    {
        label.textColor = [UIColor colorWithRed:231.0/255.0 green:231.0/255.0 blue:231.0/255.0 alpha:1.0];
        play.hidden = NO;
        stop.hidden = YES;

    }
}

- (void)updateEvent:(NSNotification *)notif
{
    NSDictionary *userData = [notif userInfo];
    
    NSLog(@"event for : %@", [userData objectForKey:@"id"]);
    
    if (![[userData objectForKey:@"id"] isEqualToString:input_id])
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

- (void) updateWithId:(NSString *)id
{
	input_id = [NSString stringWithString:id];
    
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    label.text = [[[calaos getOutputs] objectForKey:input_id] objectForKey:@"name"];
    
    [self updateState:[[[calaos getOutputs] objectForKey:input_id] objectForKey:@"state"]];
}

- (IBAction)buttonRun:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"output" withId:input_id andValue:@"true"];
}

- (IBAction)buttonStop:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"output" withId:input_id andValue:@"true"];
}

@end
