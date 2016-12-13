//
//  ZebraModelController.m
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/5.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraModelController.h"
#import "ZebraRFIDController.h"
#import "ScannerAppController.h"

@interface ZebraModelController ()
@property (strong, nonatomic) IBOutlet UIButton *zebraScanner;
@property (strong, nonatomic) IBOutlet UIButton *zebraRfid;

@end

@implementation ZebraModelController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.zebraRfid.layer.cornerRadius = 10.0;
    self.zebraScanner.layer.cornerRadius = 10.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)jumpingToZebraRFID:(id)sender {
    ZebraRFIDController *zebraRfid = [[UIStoryboard storyboardWithName:@"ZebraRFID" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    if (zebraRfid != nil) {
        self.view.window.rootViewController = zebraRfid;
    }
    
}
- (IBAction)jumpingToZebraScanner:(id)sender {
    
    ScannerAppController *zebraScanner = [[UIStoryboard storyboardWithName:@"ZebraScanner" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    if (zebraScanner != nil) {
        self.view.window.rootViewController = zebraScanner;
    }

}


@end
