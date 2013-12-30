//
//  ShutterSmartCellView.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "ShutterSmartCellView.h"
#import "CalaosRequest.h"

@implementation ShutterSmartCellView

@synthesize label, labelStatus, labelStatus2, icon, imageShutter;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) 
    {
        closed_rect = imageShutter.frame;
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
    self.labelStatus = nil;
    self.labelStatus2 = nil;
    self.icon = nil;
    self.imageShutter = nil;
    
    [super dealloc];
}

- (void)updateState:(NSString *)stateString
{
    NSString *status;
    int percent;
    
    NSArray *tokens = [stateString componentsSeparatedByString: @" "];

    if ([tokens count] < 1)
    {
        NSLog(@"WOVoletSmart: updateState, stateString error !");
        return;
    }
    
    status = [tokens objectAtIndex:0];
    if ([tokens count] > 1)
        percent = (int)[[tokens objectAtIndex:1] doubleValue];
    
    if (percent < 100)
    {
        icon.image = [UIImage imageNamed: @"icon_shutter_on.png"];
    }
    else
    {
        icon.image = [UIImage imageNamed: @"icon_shutter_off.png"];
    }
    
    if (percent == 0)
    {
        labelStatus2.text = @"Etat : Ouvert.";
    }
    else if (percent > 0 && percent < 50)
    {
        labelStatus2.text = [NSString stringWithFormat:@"Etat : Ouvert à %d%%.", percent];
    }
    else if (percent >= 50 && percent < 100)
    {
        labelStatus2.text = [NSString stringWithFormat:@"Etat : Fermé à %d%%.", percent];
    }
    
    if (percent == 100)
    {
        labelStatus2.text = @"Etat : Fermé.";
    }
    
    if (closed_rect.origin.y == 0 && closed_rect.origin.x == 0 &&
        closed_rect.size.width == 0 && closed_rect.size.height == 0)
        closed_rect = imageShutter.frame;

    CGRect newpos = closed_rect;
    newpos.origin.y -= (48 * [[UIScreen mainScreen] scale]) * (100 - percent) / 100;
    
    imageShutter.frame = newpos;
    
    if ([status isEqualToString:@"stop"] || [status isEqualToString:@""])
    {
        labelStatus.text = @"Action : Arreté.";
    }
    else if ([status isEqualToString:@"down"])
    {
        labelStatus.text = @"Action : Fermeture.";
    }
    else if ([status isEqualToString:@"up"])
    {
        labelStatus.text = @"Action : Ouverture.";
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
    
    [self updateState:[[[calaos getOutputs] objectForKey:output_id] objectForKey:@"state"]];
}

- (IBAction)buttonUp:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"output" withId:output_id andValue:@"up"];
}

- (IBAction)buttonDown:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"output" withId:output_id andValue:@"down"];
}

- (IBAction)buttonStop:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"output" withId:output_id andValue:@"stop"];
}

@end
