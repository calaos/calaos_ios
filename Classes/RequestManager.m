//
//  RequestManager.m
//  CalaosHome
//
//  Created by Raoul on 09/05/11.
//  Copyright 2011 Calaos. All rights reserved.
//

#import "RequestManager.h"
#import "ASIHTTPRequest.h"
#import "ASINetworkQueue.h"
#import "ASIFormDataRequest.h"

@implementation RequestManager

- (id)init
{
	self = [super init];

    queueRequests = [[ASINetworkQueue alloc] init];
	[queueRequests go];
    
	return self;
}

- (void)dealloc
{
    [queueRequests release];
    
    [super dealloc];
}

- (void)sendRequest:(NSURL *)url withData:(NSString *)data andDelegate:(id)delegate andSelector:(SEL)selector
{
    [self sendRequest:url withData:data verifyCertificates:NO wantsString:YES andDelegate:delegate andSelector:selector andUserData:nil];
}

- (void)sendRequest:(NSURL *)url withData:(NSString *)data andDelegate:(id)delegate andSelector:(SEL)selector andUserData:(id)userData
{
    [self sendRequest:url withData:data verifyCertificates:NO wantsString:YES andDelegate:delegate andSelector:selector andUserData:nil];    
}

- (void)sendRequest:(NSURL *)url withData:(NSString *)data verifyCertificates:(BOOL)verifyCerts andDelegate:(id)delegate andSelector:(SEL)selector
{
    [self sendRequest:url withData:data verifyCertificates:NO wantsString:YES andDelegate:delegate andSelector:selector andUserData:nil];
}

- (void)sendRequest:(NSURL *)url withData:(NSString *)data verifyCertificates:(BOOL)verifyCerts andDelegate:(id)delegate andSelector:(SEL)selector andUserData:(id)userData
{
    [self sendRequest:url withData:data verifyCertificates:NO wantsString:YES andDelegate:delegate andSelector:selector andUserData:userData];
}

- (void)requestFinished:(ASIHTTPRequest *)_request
{
    id obj = [_request.userInfo objectForKey:@"delegate"];
    SEL doneSelector = NSSelectorFromString([_request.userInfo objectForKey:@"selector"]);
    id userData = [_request.userInfo objectForKey:@"userData"];
    BOOL stringWanted = [[_request.userInfo objectForKey:@"stringWanted"] boolValue];
    
    if (obj && [obj respondsToSelector:doneSelector])
    {
        if (stringWanted)
            [obj performSelector:doneSelector withObject:[_request responseString] withObject:userData];
        else
            [obj performSelector:doneSelector withObject:[_request responseData] withObject:userData];
    }
}

- (void)requestFailed:(ASIHTTPRequest *)_request
{
    NSDictionary *userInfo = _request.userInfo;
    
    NSError *error = [_request error];
	NSLog(@"Failed request: %@", [error localizedDescription]);
    
    int retryCount = [[userInfo objectForKey:@"retryCount"] intValue];
    
    if (retryCount > 10)
    {
        NSLog(@"Request failed after %d tries. Give up...", retryCount);
        
        id obj = [_request.userInfo objectForKey:@"delegate"];
        SEL doneSelector = NSSelectorFromString([_request.userInfo objectForKey:@"selector"]);
        id userData = [_request.userInfo objectForKey:@"userData"];
        
        if (obj && [obj respondsToSelector:doneSelector]) 
            [obj performSelector:doneSelector withObject:nil withObject:userData];
    }

    NSLog(@"Request failed.... retrying !");
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[userInfo objectForKey:@"url"]];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(requestFinished:)];
    [request setDidFailSelector:@selector(requestFailed:)];
    [request setShouldAttemptPersistentConnection:NO];
    request.validatesSecureCertificate = [[userInfo objectForKey:@"verifyCerts"] boolValue];
//    [request setTimeOutSeconds:10.0];
    [request setNumberOfTimesToRetryOnTimeout:10];
    
    retryCount++;
    [userInfo setValue:[NSNumber numberWithInt:retryCount] forKey:@"retryCount"];
    request.userInfo = userInfo;
    
    [request appendPostData:[[userInfo objectForKey:@"data"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [queueRequests addOperation:request];
}

- (void)sendRequest:(NSURL *)url withData:(NSString *)data verifyCertificates:(BOOL)verifyCerts wantsString:(BOOL)strWanted andDelegate:(id)delegate andSelector:(SEL)selector andUserData:(id)userData
{
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setDidFinishSelector:@selector(requestFinished:)];
    [request setDidFailSelector:@selector(requestFailed:)];
    [request setShouldAttemptPersistentConnection:NO];
    request.validatesSecureCertificate = verifyCerts;
//    [request setTimeOutSeconds:10.0];
    [request setNumberOfTimesToRetryOnTimeout:10];
    
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              delegate, @"delegate", 
                              NSStringFromSelector(selector), @"selector",
                              url, @"url",
                              [NSNumber numberWithBool:verifyCerts], @"verifyCerts",
                              [NSNumber numberWithInt:0], @"retryCount",
                              [NSNumber numberWithBool:strWanted], @"stringWanted",
                              nil];
    
    NSLog(@"Request to url: %@", [url absoluteString]);
    
    if (data)
        [userInfo setValue:data forKey:@"data"];
    if (userData)
        [userInfo setValue:userData forKey:@"userData"];
    
    request.userInfo = userInfo;
    
    if (data)
    {
        [request appendPostData:[data dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSLog(@"Request : %@", data);
    }
    
    [queueRequests addOperation:request];
}

@end
