//
//  NavBarView.m
//  AWSAuthUI
//
//  Created by Руслан Кукса on 04.11.2019.
//  Copyright © 2019 Dubal, Rohan. All rights reserved.
//

#import "NavBarView.h"

@implementation NavBarView

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
        printf("It's alive");
    }
    return self;
}

-(void)navBarSetup {
    self.backgroundColor = UIColor.clearColor;
    UIImage *logoImage = [UIImage imageNamed:@"walkthrough_logo"];
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 200, 45)];
    [imageView setCenter:CGPointMake(self.center.x, 0)];
    imageView.image = logoImage;
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    UILabel *labelView = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 45)];
    labelView.text = @"Sign In";
    labelView.textColor = UIColor.whiteColor;
    [labelView setCenter:CGPointMake(self.center.x, 30)];
    [labelView setFont:[UIFont fontWithName:@"MavenPro-Bold" size:25]];
    
    [self addSubview:imageView];
    [self addSubview:labelView];
}

@end
