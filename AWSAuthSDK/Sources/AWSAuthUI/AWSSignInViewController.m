//
// Copyright 2010-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

#import <Foundation/Foundation.h>
#import <AWSCore/AWSCore.h>
#import <AWSAuthCore/AWSAuthCore.h>

#import "AWSFormTableCell.h"
#import "AWSTableInputCell.h"
#import "AWSFormTableDelegate.h"
#import "AWSUserPoolsUIHelper.h"
#import "AWSSignInViewController.h"
#import "NavBarView.h"

//#define DEFAULT_BACKGROUND_COLOR_TOP [UIColor darkGrayColor]
//#define DEFAULT_BACKGROUND_COLOR_BOTTOM [UIColor whiteColor]
//#define NAVIGATION_BAR_HEIGHT 64

static NSString *const RESOURCES_BUNDLE = @"AWSAuthUI.bundle";

static NSString *const SIGNIN_STORYBOARD = @"SignIn";
static NSString *const SIGNIN_VIEW_CONTROLLER_IDENTIFIER = @"SignIn";;
static NSString *const USERPOOLS_UI_OPERATIONS = @"AWSUserPoolsUIOperations";

@interface AWSSignInManager()

@property (nonatomic) BOOL shouldFederate;
@property (nonatomic) BOOL pendingSignIn;
@property (strong, atomic) NSString *pendingUsername;
@property (strong, atomic) NSString *pendingPassword;

@end

@interface AWSUserPoolsUIOperations: NSObject

-(id)initWithAuthUIConfiguration:(AWSAuthUIConfiguration *)configuration;

-(void)loginWithUserName:(NSString *)userName
                password:(NSString *)password
    navigationController:(UINavigationController *)navController
       completionHandler:(void (^)(id _Nullable result, NSError * _Nullable error))completionHandler;


-(void)pushSignUpVCFromNavigationController:(UINavigationController *)navController;

-(void)pushForgotPasswordVCFromNavigationController:(UINavigationController *)navController;

@end

@interface AWSSignInViewController() <AWSSignInDelegate>

@end


@interface AWSAuthUIConfiguration()

@property(nonatomic, nullable) NSMutableArray<Class<AWSSignInButtonView>> *registeredSignInButtonViews;

- (NSMutableArray<Class<AWSSignInButtonView>> *_Nonnull)getAllSignInButtonViews;

- (BOOL)hasSignInButtonView;

@end


@implementation AWSSignInViewController

@synthesize canCancel;
@synthesize config;
@synthesize statusLabel;

+ (void)initialize {
    AWSDDLogDebug(@"Initializing the AWSSignInViewController...");
    [super initialize];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if (self  = [super initWithCoder:decoder]) {
        
    }
    return self;
}

#pragma mark - keyboard movements
- (void)keyboardWillShow:(NSNotification *)notification {
    
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = -keyboardSize.height / 2;
        self.view.frame = f;
    }];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = 0.0f;
        self.view.frame = f;
    }];
}

- (void)keyboardWillChange:(NSNotification *)notification {
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.config.enableUserPoolsUI = true;
    AWSDDLogDebug(@"Sign-In Loading...");
    
    // set up the navigation controller
    [self setUpNavigationController];
    
    // set up username and password UI if user pools enabled
    [self setUpUserPoolsUI];
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]initWithString:statusLabel.text];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 8)];
    [statusLabel setAttributedText:text];
}
    
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([AWSSignInManager sharedInstance].pendingSignIn) {
        
        Class awsUserPoolsUIOperations = NSClassFromString(USERPOOLS_UI_OPERATIONS);
        AWSUserPoolsUIOperations *userPoolsOperations = [[awsUserPoolsUIOperations alloc] initWithAuthUIConfiguration:self.config];
        [userPoolsOperations loginWithUserName:[AWSSignInManager sharedInstance].pendingUsername
                                      password:[AWSSignInManager sharedInstance].pendingPassword
                          navigationController:self.navigationController
                             completionHandler:self.completionHandler];
    }
    [AWSSignInManager sharedInstance].pendingSignIn = NO;
    [AWSSignInManager sharedInstance].pendingUsername = @"";
    [AWSSignInManager sharedInstance].pendingPassword = @"";
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

// This is used to dismiss the keyboard, user just has to tap outside the
// user name and password views and it will dismiss
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.phase == UITouchPhaseBegan) {
        [self.view endEditing:YES];
    }
    
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - Utility Methods

