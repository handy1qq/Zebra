//
//  ScannerListTable.h
//  ZebraRFD8500Scanner
//
//  Created by fengwenwei on 16/12/1.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ScannerAppEngine.h"

@interface ScannerListTable : UITableViewController<IScannerAppEngineDevListDelegate,IScannerAppEngineDevConnectionsDelegate>{
    
    int m_CurrentScannerId;
    BOOL m_CurrentScannerActive;
    BOOL m_EmptyDeviceList;
}

- (void)showActiveScannerVC:(NSNumber*)scannerID aBarcodeView:(BOOL)barcodeView aAnimated:(BOOL)animated;

@end
