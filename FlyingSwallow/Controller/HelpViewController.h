//
//  HelpViewController.h
//  RCTouch
//
//  Created by koupoo on 13-12-16.
//  Copyright (c) 2013年 www.angeleyes.it. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kNotificationDismissHelpView @"NotificationDissmissHelpView"

@interface HelpViewController : UIViewController<UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *pageTitleLabel;
@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
@property (nonatomic, weak) IBOutlet UIScrollView *settingsPageScrollView;
@property (nonatomic, weak) IBOutlet UIView *pageView01;
@property (nonatomic, weak) IBOutlet UIView *pageView02;
@property (nonatomic, weak) IBOutlet UIView *pageView03;
@property (nonatomic, weak) IBOutlet UIView *pageView04;
@property (nonatomic, weak) IBOutlet UIView *pageView05;
@property (nonatomic, weak) IBOutlet UIButton *closeBtn;

- (IBAction)close:(id)sender;

@end
