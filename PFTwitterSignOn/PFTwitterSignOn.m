//
//  PFTwitterSignOn.m
//  PFTwitterSignOnExample
//
//  Created by Jesse Ditson on 1/18/14.
//  Copyright (c) 2014 Prix Fixe. All rights reserved.
//

#import "PFTwitterSignOn.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import <LVTwitterOAuthClient/LVTwitterOAuthClient.h>
#import <AFOAuth1Client/AFOAuth1Client.h>
#import <AFNetworking/AFNetworking.h>
#import "PFTwitterAccountSelectDialog.h"

#define kUserInfoURL @"https://api.twitter.com/1.1/account/verify_credentials.json"
#define kUserInfoParams @{@"include_entities" : [NSNumber numberWithInteger:0], @"skip_status" : [NSNumber numberWithInteger:1]}

@interface PFTwitterSignOn()

@end

static ACAccountStore *__accountStore;
static PFTwitterSignOn *__sharedInstance;

@implementation PFTwitterSignOn

+ (PFTwitterSignOn *)sharedInstance
{
    if (!__sharedInstance) {
        __sharedInstance = [[PFTwitterSignOn alloc] init];
    }
    return __sharedInstance;
}

+ (ACAccountStore *)accountStore
{
    if (!__accountStore) {
        __accountStore = [[ACAccountStore alloc] init];
    }
    return __accountStore;
}

+ (void)setCredentialsWithConsumerKey:(NSString *)key andSecret:(NSString *)secret
{
    PFTwitterSignOn *signOnInstance = [self sharedInstance];
    signOnInstance.consumerKey = key;
    signOnInstance.consumerSecret = secret;
}

+ (void)requestAuthenticationInView:(UIView *)view andCompletion:(twitterAuthenticationCallback)callback
{
    [self requestAuthenticationWithSelectCallback:^(NSArray *accounts, twitterAccountCallback callback){
        NSMutableArray *accountNames = [[accounts valueForKey:@"username"] mutableCopy];
        [accountNames enumerateObjectsUsingBlock:^(NSString *accountName, NSUInteger index, BOOL *stop){
            [accountNames replaceObjectAtIndex:index withObject:[NSString stringWithFormat:@"@%@",accountName]];
        }];
        [PFTwitterAccountSelectDialog showSelectDialogInView:view withItems:accountNames cancelButtonTitle:@"Cancel" confirmBlock:^(NSInteger selectedIndex){
            callback([accounts objectAtIndex:selectedIndex]);
        } cancelBlock:nil];
    } andCompletion:callback];
}

+ (void)requestAuthenticationWithSelectCallback:(twitterSelectAccountCallback)selectCallback andCompletion:(twitterAuthenticationCallback)callback
{
    NSParameterAssert(selectCallback);
    PFTwitterSignOn *signOnInstance = [self sharedInstance];
    NSAssert(signOnInstance.consumerKey, @"You must set a shared consumer key before requesting twitter authentication");
    NSAssert(signOnInstance.consumerSecret, @"You must set a shared consumer secret before requesting twitter authentication");
    ACAccountStore *accountStore = [self accountStore];
    ACAccountType *twitterType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PF_TWITTER_SIGN_ON_LOADING_STARTED_NOTIFICATION object:nil userInfo:@{@"action" : @"selectAccount"}];
    });
    [accountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PF_TWITTER_SIGN_ON_LOADING_ENDED_NOTIFICATION object:nil userInfo:@{@"action" : @"selectAccount"}];
            NSArray *accounts = [accountStore accountsWithAccountType:twitterType];
            if (error && callback) {
                callback(nil, error);
                return;
            } else if (granted && accounts.count) {
                if ([accounts count] > 1) {
                    // go back to the main thread before returning to a consumer
                    selectCallback(accounts,^(ACAccount *account){
                        [self signInWithAccount:account andCallback:callback];
                    });
                    return;
                } else if([accounts count] == 1){
                    [self signInWithAccount:[accounts firstObject] andCallback:callback];
                    return;
                }
            }
            // if we haven't broken out by now, sign in with the web view by default.
            [self signInWithWebView:callback];
        });
    }];
}

