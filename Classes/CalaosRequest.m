//
//  CalaosRequest.m
//  CalaosHome
//
//  Created by Raoul on 18/02/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "CalaosRequest.h"
#import "JSON.h"
#import "AsyncSocket.h"
#import "AsyncUdpSocket.h"
#import "ASIHTTPRequest.h"

#include <arpa/inet.h>

#ifndef BCAST_UDP_PORT
#define BCAST_UDP_PORT          4545
#endif

#ifndef CALAOS_TCP_PORT
#define CALAOS_TCP_PORT         4456
#endif

enum { TAG_LOGIN, TAG_LISTENDATA };

NSString *const CalaosNotificationConnected = @"CalaosNotificationConnected";
NSString *const CalaosNotificationLoginFailed = @"CalaosNotificationLoginFailed";

NSString *const CalaosNotificationIOChanged = @"CalaosNotificationIOChanged";
NSString *const CalaosNotificationRoomChanged = @"CalaosNotificationRoomChanged";

NSString *const CalaosNotificationReload = @"CalaosNotificationReload";

NSString *const CalaosNotificationAudioVolumeChanged = @"CalaosNotificationAudioVolumeChanged";
NSString *const CalaosNotificationAudioStatusChanged = @"CalaosNotificationAudioStatusChanged";
NSString *const CalaosNotificationAudioPlayerChanged = @"CalaosNotificationAudioPlayerChanged";
NSString *const CalaosNotificationAudioPlaylistChanged = @"CalaosNotificationAudioPlaylistChanged";
NSString *const CalaosNotificationAudioPlaylistItemUpdated = @"CalaosNotificationAudioPlaylistItemUpdated";

NSString *const CalaosNetworkUrl = @"https://www.calaos.fr/calaos_network/api.php";
NSString *const CalaosBoxUrl = @"https://%@/api.php";

static CalaosRequest *sharedInstance = nil;

@interface CalaosRequest (hidden)

- (void)initialization;

- (void)didReceiveMemoryWarning:(NSNotification *)notification;
- (void)willResignActive:(NSNotification *)notification;
- (void)willTerminate:(NSNotification *)notification;

- (void)startUDPSearch;
- (void)timerDetectSendData:(NSTimer *)timer;

@end

@implementation CalaosRequest (hidden)

#pragma mark System notifications

- (void)initialization 
{
	NSNotificationCenter *nc  = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self
		   selector:@selector(didReceiveMemoryWarning:) 
			   name:UIApplicationDidReceiveMemoryWarningNotification
			 object:nil];
	[nc addObserver:self
		   selector:@selector(willResignActive:) 
			   name:UIApplicationWillResignActiveNotification
			 object:nil];
	[nc addObserver:self
		   selector:@selector(willTerminate:) 
			   name:UIApplicationWillTerminateNotification
			 object:nil];
    
    requestManager = [[RequestManager alloc] init];
    
    cacheInputs = [[NSMutableDictionary alloc] init];
    cacheOutputs = [[NSMutableDictionary alloc] init];
    cacheScenarios = [[NSMutableArray alloc] init];
    cacheLightsOn = [[NSMutableArray alloc] init];
    homeArray = nil;
    
    detectSocket = nil;
    listenSocket = nil;
    
    uuid = nil;
    
    cacheTracks = nil;
}

- (void)startUDPSearch
{
    if (detectSocket)
        return;
    
    NSError *err;
    
    // Failed to send request to calaos.fr, try to detect the machine with an UDP broadcast
    NSLog(@"Trying to detect on LAN network...");

    NSArray *runLoopCommonModesArray = [NSArray arrayWithObject:NSRunLoopCommonModes];
    detectSocket = [[AsyncUdpSocket alloc] initIPv4];
    [detectSocket setDelegate:self];
    [detectSocket setRunLoopModes:runLoopCommonModesArray];
    
    if (![detectSocket bindToPort:BCAST_UDP_PORT error:&err])
        NSLog (@"UDP Socket bind failed (%@)!", err);
    
    [detectSocket receiveWithTimeout:-1 tag:0];
    
    detectSocketTX = [[AsyncUdpSocket alloc] initIPv4];
    [detectSocketTX setDelegate:self];
    [detectSocketTX setRunLoopModes:runLoopCommonModesArray];

    struct sockaddr_in bcast_addr;
    bcast_addr.sin_family = AF_INET;
    bcast_addr.sin_addr.s_addr = INADDR_NONE;
    bcast_addr.sin_port = htons (BCAST_UDP_PORT);
    
    if (![detectSocketTX enableBroadcast:TRUE error:&err])
        NSLog (@"Could not enable broadcast on the detectSocket: %@", err);
    
    if (![detectSocketTX connectToAddress:[NSData dataWithBytes:&bcast_addr length:sizeof(bcast_addr)] error:&err])
        NSLog (@"Could not connect the detectSocket: %@", err);
    
    detectTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                   target:self
                                                 selector:@selector(timerDetectSendData:)
                                                 userInfo:nil
                                                  repeats:YES];
    
    detectCount = 0;
}

