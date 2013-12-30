//
//  RoomCellView.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "RoomCellView.h"
#import "CalaosRequest.h"

@implementation RoomCellView

@synthesize delegate, roomIcon, labelName, labelLights, labelHeat, viewHeat, room, iconLights;

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
	[roomIcon release];
	roomIcon = nil;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    
    [lightsOn release];
    lightsOn = nil;
    
    self.roomIcon = nil;
    self.iconLights = nil;
    self.viewHeat = nil;
    self.labelName = nil;
    self.labelLights = nil;
    self.labelHeat = nil;
    self.room = nil;
	
    [super dealloc];
}

- (IBAction)moreClick:(id) sender
{
	if (delegate != nil && [delegate respondsToSelector:@selector(wantsMore:)])
		[delegate wantsMore:room];
}

- (IBAction)buttonHeatPlus:(id)sender
{
}

- (IBAction)buttonHeatMin:(id)sender
{
}

- (void)updateLightsOn
{
    if (lightsOnCount == 0)
    {
        self.labelLights.text = @"Aucune allumée";
        iconLights.image = [UIImage imageNamed: @"icon_light_off.png"];
    }
    else if (lightsOnCount == 1)
    {
        self.labelLights.text = [NSString stringWithFormat:@"%d lumière allumée", lightsOnCount];
        iconLights.image = [UIImage imageNamed: @"icon_light_on.png"];
    }
    else
    {
        self.labelLights.text = [NSString stringWithFormat:@"%d lumières allumées", lightsOnCount];
        iconLights.image = [UIImage imageNamed: @"icon_light_on.png"];
    }
}

- (void)updateState
{
    self.labelName.text = [room objectForKey:@"name"];
    
    NSString *icon_file;
    
    if ([[room objectForKey:@"type"] isEqualToString:@"bathroom"] ||
        [[room objectForKey:@"type"] isEqualToString:@"sdb"])
        icon_file = @"bathroom";
    else if ([[room objectForKey:@"type"] isEqualToString:@"bedroom"] ||
             [[room objectForKey:@"type"] isEqualToString:@"chambre"])
        icon_file = @"bedroom";
    else if ([[room objectForKey:@"type"] isEqualToString:@"cellar"] ||
             [[room objectForKey:@"type"] isEqualToString:@"cave"])
        icon_file = @"cellar";
    else if ([[room objectForKey:@"type"] isEqualToString:@"corridor"] ||
             [[room objectForKey:@"type"] isEqualToString:@"hall"] ||
             [[room objectForKey:@"type"] isEqualToString:@"couloir"])
        icon_file = @"corridor";
    else if ([[room objectForKey:@"type"] isEqualToString:@"diningroom"] ||
             [[room objectForKey:@"type"] isEqualToString:@"sam"])
        icon_file = @"diningroom";
    else if ([[room objectForKey:@"type"] isEqualToString:@"garage"])
        icon_file = @"garage";
    else if ([[room objectForKey:@"type"] isEqualToString:@"kitchen"] ||
             [[room objectForKey:@"type"] isEqualToString:@"cuisine"])
        icon_file = @"kitchen";
    else if ([[room objectForKey:@"type"] isEqualToString:@"lounge"] ||
             [[room objectForKey:@"type"] isEqualToString:@"salon"])
        icon_file = @"lounge";
    else if ([[room objectForKey:@"type"] isEqualToString:@"office"] ||
             [[room objectForKey:@"type"] isEqualToString:@"bureau"])
        icon_file = @"office";
    else if ([[room objectForKey:@"type"] isEqualToString:@"outside"] ||
             [[room objectForKey:@"type"] isEqualToString:@"exterieur"])
        icon_file = @"outside";
    else
        icon_file = @"various";
        
    self.roomIcon.image = [UIImage imageNamed: icon_file];

    [self updateLightsOn];
    
    self.viewHeat.hidden = YES; //TODO
}

