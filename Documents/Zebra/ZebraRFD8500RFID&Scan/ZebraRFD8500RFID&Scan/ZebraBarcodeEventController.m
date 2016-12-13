//
//  ZebraBarcodeEventController.m
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/7.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraBarcodeEventController.h"
#import "SbtSdkDefs.h"
#import "BarcodeTypes.h"
@interface ZebraBarcodeEventController ()

@end

@implementation ZebraBarcodeEventController


- (id)initWithCoder:(NSCoder *)aDecoder {

    [super initWithCoder:aDecoder];
    if (self != nil) {
        m_Child = NO;
        m_ScannerID = SBT_SCANNER_ID_INVALID;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setBarcodeEventData:(zt_BarcodeData *)barcodeData fromScanner:(int)scannerID {
    m_ScannerID = scannerID;
    m_BarcodeData = barcodeData;
    [self updateBarcodeUI];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateBarcodeUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateBarcodeUI];
}

- (void)updateBarcodeUI {
    self.m_lblScannerID.text = [NSString stringWithFormat:@"%d",m_ScannerID];
    
    self.m_lblBarcodeType.text = [NSString stringWithFormat:@"%@",get_barcode_type_name([m_BarcodeData getDecodeType])];
    
    self.m_lblBarcodeData.text = [m_BarcodeData getDecodeDataAsStringUsingEncoding:NSUTF8StringEncoding];

}

- (void)configureAsChild
{
    m_Child = YES;
}

- (BOOL)isChildOfActiveVC
{
    return m_Child;
}

- (void)dealloc {
    [_m_lblScannerID release];
    [_m_lblBarcodeType release];
    [_m_lblBarcodeData release];
    [super dealloc];
}

- (void)viewDidLayoutSubviews
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _m_lblBarcodeData.preferredMaxLayoutWidth = _m_lblBarcodeData.bounds.size.width;
    });
}

- (void)dismissAction
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
