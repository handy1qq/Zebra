//
//  ScannerAppController.m
//  ZebraRFD8500Scanner
//
//  Created by fengwenwei on 16/12/1.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ScannerAppController.h"
#import "ActiveScannerVC.h"
#import "config.h"
#import "ScannerListTable.h"
#import "ZebraModelController.h"
#import "ZebraActiveScannerController.h"

typedef enum {
    MENU_INDEX_CONNECTION = 0,
    MENU_INDEX_APP_SETTINGS,
    MENU_INDEX_TOTAL

} MainMenuIndex;


@interface ScannerAppController ()

@end

@implementation ScannerAppController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [[zt_ScannerAppEngine sharedAppEngine] addDevEventsDelegate:self];
    }
    return self;
}

- (void)dealloc {
    [self.tableView setDataSource:nil];
    [self.tableView setDelegate:nil];
    [[zt_ScannerAppEngine sharedAppEngine] removeDevEventsDelegate:self];

    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = [ [UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStyleDone target:self action:@selector(back)];
}

- (void)back {
    ZebraModelController *model = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    self.view.window.rootViewController = model;

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scannerBarcodeEvent:(NSData *)barcodeData barcodeType:(int)barcodeType fromScanner:(int)scannerID {
    [self displayBarcodeFromScannerId:scannerID];
    
}

- (void) displayBarcodeFromScannerId:(int)scannerId
{
    UIViewController *topVc;
    
    topVc = [self.navigationController topViewController];
    
    if ([topVc isKindOfClass:[ZebraActiveScannerController class]] == YES)
    {
        // is this active scanner vc for the current scanner id?
        if ([(ZebraActiveScannerController*)topVc getScannerID] == scannerId)
        {
            // yes it is, show the barcode information
            [(ZebraActiveScannerController*)topVc showBarcode];
        }
    } else {

    UINavigationController *mainNavVc;
    ScannerListTable *scanner_vc = nil;
    if ([topVc isKindOfClass:[ScannerListTable class]]) {
        
        scanner_vc = (ScannerListTable *)[[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ID_SCANNERS_TABLE_VC"];
    }
    
    [mainNavVc popToRootViewControllerAnimated:NO];
    if (scanner_vc != nil) {
        [mainNavVc pushViewController:scanner_vc animated:YES];
        [scanner_vc showActiveScannerVC:[NSNumber numberWithInt:scannerId] aBarcodeView:YES aAnimated:NO];
    }
    }
}

- (void)showScannerRelatedUI:(int)scannerID barcodeNotification:(BOOL)barcode {
    if (barcode == NO) {
        SbtScannerInfo *info = [[zt_ScannerAppEngine sharedAppEngine] getScannerByID:scannerID];
        
        ScannerListTable *scanner_vc = nil;
        scanner_vc = (ScannerListTable *)[[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ID_SCANNERS_TABLE_VC"];
        if (info != nil) {
            if ([info isActive]) {
                [self.navigationController pushViewController:scanner_vc animated:YES];
                [scanner_vc showActiveScannerVC:[NSNumber numberWithInt:scannerID] aBarcodeView:barcode aAnimated:NO];
                
            }
        }
    }
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MENU_INDEX_TOTAL;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (MENU_INDEX_CONNECTION == indexPath.row) {
        ScannerListTable *scanner_vc = nil;
        scanner_vc = (ScannerListTable *)[[UIStoryboard storyboardWithName:@"ZebraScanner" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ID_SCANNERS_TABLE_VC"];
        if (scanner_vc != nil) {
            [self.navigationController pushViewController:scanner_vc animated:YES];
        }
        
    }




}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