- (void)timerDetectSendData:(NSTimer *)timer
{
    NSLog(@"Sending UDP search...");
    
    if (detectCount >= 10)
    {
        NSLog(@"No Calaos machine found on LAN...");
        
        [detectSocket close];
        [detectSocket autorelease];
        detectSocket = nil;
        
        [detectSocketTX close];
        [detectSocketTX autorelease];
        detectSocketTX = nil;
        
        [detectTimer invalidate];
        detectTimer = nil;

        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        
        [nc postNotificationName:CalaosNotificationLoginFailed
                          object:nil
                        userInfo:nil];
        
        return;
    }
    
    NSString *data = @"CALAOS_DISCOVER";
    [detectSocketTX sendData:[data dataUsingEncoding:NSASCIIStringEncoding] 
                 withTimeout:-1
                         tag:0];
    
    detectCount++;
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification 
{
}

- (void)willResignActive:(NSNotification *)notification 
{
}

- (void)willTerminate:(NSNotification *)notification 
{
}

@end

@implementation CalaosRequest

@synthesize username, password, private_ip, public_ip, homeDict;

#pragma mark Getters

- (NSDictionary *)getInputs
{
    return cacheInputs;
}

- (NSDictionary *)getOutputs
{
    return cacheOutputs;
}

- (NSArray *)getScenarios
{
    return cacheScenarios;
}

- (NSArray *)getLightsOn
{
    return cacheLightsOn;
}

- (NSArray *)getHome
{
    NSLog(@"retain count: %d", [homeArray retainCount]);
    return homeArray;
}

- (NSArray *)getCameras
{
    return [self.homeDict objectForKey:@"cameras"];
}

- (NSInteger)getAudioPlayersCount
{
    NSArray *audios = [self.homeDict objectForKey:@"audio"];
    
    if (!audios)
        return 0;
    
    return [audios count];
}

- (NSDictionary *)getAudioWithId:(NSInteger)player_id
{
    NSArray *audios = [self.homeDict objectForKey:@"audio"];
    
    if (!audios)
        return nil;
    
    if (player_id < 0 || player_id >= [audios count])
        return nil;
    
    return [audios objectAtIndex:player_id];
}

- (NSString *)getConsigneForInput:(NSString *)input_id
{   
    NSEnumerator *iter = [cacheInputs objectEnumerator];
    NSDictionary *input;
    while ((input = [iter nextObject]))
    {
        if (![[input objectForKey:@"type"] isEqualToString:@"InternalInt"] &&
            ![[input objectForKey:@"gui_type"] isEqualToString:@"var_int"])
            continue;
        
        if ([[input objectForKey:@"chauffage_id"] isEqualToString:[[cacheInputs objectForKey:input_id] objectForKey:@"chauffage_id"]])
            return [input objectForKey:@"id"];
    }
    
    return nil;
}

#pragma mark Utility functions

- (NSString *)computeCalaosUrl
{
	if (at_home)
		return [NSString stringWithFormat:CalaosBoxUrl, self.private_ip];
	else
		return [NSString stringWithFormat:CalaosBoxUrl, self.public_ip];
}

- (NSString *)computeCameraUrl:(NSString *)camera_url
{
	if (at_home)
		return [NSString stringWithFormat:@"https://%@%@&u=%@&p=%@", self.private_ip, camera_url, [self.username stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [self.password stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	else
		return [NSString stringWithFormat:@"https://%@%@&u=%@&p=%@", self.public_ip, camera_url, [self.username stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [self.password stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
}

- (void)updateCache
{
    NSLog(@"UPDATE CACHE");
    
    [cacheInputs removeAllObjects];
    [cacheOutputs removeAllObjects];
    [cacheScenarios removeAllObjects];
    [cacheLightsOn removeAllObjects];
    if (homeArray)
        [homeArray release];
    homeArray = nil;
    
    //Update io tables
    homeArray = [NSMutableArray arrayWithArray:[[self.homeDict objectForKey:@"home"] sortedArrayUsingComparator: ^(id obj1, id obj2) 
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
    
    if (!homeArray)
    {
        NSLog(@"Error \"home\" not found in homeArray");
        
        return;
    }
    
    NSLog(@"Found %d rooms", [homeArray count]);
    [homeArray retain];
    
    //remove the Internal room from the list (only for calaos_server < 2.0)
    for (int i = 0;i < [homeArray count];i++)
    {
        if ([[[homeArray objectAtIndex:i] objectForKey:@"type"] isEqualToString:@"Internal"])
        {
            [homeArray removeObjectAtIndex:i];
            break;
        }
    }
    
    NSEnumerator *enumerator = [homeArray objectEnumerator];
    NSDictionary *room;
    while ((room = [enumerator nextObject])) 
    {
        NSDictionary *items = [room objectForKey:@"items"];
        if (!items)
        {
            NSLog(@"Error: items key not found");
            continue;
        }
        
        NSArray *inputs = [items objectForKey:@"inputs"];
        
        if ([inputs isKindOfClass:[NSNull class]] || !inputs)
        {
            //create an empty array if it didn't exists
            [items setValue:[NSArray array] forKey:@"inputs"];
            inputs = [items objectForKey:@"inputs"];
        }
        
        NSEnumerator *iter = [inputs objectEnumerator];
        NSDictionary *input;
        while ((input = [iter nextObject])) 
        {
            [cacheInputs setObject:input forKey:[input objectForKey:@"id"]];
            
            //item is not visible. Show all scenarios event they are not visible
            //if (![[input objectForKey:@"visible"] isEqualToString:@"true"])
            //    continue;
            
            //item is scenario
            if ([[input objectForKey:@"type"] isEqualToString:@"scenario"] ||
                [[input objectForKey:@"type"] isEqualToString:@"Scenario"] ||
                [[input objectForKey:@"gui_type"] isEqualToString:@"scenario"])
            {
                [cacheScenarios addObject:input];
            }
        }
        
        NSArray *outputs = [items objectForKey:@"outputs"];
        
        if ([outputs isKindOfClass:[NSNull class]] || !outputs)
        {
            //create an empty array if it didn't exists
            [items setValue:[NSArray array] forKey:@"outputs"];
            outputs = [items objectForKey:@"outputs"];
        }
        
        iter = [outputs objectEnumerator];
        NSDictionary *output;
        while ((output = [iter nextObject])) 
        {
            [cacheOutputs setObject:output forKey:[output objectForKey:@"id"]];
            
            //item is not visible
            if (![[output objectForKey:@"visible"] isEqualToString:@"true"])
                continue;
            
            //item is WODigital, WODali or WODaliRGB
            if (([[output objectForKey:@"type"] isEqualToString:@"WODigital"] &&
                 [[output objectForKey:@"gtype"] isEqualToString:@"light"]) ||
                [[output objectForKey:@"type"] isEqualToString:@"WODali"] ||
                [[output objectForKey:@"type"] isEqualToString:@"WODaliRVB"] ||
                [[output objectForKey:@"gui_type"] isEqualToString:@"light"])
            {
                NSString *state = [output objectForKey:@"state"];
                if ([state isEqualToString:@"true"])
                {                    
                    [cacheLightsOn addObject:output];
                }
                else
                {
                    double value = [state doubleValue];
                    if (value > 0)
                        [cacheLightsOn addObject:output];
                }
            }
        }
    }
}

#pragma mark Singleton

+ (CalaosRequest *)sharedInstance 
{
    if (!sharedInstance) 
	{
        sharedInstance = [[super allocWithZone:NULL] init];
		[sharedInstance initialization];
    }
	
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone*)zone 
{
    return [[self sharedInstance] retain];
}

- (id)copyWithZone:(NSZone *)zone 
{
    return self;
}

- (id)retain 
{
    return self;
}

- (NSUInteger)retainCount 
{
    return NSUIntegerMax;
}

- (void)release 
{
    /*
     SHOULD NOT DO THIS HERE!
     this is a singleton instance
     
    [cacheScenarios release];
    [cacheLightsOn release];
    [cacheInputs release];
    [cacheOutputs release];
    
	[username release];
	[password release];
	[public_ip release];
	[private_ip release];
	[homeDict release];
	[queueRequests cancelAllOperations];
	[queueRequests release];*/
}

- (id)autorelease 
{
    return self;
}

#pragma mark Calaos Requests

- (void)loadHome
{
    //Now that we know the ip address of the remote calaos system,
    //we can load the entire home.
    NSURL *url = [NSURL URLWithString:[self computeCalaosUrl]];

    NSString *data = [NSString stringWithFormat:@"{\"cn_user\":\"%@\",\"cn_pass\":\"%@\",\"action\":\"get_home\"}", self.username, self.password];
    NSLog(@"Sending request: %@ to : %@", data, [self computeCalaosUrl]);
    
    [requestManager sendRequest:url 
                       withData:data 
                    andDelegate:self 
                    andSelector:@selector(requestGetHomeFinished:withUserData:)];
}

- (void)reloadHome
{
    //reload the entire home.
    if (at_home)
    {
        if (listenSocket)
        {
            [listenSocket setDelegate:nil];
            [listenSocket disconnect];
            [listenSocket release];
            listenSocket = nil;
        }
        
        if (detectSocket)
        {
            [detectSocket setDelegate:nil];
            [detectSocket close];
            [detectSocket release];
            detectSocket = nil;
        }
        
        if (detectSocketTX)
        {
            [detectSocketTX setDelegate:nil];
            [detectSocketTX close];
            [detectSocketTX release];
            detectSocketTX = nil;
        }
    }
    
    if (cacheTracks)
    {
        [cacheTracks release];
        cacheTracks = nil;
    }
    
    [self loadHome];
}

- (void)reconnectAll
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc postNotificationName:CalaosNotificationLoginFailed
                      object:nil
                    userInfo:nil];
    
    if (listenSocket)
    {
        [listenSocket setDelegate:nil];
        [listenSocket disconnect];
        [listenSocket release];
        listenSocket = nil;
    }
    
    if (detectSocket)
    {
        [detectSocket setDelegate:nil];
        [detectSocket close];
        [detectSocket release];
        detectSocket = nil;
    }
    
    if (detectSocketTX)
    {
        [detectSocketTX setDelegate:nil];
        [detectSocketTX close];
        [detectSocketTX release];
        detectSocketTX = nil;
    }
    
    if (cacheTracks)
    {
        [cacheTracks release];
        cacheTracks = nil;
    }
    
    [self connectWithUsername:self.username andPassword:self.password];
}

- (void)requestUpdatedAudioPlayerFinished:(NSString *)responseString withUserData:(id)userData
{		
	NSDictionary *dict = [responseString JSONValue];
	
	if (!dict)
        return;
    
    NSArray *audio_players = [dict objectForKey:@"audio_players"];
    
    if ([audio_players isKindOfClass:[NSNull class]])
        return;
    
    NSEnumerator *iter = [audio_players objectEnumerator];
    NSDictionary *player;
    while ((player = [iter nextObject])) 
    {
        int num = [[player objectForKey:@"player_id"] doubleValue];
        
        NSDictionary *aplayer = [self getAudioWithId:num];
        if (!aplayer)
            continue;
        
        //Update player infos
        [aplayer setValuesForKeysWithDictionary:player];
        
        NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [player objectForKey:@"player_id"], @"player_id",
                                  nil];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:CalaosNotificationAudioPlayerChanged
                          object:nil
                        userInfo:userData];
    }
}

- (void)updateAudioPlayer:(NSInteger)num
{    
    NSURL *url = [NSURL URLWithString:[self computeCalaosUrl]];    
    NSString *data = [NSString stringWithFormat:@"{\"cn_user\":\"%@\",\"cn_pass\":\"%@\",\"action\":\"get_state\",\"audio_players\": [\"%d\"]}", self.username, self.password, num];
 
    [requestManager sendRequest:url 
                       withData:data 
                    andDelegate:self 
                    andSelector:@selector(requestUpdatedAudioPlayerFinished:withUserData:)];
}

- (void)processListenNotification:(NSString *)calaos_event
{
    NSLog(@"Got Calaos Event: %@", calaos_event);
    
    NSMutableArray *tokens = [NSMutableArray arrayWithArray:[calaos_event componentsSeparatedByString: @" "]];
    
    if ([tokens count] < 2)
    {
        //drop, this is probably not a calaos event...
        return;
    }
    
    //Url decode parameters
    for (int i = 0;i < [tokens count];i++)
    {
        [tokens replaceObjectAtIndex:i withObject:[[tokens objectAtIndex:i] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    if ([[tokens objectAtIndex:0] isEqualToString:@"input"] ||
        [[tokens objectAtIndex:0] isEqualToString:@"output"])
    {
        NSMutableDictionary *dict;
        
        if ([[tokens objectAtIndex:0] isEqualToString:@"input"])
            dict = cacheInputs;
        else
            dict = cacheOutputs;
        
        NSArray *tokensChange = [[tokens objectAtIndex:2] componentsSeparatedByString: @":"];
        if ([tokensChange count] == 2)
        {
            NSString *value = [tokensChange objectAtIndex:1];
            NSString *key = [tokensChange objectAtIndex:0];
            
            [[dict objectForKey:[tokens objectAtIndex:1]] setValue:value forKey:key];
        }

        NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [tokens objectAtIndex:0], @"type",
                                  [tokens objectAtIndex:1], @"id",
                                  [tokens objectAtIndex:2], @"change",
                                  nil];
        
        //Notify IO change
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:CalaosNotificationIOChanged
                          object:nil
                        userInfo:userData];
    }
    else if ([[tokens objectAtIndex:0] isEqualToString:@"new_output"] ||
             [[tokens objectAtIndex:0] isEqualToString:@"new_input"])
    {
        //We don't notify here, but just reload home
        [self reloadHome];
    }
    else if ([[tokens objectAtIndex:0] isEqualToString:@"delete_output"] ||
             [[tokens objectAtIndex:0] isEqualToString:@"delete_input"])
    {
        //We don't notify here, but just reload home
        [self reloadHome];
    }
    else if ([[tokens objectAtIndex:0] isEqualToString:@"modify_room"])
    {
        //Notify modify room
        NSDictionary *userData;
        
        if ([[[tokens objectAtIndex:1] substringToIndex:14] isEqualToString:@"old_room_name:"])
        {
            userData = [NSDictionary dictionaryWithObjectsAndKeys:
                        [[tokens objectAtIndex:1] substringFromIndex:14], @"old_room_name",
                        [[tokens objectAtIndex:2] substringFromIndex:14], @"new_room_name",
                        [[tokens objectAtIndex:3] substringFromIndex:10], @"room_type",
                        nil];
        }
        else if ([[[tokens objectAtIndex:1] substringToIndex:14] isEqualToString:@"old_room_type:"])
        {
            userData = [NSDictionary dictionaryWithObjectsAndKeys:
                        [[tokens objectAtIndex:1] substringFromIndex:14], @"old_room_type",
                        [[tokens objectAtIndex:2] substringFromIndex:14], @"new_room_type",
                        [[tokens objectAtIndex:3] substringFromIndex:10], @"room_name",
                        nil];
        }
        else if ([[[tokens objectAtIndex:1] substringToIndex:14] isEqualToString:@"old_room_hits:"])
        {
            userData = [NSDictionary dictionaryWithObjectsAndKeys:
                        [[tokens objectAtIndex:1] substringFromIndex:14], @"old_room_hits",
                        [[tokens objectAtIndex:2] substringFromIndex:14], @"new_room_hits",
                        [[tokens objectAtIndex:3] substringFromIndex:10], @"room_name",
                        [[tokens objectAtIndex:3] substringFromIndex:10], @"room_type",
                        nil];
        }
        
        //Notify room change
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:CalaosNotificationRoomChanged
                          object:nil
                        userInfo:userData];
    }
    else if ([[tokens objectAtIndex:0] isEqualToString:@"delete_room"])
    {
        //We don't notify here, but just reload home
        [self reloadHome];
    }
    else if ([[tokens objectAtIndex:0] isEqualToString:@"new_room"])
    {
        //We don't notify here, but just reload home
        [self reloadHome];
    }
    else if ([[tokens objectAtIndex:0] isEqualToString:@"audio_volume"])
    {
        NSDictionary *player = [self getAudioWithId:[[tokens objectAtIndex:1] doubleValue]];
        
        if (!player)
            return;
        
        if ([tokens count] < 4)
            return;
        
        NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [tokens objectAtIndex:1], @"player_id",
                                  [tokens objectAtIndex:3], @"volume",
                                  nil];
        
        [player setValue:[tokens objectAtIndex:3] forKey:@"volume"];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:CalaosNotificationAudioVolumeChanged
                          object:nil
                        userInfo:userData];
    }
    else if ([[tokens objectAtIndex:0] isEqualToString:@"audio_status"])
    {
        NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [tokens objectAtIndex:1], @"player_id",
                                  [tokens objectAtIndex:2], @"status",
                                  nil];
        
        NSDictionary *player = [self getAudioWithId:[[tokens objectAtIndex:1] doubleValue]];
        
        if (!player)
            return;
        
        [player setValue:[tokens objectAtIndex:2] forKey:@"status"];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc postNotificationName:CalaosNotificationAudioStatusChanged
                          object:nil
                        userInfo:userData];
    }
    else if ([[tokens objectAtIndex:0] isEqualToString:@"audio"] &&
             [[tokens objectAtIndex:2] isEqualToString:@"songchanged"])
    {
        [self updateAudioPlayer:[[tokens objectAtIndex:1] doubleValue]];
    }
        
}

- (void)requestGetPollingFinished:(NSString *)responseString withUserData:(id)userData
{	
	NSDictionary *dict = [responseString JSONValue];
	
	if (!dict)
        return;
    
    NSArray *events = [dict objectForKey:@"events"];
	
    NSEnumerator *iter = [events objectEnumerator];
    NSString *msg;
    while ((msg = [iter nextObject])) 
    {
        if ([msg length] > 2)
            [self processListenNotification:msg];
    }
    
    //Start the "listen polling"
    [self performSelector:@selector(startListenPolling:) withObject:nil afterDelay:1.0];
}

- (void)startListenPolling:(id)unused
{
    NSURL *url = [NSURL URLWithString:[self computeCalaosUrl]];
    NSString *data = [NSString stringWithFormat:@"{\"cn_user\":\"%@\",\"cn_pass\":\"%@\",\"action\":\"poll_listen\",\"type\":\"get\",\"uuid\":\"%@\"}", self.username, self.password, uuid];
    
    [requestManager sendRequest:url 
                       withData:data 
                    andDelegate:self 
                    andSelector:@selector(requestGetPollingFinished:withUserData:)];
}

- (void)requestGetUUIDFinished:(NSString *)responseString withUserData:(id)userData
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];	
	NSDictionary *dict = [responseString JSONValue];
	
	if (!dict)
	{
		[nc postNotificationName:CalaosNotificationLoginFailed
						  object:nil
						userInfo:nil];
        
        return;
	}
	
    uuid = [[NSString stringWithString:[dict objectForKey:@"uuid"]] retain];
    
    //Start the "listen polling"
    [self performSelector:@selector(startListenPolling:) withObject:nil afterDelay:1.0];
}

