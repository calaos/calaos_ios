//
//  InternalIntCellView.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "InternalIntCellView.h"
#import "CalaosRequest.h"

@implementation InternalIntCellView

@synthesize label, labelValue, icon, buttonMin, buttonPlus;

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
    self.labelValue = nil;
    self.icon = nil;
    self.buttonMin = nil;
    self.buttonPlus = nil;
    
    [super dealloc];
}

- (void)updateState:(NSString *)stateString
{
    labelValue.text = stateString;
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
        buttonPlus.hidden = NO;
        buttonMin.hidden = NO;
    }
    else
    {
        buttonPlus.hidden = YES;
        buttonMin.hidden = YES;
    }
    
    [self updateState:[[[calaos getOutputs] objectForKey:output_id] objectForKey:@"state"]];
}

- (IBAction)buttonPlus:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    double value = [[[[calaos getOutputs] objectForKey:output_id] objectForKey:@"state"] doubleValue];
    
    value++;
    NSString *svalue = [NSString stringWithFormat:@"%d", (int)value];
    
    [calaos sendAction:@"output" withId:output_id andValue:svalue];
}

- (IBAction)buttonMin:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    double value = [[[[calaos getOutputs] objectForKey:output_id] objectForKey:@"state"] doubleValue];
    
    value--;
    NSString *svalue = [NSString stringWithFormat:@"%d", (int)value];
    
    [calaos sendAction:@"output" withId:output_id andValue:svalue];
}

@end