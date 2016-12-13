//
//  ZebraRFIDController.m
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/5.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraRFIDController.h"
#import "ZebraModelController.h"
#import "RfidAppEngine.h"
#import "config.h"
#import "ui_config.h"

@interface ZebraRFIDController ()<zt_IRfidAppEngineDevListDelegate> {
    ZebraRFIDController *zebraRfid;

}
@property (strong, nonatomic) IBOutlet UIButton *Settings;
@property (strong, nonatomic) IBOutlet UIButton *Inventory;
@property (strong, nonatomic) IBOutlet UIButton *backToZebraModel;
/** 数组 */
@property (strong, nonatomic) NSMutableArray *avaliableReadersList;


@end

@implementation ZebraRFIDController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.Settings.layer.cornerRadius = 10.0;
    self.Inventory.layer.cornerRadius = 10.0;
    self.backToZebraModel.layer.cornerRadius = 10.0;
    [[zt_RfidAppEngine sharedAppEngine] addDeviceListDelegate:self];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)backToZebraRFID:(id)sender {
    ZebraModelController *model = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    self.view.window.rootViewController = model;
}

- (void)dealloc {
    [_avaliableReadersList release];
    [_Settings release];
    [_Inventory release];
    [_backToZebraModel release];
    [[zt_RfidAppEngine sharedAppEngine] removeDeviceListDelegate:self];
    [super dealloc];
}

- (BOOL)deviceListHasBeenUpdated {
    return YES;


}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

//- (BOOL)deviceListHasBeenUpdated {
//    return YES;
//}

@end
