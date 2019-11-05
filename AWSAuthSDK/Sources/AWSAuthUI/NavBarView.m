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
    //self.clipsToBounds = YES;
    self.backgroundColor = UIColor.clearColor;
    UIImage *logoImage = [UIImage imageNamed:@"walkthrough_logo"];
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 200, 45)];

    [imageView setCenter:CGPointMake(self.center.x, 20)];
    imageView.image = logoImage;
    imageView.contentMode = UIViewContentModeScaleAspectFill;

    UILabel *labelView = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 45)];
    labelView.text = navBarText;
    labelView.textColor = UIColor.whiteColor;
    labelView.textAlignment = NSTextAlignmentCenter;
    [labelView setCenter:CGPointMake(self.center.x, 60)];
    [labelView setFont:[UIFont fontWithName:@"MavenPro-Bold" size:25]];
    
    [self addSubview:imageView];
    [self addSubview:labelView];
}

@end
