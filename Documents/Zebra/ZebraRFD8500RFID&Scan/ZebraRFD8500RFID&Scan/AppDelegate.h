//
//  AppDelegate.h
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/5.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabletMainSplitVC.h"
#import "TabletMainSplitVCDelegate.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>{
    UINavigationController *m_NavigationVC;
    zt_TabletMainSplitVC *m_SplitVC;
    zt_TabletMainSplitVCDelegate *m_SplitVCDelegate;
#ifndef SST_SKIP_BACKGROUND_DETECTION_TASK
    UIBackgroundTaskIdentifier m_BackgroundHelperTask;
#endif /* SST_SKIP_BACKGROUND_DETECTION_TASK */
}

@property (strong, nonatomic) UIWindow *window;


@end

