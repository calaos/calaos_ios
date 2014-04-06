
//
//  CalaosHomeViewController.m
//  CalaosHome
//
//  Created by calaos on 28/12/10.
//  Copyright 2010 Calaos. All rights reserved.
//

#import "Common.h"
#import "CalaosHomeViewController.h"
#import "SettingsTableViewController.h"

#import "HomeLightCellView.h"
#import "HomeScenarioCellView.h"

#import "MBProgressHUD.h"
#import "CalaosRequest.h"

#import "UIImageAdditions.h"

@interface CalaosHomeViewController (hidden)

- (void)loginSuccess:(NSNotification *)n;
- (void)loginFailed:(NSNotification *)n;

@end

@implementation CalaosHomeViewController

@synthesize homeTableView, camera, labelCamera;
@synthesize passwordItem;
@synthesize audioTitle, audioCover, audioArtist, audioBtPlay, audioBtStop, audioVolume;

#pragma mark -
#pragma mark Memory and orientations

- (BOOL)loadNibFile:(NSString *)nibName
{
	if ([[NSBundle mainBundle] loadNibNamed:nibName owner:self options:nil] == nil)
	{
		NSLog(@"Error! Could not load %@ file.", nibName);
		return NO;
	}
	
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
	{
        [self loadNibFile:@"CalaosHomeViewController"];
		
		self.homeTableView.delegate = self;
		self.homeTableView.dataSource = self;
		self.homeTableView.allowsSelection = NO;
		
		if (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown)
			self.view.transform = CGAffineTransformMakeRotation(PI);
        
        [self updateAudioPlayer];
	}
	else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
	{
		[self loadNibFile:@"CalaosHomeViewController-landscape"];
		
		self.homeTableView.delegate = self;
		self.homeTableView.dataSource = self;
		self.homeTableView.allowsSelection = NO;
		
		if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft)
			self.view.transform = CGAffineTransformMakeRotation(PI + PI / 2);
		else
			self.view.transform = CGAffineTransformMakeRotation(PI / 2);
        
        [self updateAudioPlayer];
	}

}

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];

	cellLoader = [[CellLoader alloc] init];
	
	self.homeTableView.delegate = self;
	self.homeTableView.dataSource = self;
	self.homeTableView.allowsSelection = NO;
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self
		   selector:@selector(loginSuccess:)
			   name:CalaosNotificationConnected
			 object:nil];
	[nc addObserver:self
		   selector:@selector(loginFailed:)
			   name:CalaosNotificationLoginFailed
			 object:nil];
    [nc addObserver:self
		   selector:@selector(reloadData:)
			   name:CalaosNotificationReload
			 object:nil];
    
    //Audio notifications
    [nc addObserver:self
		   selector:@selector(updateAudioPlayerNotif:)
			   name:CalaosNotificationAudioVolumeChanged
			 object:nil];
    [nc addObserver:self
		   selector:@selector(updateAudioPlayerNotif:)
			   name:CalaosNotificationAudioStatusChanged
			 object:nil];
    [nc addObserver:self
		   selector:@selector(updateAudioPlayerNotif:)
			   name:CalaosNotificationAudioPlayerChanged
			 object:nil];
	
	//Try to connect at startup
	NSLog(@"Trying to connect...");
	
	LoadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	LoadingHUD.labelText = @"Connexion en cours...";
	
	// Try to connect
	CalaosRequest *calaos = [CalaosRequest sharedInstance];
	[calaos connectWithUsername:[passwordItem objectForKey:(id)kSecAttrAccount]
					andPassword:[passwordItem objectForKey:(id)kSecValueData]];
    
    cameraInProgress = NO;
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc 
{
	[cellLoader release];
    
    self.homeTableView = nil;
    self.passwordItem = nil;
    self.camera = nil;
    self.labelCamera = nil;
    
    self.audioBtStop = nil;
    self.audioBtPlay = nil;
    self.audioArtist = nil;
    self.audioTitle = nil;
    self.audioCover = nil;
    self.audioVolume = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark Calaos Notifications

- (void)loginSuccess:(NSNotification *)n
{
	[MBProgressHUD hideHUDForView:self.view animated:YES];
    
    [homeTableView reloadData];
    
    //Start camera viewer if needed
    [self startCameraViewer];
    
    [self updateAudioPlayer];
}

- (void)loginFailed:(NSNotification *)n
{
	[MBProgressHUD hideHUDForView:self.view animated:YES];
	NSLog(@"Login failed !");
    
    [self stopCameraViewer];
    
    [homeTableView reloadData];
	
	//Show settings page if login failed
	[self settingClick:nil];
}

- (void)reloadData:(NSNotification *)n
{
    //[homeTableView reloadData];
}

- (void)updateAudioPlayerNotif:(NSNotification *)n
{
    [self updateAudioPlayer];
}

#pragma mark -
#pragma mark Buttons action

- (IBAction)settingClick:(id) sender
{
    [self stopCameraViewer];
    
	SettingsTableViewController *controller = [[SettingsTableViewController alloc] initWithNibName:@"SettingsTableViewController"
																							bundle:nil];
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	controller.delegate = self;
	controller.passwordItem = self.passwordItem;
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
	[self presentModalViewController:navigationController animated:YES];
	
	[navigationController release];
	
	[controller release];
}

- (IBAction)camerasClick:(id) sender
{
    [self stopCameraViewer];
    
	CamerasTableViewController *controller = [[CamerasTableViewController alloc] initWithNibName:@"CamerasTableViewController"
																						  bundle:nil];
	
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	controller.delegate = self;
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
	
	navigationController.navigationBar.barStyle = UIBarStyleBlack;
	[self presentModalViewController:navigationController animated:YES];
	
	[navigationController release];
	
	[controller release];
}

- (IBAction)musicClick:(id) sender
{
    [self stopCameraViewer];
    
	MusicTableViewController *controller = [[MusicTableViewController alloc] initWithNibName:@"MusicTableViewController"
																						  bundle:nil];
	
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	controller.delegate = self;
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
	
	navigationController.navigationBar.barStyle = UIBarStyleBlack;
	[self presentModalViewController:navigationController animated:YES];
	
	[navigationController release];
	
	[controller release];
}

- (IBAction)homeClick:(id) sender
{
    [self stopCameraViewer];
    
	HomeTableViewController *controller = [[HomeTableViewController alloc] initWithNibName:@"HomeTableViewController"
																					  bundle:nil];
	
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	controller.delegate = self;
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
	
	navigationController.navigationBar.barStyle = UIBarStyleBlack;
	[self presentModalViewController:navigationController animated:YES];
	
	[navigationController release];
	
	[controller release];
}

- (void)settingsViewDidFinish:(SettingsTableViewController *)controller
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
	[self dismissModalViewControllerAnimated:YES];
    
    [self startCameraViewer];
}

