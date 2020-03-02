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

#import "AWSUserPoolSignUpViewController.h"
#import <AWSUserPoolsSignIn/AWSUserPoolsSignIn.h>
#import "AWSFormTableCell.h"
#import "AWSTableInputCell.h"
#import "AWSFormTableDelegate.h"
#import "AWSUserPoolsUIHelper.h"
#import <AWSAuthCore/AWSSignInManager.h>
#import <AWSAuthCore/AWSUIConfiguration.h>
#import "NavBarView.h"


@interface AWSSignInManager()
    
@property (nonatomic) BOOL pendingSignIn;
@property (strong, atomic) NSString *pendingUsername;
@property (strong, atomic) NSString *pendingPassword;
    
-(void)reSignInWithUsername:(NSString *)username
               password:(NSString *)password;
@end

@interface AWSUserPoolSignUpViewController()

@property (nonatomic, strong) AWSCognitoIdentityUserPool * pool;
@property (nonatomic, strong) NSString* sentTo;

@end

@interface UserPoolSignUpConfirmationViewController()

@property (nonatomic, strong) NSString* sentTo;
@property (nonatomic, strong) AWSCognitoIdentityUser * user;
@property (nonatomic, strong) AWSCognitoIdentityUserPool * pool;

@end

@implementation AWSUserPoolSignUpViewController

@synthesize topLabel;
@synthesize emailTextField;
@synthesize passwordTextField;
@synthesize envelopeImage;
@synthesize keyImage;

id<AWSUIConfiguration> config = nil;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pool = [AWSCognitoIdentityUserPool defaultCognitoIdentityUserPool];
    [self setUpNavigationBar];
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]initWithString:topLabel.text];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(32, 9)];
    [topLabel setAttributedText:text];
    
    envelopeImage.tintColor = UIColor.lightGrayColor;
    keyImage.tintColor = UIColor.lightGrayColor;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

#pragma mark - keyboard movements
- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = -150;
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

// This is used to dismiss the keyboard, user just has to tap outside the
// user name and password views and it will dismiss
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.phase == UITouchPhaseBegan) {
        [self.view endEditing:YES];
    }

    [super touchesBegan:touches withEvent:event];
}
- (IBAction)showHidePassword:(UIButton *)sender {
    passwordTextField.secureTextEntry = !passwordTextField.secureTextEntry;
}

- (void)setUpNavigationBar {
    NavBarView *navBarView = [[NavBarView alloc]initWithName:@"Sign Up"];
    self.navigationItem.titleView = navBarView;
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([@"SignUpConfirmSegue" isEqualToString:segue.identifier]){
        UserPoolSignUpConfirmationViewController *signUpConfirmationViewController = segue.destinationViewController;
        signUpConfirmationViewController.isNewUser = YES;
        signUpConfirmationViewController.sentTo = self.sentTo;
        NSString *userName = emailTextField.text;
        signUpConfirmationViewController.user = [self.pool getUser:userName];
    }
}


- (IBAction)onSignUpClicked:(id)sender {
    
    NSMutableArray * attributes = [NSMutableArray new];
    AWSCognitoIdentityUserAttributeType * email = [AWSCognitoIdentityUserAttributeType new];
    email.name = @"email";
    email.value = self.emailTextField.text;
    
    if(![@"" isEqualToString:email.value]){
        [attributes addObject:email];
    }
    
    NSString *userName = self.emailTextField.text;
    NSString *password = self.passwordTextField.text;
    if ([userName isEqualToString:@""] || [password isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Missing Information"
                                                                                 message:@"Please enter a valid email and password."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController
                           animated:YES
                         completion:nil];
        return;
    }
    
    //sign up the user
    [[self.pool signUp:userName
              password:password
        userAttributes:attributes validationData:nil]
     continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserPoolSignUpResponse *> * _Nonnull task) {
        [[AWSSignInManager sharedInstance] reSignInWithUsername:userName password:password];
        AWSDDLogDebug(@"Successful signUp user: %@",task.result.user.username);
        dispatch_async(dispatch_get_main_queue(), ^{
            if(task.error){
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:task.error.userInfo[@"__type"]
                                                                                         message:task.error.userInfo[@"message"]
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:ok];
                [self presentViewController:alertController
                                   animated:YES
                                 completion:nil];
            }else if(task.result.user.confirmedStatus != AWSCognitoIdentityUserStatusConfirmed){
                self.sentTo = task.result.codeDeliveryDetails.destination;
                [self performSegueWithIdentifier:@"SignUpConfirmSegue" sender:sender];
            }
            else{
                [AWSSignInManager sharedInstance].pendingSignIn = YES;
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Registration Complete"
                                                                                         message:@"Registration was successful."
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                }];
                [alertController addAction:ok];
                [self presentViewController:alertController
                                   animated:YES
                                 completion:nil];
            }});
        return nil;
    }];
}