- (void)requestGetHomeFinished:(NSString *)responseString withUserData:(id)userData
{
    [ASIHTTPRequest hideNetworkActivityIndicator];
    
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	self.homeDict = [responseString JSONValue];
	
    [self updateCache];
    
	if (!self.homeDict)
	{
		[nc postNotificationName:CalaosNotificationLoginFailed
						  object:nil
						userInfo:nil];
        
        return;
	}
	
	NSArray *_homeArray = [self.homeDict objectForKey:@"home"];
	
	if (_homeArray)
	{
		[nc postNotificationName:CalaosNotificationConnected
						  object:nil
						userInfo:nil];
        
        [nc postNotificationName:CalaosNotificationReload
						  object:nil
						userInfo:nil];
        
        if (at_home)
        {
            //connect the listening Socket for events
            NSArray *runLoopCommonModesArray = [NSArray arrayWithObject:NSRunLoopCommonModes];
            listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
            [listenSocket setRunLoopModes:runLoopCommonModesArray];
            
            NSError *err;
            if (![listenSocket connectToHost:self.private_ip onPort:CALAOS_TCP_PORT withTimeout:2.0 error:&err])
                NSLog(@"TCP Listen socket, can't connect: %@", err);
        }
        else
        {
            //Get a uuid for poll_listen
            NSURL *url = [NSURL URLWithString:[self computeCalaosUrl]];            
            NSString *data = [NSString stringWithFormat:@"{\"cn_user\":\"%@\",\"cn_pass\":\"%@\",\"action\":\"poll_listen\",\"type\":\"register\"}", self.username, self.password];
            
            [requestManager sendRequest:url
                               withData:data
                            andDelegate:self 
                            andSelector:@selector(requestGetUUIDFinished:withUserData:)];
        }
	}
	else 
	{
		[nc postNotificationName:CalaosNotificationLoginFailed
						  object:nil
						userInfo:nil];
	}
}

