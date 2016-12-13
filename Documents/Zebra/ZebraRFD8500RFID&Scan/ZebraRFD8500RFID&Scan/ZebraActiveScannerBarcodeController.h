//
//  ZebraActiveScannerBarcodeController.h
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/7.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZebraActiveScannerBarcodeController : UITableViewController <UIAlertViewDelegate>{
int m_ScannerID;
NSMutableArray *m_BarcodeList;

BOOL m_HideModeSwitch;
}

- (void)showBarcode;
- (void)performActionTriggerPull:(NSString*)param;
- (void)performActionTriggerRelease:(NSString*)param;
- (void)performActionBarcodeMode:(NSString*)param;



@end
