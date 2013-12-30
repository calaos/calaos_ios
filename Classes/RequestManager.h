//
//  RequestManager.h
//  CalaosHome
//
//  Created by Raoul on 09/05/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ASIHTTPRequest;
@class ASINetworkQueue;

@interface RequestManager : NSObject 
{
    ASINetworkQueue *queueRequests;
}

- (void)sendRequest:(NSURL *)url withData:(NSString *)data andDelegate:(id)delegate andSelector:(SEL)selector;
- (void)sendRequest:(NSURL *)url withData:(NSString *)data andDelegate:(id)delegate andSelector:(SEL)selector andUserData:(id)userData;
- (void)sendRequest:(NSURL *)url withData:(NSString *)data verifyCertificates:(BOOL)verifyCerts andDelegate:(id)delegate andSelector:(SEL)selector;
- (void)sendRequest:(NSURL *)url withData:(NSString *)data verifyCertificates:(BOOL)verifyCerts andDelegate:(id)delegate andSelector:(SEL)selector andUserData:(id)userData;
- (void)sendRequest:(NSURL *)url withData:(NSString *)data verifyCertificates:(BOOL)verifyCerts wantsString:(BOOL)strWanted andDelegate:(id)delegate andSelector:(SEL)selector andUserData:(id)userData;


@end