+ (void)signInWithAccount:(ACAccount *)account andCallback:(twitterAuthenticationCallback)callback
{
    PFTwitterSignOn *signOnInstance = [self sharedInstance];
    LVTwitterOAuthClient *twitterClient = [[LVTwitterOAuthClient alloc] initWithConsumerKey:signOnInstance.consumerKey andConsumerSecret:signOnInstance.consumerSecret];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PF_TWITTER_SIGN_ON_LOADING_STARTED_NOTIFICATION object:nil userInfo:@{@"action" : @"fetchCredentials"}];
    });
    [twitterClient requestTokensForAccount:account withHandler:^(NSString *oAuthAccessToken, NSString *oAuthTokenSecret, NSError *error){
        if (!oAuthAccessToken || !oAuthTokenSecret) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:PF_TWITTER_SIGN_ON_LOADING_ENDED_NOTIFICATION object:nil userInfo:@{@"action" : @"fetchCredentials"}];
                NSError *error = [NSError errorWithDomain:@"com.prixfixe.PFTwitterSignOn" code:500 userInfo:@{NSLocalizedDescriptionKey : @"Invalid key or secret - unable to retrieve user access token & secret."}];
                callback(nil,error);
            });
        } else {
            SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:kUserInfoURL] parameters:kUserInfoParams];
            [request setAccount:account];
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:PF_TWITTER_SIGN_ON_LOADING_ENDED_NOTIFICATION object:nil userInfo:@{@"action" : @"fetchCredentials"}];
                    if (responseData) {
                        if (urlResponse.statusCode >= 200 && urlResponse.statusCode < 300) {
                            NSError *jsonError;
                            NSMutableDictionary *userData = [[NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&jsonError] mutableCopy];
                            if (userData) {
                                [userData setObject:oAuthAccessToken forKey:@"accessToken"];
                                [userData setObject:oAuthTokenSecret forKey:@"tokenSecret"];
                                callback(userData,error);
                            } else {
                                // Our JSON deserialization went awry
                                callback(nil, jsonError);
                            }
                        } else {
                            // The server did not respond ... were we rate-limited?
                            callback(nil, error);
                        }
                    } else {
                        callback(nil, error);
                    }
                });
            }];
        }
    }];
}

+ (void)signInWithWebView:(twitterAuthenticationCallback)callback
{
    PFTwitterSignOn *signOnInstance = [self sharedInstance];
    AFOAuth1Client *twitterClient = [[AFOAuth1Client alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.twitter.com/"] key:signOnInstance.consumerKey secret:signOnInstance.consumerSecret];
    // read a valid callback URL from info.plist
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *urlScheme = [[[[mainBundle objectForInfoDictionaryKey:@"CFBundleURLTypes"] firstObject] objectForKey:@"CFBundleURLSchemes"] firstObject];
    NSURL *callbackURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://pftwittersuccess",urlScheme]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PF_TWITTER_SIGN_ON_LOADING_STARTED_NOTIFICATION object:nil userInfo:@{@"action" : @"fetchCredentialsViaWeb"}];
    });
    // Your application will be sent to the background until the user authenticates, and then the app will be brought back using the callback URL
    [twitterClient authorizeUsingOAuthWithRequestTokenPath:@"oauth/request_token" userAuthorizationPath:@"oauth/authorize" callbackURL:callbackURL accessTokenPath:@"oauth/access_token" accessMethod:@"POST" scope:nil success:^(AFOAuth1Token *accessToken, id responseObject) {
        [twitterClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [twitterClient getPath:kUserInfoURL parameters:kUserInfoParams success:^(AFHTTPRequestOperation *operation, NSDictionary *userInfo){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:PF_TWITTER_SIGN_ON_LOADING_ENDED_NOTIFICATION object:nil userInfo:@{@"action" : @"fetchCredentialsViaWeb"}];
                NSMutableDictionary *userData = [userInfo mutableCopy];
                [userData setObject:accessToken.key forKey:@"accessToken"];
                [userData setObject:accessToken.secret forKey:@"tokenSecret"];
                callback(userData,nil);
            });
        } failure:^(AFHTTPRequestOperation *operation, NSError *error){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:PF_TWITTER_SIGN_ON_LOADING_ENDED_NOTIFICATION object:nil userInfo:@{@"action" : @"fetchCredentialsViaWeb"}];
                callback(nil,error);
            });
        }];
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:PF_TWITTER_SIGN_ON_LOADING_ENDED_NOTIFICATION object:nil userInfo:@{@"action" : @"fetchCredentialsViaWeb"}];
            callback(nil,error);
        });
    }];
}

@end