- (void)requestGetIPFinished:(NSString *)responseString withUserData:(id)userData
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
    if (!responseString)
    {
        if ([ASIHTTPRequest isNetworkReachableViaWWAN])
        {
            [ASIHTTPRequest hideNetworkActivityIndicator];
            
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            
            [nc postNotificationName:CalaosNotificationLoginFailed
                              object:nil
                            userInfo:nil];
        }
        else
        {
            [self startUDPSearch];
        }
    }
    
	NSDictionary *dict = [responseString JSONValue];
	
	if (!dict)
	{
		[nc postNotificationName:CalaosNotificationLoginFailed
						  object:nil
						userInfo:nil];
	}
	
	if ([[dict objectForKey:@"cn_user"] isEqualToString:self.username])
	{
		self.private_ip = [dict objectForKey:@"private_ip"];
		self.public_ip = [dict objectForKey:@"public_ip"];
		
		id boolNumber = [dict objectForKey:@"at_home"];
		if ((boolNumber) && [boolNumber isKindOfClass:[NSNumber class]])
			at_home = [boolNumber boolValue];
	
		[self loadHome];
	}
	else 
	{
        [ASIHTTPRequest hideNetworkActivityIndicator];
        
		[nc postNotificationName:CalaosNotificationLoginFailed
						  object:nil
						userInfo:nil];
	}

}

