//
//  NavBarView.h
//  AWSAuthUI
//
//  Created by Руслан Кукса on 04.11.2019.
//  Copyright © 2019 Dubal, Rohan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NavBarView : UIView

@property (nonatomic, strong) NSString *navBarText;
- (instancetype)initWithName:(NSString *)text;

@end

NS_ASSUME_NONNULL_END
