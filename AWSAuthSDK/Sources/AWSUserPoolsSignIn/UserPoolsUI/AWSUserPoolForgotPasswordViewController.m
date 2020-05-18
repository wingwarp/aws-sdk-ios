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

#import "AWSUserPoolForgotPasswordViewController.h"
#import <AWSUserPoolsSignIn/AWSUserPoolsSignIn.h>
#import "AWSFormTableCell.h"
#import "AWSFormTableDelegate.h"
#import "AWSUserPoolsUIHelper.h"
#import <AWSAuthCore/AWSUIConfiguration.h>
#import "NavBarView.h"

@interface AWSUserPoolForgotPasswordViewController ()

@property (nonatomic, strong) AWSCognitoIdentityUserPool *pool;
@property (nonatomic, strong) AWSCognitoIdentityUser *user;
@property (nonatomic, strong) AWSFormTableCell *userNameRow;
@property (nonatomic, strong) AWSFormTableDelegate *tableDelegate;

@end

@interface AWSUserPoolNewPasswordViewController ()

@property (nonatomic, strong) AWSCognitoIdentityUser *user;
@property (nonatomic, strong) AWSFormTableCell *updatedPasswordRow;
@property (nonatomic, strong) AWSFormTableCell *confirmationCodeRow;
@property (nonatomic, strong) AWSFormTableDelegate *tableDelegate;

@end

@implementation AWSUserPoolForgotPasswordViewController

#pragma mark - UIViewController

@synthesize emailTextField;
@synthesize envelopeImage;
@synthesize emailView;

@synthesize darkColor;
@synthesize lightGreenColor;
@synthesize redColor;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNavigationBar];
    self.pool = [AWSCognitoIdentityUserPool defaultCognitoIdentityUserPool];
    
    darkColor = [UIColor colorWithRed:38/255.0 green:51/255.0 blue:65/255.0 alpha:1];
    lightGreenColor = [UIColor colorWithRed:36/255.0 green:209/255.0 blue:195/255.0 alpha:1];
    redColor = [UIColor colorWithRed:233/255.0 green:57/255.0 blue:57/255.0 alpha:1];
    
    envelopeImage.tintColor = UIColor.lightGrayColor;
    emailView.layer.borderColor = [UIColor lightGrayColor].CGColor;
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
        f.origin.y = -keyboardSize.height / 3;
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

- (void)setUpNavigationBar {
    [self.navigationItem setBackBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil]];
    self.navigationItem.backBarButtonItem.tintColor = [[UIColor alloc]initWithRed:70/255.0 green:24/255.0 blue:217/255.0 alpha:1];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([@"NewPasswordSegue" isEqualToString:segue.identifier]){
        AWSUserPoolNewPasswordViewController * confirmForgot = segue.destinationViewController;
        confirmForgot.user = self.user;
    }
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == emailTextField) {
        emailView.layer.borderColor = darkColor.CGColor;
        envelopeImage.tintColor = darkColor;
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
    }
    
    return YES;
}

- (IBAction)onForgotPassword:(id)sender {
    NSString *userName = emailTextField.text;
    if ([userName isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Missing Email"
                                                                                 message:@"Please enter a valid email adress."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController
                           animated:YES
                         completion:nil];
        return;
    }
    self.user = [self.pool getUser:userName];
    [[self.user forgotPassword] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserForgotPasswordResponse *> * _Nonnull task) {
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
                [self performSegueWithIdentifier:@"NewPasswordSegue" sender:sender];
            }
        });
        return nil;
    }];
}

@end

@implementation AWSUserPoolNewPasswordViewController

#pragma mark - UIViewController

@synthesize codeTextField;
@synthesize passwordTextField;
@synthesize emailView;
@synthesize passwordView;

@synthesize lockImage;
@synthesize keyImage;
@synthesize eyeButton;

@synthesize darkColor;
@synthesize lightGreenColor;
@synthesize redColor;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNavigationBar];
    
    darkColor = [UIColor colorWithRed:38/255.0 green:51/255.0 blue:65/255.0 alpha:1];
    lightGreenColor = [UIColor colorWithRed:36/255.0 green:209/255.0 blue:195/255.0 alpha:1];
    redColor = [UIColor colorWithRed:233/255.0 green:57/255.0 blue:57/255.0 alpha:1];
    
    lockImage.tintColor = [UIColor lightGrayColor];
    keyImage.tintColor = [UIColor lightGrayColor];
    eyeButton.tintColor = [UIColor lightGrayColor];
    
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
    self.title = @"";
}
#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == codeTextField) {
        emailView.layer.borderColor = darkColor.CGColor;
        lockImage.tintColor = darkColor;
    } else {
        keyImage.tintColor = darkColor;
        eyeButton.tintColor = darkColor;
        passwordView.layer.borderColor = darkColor.CGColor;
    }
    
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    
    if (textField == codeTextField) {
        if (![textField.text  isEqual: @""]) {
            emailView.layer.borderColor = lightGreenColor.CGColor;
            lockImage.tintColor = lightGreenColor;
        } else {
            emailView.layer.borderColor = [UIColor lightGrayColor].CGColor;
            lockImage.tintColor = [UIColor lightGrayColor];
        }
    } else {
        if (![textField.text isEqualToString:@""]) {
            passwordView.layer.borderColor = lightGreenColor.CGColor;
            keyImage.tintColor = lightGreenColor;
        } else {
            passwordView.layer.borderColor = [UIColor lightGrayColor].CGColor;
            keyImage.tintColor = [UIColor lightGrayColor];
            eyeButton.tintColor = [UIColor lightGrayColor];
        }
    }
    return YES;
}

- (IBAction)onUpdatePassword:(id)sender {
    //confirm forgot password with input from ui.
    NSString *confirmationCode = codeTextField.text;
    NSString *updatedPassword = passwordTextField.text;
    if ([confirmationCode isEqualToString:@""] || [updatedPassword isEqualToString:@""]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Missing Information"
                                                                                 message:@"Please enter valid confirmation code and password values."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController
                           animated:YES
                         completion:nil];
        return;
    }
    [[self.user confirmForgotPassword:confirmationCode password:updatedPassword] continueWithBlock:^id _Nullable(AWSTask<AWSCognitoIdentityUserConfirmForgotPasswordResponse *> * _Nonnull task) {
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
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Password Reset Complete"
                                                                                         message:@"Password Reset was completed successfully."
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

@end

