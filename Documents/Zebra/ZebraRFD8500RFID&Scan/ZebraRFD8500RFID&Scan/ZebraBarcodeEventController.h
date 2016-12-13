//
//  ZebraBarcodeEventController.h
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/7.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DecodeEvent.h"


@interface ZebraBarcodeEventController : UIViewController {
    zt_BarcodeData *m_BarcodeData;
    int m_ScannerID;
    BOOL m_Child;
}
@property (retain, nonatomic) IBOutlet UILabel *m_lblScannerID;
@property (retain, nonatomic) IBOutlet UILabel *m_lblBarcodeType;
@property (retain, nonatomic) IBOutlet UILabel *m_lblBarcodeData;

- (void)configureAsChild;
- (BOOL)isChildOfActiveVC;
- (void)setBarcodeEventData:(zt_BarcodeData*)barcodeData fromScanner:(int)scannerID;
- (void)dismissAction;
- (void)updateBarcodeUI;

@end
