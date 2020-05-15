//
// Copyright 2010-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

#import <UIKit/UIKit.h>
#import <AWSAuthCore/AWSSignInButtonView.h>
#import "AWSAuthUIConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWSSignInViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIImageView *envelopeImage;
@property (weak, nonatomic) IBOutlet UIButton *eyeButton;
@property (weak, nonatomic) IBOutlet UIImageView *keyImage;
@property (weak, nonatomic) IBOutlet UIView *emailView;
@property (weak, nonatomic) IBOutlet UIView *passwordView;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

/**
 @property canCancel
 @brief If set to `YES` user can hit cancel button to dismiss sign in UI
 **/
@property (atomic) BOOL canCancel;

@property (atomic) UIColor *darkColor;
@property (atomic) UIColor *lightGreenColor;
@property (atomic) UIColor *redColor;

/**
 @property signInButton
 @brief UIButton that kicks off the SignIn flow on click
 **/
@property (weak, nonatomic) IBOutlet UIButton *signInButton;

/**
 @property signUpButton
 @brief UIButton that kicks off the SignUp flow on click
 **/
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;

@property (weak, nonatomic) IBOutlet UIButton *confirmationButton;


/**
 @property forgotPasswordButton
 @brief UIButton that kicks off the ForgotPassword flow on click
 **/
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

/**
 @property completionHandler
 @brief Callback to the application which notifies success/failure of the SignIn
 **/
@property (nonatomic, copy) void (^completionHandler)(id<AWSSignInProvider> signInProvider, NSError * _Nullable error);

@property (nonatomic, copy) void (^completionHandlerCustom)(NSString  * _Nullable providerKey, NSString * _Nullable token, NSError * _Nullable error);

/**
 @property config
 @brief Auth UI Confguration
 **/
@property (strong, nonatomic) AWSAuthUIConfiguration *config;

/**
 Creates a new AWSSignInViewController instance
 
 @param     configuration           The AWSAuthUIConfiguration object configured with logo, background color, etc.
 @return    AWSSignInViewController The SignIniewController object initialized with the storyboard
 **/
+ (AWSSignInViewController *)getAWSSignInViewControllerWithconfiguration:(AWSAuthUIConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END

