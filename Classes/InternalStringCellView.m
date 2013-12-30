//
//  InternalStringCellView.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "InternalStringCellView.h"
#import "CalaosRequest.h"
#import "AlertPrompt.h"

@implementation InternalStringCellView

@synthesize label, buttonEdit;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code.
    }
    return self;
}

- (void)dealloc 
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    
    self.label = nil;
    self.buttonEdit = nil;
    
    [super dealloc];
}

- (void)updateState:(NSString *)stateString
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    if ([stateString isEqualToString:@""])
        label.text = [[[calaos getOutputs] objectForKey:output_id] objectForKey:@"name"];
    else
        label.text = stateString;
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
        buttonEdit.hidden = NO;
    }
    else
    {
        buttonEdit.hidden = YES;
    }
    
    [self updateState:[[[calaos getOutputs] objectForKey:output_id] objectForKey:@"state"]];
}

- (IBAction)buttonEdit:(id)sender
{
    AlertPrompt *prompt = [AlertPrompt alloc];
    prompt = [prompt initWithTitle:@"Changer le texte" message:@"Entrez le nouveau texte" delegate:self cancelButtonTitle:@"Annuler" okButtonTitle:@"Valider"];
    [prompt show];
    [prompt release];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != [alertView cancelButtonIndex])
	{
        CalaosRequest *calaos = [CalaosRequest sharedInstance];
        
        [calaos sendAction:@"output" withId:output_id andValue:[(AlertPrompt *)alertView enteredText]];
	}
}

@end