- (void)handleLoginWithSignInProvider:(id<AWSSignInProvider>)signInProvider {
    [[AWSSignInManager sharedInstance]
     loginWithSignInProviderKey:[signInProvider identityProviderName]
     completionHandler:^(id result, NSError *error) {
         
         if (![[AWSSignInManager sharedInstance] shouldFederate]) {
             if (error) {
                 self.completionHandlerCustom(nil, nil, error);
             } else {
                 [[signInProvider token] continueWithBlock:^id _Nullable(AWSTask<NSString *> * _Nonnull task) {
                     if (task.result) {
                         NSString *token = task.result;
                         NSString *provider = signInProvider.identityProviderName;
                         self.completionHandlerCustom(provider, token, nil);
                     }
                     return nil;
                 }];
             }
         } else if (!error) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self dismissViewControllerAnimated:YES
                                          completion:nil];
                 if (self.completionHandler) {
                     self.completionHandler(signInProvider, error);
                 }
             });
         } else {
             // in case of error, propogate the error back to customer, but do not dismiss sign in vc
             if (self.completionHandler) {
                 self.completionHandler(signInProvider, error);
             }
         }
         
         AWSDDLogDebug(@"result = %@, error = %@", result, error);
     }];
}

- (void)setUpUserPoolsUI {
    if (self.config.enableUserPoolsUI) {
        AWSDDLogDebug(@"User Pools Enabled. Setting up the view...");

        Class AWSUserPoolsUIHelper = NSClassFromString(@"AWSUserPoolsUIHelper");

        
        if ([AWSUserPoolsUIHelper respondsToSelector:@selector(setAWSUIConfiguration:)]) {
            [AWSUserPoolsUIHelper setAWSUIConfiguration:self.config];
        }
        
        // Add SignInButton to the view
        [self.signInButton addTarget:self
                              action:@selector(handleUserPoolSignIn)
                    forControlEvents:UIControlEventTouchUpInside];
        
        if (self.config.enableUserPoolsUI) {
            [self.forgotPasswordButton addTarget:self
                                          action:@selector(handleUserPoolForgotPassword)
                                forControlEvents:UIControlEventTouchUpInside];
        } else {
            [self.forgotPasswordButton removeFromSuperview];
        }
        
        if (self.config.enableUserPoolsUI && !self.config.disableSignUpButton) {
            
            [self.signUpButton addTarget:self
                                  action:@selector(handleUserPoolSignUp)
                        forControlEvents:UIControlEventTouchUpInside];
        } else {
            [self.signUpButton removeFromSuperview];
        }
    } else {
        [self.signInButton removeFromSuperview];
        [self.signUpButton removeFromSuperview];
        [self.forgotPasswordButton removeFromSuperview];
        
//        [self.view addConstraint: [NSLayoutConstraint constraintWithItem:self.orSignInWithLabel
//                                                               attribute:NSLayoutAttributeTop
//                                                               relatedBy:NSLayoutRelationEqual
//                                                                  toItem:self.logoView
//                                                               attribute:NSLayoutAttributeBottom multiplier:1 constant:8.0]];
    }
}

- (void)setUpResponders {
    [self.signUpButton addTarget:self
                          action:@selector(handleUserPoolSignUp)
                forControlEvents:UIControlEventTouchUpInside];
    [self.signInButton addTarget:self
                          action:@selector(handleUserPoolSignIn)
                forControlEvents:UIControlEventTouchUpInside];
    [self.forgotPasswordButton addTarget:self
                                  action:@selector(handleUserPoolForgotPassword)
                        forControlEvents:UIControlEventTouchUpInside];
}

