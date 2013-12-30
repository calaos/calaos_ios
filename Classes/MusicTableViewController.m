//
//  MusicTableViewController.m
//  CalaosHome
//
//  Created by calaos on 03/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "MusicTableViewController.h"
#import "MusicCellView.h"
#import "MusicPlaylistViewController.h"
#import "CalaosRequest.h"

@implementation MusicTableViewController

@synthesize delegate;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad 
{
    [super viewDidLoad];

	UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithTitle:@"Accueil" 
																style:UIBarButtonItemStyleBordered 
															   target:self 
															   action:@selector(actionButton:)] autorelease];
	self.navigationItem.rightBarButtonItem = button;
	
	self.title = @"Musique";
	
	cellLoader = [[CellLoader alloc] init];
	
	self.tableView.allowsSelection = NO;
}

- (void)actionButton:(id)sender
{
	if (delegate != nil && [delegate respondsToSelector:@selector(musicViewDidFinish:)])
		[delegate musicViewDidFinish:self];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)wantsMore:(NSInteger)player_id
{
	MusicPlaylistViewController *controller = [[MusicPlaylistViewController alloc] initWithNibName:@"MusicPlaylistViewController"
																							bundle:nil];
	
    [controller setPlayerId:player_id];
    
	[self.navigationController pushViewController:controller animated:YES];
	
	[controller release];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    return [calaos getAudioPlayersCount];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *cellIdentifier = @"MusicCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    BOOL initCell = NO;
    if (cell == nil) 
	{
		[cellLoader loadNibFile:cellIdentifier];
		cell = cellLoader.cell;
		cellLoader.cell = nil;
        initCell = YES;
    }
	
	MusicCellView *c = (MusicCellView *)cell;
	c.delegate = self;
	
    if (initCell)
        [c initCell];
	[c updateWithPlayer:indexPath.row];
	
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
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc 
{
	[cellLoader release];
	self.delegate = nil;
	
    [super dealloc];
}


@end

