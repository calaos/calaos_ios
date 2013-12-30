//
//  SettingsTableViewController.m
//  CalaosHome
//
//  Created by calaos on 29/12/10.
//  Copyright 2010 Calaos. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "CalaosRequest.h"

#import <Security/Security.h>
#import "KeychainItemWrapper.h"

#import "MBProgressHUD.h"

@interface SettingsTableViewController (hidden)

- (void)loginSuccess:(NSNotification *)n;
- (void)loginFailed:(NSNotification *)n;

@end


@implementation SettingsTableViewController

@synthesize delegate, headerView, emailCell, passCell,
			emailField, passField;
@synthesize passwordItem;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad 
{
    [super viewDidLoad];

	UIBarButtonItem *doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																				 target:self 
																				 action:@selector(doneSettings:)] autorelease];
	self.navigationItem.rightBarButtonItem = doneButton;
	
	UIBarButtonItem *deleteButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
																				   target:self 
																				   action:@selector(resetSettings:)] autorelease];
	self.navigationItem.leftBarButtonItem = deleteButton;
	
	self.title = @"Réglages";
	
	CGRect newFrame = CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, self.headerView.frame.size.height);
	self.headerView.backgroundColor = [UIColor clearColor];
	self.headerView.frame = newFrame;
	self.tableView.tableHeaderView = self.headerView;
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self
		   selector:@selector(loginSuccess:)
			   name:CalaosNotificationConnected
			 object:nil];
	[nc addObserver:self
		   selector:@selector(loginFailed:)
			   name:CalaosNotificationLoginFailed
			 object:nil];
	
	connectionInProgress = FALSE;
    
    self.tableView.allowsSelection = NO;
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)loginSuccess:(NSNotification *)n
{
	connectionInProgress = FALSE;
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	
	//Save login info in KeyChain
	[passwordItem setObject:[emailField text] forKey:(id)kSecAttrAccount];
	[passwordItem setObject:[passField text] forKey:(id)kSecValueData];
	
	//Close settings view
	if (delegate != nil && [delegate respondsToSelector:@selector(settingsViewDidFinish:)])
		[self.delegate settingsViewDidFinish:self];	
}

- (void)loginFailed:(NSNotification *)n
{
	connectionInProgress = FALSE;
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	NSLog(@"Login failed !");
}

- (void)doneSettings:(id)sender
{
	LoadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	LoadingHUD.labelText = @"Connexion en cours...";

	if (!connectionInProgress)
	{
		connectionInProgress = TRUE;
	
		// Try to connect
		CalaosRequest *calaos = [CalaosRequest sharedInstance];
		[calaos connectWithUsername:[emailField text] andPassword:[passField text]];
	}
}

// Action sheet delegate method.
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // the user clicked one of the OK/Cancel buttons
    if (buttonIndex == 0)
    {
        [passwordItem resetKeychainItem];
        [self.tableView reloadData];
    }
}

- (void)resetSettings:(id)sender
{
    // open a dialog with an OK and cancel button
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Voulez vous supprimer vos informations?"
															 delegate:self cancelButtonTitle:@"Annuler" destructiveButtonTitle:@"Supprimer" otherButtonTitles:nil];
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    [actionSheet showInView:self.view];
    [actionSheet release];
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

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return YES;
}



#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    // Return the number of sections.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (section == 0)
		return @"Informations de connexion:";

	return @"???";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if (section == 0)
		return 2;
	
	return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCellID = @"cellID";
	
	if (indexPath.section == 0)
	{
		if (indexPath.row == 0)
			kCellID = @"cellIDEmail";
		else
			kCellID = @"cellIDPass";
	}
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellID];
	if (cell == nil)
	{
		if ([kCellID isEqualToString:@"cellIDEmail"])
		{
			self.emailField.delegate = self;
			cell = self.emailCell;
		}
		else if ([kCellID isEqualToString:@"cellIDPass"])
		{
			self.passField.delegate = self;
			cell = self.passCell;
		}
		else 
		{
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellID] autorelease];
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
	}
	
	if ([kCellID isEqualToString:@"cellIDEmail"])
	{
		emailField.text = [passwordItem objectForKey:(id)kSecAttrAccount];
	}
	else if ([kCellID isEqualToString:@"cellIDPass"])
	{
		passField.text = [passwordItem objectForKey:(id)kSecValueData];
	}
	
	return cell;
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

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{	
	if (theTextField == emailField)
		[passField becomeFirstResponder];
	
	if (theTextField == passField)
		[passField resignFirstResponder];
	
	return YES;
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
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	
	self.headerView = nil;
	self.emailCell = nil;
	self.passCell = nil;
	self.emailField = nil;
	self.passField = nil;
}


- (void)dealloc 
{
	[headerView release];
	[emailCell release];
	[passCell release];
	[emailField release];
	[passField release];
	[passwordItem release];
	self.delegate = nil;

	[super dealloc];
}


@end

