//
//  PFTwitterSignOn.h
//  PFTwitterSignOnExample
//
//  Created by Jesse Ditson on 1/18/14.
//  Copyright (c) 2014 Prix Fixe. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PF_TWITTER_SIGN_ON_LOADING_STARTED_NOTIFICATION @"PFTwitterSignOnLoadingStartedNotification"
#define PF_TWITTER_SIGN_ON_LOADING_ENDED_NOTIFICATION @"PFTwitterSignOnLoadingEndedNotification"

@class ACAccount;

typedef void (^twitterAuthenticationCallback)(NSDictionary *accountInfo, NSError *error);
typedef void (^twitterAccountCallback)(ACAccount *account);
typedef void (^twitterSelectAccountCallback)(NSArray *accounts, twitterAccountCallback callback);

@interface PFTwitterSignOn : NSObject

@property (nonatomic, strong) NSString *consumerKey;
@property (nonatomic, strong) NSString *consumerSecret;

+ (PFTwitterSignOn *)sharedInstance;

+ (void)setCredentialsWithConsumerKey:(NSString *)key andSecret:(NSString *)secret;

+ (void)requestAuthenticationWithSelectCallback:(twitterSelectAccountCallback)selectCallback andCompletion:(twitterAuthenticationCallback)callback;

+ (void)requestAuthenticationInView:(UIView *)view andCompletion:(twitterAuthenticationCallback)callback;

@end