- (void)updateEvent:(NSNotification *)notif
{
    NSDictionary *userData = [notif userInfo];
    
    if ([userData objectForKey:@"old_room_name"])
    {
        //update room name
        
        if (![[userData objectForKey:@"old_room_name"] isEqualToString:[room objectForKey:@"name"]])
            return; //not for us
        if (![[userData objectForKey:@"room_type"] isEqualToString:[room objectForKey:@"type"]])
            return; //not for us
        
        [room setValue:[userData objectForKey:@"new_room_name"] forKey:@"name"];
        
        [self updateState];
    }
    else if ([userData objectForKey:@"old_room_type"])
    {
        //update room type
        
        if (![[userData objectForKey:@"old_room_type"] isEqualToString:[room objectForKey:@"type"]])
            return; //not for us
        if (![[userData objectForKey:@"room_name"] isEqualToString:[room objectForKey:@"name"]])
            return; //not for us
        
        [room setValue:[userData objectForKey:@"new_room_type"] forKey:@"type"];
        
        [self updateState];
    }
    if ([userData objectForKey:@"old_room_hits"])
    {
        //update room hits
        
        if (![[userData objectForKey:@"room_name"] isEqualToString:[room objectForKey:@"name"]])
            return; //not for us
        if (![[userData objectForKey:@"room_type"] isEqualToString:[room objectForKey:@"type"]])
            return; //not for us
        
        [room setValue:[userData objectForKey:@"new_room_hits"] forKey:@"hits"];
        
        [self updateState];
    }
}

- (void)updateEventIO:(NSNotification *)notif
{   
    NSDictionary *userData = [notif userInfo];
    
    NSMutableDictionary *output = [lightsOn objectForKey:[userData objectForKey:@"id"]];
    
    if (!output)
        return; //drop event, not for us
    
    NSArray *tokens = [[userData objectForKey:@"change"] componentsSeparatedByString: @":"];
    if ([tokens count] < 2)
        return;
    
    if ([[tokens objectAtIndex:0] isEqualToString:@"state"])
    {
        if (([[output objectForKey:@"type"] isEqualToString:@"WODigital"] ||
             [[output objectForKey:@"gui_type"] isEqualToString:@"light"]
            ) &&
            ![[output objectForKey:@"state"] isEqualToString:[tokens objectAtIndex:1]])
        {
            if ([[tokens objectAtIndex:1] isEqualToString:@"true"])
            {
                lightsOnCount++;
                [self updateLightsOn];
            }
            else if ([[tokens objectAtIndex:1] isEqualToString:@"false"])
            {
                lightsOnCount--;
                [self updateLightsOn];
            }
            
            [output setValue:[tokens objectAtIndex:1] forKey:@"state"];
        }
        else if (([[output objectForKey:@"type"] isEqualToString:@"WODali"] ||
                  [[output objectForKey:@"type"] isEqualToString:@"WODaliRVB"]  ||
                  [[output objectForKey:@"gui_type"] isEqualToString:@"light"]) &&
                 ![[output objectForKey:@"state"] isEqualToString:[tokens objectAtIndex:1]])
        {
            double value = [[tokens objectAtIndex:1] doubleValue];
            double old_value = [[output objectForKey:@"state"] doubleValue];
            
            if (value > 0 && old_value == 0)
            {
                lightsOnCount++;
                [self updateLightsOn];
            }
            else if (value == 0 && old_value > 0)
            {
                lightsOnCount--;
                [self updateLightsOn];
            }
            
            [output setValue:[tokens objectAtIndex:1] forKey:@"state"];
        }
    }

}

- (void)initCell
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(updateEvent:)
               name:CalaosNotificationRoomChanged
             object:nil];
    
    [nc addObserver:self
           selector:@selector(updateEventIO:)
               name:CalaosNotificationIOChanged
             object:nil];
}

- (void)updateWithRoom:(NSDictionary *)roomDict
{
    self.room = roomDict;
    
    if (!lightsOn)
        lightsOn = [[NSMutableDictionary alloc] init];
    
    //Fill cache for lights on
    lightsOnCount = 0;
    [lightsOn removeAllObjects];
    
    NSEnumerator *iter = [[[room objectForKey:@"items"] objectForKey:@"outputs"] objectEnumerator];
    NSDictionary *output;
    while ((output = [iter nextObject])) 
    {           
        if ([[output objectForKey:@"type"] isEqualToString:@"WODigital"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"light"])
        {
            NSMutableDictionary *dict = [output mutableCopy];
            [lightsOn setObject:dict forKey:[output objectForKey:@"id"]];
            [dict release];
            
            if ([[output objectForKey:@"state"] isEqualToString:@"true"])
                lightsOnCount++;
        }
        
        if ([[output objectForKey:@"type"] isEqualToString:@"WODali"] ||
            [[output objectForKey:@"type"] isEqualToString:@"WODaliRVB"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"light_dimmer"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"light_rgb"])
        {
            NSMutableDictionary *dict = [output mutableCopy];
            [lightsOn setObject:dict forKey:[output objectForKey:@"id"]];
            [dict release];
            
            double value = [[output objectForKey:@"state"] doubleValue];
            
            if (value > 0)
                lightsOnCount++;
        }
    }
    
	[self updateState];
}

@end
