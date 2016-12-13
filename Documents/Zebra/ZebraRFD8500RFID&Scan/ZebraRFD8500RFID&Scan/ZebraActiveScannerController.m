//
//  ZebraActiveScannerController.m
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/7.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraActiveScannerController.h"
#import "FwwTabBar.h"
#import "ScannerListTable.h"
#import "config.h"
#import "ZebraActiveScannerBarcodeController.h"

@interface ZebraActiveScannerController ()


@end

@implementation ZebraActiveScannerController

@dynamic tabBar;

- (id)initWithCoder:(NSCoder *)aDecoder {
    [super initWithCoder:aDecoder];
    if (self != nil) {
        m_ScannerID = SBT_SCANNER_ID_INVALID;
        m_WillDisappear = NO;
        [[zt_ScannerAppEngine sharedAppEngine] addDevConnectionsDelegate:self];
        
    }
    return self;
}

- (void)dealloc
{
    [[zt_ScannerAppEngine sharedAppEngine] removeDevConnectiosDelegate:self];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.tabBar = [[FwwTabBar alloc] init];
//    [self.tabBar setTabBar:self.tabBarController];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
   
}


- (void)setScannerID:(int)scannerID {
    m_ScannerID = scannerID;
    [[zt_ScannerAppEngine sharedAppEngine] getScannerByID:m_ScannerID];
    NSMutableArray *vc = [[NSMutableArray alloc] init];
    [vc addObject:[[self viewControllers] objectAtIndex:0]]; /* info tab */
    [vc addObject:[[self viewControllers] objectAtIndex:1]]; /* decode tab */
  //  [vc addObject:[[self viewControllers] objectAtIndex:3]]; /* settings tab tab */
    [self setViewControllers:vc];
    [vc removeAllObjects];
    [vc release];

}

- (int)getScannerID {
    return m_ScannerID;
    
}

- (void)showBarcode {
    [self showBarcodeList];
    [(ZebraActiveScannerBarcodeController*)[self selectedViewController] showBarcode];
}

- (void)showBarcodeList {

    [self setSelectedViewController:[self.viewControllers objectAtIndex:1]];
}

- (BOOL)scannerHasAppeared:(int)scannerID
{
    /* should not matter */
    return NO; /* we have not processed the notification */
}

- (BOOL)scannerHasDisappeared:(int)scannerID
{
    if (scannerID == m_ScannerID)
    {
        /*
         // All alerts are in ScannerAppEngine
         UIAlertView *alert = [[UIAlertView alloc]
         initWithTitle:MOT_SCANNER_APP_NAME
         message:@"Active scanner has disappeared"
         delegate:nil
         cancelButtonTitle:@"OK"
         otherButtonTitles:nil];
         [alert show];
         [alert release];
         */
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            /* iphone */
            for (UIViewController *vc in [self.navigationController viewControllers])
            {
                if ([vc isKindOfClass:[ScannerListTable class]] == YES)
                {
                    /* nrv364:
                     we should pop exactly to scanner list view controller
                     it is actual for active scanner VC as active scanner VC could be
                     not on the top of stack (e.g. symbologies or beeper/led action vc
                     could be presented)
                     as available scanner VC should be always on top of navigation
                     stack, the available scanner VC may just pop itself
                     */
                    if (NO == m_WillDisappear)
                    {
                        m_WillDisappear = YES;
                        [self.navigationController popToViewController:vc animated:YES];
                    }
                    
                }
            }
        }
        else
        {
            /* ipad */
            /* do nothing; all logic is in ScannersTableVC */
        }
        return YES; /* we have processed the notification */
    }
    return NO; /* we have not processed the notification */
}

- (BOOL)scannerHasConnected:(int)scannerID
{
    /* should not matter */
    return NO; /* we have not processed the notification */
}

- (BOOL)scannerHasDisconnected:(int)scannerID
{
    if (scannerID == m_ScannerID)
    {
        /*
         // All alerts are in ScannerAppEngine
         UIAlertView *alert = [[UIAlertView alloc]
         initWithTitle:MOT_SCANNER_APP_NAME
         message:@"Communication session has been terminated"
         delegate:nil
         cancelButtonTitle:@"OK"
         otherButtonTitles:nil];
         [alert show];
         [alert release];
         */
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        {
            /* iphone */
            for (UIViewController *vc in [self.navigationController viewControllers])
            {
                if ([vc isKindOfClass:[ScannerListTable class]] == YES)
                {
                    /* nrv364:
                     we should pop exactly to scanner list view controller
                     it is actual for active scanner VC as active scanner VC could be
                     not on the top of stack (e.g. symbologies or beeper/led action vc
                     could be presented)
                     as available scanner VC should be always on top of navigation
                     stack, the available scanner VC may just pop itself
                     */
                    /* after disconnection available vc will be shown with animation;
                     the animated poping will cause UI degradation */
                    
                    if (NO == m_WillDisappear)
                    {
                        m_WillDisappear = YES;
                        [self.navigationController popToViewController:vc animated:NO];
                    }
                }
            }
        }
        else
        {
            /* ipad */
            /* do nothing; all logic is in ScannersTableVC */
        }
        return YES; /* we have processed the notification */
    }
    return NO; /* we have not processed the notification */
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
