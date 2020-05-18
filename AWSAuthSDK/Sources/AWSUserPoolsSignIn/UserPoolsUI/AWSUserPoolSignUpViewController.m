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

@synthesize emailTextField;
@synthesize passwordTextField;
@synthesize envelopeImage;
@synthesize keyImage;
@synthesize eyeButton;
@synthesize emailView;
@synthesize passwordView;

@synthesize darkColor;
@synthesize lightGreenColor;
@synthesize redColor;

id<AWSUIConfiguration> config = nil;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pool = [AWSCognitoIdentityUserPool defaultCognitoIdentityUserPool];
    [self setUpNavigationBar];
    
    darkColor = [UIColor colorWithRed:38/255.0 green:51/255.0 blue:65/255.0 alpha:1];
    lightGreenColor = [UIColor colorWithRed:36/255.0 green:209/255.0 blue:195/255.0 alpha:1];
    redColor = [UIColor colorWithRed:233/255.0 green:57/255.0 blue:57/255.0 alpha:1];
    
    envelopeImage.tintColor = UIColor.lightGrayColor;
    keyImage.tintColor = UIColor.lightGrayColor;
    eyeButton.tintColor = UIColor.lightGrayColor;
    emailView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    passwordView.layer.borderColor = [UIColor lightGrayColor].CGColor;
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
//    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

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

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == emailTextField) {
        emailView.layer.borderColor = darkColor.CGColor;
        envelopeImage.tintColor = darkColor;
    } else {
        keyImage.tintColor = darkColor;
        eyeButton.tintColor = darkColor;
        passwordView.layer.borderColor = darkColor.CGColor;
    }
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    
    if (textField == emailTextField) {
        if (![textField.text  isEqual: @""]) {
            emailView.layer.borderColor = lightGreenColor.CGColor;
            envelopeImage.tintColor = lightGreenColor;
        } else {
            emailView.layer.borderColor = [UIColor lightGrayColor].CGColor;
            envelopeImage.tintColor = [UIColor lightGrayColor];
        }
    } else {
        if (![textField.text isEqualToString:@""]) {
            passwordView.layer.borderColor = lightGreenColor.CGColor;
            keyImage.tintColor = lightGreenColor;
        } else {
            passwordView.layer.borderColor = [UIColor lightGrayColor].CGColor;
            keyImage.tintColor = [UIColor lightGrayColor];
        }
    }
    return YES;
}

- (IBAction)showHidePassword:(UIButton *)sender {
    passwordTextField.secureTextEntry = !passwordTextField.secureTextEntry;
}

- (void)setUpNavigationBar {
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Sign Up" style:UIBarButtonItemStylePlain target:nil action:nil]];
    self.navigationItem.backBarButtonItem.tintColor = [[UIColor alloc]initWithRed:70/255.0 green:24/255.0 blue:217/255.0 alpha:1];
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

- (IBAction)signInClicked:(UIButton *)sender {
    [self.view endEditing:YES];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)enterConfirmationClicked:(UIButton *)sender {
    [self.view endEditing:YES];
    Class awsUserPoolsUIOperations = NSClassFromString(@"AWSUserPoolsUIOperations");
    AWSUserPoolsUIOperations *userPoolsOperations = [[awsUserPoolsUIOperations alloc] initWithAuthUIConfiguration:self.config];
    [userPoolsOperations pushConfirmationSignUpVCFromNavigationController:self.navigationController];
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

@synthesize emailTextField;
@synthesize passwordTextField;
@synthesize codeTextField;

@synthesize emailView;
@synthesize passwordView;
@synthesize confirmationView;

@synthesize emailStackView;
@synthesize passwordStackView;

@synthesize envelopeImage;
@synthesize keyImage;
@synthesize lockImage;
@synthesize eyeButton;

@synthesize darkColor;
@synthesize lightGreenColor;
@synthesize redColor;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pool = [AWSCognitoIdentityUserPool defaultCognitoIdentityUserPool];
    [self setUpNavigationBar];
    [self setUpView];
    
    darkColor = [UIColor colorWithRed:38/255.0 green:51/255.0 blue:65/255.0 alpha:1];
    lightGreenColor = [UIColor colorWithRed:36/255.0 green:209/255.0 blue:195/255.0 alpha:1];
    redColor = [UIColor colorWithRed:233/255.0 green:57/255.0 blue:57/255.0 alpha:1];
    
    envelopeImage.tintColor = UIColor.lightGrayColor;
    keyImage.tintColor = UIColor.lightGrayColor;
    lockImage.tintColor = UIColor.lightGrayColor;
    eyeButton.tintColor = UIColor.lightGrayColor;
    
    emailView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    passwordView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    confirmationView.layer.borderColor = [UIColor lightGrayColor].CGColor;
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
//    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

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
    self.title = @"";
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == emailTextField) {
        emailView.layer.borderColor = darkColor.CGColor;
        envelopeImage.tintColor = darkColor;
    } else if (textField == passwordTextField) {
        keyImage.tintColor = darkColor;
        eyeButton.tintColor = darkColor;
        passwordView.layer.borderColor = darkColor.CGColor;
    } else {
        lockImage.tintColor = darkColor;
        confirmationView.layer.borderColor = darkColor.CGColor;
    }
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    
    if (textField == emailTextField) {
        if (![textField.text  isEqual: @""]) {
            emailView.layer.borderColor = lightGreenColor.CGColor;
            envelopeImage.tintColor = lightGreenColor;
        } else {
            emailView.layer.borderColor = [UIColor lightGrayColor].CGColor;
            envelopeImage.tintColor = [UIColor lightGrayColor];
        }
    } else if (textField == passwordTextField) {
        if (![textField.text isEqualToString:@""]) {
            passwordView.layer.borderColor = lightGreenColor.CGColor;
            keyImage.tintColor = lightGreenColor;
        } else {
            passwordView.layer.borderColor = [UIColor lightGrayColor].CGColor;
            keyImage.tintColor = [UIColor lightGrayColor];
            eyeButton.tintColor = [UIColor lightGrayColor];
        }
    } else {
        if (![textField.text isEqualToString:@""]) {
            confirmationView.layer.borderColor = lightGreenColor.CGColor;
            lockImage.tintColor = lightGreenColor;
        } else {
            confirmationView.layer.borderColor = [UIColor lightGrayColor].CGColor;
            lockImage.tintColor = [UIColor lightGrayColor];
        }
    }
    
    return YES;
}

- (void)setUpView {
    if (self.isNewUser == YES) {
        [emailStackView removeFromSuperview];
        [passwordStackView removeFromSuperview];
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
    [[AWSSignInManager sharedInstance] reSignInWithUsername:userName password:password];
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
