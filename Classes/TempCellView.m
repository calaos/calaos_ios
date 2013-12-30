//
//  TempCellView.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "TempCellView.h"
#import "CalaosRequest.h"

@implementation TempCellView

@synthesize label, labelTemp, labelConsigne;

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
    self.labelTemp = nil;
    self.labelConsigne = nil;
    
    [super dealloc];
}

- (void)updateState:(NSString *)stateString
{
    labelTemp.text = [NSString stringWithFormat:@"%@ °", stateString];
}

- (void)updateConsigne
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    if (consigne_id)
    {
        labelConsigne.text = [NSString stringWithFormat:@"/ %@", [[[calaos getOutputs] objectForKey:consigne_id] objectForKey:@"state"]];
    }
    else
    {
        labelConsigne.text = @"";
    }
}

- (void)updateEvent:(NSNotification *)notif
{
    NSDictionary *userData = [notif userInfo];
    
    if (![[userData objectForKey:@"id"] isEqualToString:input_id] &&
        ![[userData objectForKey:@"id"] isEqualToString:consigne_id])
        return; //drop event, not for us
    
    NSArray *tokens = [[userData objectForKey:@"change"] componentsSeparatedByString: @":"];
    if ([tokens count] < 2)
        return;
    
    if ([[tokens objectAtIndex:0] isEqualToString:@"name"] &&
        [[userData objectForKey:@"id"] isEqualToString:input_id])
    {
        label.text = [tokens objectAtIndex:1];
    }
    else if ([[tokens objectAtIndex:0] isEqualToString:@"state"])
    {
        if ([[userData objectForKey:@"id"] isEqualToString:input_id])
            [self updateState:[tokens objectAtIndex:1]];
        else
            [self updateConsigne];
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
	input_id = [NSString stringWithString:id];
    
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    label.text = [[[calaos getInputs] objectForKey:input_id] objectForKey:@"name"];
    
    consigne_id = [calaos getConsigneForInput:input_id];

    [self updateState:[[[calaos getInputs] objectForKey:input_id] objectForKey:@"state"]];
    
    [self updateConsigne];
}

@end
