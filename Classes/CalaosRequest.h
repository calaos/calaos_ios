//
//  CalaosRequest.h
//  CalaosHome
//
//  Created by Raoul on 18/02/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "AsyncUdpSocket.h"
#import "RequestManager.h"

extern NSString *const CalaosNotificationConnected;
extern NSString *const CalaosNotificationLoginFailed;

extern NSString *const CalaosNotificationIOChanged;
extern NSString *const CalaosNotificationRoomChanged;

extern NSString *const CalaosNotificationReload;

extern NSString *const CalaosNotificationAudioVolumeChanged;
extern NSString *const CalaosNotificationAudioStatusChanged;
extern NSString *const CalaosNotificationAudioPlayerChanged;
extern NSString *const CalaosNotificationAudioPlaylistChanged;
extern NSString *const CalaosNotificationAudioPlaylistItemUpdated;

@interface CalaosRequest : NSObject <AsyncSocketDelegate, 
                                     AsyncUdpSocketDelegate> 
{
    RequestManager *requestManager;
    
    AsyncSocket *listenSocket;
    NSMutableString *listenBuffer;
    
    AsyncUdpSocket *detectSocket;
    AsyncUdpSocket *detectSocketTX;
    NSTimer *detectTimer;
    int detectCount;
	
	NSString *public_ip;
	NSString *private_ip;
	NSString *username;
	NSString *password;
	
	BOOL at_home;
	
	NSDictionary *homeDict;
    
    NSString *uuid;
    
    //Lists of input/output ids
    NSMutableArray *cacheScenarios;
    NSMutableArray *cacheLightsOn;
    NSMutableArray *homeArray; //Sorted by hits
    
    //hash tables containing all io
    NSMutableDictionary *cacheInputs;
    NSMutableDictionary *cacheOutputs;
    
    NSMutableArray *cacheTracks;
    NSInteger isLoadingTracks;
    NSInteger loadTracksCacheCount;
}

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *public_ip;
@property (nonatomic, copy) NSString *private_ip;
@property (nonatomic, copy) NSDictionary *homeDict;

+ (id)sharedInstance;

- (void)connectWithUsername:(NSString *)username andPassword:(NSString *)password;

- (NSDictionary *)getInputs;
- (NSDictionary *)getOutputs;
- (NSArray *)getScenarios;
- (NSArray *)getLightsOn;
- (NSArray *)getHome;
- (NSArray *)getCameras;
- (NSInteger)getAudioPlayersCount;
- (NSDictionary *)getAudioWithId:(NSInteger)player_id;
- (NSString *)getConsigneForInput:(NSString *)input_id;

- (void)sendAction:(NSString *)type withId:(NSString *)calaos_id andValue:(NSString *)value;
- (void)sendCameraAction:(NSString *)action forCamera:(NSString *)camera_id withValue:(NSString *)value;

- (void)getPictureForCamera:(NSInteger)num withDelegate:(id)obj andDoneSelector:(SEL)doneSelector;
- (void)getCoverForAudio:(NSInteger)num withDelegate:(id)obj andDoneSelector:(SEL)doneSelector;

- (void)sendAudioFile:(NSString *)soundFilePath toPlayer:(NSInteger)playerId withDelegate:(id)obj andDoneSelector:(SEL)doneSelector;

- (NSString *)getPlaylistTrackTitle:(NSInteger)track_id forPlayer:(NSInteger)player_id;

@end
