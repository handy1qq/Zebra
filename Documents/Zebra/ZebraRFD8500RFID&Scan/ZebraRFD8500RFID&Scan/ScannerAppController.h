//
//  ScannerAppController.h
//  ZebraRFD8500Scanner
//
//  Created by fengwenwei on 16/12/1.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActiveScannerVC.h"
#import "ScannerAppEngine.h"

@interface ScannerAppController : UITableViewController<IScannerAppEngineDevEventsDelegate>

/**<#注释#> */
@property (strong, nonatomic) zt_ActiveScannerVC *activeScannerVc;


@end
