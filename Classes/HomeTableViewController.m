//
//  HomeTableViewController.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "HomeTableViewController.h"
#import "RoomCellView.h"
#import "RoomViewController.h"
#import "CalaosRequest.h"

@implementation HomeTableViewController

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
	
	self.title = @"Ma Maison";
	
	cellLoader = [[CellLoader alloc] init];
	
	self.tableView.allowsSelection = NO;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
		   selector:@selector(reloadData:)
			   name:CalaosNotificationReload
			 object:nil];
    [nc addObserver:self
		   selector:@selector(loginFailed:)
			   name:CalaosNotificationLoginFailed
			 object:nil];
}

- (void)reloadData:(NSNotification *)n
{
    [self.tableView reloadData];
}

- (void)loginFailed:(NSNotification *)n
{
    if (delegate != nil && [delegate respondsToSelector:@selector(homeViewDidFinish:)])
		[delegate homeViewDidFinish:self];
}

- (void)actionButton:(id)sender
{
	if (delegate != nil && [delegate respondsToSelector:@selector(homeViewDidFinish:)])
		[delegate homeViewDidFinish:self];
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

- (void)wantsMore:(NSDictionary *)theRoom
{
	RoomViewController *controller = [[RoomViewController alloc] initWithNibName:@"RoomViewController"
																							bundle:nil];
	
    [controller setRoom:theRoom];
    
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
    // Return the number of rows in the section.
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    return [[calaos getHome] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *cellIdentifier = @"RoomCell";
    
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    BOOL initCell = NO;
    if (cell == nil) 
	{
		[cellLoader loadNibFile:cellIdentifier];
		cell = cellLoader.cell;
		cellLoader.cell = nil;
        
        initCell = YES;
    }
	
	RoomCellView *c = (RoomCellView *)cell;
	c.delegate = self;
    
	[c updateWithRoom:[[calaos getHome] objectAtIndex:indexPath.row]];
    
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
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload 
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}


- (void)dealloc 
{
	[cellLoader release];
	self.delegate = nil;
	
    [super dealloc];
}


@end

