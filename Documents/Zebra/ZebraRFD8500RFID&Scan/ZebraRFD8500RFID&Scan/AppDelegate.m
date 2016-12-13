//
//  AppDelegate.m
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/5.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "AppDelegate.h"
#import "ConnectionManager.h"
#import "ScannerAppEngine.h"
#import "AppSettingsKeys.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
//    // Override point for customization after application launch.
#ifndef SST_SKIP_BACKGROUND_DETECTION_TASK
    m_BackgroundHelperTask = UIBackgroundTaskInvalid;
#endif /* SST_SKIP_BACKGROUND_DETECTION_TASK */
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        /* ipad */
        if (m_SplitVCDelegate == nil)
        {
            m_SplitVC = (zt_TabletMainSplitVC*)self.window.rootViewController;
            m_SplitVCDelegate = [[zt_TabletMainSplitVCDelegate alloc] init];
            [m_SplitVC setDelegate:m_SplitVCDelegate];
        }
    }
    else
    {
        /* iphone */
        m_NavigationVC = (UINavigationController*)self.window.rootViewController;
    }
    
    // Override point for customization after application launch.
    
    /* initialize the engine */
    [zt_ScannerAppEngine sharedAppEngine];
    [[ConnectionManager sharedConnectionManager] initializeConnectionManager];
    
    /* the application is really started by notification, not just switched
     from backround to foreground */
    UILocalNotification *bg_notification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (bg_notification)
    {
        [[zt_ScannerAppEngine sharedAppEngine] processBackroundNotification:bg_notification];
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
    {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge|UIUserNotificationTypeSound|UIUserNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        
    }
    
    // Extend the splash screen for 1.75 seconds.
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.75]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    
    
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
