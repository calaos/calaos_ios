//
//  LightDaliRGBCellView.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "LightDaliRGBCellView.h"
#import "CalaosRequest.h"

@implementation LightDaliRGBCellView

@synthesize label, text_blue, text_red, text_green, icon, icon_color, slider_red, slider_blue, slider_green;

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
    self.text_blue = nil;
    self.text_green = nil;
    self.text_red = nil;
    self.icon_color = nil;
    self.slider_red = nil;
    self.slider_green = nil;
    self.slider_blue = nil;
    
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
        icon.image = [UIImage imageNamed: @"icon_light_on.png"];
        label.textColor = [UIColor colorWithRed:1.0 green:217.0/255.0 blue:78.0/255.0 alpha:1.0];
    }
    else
    {
        icon.image = [UIImage imageNamed: @"icon_light_off.png"];
        label.textColor = [UIColor colorWithRed:231.0/255.0 green:231.0/255.0 blue:231.0/255.0 alpha:1.0];
    }
    
    
    
    int val = (int)[stateString doubleValue];
    
    int _red = ((val >> 16) * 100) / 255;
    int _green = (((val >> 8) & 0x0000FF) * 100) / 255;
    int _blue = ((val & 0x0000FF) * 100) / 255;
    
    text_red.text = [NSString stringWithFormat:@"%d%%", _red];
    text_green.text = [NSString stringWithFormat:@"%d%%", _green];
    text_blue.text = [NSString stringWithFormat:@"%d%%", _blue];
    
    slider_red.value = (double)_red / 100.0;
    slider_green.value = (double)_green / 100.0;
    slider_blue.value = (double)_blue / 100.0;
    
    icon_color.backgroundColor = [UIColor colorWithRed:_red/255.0 green:_green/255.0 blue:_blue/255.0 alpha:1.0];
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

- (IBAction)sliderRedChange:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    int val = (int)[[[[calaos getOutputs] objectForKey:output_id] objectForKey:@"state"] doubleValue];
    
    int _red = slider_red.value * 100.0;
    int _green = (((val >> 8) & 0x0000FF) * 100) / 255;
    int _blue = ((val & 0x0000FF) * 100) / 255;
    
    val = (((int)(_red * 255 / 100)) << 16)
    + (((int)(_green * 255 / 100)) << 8)
    + _blue * 255 / 100;
    
    [calaos sendAction:@"output" withId:output_id andValue:[NSString stringWithFormat:@"set %d", (int)val]];
}

- (IBAction)sliderGreenChange:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    int val = (int)[[[[calaos getOutputs] objectForKey:output_id] objectForKey:@"state"] doubleValue];
    
    int _red = ((val >> 16) * 100) / 255;
    int _green = slider_green.value * 100.0;
    int _blue = ((val & 0x0000FF) * 100) / 255;
    
    val = (((int)(_red * 255 / 100)) << 16)
    + (((int)(_green * 255 / 100)) << 8)
    + _blue * 255 / 100;
    
    [calaos sendAction:@"output" withId:output_id andValue:[NSString stringWithFormat:@"set %d", (int)val]];
}

- (IBAction)sliderBlueChange:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    int val = (int)[[[[calaos getOutputs] objectForKey:output_id] objectForKey:@"state"] doubleValue];
    
    int _red = ((val >> 16) * 100) / 255;
    int _green = (((val >> 8) & 0x0000FF) * 100) / 255;
    int _blue = slider_blue.value * 100.0;
    
    val = (((int)(_red * 255 / 100)) << 16)
    + (((int)(_green * 255 / 100)) << 8)
    + _blue * 255 / 100;

    [calaos sendAction:@"output" withId:output_id andValue:[NSString stringWithFormat:@"set %d", (int)val]];
}

@end