/*
- (void)requestFailed:(ASIHTTPRequest *)_request
{
    [ASIHTTPRequest hideNetworkActivityIndicator];
    
	NSError *error = [_request error];
	NSLog(@"Failed request: %@", [error localizedDescription]);
	
	[self reconnectAll];
}

- (void)requestIPFailed:(ASIHTTPRequest *)_request
{
	NSError *error = [_request error];
	NSLog(@"Failed request: %@", [error localizedDescription]);
	
    if ([ASIHTTPRequest isNetworkReachableViaWWAN])
    {
        [ASIHTTPRequest hideNetworkActivityIndicator];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
        [nc postNotificationName:CalaosNotificationLoginFailed
                          object:nil
                        userInfo:nil];
    }
    else
    {
        [self startUDPSearch];
    }
}
*/

- (void)connectWithUsername:(NSString *)_username andPassword:(NSString *)_password
{
    [ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];
    [ASIHTTPRequest showNetworkActivityIndicator];
    
	self.username = _username;
	self.password = _password;
	
	NSURL *url = [NSURL URLWithString:CalaosNetworkUrl];
	NSString *data = [NSString stringWithFormat:@"{\"cn_user\":\"%@\",\"cn_pass\":\"%@\",\"action\":\"get_ip\"}", self.username, self.password];
	
	[requestManager sendRequest:url 
                       withData:data
             verifyCertificates:YES 
                    andDelegate:self 
                    andSelector:@selector(requestGetIPFinished:withUserData:)];
}

