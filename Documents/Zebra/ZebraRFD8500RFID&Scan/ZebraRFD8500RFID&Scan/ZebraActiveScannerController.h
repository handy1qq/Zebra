//
//  ZebraActiveScannerController.h
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/7.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScannerAppEngine.h"

@interface ZebraActiveScannerController : UITabBarController <IScannerAppEngineDevConnectionsDelegate>{
    int m_ScannerID;
    BOOL m_WillDisappear;
}

- (void)setScannerID:(int)scannerID;
- (int)getScannerID;
- (void)showBarcode;
- (void)showBarcodeList;

@end
