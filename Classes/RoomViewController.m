//
//  RoomViewController.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "RoomViewController.h"
#import "LightCellView.h"
#import "CalaosRequest.h"

@implementation RoomViewController

@synthesize elementTableView, labelName, iconRoom;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) 
    {
        cacheItems = nil;
    }
    return self;
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
    
    self.iconRoom.image = [UIImage imageNamed: icon_file];
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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];

	self.title = @"Détails";
	
	elementTableView.delegate = self;
	elementTableView.dataSource = self;
	elementTableView.allowsSelection = NO;
	
	cellLoader = [[CellLoader alloc] init];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(updateEvent:)
               name:CalaosNotificationRoomChanged
             object:nil];
    [nc addObserver:self
		   selector:@selector(reloadData:)
			   name:CalaosNotificationReload
			 object:nil];
    [nc addObserver:self
		   selector:@selector(loginFailed:)
			   name:CalaosNotificationLoginFailed
			 object:nil];
    
    [self updateState];
}

- (void)reloadData:(NSNotification *)n
{
    [self.elementTableView reloadData];
}

- (void)loginFailed:(NSNotification *)n
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)setRoom:(NSDictionary *)theRoom
{
    room = theRoom;

    if (cacheItems)
    {
        [cacheItems release];
    }
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    NSEnumerator *iter = [[[room objectForKey:@"items"] objectForKey:@"inputs"] objectEnumerator];
    NSDictionary *input;
    while ((input = [iter nextObject]))
    {
        if ([[input objectForKey:@"type"] isEqualToString:@"scenario"] ||
            [[input objectForKey:@"type"] isEqualToString:@"Scenario"] ||
            [[input objectForKey:@"type"] isEqualToString:@"WITemp"] ||
            [[input objectForKey:@"type"] isEqualToString:@"OWTemp"] ||
            [[input objectForKey:@"gui_type"] isEqualToString:@"scenario"] ||
            [[input objectForKey:@"gui_type"] isEqualToString:@"temp"])
        {
            if ([[input objectForKey:@"visible"] isEqualToString:@"true"])
                [tempArray addObject:input];
        }
    }
    
    iter = [[[room objectForKey:@"items"] objectForKey:@"outputs"] objectEnumerator];
    NSDictionary *output;
    while ((output = [iter nextObject]))
    {
        if ([[output objectForKey:@"type"] isEqualToString:@"WODigital"] ||
            [[output objectForKey:@"type"] isEqualToString:@"WODali"] ||
            [[output objectForKey:@"type"] isEqualToString:@"WODaliRVB"] ||
            [[output objectForKey:@"type"] isEqualToString:@"InternalBool"] ||
            [[output objectForKey:@"type"] isEqualToString:@"InternalInt"] ||
            [[output objectForKey:@"type"] isEqualToString:@"InternalString"] ||
            [[output objectForKey:@"type"] isEqualToString:@"WOVolet"] ||
            [[output objectForKey:@"type"] isEqualToString:@"WOVoletSmart"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"light"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"light_dimmer"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"light_rgb"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"var_bool"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"var_int"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"var_string"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"shutter"] ||
            [[output objectForKey:@"gui_type"] isEqualToString:@"shutter_smart"])
        {
            if ([[output objectForKey:@"visible"] isEqualToString:@"true"])
                [tempArray addObject:output];
        }
    }

    //Sort by hits
    cacheItems = [NSMutableArray arrayWithArray:[tempArray sortedArrayUsingComparator: ^(id obj1, id obj2) 
                                                {
                                                    int hits1, hits2;
                                                    hits1 = [[obj1 objectForKey:@"hits"] integerValue];
                                                    hits2 = [[obj2 objectForKey:@"hits"] integerValue];
                                                    
                                                    if (hits1 < hits2)
                                                        return (NSComparisonResult)NSOrderedDescending;
                                                    
                                                    if (hits1 > hits2)
                                                        return (NSComparisonResult)NSOrderedAscending;
                                                    
                                                    return (NSComparisonResult)NSOrderedSame;
                                                }]];
    [cacheItems retain];
    [tempArray release];
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations.
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Return the number of rows in the section.
    return [cacheItems count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *cellIdentifier;

    NSDictionary *element = [cacheItems objectAtIndex:indexPath.row];
    
    if ([[element objectForKey:@"type"] isEqualToString:@"scenario"] ||
        [[element objectForKey:@"type"] isEqualToString:@"Scenario"] ||
        [[element objectForKey:@"gui_type"] isEqualToString:@"scenario"])
        cellIdentifier = @"ScenarioCell";
    else if ([[element objectForKey:@"type"] isEqualToString:@"WITemp"] ||
             [[element objectForKey:@"type"] isEqualToString:@"OWTemp"] ||
             [[element objectForKey:@"gui_type"] isEqualToString:@"temp"])
        cellIdentifier = @"TempCell";
    else if ([[element objectForKey:@"type"] isEqualToString:@"WODigital"] ||
             [[element objectForKey:@"gui_type"] isEqualToString:@"light"])
        cellIdentifier = @"LightCell";
    else if ([[element objectForKey:@"type"] isEqualToString:@"WODali"] ||
             [[element objectForKey:@"gui_type"] isEqualToString:@"light_dimmer"])
        cellIdentifier = @"LightDaliCell";
    else if ([[element objectForKey:@"type"] isEqualToString:@"WODaliRVB"] ||
             [[element objectForKey:@"gui_type"] isEqualToString:@"light_rgb"])
        cellIdentifier = @"LightDaliRGBCell";
    else if ([[element objectForKey:@"type"] isEqualToString:@"InternalBool"] ||
             [[element objectForKey:@"gui_type"] isEqualToString:@"var_bool"])
        cellIdentifier = @"InternalBoolCell";
    else if ([[element objectForKey:@"type"] isEqualToString:@"InternalInt"] ||
             [[element objectForKey:@"gui_type"] isEqualToString:@"var_int"])
        cellIdentifier = @"InternalIntCell";
    else if ([[element objectForKey:@"type"] isEqualToString:@"InternalString"] ||
             [[element objectForKey:@"gui_type"] isEqualToString:@"var_string"])
        cellIdentifier = @"InternalStringCell";
    else if ([[element objectForKey:@"type"] isEqualToString:@"WOVolet"] ||
             [[element objectForKey:@"gui_type"] isEqualToString:@"shutter"])
        cellIdentifier = @"ShutterCell";
    else if ([[element objectForKey:@"type"] isEqualToString:@"WOVoletSmart"] ||
             [[element objectForKey:@"gui_type"] isEqualToString:@"shutter_smart"])
        cellIdentifier = @"ShutterSmartCell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    BOOL initCell = NO;
    if (cell == nil) 
	{
		[cellLoader loadNibFile:cellIdentifier];
		cell = cellLoader.cell;
		cellLoader.cell = nil;
        initCell = YES;
    }
	
	LightCellView *c = (LightCellView *)cell;
	
	[c updateWithId:[element objectForKey:@"id"]];
    
    if (initCell)
        [c initCell];
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	return cell.bounds.size.height;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
	 // ...
	 // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    
	self.elementTableView = nil;
    self.labelName = nil;
    self.iconRoom = nil;
	
	[cellLoader release];
	cellLoader = nil;
}


- (void)dealloc 
{
	[elementTableView release];
    [super dealloc];
}


@end