- (void)requestCameraFinished:(NSData *)responseData withUserData:(id)userData
{
    id obj = [userData objectForKey:@"delegate"];
    SEL doneSelector = NSSelectorFromString([userData objectForKey:@"selector"]);
    
    if (obj && [obj respondsToSelector:doneSelector]) 
        [obj performSelector:doneSelector withObject:responseData];
}

- (void)getPictureForCamera:(NSInteger)num withDelegate:(id)obj andDoneSelector:(SEL)doneSelector
{
    if (num >= [[self getCameras] count] || num < 0)
    {
        if (obj && [obj respondsToSelector:doneSelector]) 
            [obj performSelector:doneSelector withObject:nil];
        
        return;
    }
    
    NSString *camUrl = [[[self getCameras] objectAtIndex:num] objectForKey:@"url_lowres"];
    
    if (!camUrl)
    {
        if (obj && [obj respondsToSelector:doneSelector]) 
            [obj performSelector:doneSelector withObject:NO withObject:nil];
        
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[self computeCameraUrl:camUrl]];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              obj, @"delegate", 
                              NSStringFromSelector(doneSelector), @"selector", 
                              nil];
    
    [requestManager sendRequest:url 
                       withData:nil
             verifyCertificates:NO
                    wantsString:NO
                    andDelegate:self 
                    andSelector:@selector(requestCameraFinished:withUserData:)
                    andUserData:userInfo];
}

- (void)getCoverForAudio:(NSInteger)num withDelegate:(id)obj andDoneSelector:(SEL)doneSelector
{
    NSDictionary *audio = [self getAudioWithId:num];
    
    if (!audio)
    {
        if (obj && [obj respondsToSelector:doneSelector]) 
            [obj performSelector:doneSelector withObject:nil];
        
        return;
    }
    
    NSString *coverUrl = [audio objectForKey:@"cover_url"];
    
    if (!coverUrl)
    {
        if (obj && [obj respondsToSelector:doneSelector]) 
            [obj performSelector:doneSelector withObject:NO withObject:nil];
        
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[self computeCameraUrl:coverUrl]];    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:obj, @"delegate", NSStringFromSelector(doneSelector), @"selector", nil];
    
    [requestManager sendRequest:url 
                       withData:nil
             verifyCertificates:NO
                    wantsString:NO
                    andDelegate:self 
                    andSelector:@selector(requestCameraFinished:withUserData:)
                    andUserData:userInfo];
}

- (void)requestSendFinished:(NSString *)responseString withUserData:(id)userData
{
    if (responseString)
        NSLog(@"Command sent, result: %@", responseString);
    else
        NSLog(@"Command failed !");
}

- (void)sendAction:(NSString *)type withId:(NSString *)calaos_id andValue:(NSString *)value
{
    NSURL *url = [NSURL URLWithString:[self computeCalaosUrl]];
    
    NSString *_type;
    if ([type isEqualToString:@"audio"])
        _type = [NSString stringWithFormat:@"\"player_id\":\"%@\"", calaos_id];
    else
        _type = [NSString stringWithFormat:@"\"id\":\"%@\"", calaos_id];
    
    NSString *data = [NSString stringWithFormat:@"{\"cn_user\":\"%@\",\"cn_pass\":\"%@\",\"action\":\"set_state\",\"type\":\"%@\",%@,\"value\":\"%@\"}", username, password, type, _type, value];
    
    [requestManager sendRequest:url 
                       withData:data
             verifyCertificates:NO
                    andDelegate:self 
                    andSelector:@selector(request)];
}