- (void)setUpNavigationController {
    UIImage *bgImage = [UIImage imageNamed:@"navbar_bg"];
    [self.navigationController.navigationBar setBackgroundImage:bgImage forBarMetrics:UIBarMetricsDefault];
    self.navigationItem.title = @"";
    self.navigationController.navigationBar.tintColor = UIColor.whiteColor;
    
    NavBarView *navBarView = [[NavBarView alloc]initWithName:@"Sign In"];
    self.navigationItem.titleView = navBarView;
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

- (void)barButtonClosePressed {
    [self dismissViewControllerAnimated:YES completion:nil];
    self.completionHandlerCustom(nil, nil, [[NSError alloc] initWithDomain:@"AWSMobileClientError" code:-2 userInfo:@{@"message": @"The user cancelled the sign in operation"}]);
    AWSDDLogDebug(@"User closed sign in screen.");
}

+ (UIImage *)getImageFromBundle:(NSString *)imageName {
    NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
    // Check if the logo image is available in the framework directly; if available fetch and return it.
    // This is applicable when dependency is consumed via Carthage/ Frameworks.
    UIImage *imageFromCurrentBundle = [UIImage imageNamed:imageName inBundle:currentBundle compatibleWithTraitCollection:nil];
    if (imageFromCurrentBundle) {
        return imageFromCurrentBundle;
    }
    
    // If the image is not available in the framework, it is part of the resources bundle.
    // This is applicable when dependency is consumed via Cocoapods.
    NSURL *url = [[currentBundle resourceURL] URLByAppendingPathComponent:RESOURCES_BUNDLE];
    AWSDDLogDebug(@"URL: %@", url);
    
    NSBundle *assetsBundle = [NSBundle bundleWithURL:url];
    AWSDDLogDebug(@"assetsBundle: %@", assetsBundle);
    
    return [UIImage imageNamed:imageName inBundle:assetsBundle compatibleWithTraitCollection:nil];
}

+ (UIStoryboard *)getUIStoryboardFromBundle:(NSString *)storyboardName {
    NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
    
    // Check if the storyboard is available in the framework directly; if available fetch and return it.
    // This is applicable when dependency is consumed via Carthage/ Frameworks.
    if ([currentBundle pathForResource:storyboardName ofType:@"storyboardc"] != nil) {
        return [UIStoryboard storyboardWithName:storyboardName
                                         bundle:currentBundle];
    }
    
    // If the storyboard is not available in the framework, it is part of the resources bundle.
    // This is applicable when dependency is consumed via Cocoapods.
    NSURL *url = [[currentBundle resourceURL] URLByAppendingPathComponent:RESOURCES_BUNDLE];
    AWSDDLogDebug(@"URL: %@", url);
    
    NSBundle *resourcesBundle = [NSBundle bundleWithURL:url];
    AWSDDLogDebug(@"assetsBundle: %@", resourcesBundle);
    
    return [UIStoryboard storyboardWithName:storyboardName
                                     bundle:resourcesBundle];
}

+ (UIViewController *)getViewControllerWithName:(NSString *)viewControllerIdentitifer
                                     storyboard:(NSString *)storyboardIdentifier {
    UIStoryboard *storyboard = [AWSSignInViewController getUIStoryboardFromBundle:storyboardIdentifier];
    return (UIViewController *)[storyboard instantiateViewControllerWithIdentifier:viewControllerIdentitifer];
}

+ (AWSSignInViewController *)getAWSSignInViewControllerWithconfiguration:(AWSAuthUIConfiguration *)configuration {
    AWSSignInViewController *vc = (AWSSignInViewController *)[AWSSignInViewController getViewControllerWithName:SIGNIN_VIEW_CONTROLLER_IDENTIFIER
                                                                                                     storyboard:SIGNIN_STORYBOARD];
    if (configuration) {
        vc.config = configuration;
    }
    return vc;
}

#pragma mark - IBActions

-(void)createInternalCompletionHandler {
    __weak AWSSignInViewController *weakSelf = self;
    self.completionHandler = ^(id<AWSSignInProvider>  _Nonnull signInProvider, NSError * _Nullable error) {
        if (error) {
            weakSelf.completionHandlerCustom(nil, nil, error);
        } else{
            [[signInProvider token] continueWithBlock:^id _Nullable(AWSTask<NSString *> * _Nonnull task) {
                if (task.result) {
                    weakSelf.completionHandlerCustom(signInProvider.identityProviderName, task.result, nil);
                } else {
                    weakSelf.completionHandlerCustom(nil, nil, task.error);
                }
                return nil;
            }];
        }
    };
}

- (void)handleUserPoolSignIn {
    Class awsUserPoolsUIOperations = NSClassFromString(USERPOOLS_UI_OPERATIONS);
    AWSUserPoolsUIOperations *userPoolsOperations = [[awsUserPoolsUIOperations alloc] initWithAuthUIConfiguration:self.config];
    
    [userPoolsOperations loginWithUserName:_emailTextField.text password:_passwordTextField.text navigationController:self.navigationController completionHandler:self.completionHandler];
}


- (void)handleUserPoolSignUp {
    
    // Dismisses the keyboard if open before transitioning to the new storyboard
    [self.view endEditing:YES];
    
    Class awsUserPoolsUIOperations = NSClassFromString(USERPOOLS_UI_OPERATIONS);
    AWSUserPoolsUIOperations *userPoolsOperations = [[awsUserPoolsUIOperations alloc] initWithAuthUIConfiguration:self.config];
    [userPoolsOperations pushSignUpVCFromNavigationController:self.navigationController];
}

- (void)handleUserPoolForgotPassword {
    
    // Dismisses the keyboard if open before transitioning to the new storyboard
    [self.view endEditing:YES];
    
    Class awsUserPoolsUIOperations = NSClassFromString(USERPOOLS_UI_OPERATIONS);
    AWSUserPoolsUIOperations *userPoolsOperations = [[awsUserPoolsUIOperations alloc] initWithAuthUIConfiguration:self.config];
    [userPoolsOperations pushForgotPasswordVCFromNavigationController:self.navigationController];
}

- (void)onLoginWithSignInProvider:(id<AWSSignInProvider>)signInProvider
                           result:(id _Nullable)result
                            error:(NSError * _Nullable)error {
    if (!error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES
                                     completion:nil];
            if (self.completionHandler) {
                self.completionHandler(signInProvider, error);
            }
        });
    } else {
        // in case of error attempt, send a completion handler to customer but do not dismiss vc
        if (self.completionHandler) {
            self.completionHandler(signInProvider, error);
        }
    }
    AWSDDLogDebug(@"result = %@, error = %@", result, error);
}

@end
