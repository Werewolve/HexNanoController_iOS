//
//  HelpViewController.m
//  RCTouch
//
//  Created by koupoo on 13-12-16.
//  Copyright (c) 2013年 www.angeleyes.it. All rights reserved.
//

#import "HelpViewController.h"
#import "Macros.h"

@interface HelpViewController ()

@property (nonatomic, strong) NSMutableArray *pageViewArray;
@property (nonatomic, strong) NSMutableArray *pageTitleArray;
@property (nonatomic, assign) NSUInteger pageCount;

@end

@implementation HelpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.pageViewArray = [[NSMutableArray alloc] initWithCapacity:5];
        self.pageTitleArray = [[NSMutableArray alloc] initWithCapacity:5];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
    [self.pageViewArray addObject:self.pageView01];
    [self.pageTitleArray addObject:NSLocalizedString(@"BLE DEVICES",nil)];
    
    [self.pageViewArray addObject:self.pageView02];
    [self.pageTitleArray addObject:NSLocalizedString(@"PERSONAL SETTINGS",nil)];
    
    [self.pageViewArray addObject:self.pageView03];
    [self.pageTitleArray addObject:NSLocalizedString(@"TRIM SETTINGS",nil)];
    
    [self.pageViewArray addObject:self.pageView04];
    [self.pageTitleArray addObject:NSLocalizedString(@"MODE SETTINGS",nil)];
    
    [self.pageViewArray addObject:self.pageView05];
    [self.pageTitleArray addObject:NSLocalizedString(@"ABOUT",nil)];
    
    self.pageCount = self.pageViewArray.count;
    
    CGFloat x = 0.0f;
    for (UIView *pageView in self.pageViewArray) {
        CGRect frame = pageView.frame;
        frame.origin.x = x;
        [pageView setFrame:frame];
        [self.settingsPageScrollView addSubview:pageView];
        x += pageView.frame.size.width;
    }
    [self.settingsPageScrollView  setContentSize:CGSizeMake(x, self.settingsPageScrollView.frame.size.height)];
    [self.pageControl setNumberOfPages:self.pageCount];
    [self.pageControl setCurrentPage:0];
    
    self.pageTitleLabel.text = NSLocalizedString(@"BLE DEVICES",nil);
}

- (void)scrollViewDidScroll:(UIScrollView *)_scrollView {
	NSUInteger currentPage = (NSUInteger) (self.settingsPageScrollView.contentOffset.x + 0.5f * self.settingsPageScrollView.frame.size.width) / self.settingsPageScrollView.frame.size.width;
    [self.pageControl setCurrentPage:currentPage];
    [self.pageTitleLabel setText:self.pageTitleArray[currentPage]];
}

- (IBAction)close:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDismissHelpView object:self userInfo:nil];
}

@end