- (void)sendCameraAction:(NSString *)action forCamera:(NSString *)camera_id withValue:(NSString *)value
{
    NSURL *url = [NSURL URLWithString:[self computeCalaosUrl]];

    NSString *data = [NSString stringWithFormat:@"{\"cn_user\":\"%@\",\"cn_pass\":\"%@\",\"action\":\"set_state\",\"type\":\"camera\",\"camera_id\":\"%@\",\"camera_action\":\"%@\",\"value\":\"%@\"}", username, password, camera_id, action, value];
    
    [requestManager sendRequest:url 
                       withData:data
             verifyCertificates:NO
                    andDelegate:self 
                    andSelector:@selector(request)];
}

- (void)sendAudioFile:(NSString *)soundFilePath toPlayer:(NSInteger)playerId withDelegate:(id)obj andDoneSelector:(SEL)doneSelector
{
    NSLog(@"Sending file: %@", soundFilePath);
    /*
    NSString *data = [NSString stringWithFormat:@"{\"cn_user\":\"%@\",\"cn_pass\":\"%@\",\"action\":\"play_file\",\"player_id\":\"%d\"}", username, password, playerId];
    
    NSURL *url = [NSURL URLWithString:[self computeCalaosUrl]];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(requestSendFinishedCallback:)];
    [request setDidFailSelector:@selector(requestSendFailedCallback:)];
    [request setShouldAttemptPersistentConnection:NO];
    request.validatesSecureCertificate = FALSE;
    
    NSLog(@"Sending request: %@", data);

    [request setPostValue:data forKey:@"json"];
    [request setFile:soundFilePath forKey:@"file"];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:obj, @"delegate", NSStringFromSelector(doneSelector), @"selector", nil];
    request.userInfo = userInfo;
    
    [queueRequests addOperation:request];*/
}

- (void)requestSendFinishedCallback:(ASIHTTPRequest *)_request
{
    id obj = [_request.userInfo objectForKey:@"delegate"];
    SEL doneSelector = NSSelectorFromString([_request.userInfo objectForKey:@"selector"]);
    
    if (obj && [obj respondsToSelector:doneSelector]) 
        [obj performSelector:doneSelector withObject:[_request responseData]];
}

- (void)requestSendFailedCallback:(ASIHTTPRequest *)_request
{
    id obj = [_request.userInfo objectForKey:@"delegate"];
    SEL doneSelector = NSSelectorFromString([_request.userInfo objectForKey:@"selector"]);
    
    if (obj && [obj respondsToSelector:doneSelector]) 
        [obj performSelector:doneSelector withObject:nil];
}

- (NSString *)getPlaylistTrackTitle:(NSInteger)track_id forPlayer:(NSInteger)player_id;
{
    NSLog(@"Getting track %d for player %d", track_id, player_id);
    
    if (cacheTracks && [cacheTracks count] != [self getAudioPlayersCount])
    {
        [cacheTracks release];
        cacheTracks = nil;
    }
    
    if (!cacheTracks)
    {
        cacheTracks = [[NSMutableArray alloc] init];
        
        for (int i = 0;i < [self getAudioPlayersCount];i++)
        {
            [cacheTracks addObject:[NSMutableArray array]];
        }
    }
    
    NSMutableArray *playlist = [cacheTracks objectAtIndex:player_id];
    
    if (track_id >= [playlist count])
    {
        NSInteger from, num_count = 20;
        
        if (isLoadingTracks > 0)
        {
            if (track_id > loadTracksCacheCount)
                from = loadTracksCacheCount;
            else
                return nil;
        }
        else
        {
            from = [playlist count];
        }
        
        if (track_id > from + num_count)
            num_count = track_id - from + 20;
     
        //Need to load more tracks
        NSURL *url = [NSURL URLWithString:[self computeCalaosUrl]];
        
        isLoadingTracks++;
        
        NSString *data = [NSString stringWithFormat:@"{\"cn_user\":\"%@\",\"cn_pass\":\"%@\",\"action\":\"get_playlist\",\"player_id\":\"%d\",\"from\":\"%d\",\"to\":\"%d\"}", username, password, player_id, from, from + num_count];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInteger:player_id], @"player_id",
                                    nil];
        
        [requestManager sendRequest:url 
                           withData:data
                 verifyCertificates:NO
                        andDelegate:self 
                        andSelector:@selector(requestGetPlaylistFinished:withUserData:)
                        andUserData:userInfo];
        
        loadTracksCacheCount = from + num_count;
        
        return nil;
    }
    
    return [playlist objectAtIndex:track_id];
}

