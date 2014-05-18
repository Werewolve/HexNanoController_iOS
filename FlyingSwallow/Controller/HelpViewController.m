//
//  HelpViewController.m
//  RCTouch
//
//  Created by koupoo on 13-12-16.
//  Copyright (c) 2013年 www.angeleyes.it. All rights reserved.
//

#import "HelpViewController.h"
#import "Macros.h"

@interface HelpViewController (){
    NSMutableArray *pageViewArray;
    NSMutableArray *pageTitleArray;
    
    int pageCount;
}

@end

@implementation HelpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        pageViewArray = [[NSMutableArray alloc] initWithCapacity:5];
        pageTitleArray = [[NSMutableArray alloc] initWithCapacity:5];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [pageViewArray addObject:pageView01];
    [pageTitleArray addObject:NSLocalizedString(@"BLE DEVICES",nil)];
    
    [pageViewArray addObject:pageView02];
    [pageTitleArray addObject:NSLocalizedString(@"PERSONAL SETTINGS",nil)];
    
    [pageViewArray addObject:pageView03];
    [pageTitleArray addObject:NSLocalizedString(@"TRIM SETTINGS",nil)];
    
    [pageViewArray addObject:pageView04];
    [pageTitleArray addObject:NSLocalizedString(@"MODE SETTINGS",nil)];
    
    [pageViewArray addObject:pageView05];
    [pageTitleArray addObject:NSLocalizedString(@"ABOUT",nil)];
    
    pageCount = pageViewArray.count;
    
    CGFloat x = 0.f;
    for (UIView *pageView in pageViewArray)
    {
        CGRect frame = pageView.frame;
        frame.origin.x = x;
        [pageView setFrame:frame];
        [settingsPageScrollView addSubview:pageView];
        x += pageView.frame.size.width;
    }
    [settingsPageScrollView  setContentSize:CGSizeMake(x, settingsPageScrollView.frame.size.height)];
    
    [pageControl setNumberOfPages:pageCount];
    [pageControl setCurrentPage:0];
    
    pageTitleLabel.text = NSLocalizedString(@"BLE DEVICES",nil);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [pageView01 release];
    [pageView02 release];
    [pageView03 release];
    [pageView04 release];
    [pageView05 release];
    [pageTitleLabel release];
    [pageControl release];
    [closeBtn release];
    [settingsPageScrollView release];
    [pageViewArray release];
    [pageTitleArray release];

    [super dealloc];
}

- (void)scrollViewDidScroll:(UIScrollView *)_scrollView
{
	int currentPage = (int) (settingsPageScrollView.contentOffset.x + .5f * settingsPageScrollView.frame.size.width) / settingsPageScrollView.frame.size.width;
    
    [pageControl setCurrentPage:currentPage];
    [pageTitleLabel setText:pageTitleArray[currentPage]];
}

- (IBAction)close:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDismissHelpView object:self userInfo:nil];
}
@end
