//
//  NavBarView.m
//  AWSAuthUI
//
//  Created by Руслан Кукса on 04.11.2019.
//  Copyright © 2019 Dubal, Rohan. All rights reserved.
//

#import "NavBarView.h"

@implementation NavBarView

@synthesize navBarText;

- (instancetype)initWithName:(NSString *)text {
    self = [super init];
    if (self) {
        [self setNavBarText:text];
        [self navBarSetup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self navBarSetup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self navBarSetup];
    }
    return self;
}

-(void)navBarSetup {
    self.backgroundColor = UIColor.clearColor;
    UIImage *logoImage = [UIImage imageNamed:@"walkthrough_logo"];
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 200, 45)];

    imageView.image = logoImage;
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *labelView = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 300, 45)];
    labelView.text = navBarText;
    labelView.textColor = UIColor.whiteColor;
    labelView.textAlignment = NSTextAlignmentCenter;
    [labelView setFont:[UIFont fontWithName:@"MavenPro-Bold" size:25]];
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    labelView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:imageView];
    [self addSubview:labelView];
    
    [imageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:10].active = YES;
    [imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
    [imageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
    [imageView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
    [imageView.heightAnchor constraintEqualToConstant:50].active = YES;
    
    [labelView.topAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:0].active = YES;
    [labelView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
    [labelView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
    [labelView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor].active = YES;
    
}

@end
