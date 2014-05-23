//
//  AppDelegate.m
//  FlyingSwallow
//
//  Created by koupoo on 12-12-21. Email: koupoo@126.com
//  Copyright (c) 2012年 www.hexairbot.com. All rights reserved.
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License V2
//  as published by the Free Software Foundation.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "AppDelegate.h"
#import "Macros.h"

@implementation AppDelegate

- (void)copyDefaultSettingsFileIfNeeded{
    NSString *documentsDir= NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *userSettingsFilePath= [documentsDir stringByAppendingPathComponent:@"Settings.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:userSettingsFilePath]) {
        NSString *settingsFilePath = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
        [fileManager copyItemAtPath:settingsFilePath toPath:userSettingsFilePath error:NULL];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self copyDefaultSettingsFileIfNeeded];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    HudViewController *viewController = nil;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        viewController = [[HudViewController alloc] initWithNibName:@"HudViewController" bundle:nil];
    } else {
        if (isIphone5()) {
            viewController = [[HudViewController alloc] initWithNibName:@"HudViewController_iPhone_tall" bundle:nil];
        } else {
            viewController = [[HudViewController alloc] initWithNibName:@"HudViewController_iPhone" bundle:nil];
        }
    }
    
    self.window.rootViewController = viewController;
    self.viewController = viewController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