- (void)requestGetPlaylistFinished:(NSString *)responseString withUserData:(id)userData
{	
	NSDictionary *dict = [responseString JSONValue];

    NSString *title = @"";
    
    NSInteger player_id = [[userData objectForKey:@"player_id"] integerValue];
    NSMutableArray *playlist = [cacheTracks objectAtIndex:player_id];
    
    isLoadingTracks--;
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    if (playlist)
    {
        NSArray *items = [dict objectForKey:@"items"];
        
        NSEnumerator *enumerator = [items objectEnumerator];
        NSDictionary *item;
        while ((item = [enumerator nextObject])) 
        {
            NSInteger it = [[item objectForKey:@"item"] doubleValue];
            
            if ([item objectForKey:@"artist"] && [item objectForKey:@"title"])
                title = [NSString stringWithFormat:@"%@ - %@", [item objectForKey:@"artist"], [item objectForKey:@"title"]];
            
            if ([item objectForKey:@"artist"])
                title = [NSString stringWithFormat:@"%@", [item objectForKey:@"artist"]];
            
            if ([item objectForKey:@"title"])
                title = [NSString stringWithFormat:@"%@", [item objectForKey:@"title"]];
            
            //update cache
            if (it >= [playlist count])
            {
                
                while (it > [playlist count])
                {
                    [playlist addObject:[NSNull null]];
                }
                
                [playlist addObject:title];
            }
            else
            {
                [playlist replaceObjectAtIndex:it withObject:title];
            }
            
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInteger:player_id], @"player_id",
                                      [NSNumber numberWithInteger:it], @"track_id",
                                      title, @"title",
                                      nil];
            
            [nc postNotificationName:CalaosNotificationAudioPlaylistItemUpdated
                              object:nil
                            userInfo:userInfo];
        }
    }
}

#pragma mark UDP Socket delegate

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"Error, UDP packet not sent : %@", [error localizedDescription]);
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)host port:(UInt16)port
{
    [detectSocket receiveWithTimeout:-1 tag:0];
    
    NSString *sdata = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    if ([sdata length] < 10)
    {
        [sdata release];
        
        return FALSE;
    }
    
    if ([[sdata substringToIndex:10] isEqualToString:@"CALAOS_IP "])
    {
        NSMutableString *str = [NSMutableString stringWithString:[sdata substringFromIndex:10]];
        at_home = YES;
        
        //Clean ending \0 chars
        while ([str characterAtIndex:[str length] - 1] == '\0')
            [str deleteCharactersInRange:NSMakeRange([str length] - 1, 1)];

        self.private_ip = str;
        str = nil;
        
        NSLog(@"Found Calaos IP on LAN: %@", self.private_ip);
        
        [detectSocket setDelegate:nil];
        [detectSocket close];
        [detectSocket autorelease];
        detectSocket = nil;
        
        [detectSocketTX setDelegate:nil];
        [detectSocketTX close];
        [detectSocketTX autorelease];
        detectSocketTX = nil;
        
        [detectTimer invalidate];
        detectTimer = nil;
        
        [self loadHome];
    }
    
    [sdata release];
    
    return TRUE;
}

#pragma mark Listen socket delegate

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Connection to %@ done.", host);

    NSLog(@"Login TCP protocol");
    
    NSString *data = [NSString stringWithFormat:@"login %@ %@\n", username, password]; 
    [listenSocket writeData:[data dataUsingEncoding:NSASCIIStringEncoding] 
                withTimeout:-1 
                        tag:TAG_LOGIN];
    
    [listenSocket readDataWithTimeout:2.0 tag:TAG_LOGIN];
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    NSLog(@"Disconnection happened: %@", err);
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSMutableString *sdata = [[NSMutableString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    
    NSLog(@"Data read: %@", sdata);
    
    switch (tag) 
    {
        case TAG_LOGIN:
        {
            //Clean ending chars
            while ([sdata characterAtIndex:[sdata length] - 1] == '\n' ||
                   [sdata characterAtIndex:[sdata length] - 1] == '\r')
                [sdata deleteCharactersInRange:NSMakeRange([sdata length] - 1, 1)];
            
            if ([[sdata stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] 
                 isEqualToString:[NSString stringWithFormat:@"login %@ ok", username]])
            {
                NSLog(@"Login OK.");
                
                NSString *data = @"listen\n"; 
                [listenSocket writeData:[data dataUsingEncoding:NSASCIIStringEncoding] 
                            withTimeout:-1 
                                    tag:TAG_LISTENDATA];
                
                [listenSocket readDataWithTimeout:-1 tag:TAG_LISTENDATA];
            }
            else
            {
                NSLog(@"Login Failed!");
                
                NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
                
                [nc postNotificationName:CalaosNotificationLoginFailed
                                  object:nil
                                userInfo:nil];
            }
            break;
        }
        case TAG_LISTENDATA:
        {
            [listenSocket readDataWithTimeout:-1 tag:TAG_LISTENDATA];
            
            NSRange r = [sdata rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"]];
            if (r.location == NSNotFound)
            {
                //We have not a complete packet yet, buffurize it.
                [listenBuffer stringByAppendingString:sdata];
                
                NSLog(@"Listen socket: Bufferize data");
                
                break;
            }
            
            if ([listenBuffer length] > 0)
            {
                sdata = listenBuffer;
                listenBuffer = [NSMutableString string];
            }
            
            //Clean ending chars
            while ([sdata characterAtIndex:[sdata length] - 1] == '\n' ||
                   [sdata characterAtIndex:[sdata length] - 1] == '\r' ||
                   [sdata characterAtIndex:[sdata length] - 1] == '\0')
                [sdata deleteCharactersInRange:NSMakeRange([sdata length] - 1, 1)];
            
            [sdata replaceOccurrencesOfString:@"\n\r" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, [sdata length])];
            [sdata replaceOccurrencesOfString:@"\r" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, [sdata length])];
                                                                                                                   
            NSArray *tokens = [sdata componentsSeparatedByString: @"\n"];
            
            NSEnumerator *iter = [tokens objectEnumerator];
            NSString *msg;
            while ((msg = [iter nextObject])) 
            {
                [self processListenNotification:msg];
            }
            
            break;
        }
        default:
            break;
    }
    
    [sdata release];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"Data written");
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"Socket disconnected");
    
  	[self reconnectAll];
}

@end
