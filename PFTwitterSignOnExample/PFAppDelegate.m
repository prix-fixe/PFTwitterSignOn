//
//  PFAppDelegate.m
//  PFTwitterSignOnExample
//
//  Created by Jesse Ditson on 1/18/14.
//  Copyright (c) 2014 Prix Fixe. All rights reserved.
//

#import "PFAppDelegate.h"
#import <AFOAuth1Client/AFOAuth1Client.h>
#import "PFTwitterAccountSelectDialog.h"
#import "PFTwitterSignOn.h"

@interface PFAppDelegate()
{
    UIView *loadingView;
}

@property (nonatomic, strong) UIViewController *rootViewController;

@end

@implementation PFAppDelegate

#pragma mark - request access to an account.

- (void)setupTwitterSignOn
{
    [PFTwitterSignOn setCredentialsWithConsumerKey:@"<your_consumer_key>" andSecret:@"<your_consumer_secret>"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLoadingWithNotification:) name:PF_TWITTER_SIGN_ON_LOADING_STARTED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showLoadingWithNotification:) name:PF_TWITTER_SIGN_ON_LOADING_ENDED_NOTIFICATION object:nil];
}

#pragma mark - 2 examples of signing in

- (void)requestAccessWithView
{
    [PFTwitterSignOn requestAuthenticationInView:_rootViewController.view andCompletion:^(NSDictionary *accountInfo, NSError *error){
        [self showCompleteMessageWithAccount:accountInfo error:error];
    }];
}

- (void)requestAccessWithCallback
{
    [PFTwitterSignOn requestAuthenticationWithSelectCallback:^(NSArray *accounts, twitterAccountCallback callback){
        // Here, you can replace this view with a custom view, or store a pointer to the callback and fire it later with a twitter account.
        NSMutableArray *accountNames = [[accounts valueForKey:@"username"] mutableCopy];
        [accountNames enumerateObjectsUsingBlock:^(NSString *accountName, NSUInteger index, BOOL *stop){
            [accountNames replaceObjectAtIndex:index withObject:[NSString stringWithFormat:@"@%@",accountName]];
        }];
        [PFTwitterAccountSelectDialog showSelectDialogInView:_rootViewController.view withItems:accountNames cancelButtonTitle:@"Nevermind" confirmBlock:^(NSInteger selectedIndex){
            callback([accounts objectAtIndex:selectedIndex]);
        } cancelBlock:nil];
    } andCompletion:^(NSDictionary *accountInfo, NSError *error){
        [self showCompleteMessageWithAccount:accountInfo error:error];
    }];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kAFApplicationLaunchedWithURLNotification object:nil userInfo:@{kAFApplicationLaunchOptionsURLKey: url}]];
    
    return YES;
}

- (void)showCompleteMessageWithAccount:(NSDictionary *)accountInfo error:(NSError *)error
{
    NSString *message;
    NSString *title;
    if (error) {
        title = @"Error Signing In";
        message = [NSString stringWithFormat:@"Error message : %@",[error localizedDescription]];
    } else {
        title = @"Successfully Signed In";
        message = [NSString stringWithFormat:@"Account info: \n%@",[accountInfo description]];
    }
    [self showMessage:message withTitle:title];
}

- (void)showMessage:(NSString *)message withTitle:(NSString *)title
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showLoadingWithNotification:(NSNotification *)notification
{
    BOOL loading = [[notification name] isEqualToString:PF_TWITTER_SIGN_ON_LOADING_STARTED_NOTIFICATION];
    [self showLoading:loading];
}

- (void)showLoading:(BOOL)loading
{
    if (loading && !loadingView) {
        CGRect viewFrame = _rootViewController.view.frame;
        float size = 120;
        loadingView = [[UIView alloc] initWithFrame:CGRectMake((viewFrame.size.width / 2) - (size/2), (viewFrame.size.height / 2) - (size/2), size, size)];
        [loadingView.layer setCornerRadius:8.f];
        [loadingView setClipsToBounds:YES];
        UIView *bgView = [[UIView alloc] initWithFrame:loadingView.bounds];
        [bgView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.7f]];
        [loadingView addSubview:bgView];
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [spinner setFrame:CGRectMake((loadingView.bounds.size.width / 2) - (spinner.frame.size.width / 2), (loadingView.bounds.size.height / 2) - (spinner.frame.size.height / 2), spinner.frame.size.width, spinner.frame.size.height)];
        [spinner startAnimating];
        [loadingView addSubview:spinner];
        [_rootViewController.view addSubview:loadingView];
    } else if([loadingView superview]){
        [loadingView removeFromSuperview];
        loadingView = nil;
    }
}

#pragma mark - drawing

- (void)drawMainView:(UIView *)mainView
{
    UIImage *image = [UIImage imageNamed:@"PrixFixe_Twitter"];
    CGRect imageRect = CGRectMake((mainView.bounds.size.width / 2) - (image.size.width / 2), 44, image.size.width, image.size.height);
    UIImageView *imgView = [[UIImageView alloc ]initWithImage:image];
    [imgView setFrame:imageRect];
    [mainView addSubview:imgView];
    
    CGRect buttonRect = mainView.bounds;
    buttonRect.size.height = 60;
    buttonRect.origin.x = buttonRect.size.width * 0.05;
    buttonRect.origin.y = imageRect.origin.y + imageRect.size.height + 20;
    buttonRect.size.width = buttonRect.size.width * 0.9;
    UIButton *signWithViewInButton = [[UIButton alloc] initWithFrame:buttonRect];
    [signWithViewInButton setBackgroundColor:[UIColor colorWithRed:154/255.f green:228/255.f blue:232/255.f alpha:1.f]];
    [signWithViewInButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [signWithViewInButton setTitle:@"Request auth in view" forState:UIControlStateNormal];
    [signWithViewInButton addTarget:self action:@selector(requestAccessWithView) forControlEvents:UIControlEventTouchUpInside];
    [signWithViewInButton.layer setCornerRadius:4.f];
    [mainView addSubview:signWithViewInButton];
    
    CGRect button2Rect = buttonRect;
    button2Rect.origin.y += buttonRect.size.height + 20;
    UIButton *signInCustomButton = [[UIButton alloc] initWithFrame:button2Rect];
    [signInCustomButton setBackgroundColor:[UIColor colorWithRed:154/255.f green:228/255.f blue:232/255.f alpha:1.f]];
    [signInCustomButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [signInCustomButton setTitle:@"Request auth in custom view" forState:UIControlStateNormal];
    [signInCustomButton addTarget:self action:@selector(requestAccessWithCallback) forControlEvents:UIControlEventTouchUpInside];
    [signInCustomButton.layer setCornerRadius:4.f];
    [mainView addSubview:signInCustomButton];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self setupTwitterSignOn];
    _rootViewController = [[UIViewController alloc] init];
    UIView *mainView = [[UIView alloc] initWithFrame:self.window.bounds];
    [self drawMainView:mainView];
    [_rootViewController setView:mainView];
    
    [self.window setRootViewController:_rootViewController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