- (void)camerasViewDidFinish:(CamerasTableViewController *)controller
{
	[self dismissModalViewControllerAnimated:YES];
    
    [homeTableView reloadData];
    
    [self startCameraViewer];
}

- (void)musicViewDidFinish:(MusicTableViewController *)controller
{
	[self dismissModalViewControllerAnimated:YES];
    
    [homeTableView reloadData];
    
    [self startCameraViewer];
}

- (void)homeViewDidFinish:(HomeTableViewController *)controller
{
	[self dismissModalViewControllerAnimated:YES];
    
    [homeTableView reloadData];
    
    [self startCameraViewer];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    // Return the number of rows in the section.
    
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    int scenarios_count = [[calaos getScenarios] count];
    int lightsOn_count = [[calaos getLightsOn] count];
    
    NSLog(@"numberOfRow: scenarios:%d lights:%d", scenarios_count, lightsOn_count);
    
    return scenarios_count + lightsOn_count;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *cellIdentifier;
	
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    int scenarios_count = [[calaos getScenarios] count];
    //int lightsOn_count = [[calaos getLightsOn] count];
    
	if (indexPath.row < scenarios_count)
		cellIdentifier = @"HomeScenarioCell";
	else
		cellIdentifier = @"HomeLightCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    BOOL initCell = NO;
    if (cell == nil) 
	{
		[cellLoader loadNibFile:cellIdentifier];
		cell = cellLoader.cell;
		cellLoader.cell = nil;
        initCell = YES;
    }

    if ([cellIdentifier isEqualToString:@"HomeLightCell"])
    {
        HomeLightCellView *c = (HomeLightCellView *)cell;
	
        [c updateWithId:[[[calaos getLightsOn] objectAtIndex:indexPath.row - scenarios_count] objectForKey:@"id"]];
        
        if (initCell)
            [c initCell];
    }
    else if ([cellIdentifier isEqualToString:@"HomeScenarioCell"])
    {
        HomeScenarioCellView *c = (HomeScenarioCellView *)cell;
        
        [c updateWithId:[[[calaos getScenarios] objectAtIndex:indexPath.row] objectForKey:@"id"]];
        
        if (initCell)
            [c initCell];
    }
	
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
#pragma mark Camera Viewer

- (void)cameraPictureDone:(NSData *)pictureData
{
    cameraInProgress = NO;
    
    if (!pictureData)
    {
        NSLog(@"Failed to get camera picture");
        return;
    }
    else
    {
        self.camera.image = [[UIImage imageWithData:pictureData] imageByScalingAndCroppingForSize:self.camera.frame.size];
    }
    
    if (cameraRun)
        [self updateCameraViewer];
}

- (void)updateCameraViewer
{
    if (cameraInProgress)
        return;
    
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    NSArray *cameras = [calaos getCameras];
    
    if ([cameras count] <= 0)
        return;
    
    labelCamera.text = [[cameras objectAtIndex:0] objectForKey:@"name"];
    
    [calaos getPictureForCamera:0 withDelegate:self andDoneSelector:@selector(cameraPictureDone:)];
    
    cameraInProgress = YES;
}

- (void)startCameraViewer
{
    cameraRun = YES;
    
    [self updateCameraViewer];
}

- (void)stopCameraViewer
{
    cameraRun = NO;
}

#pragma mark -
#pragma mark Audio player

- (void)audioNext:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"next"];
}

