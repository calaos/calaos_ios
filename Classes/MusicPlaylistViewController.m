//
//  MusicPlaylistViewController.m
//  CalaosHome
//
//  Created by calaos on 04/01/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "MusicPlaylistViewController.h"
#import "TrackCellView.h"
#import "CalaosRequest.h"
#import "UIImageAdditions.h"

@implementation MusicPlaylistViewController

@synthesize playlistTableView, playerName, playerCover, songTitle, songArtist, buttonPlay, buttonStop, sliderVolume, animationView;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    UIBarButtonItem *button = [[[UIBarButtonItem alloc] initWithTitle:@"Plus..." 
																style:UIBarButtonItemStyleBordered 
															   target:self 
															   action:@selector(actionButtonPlus:)] autorelease];
	self.navigationItem.rightBarButtonItem = button;
	audioOptionsController = nil;
    
	self.title = @"Liste de lecture";

	playlistTableView.delegate = self;
	playlistTableView.dataSource = self;
	playlistTableView.allowsSelection = NO;
	
	cellLoader = [[CellLoader alloc] init];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
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
    
    [self updateAudioPlayer];
    
    cellHeightCache = 0;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)actionButtonPlus:(id)sender
{
    if(!audioOptionsController) 
    {
        audioOptionsController = [[AudioOptionsViewController alloc] initWithNibName:@"AudioOptionsView" 
                                                                              bundle:nil];
        audioOptionsController.playerId = player_id;

		[UIView transitionWithView:animationView duration:0.5
						   options:UIViewAnimationOptionTransitionFlipFromLeft
						animations:^ { [animationView addSubview:audioOptionsController.view]; }
						completion:nil];
	}
    else 
    {
		[UIView transitionWithView:animationView duration:0.5
						   options:UIViewAnimationOptionTransitionFlipFromRight
						animations:^ { [audioOptionsController.view removeFromSuperview]; }
						completion:nil];

		[audioOptionsController release];
        audioOptionsController = nil;
    }
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
    
    NSDictionary *player = [calaos getAudioWithId:player_id];
    NSString *playlist_size = [player objectForKey:@"playlist_size"];
    
    if (playlist_size)
        return [playlist_size doubleValue];
    
    return 0;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
    static NSString *cellIdentifier = @"TrackCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    BOOL initCell = NO;
    
    if (cell == nil) 
	{
		[cellLoader loadNibFile:cellIdentifier];
		cell = cellLoader.cell;
		cellLoader.cell = nil;
        initCell = YES;
    }

	TrackCellView *c = (TrackCellView *)cell;
	
    if (initCell)
        [c initCell];
	[c updateWithTrack:indexPath.row andPlayer:player_id];
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (cellHeightCache == 0)
    {
        UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
        
        cellHeightCache = cell.bounds.size.height;
    }
    
    return cellHeightCache;
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
#pragma mark Audio player

- (void)audioCoverDone:(NSData *)pictureData
{   
    if (!pictureData)
    {
        NSLog(@"Failed to get audio cover picture");
    }
    else
    {
        self.playerCover.image = [[UIImage imageWithData:pictureData] imageByScalingAndCroppingForSize:self.playerCover.frame.size];
    }
}

- (void)updateAudioPlayer
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    NSDictionary *player = [calaos getAudioWithId:player_id];
    
    if (!player)
        return;
    
    playerName.text = [player objectForKey:@"name"];
    songArtist.text = [[player objectForKey:@"current_track"] objectForKey:@"artist"];
    songTitle.text = [[player objectForKey:@"current_track"] objectForKey:@"title"];
    sliderVolume.value = [[player objectForKey:@"volume"] doubleValue] / 100.0;
    
    if ([[player objectForKey:@"status"] isEqualToString:@"play"] ||
        [[player objectForKey:@"status"] isEqualToString:@"playing"])
    {
        buttonPlay.hidden = YES;
        buttonStop.hidden = NO;
    }
    else
    {
        buttonPlay.hidden = NO;
        buttonStop.hidden = YES;
    }
    
    [calaos getCoverForAudio:0 withDelegate:self andDoneSelector:@selector(audioCoverDone:)];
}

- (void)updateAudioPlayerNotif:(NSNotification *)n
{
    [self updateAudioPlayer];
}

- (void)setPlayerId:(NSInteger)thePlayer
{
    player_id = thePlayer;
}

- (IBAction)buttonPrevious:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"previous"];
}

- (IBAction)buttonPlay:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"play"];
}

- (IBAction)buttonStop:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"pause"];
}

- (IBAction)buttonNext:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:@"next"];
}

- (IBAction)volumeChanged:(id) sender
{
    CalaosRequest *calaos = [CalaosRequest sharedInstance];
    
    [calaos sendAction:@"audio" withId:@"0" andValue:[NSString stringWithFormat:@"volume %d", (int)(sliderVolume.value * 100.0)]];
}

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

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc 
{
    [super dealloc];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
    
	/*self.playlistTableView = nil;
    self.playerCover = nil;
    self.playerName = nil;
    self.songArtist = nil;
    self.songTitle = nil;
    self.buttonStop = nil;
    self.buttonPlay = nil;
    self.sliderVolume = nil;
    self.animationView = nil;
     
     this crashes the app... why?
     */
    
	[cellLoader release];
	cellLoader = nil;
}


@end