@end

@implementation UserPoolSignUpConfirmationViewController

#pragma mark - UIViewController

@synthesize topLabel;
@synthesize emailTextField;
@synthesize passwordTextField;
@synthesize codeTextField;

@synthesize emailView;
@synthesize passwordView;

@synthesize envelopeImage;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pool = [AWSCognitoIdentityUserPool defaultCognitoIdentityUserPool];
    [self setUpNavigationBar];
    [self setUpView];
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]initWithString:topLabel.text];
    [text addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(62, 8)];
    [topLabel setAttributedText:text];
    
    envelopeImage.tintColor = UIColor.lightGrayColor;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

#pragma mark - keyboard movements
- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = -150;
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

// This is used to dismiss the keyboard, user just has to tap outside the
// user name and password views and it will dismiss
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    if (touch.phase == UITouchPhaseBegan) {
        [self.view endEditing:YES];
    }

    [super touchesBegan:touches withEvent:event];
}

- (IBAction)showHidePassword:(UIButton *)sender {
    self.passwordTextField.secureTextEntry = !self.passwordTextField.secureTextEntry;
}

- (void)setUpNavigationBar {
    NavBarView *navBarView = [[NavBarView alloc]initWithName:@"Confirm Signup"];
    self.navigationItem.titleView = navBarView;
}

- (void)setUpView {
    if (self.isNewUser == YES) {
        [emailView removeFromSuperview];
        [passwordView removeFromSuperview];
    }
}

- (void)getUser {
    
    if ([self.emailTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Missing Infromation" message:@"Please enter a valid email and password." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okButton = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okButton];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    NSMutableArray * attributes = [NSMutableArray new];
    AWSCognitoIdentityUserAttributeType * email = [AWSCognitoIdentityUserAttributeType new];
    email.name = @"email";
    email.value = self.emailTextField.text;
    
    if(![@"" isEqualToString:email.value]){
        [attributes addObject:email];
    }
    
    NSString *userName = self.emailTextField.text;
    NSString *password = self.passwordTextField.text;
    
    //sign up the user
    [self.pool signUp:userName
              password:password
        userAttributes:attributes validationData:nil];
    
    self.user = [self.pool getUser:userName];
}

- (IBAction)onConfirmCode:(id)sender {
    
    if (self.isNewUser == NO) {
        [self getUser];
    }
    
    NSString *confirmationCode = codeTextField.text;
    if ([confirmationCode isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Missing Information"
                                                                                 message:@"Please enter a valid confirmation code."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController
                           animated:YES
                         completion:nil];
        return;
    }
    [[self.user confirmSignUp:confirmationCode forceAliasCreation:YES] continueWithBlock: ^id _Nullable(AWSTask<AWSCognitoIdentityUserConfirmSignUpResponse *> * _Nonnull task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(task.error){
                if(task.error){
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:task.error.userInfo[@"__type"]
                                                                                             message:task.error.userInfo[@"message"]
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
                    [alertController addAction:ok];
                    [self presentViewController:alertController
                                       animated:YES
                                     completion:nil];
                }
            } else {
                //return to initial screen
                [AWSSignInManager sharedInstance].pendingSignIn = YES;
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Registration Complete"
                                                                                         message:@"Registration was successful."
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                [alertController addAction:ok];
                [self presentViewController:alertController
                                   animated:YES
                                 completion:nil];
            }
        });
        return nil;
    }];
}

- (IBAction)onResendConfirmationCode:(id)sender {
    //resend the confirmation code
    if (self.isNewUser == NO) {
        [self getUser];
    }
    
    [[self.user resendConfirmationCode] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserResendConfirmationCodeResponse *> * _Nonnull task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(task.error){
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:task.error.userInfo[@"__type"]
                                                                                         message:task.error.userInfo[@"message"]
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:ok];
                [self presentViewController:alertController
                                   animated:YES
                                 completion:nil];
            }else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Code Resent"
                                                                                         message:[NSString stringWithFormat:@"Code resent to: %@", task.result.codeDeliveryDetails.destination]
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:ok];
                [self presentViewController:alertController
                                   animated:YES
                                 completion:nil];
            }
        });
        return nil;
    }];
}

@end