- (void)audioPrevious:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"previous"];
}

- (void)audioPlay:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"play"];
}

- (void)audioStop:(id)sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"pause"];
}

- (IBAction)volumeSliderMoved:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:[NSString stringWithFormat:@"volume %d", (int)(audioVolume.value * 100.0)]];
}

- (void)audioCoverDone:(NSData *)pictureData
{   
    if (!pictureData)
    {
        NSLog(@"Failed to get audio cover picture");
    }
    else
    {
        self.audioCover.image = [[UIImage imageWithData:pictureData] imageByScalingAndCroppingForSize:self.audioCover.frame.size];
    }
}

- (void)updateAudioPlayer
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    NSDictionary *player = [calaos getAudioWithId:0];
    
    if (!player)
        return;
    
    audioArtist.text = [[player objectForKey:@"current_track"] objectForKey:@"artist"];
    audioTitle.text = [[player objectForKey:@"current_track"] objectForKey:@"title"];
    audioVolume.value = [[player objectForKey:@"volume"] doubleValue] / 100.0;
    
    if ([[player objectForKey:@"status"] isEqualToString:@"play"] ||
        [[player objectForKey:@"status"] isEqualToString:@"playing"])
    {
        audioBtPlay.hidden = YES;
        audioBtStop.hidden = NO;
    }
    else
    {
        audioBtPlay.hidden = NO;
        audioBtStop.hidden = YES;
    }

    [calaos getCoverForAudio:0 withDelegate:self andDoneSelector:@selector(audioCoverDone:)];
}

@end
