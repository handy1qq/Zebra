//
//  ScannerListTable.m
//  ZebraRFD8500Scanner
//
//  Created by fengwenwei on 16/12/1.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ScannerListTable.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "AlertView.h"
#import "ConnectionManager.h"
#import "config.h"
#import "AppSettingsKeys.h"
#import "ZebraActiveScannerController.h"

@interface ScannerListTable ()

/** scanner list */
@property (strong, nonatomic) NSArray *m_tableData;


@end

@implementation ScannerListTable

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        m_EmptyDeviceList = YES;
        
        self.m_tableData = [[NSArray alloc] init];
        
        m_CurrentScannerActive = NO;
        m_CurrentScannerId = SBT_SCANNER_ID_INVALID;
        
//        m_btnUpdateDevList = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(btnUpdateScannersListPressed)];
        
        [[zt_ScannerAppEngine sharedAppEngine] addDevListDelegate:self];
        [[zt_ScannerAppEngine sharedAppEngine] addDevConnectionsDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [[zt_ScannerAppEngine sharedAppEngine] removeDevListDelegate:self];
    [[zt_ScannerAppEngine sharedAppEngine] removeDevConnectiosDelegate:self];
    
    [self.tableView setDataSource:nil];
    [self.tableView setDelegate:nil];
    
    if (self.m_tableData != nil) {
        [self.m_tableData release];
    }
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scannersListHasBeenUpdated];
}

- (BOOL)scannersListHasBeenUpdated {
    [self.tableView reloadData];
    
    self.m_tableData = [[zt_ScannerAppEngine sharedAppEngine] getAvailableScannersList];
    [[self tableView] reloadData];
    
    if ([self.m_tableData count] > 0)
    {
        /* for iPad only: we should select some row in master view to show smth in
         detail view of split view controller */
        
        /* determine actual status of previously selected scanner */
        NSArray *lst = self.m_tableData;
        BOOL found = NO;
        int selected_scanner_idx = 0;
        SbtScannerInfo *info = nil;
        for (int i = 0; i < [lst count]; i++)
        {
            info = (SbtScannerInfo*)[lst objectAtIndex:i];
            
            if ([info isActive])
            {
                /* previously selected scanner is still at least available */
                /* get new idx of previously selected scanner */
                selected_scanner_idx = i;
                found = YES;
                break;
            }
        }
        
        if (YES == found) {
            info = (SbtScannerInfo *)[lst objectAtIndex:selected_scanner_idx];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                if ([info isActive] != m_CurrentScannerActive)
                {
                    [[self tableView] selectRowAtIndexPath:[NSIndexPath indexPathForRow:selected_scanner_idx inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
                    
                    // ipad
                    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:selected_scanner_idx inSection:0]];
                }
                else
                {
                    // iphone
                    [[self tableView] selectRowAtIndexPath:[NSIndexPath indexPathForRow:selected_scanner_idx inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
                }
            }
        }

        else
        {
            /* previously selected scanner is not available now */
            /* iphone -> show scanner list */
            /* ipad -> select just first scanner in the list */
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                /* ipad */
                //zt_TabletNoticeVC *notice_vc = (zt_TabletNoticeVC*)[[UIStoryboard storyboardWithName:@"ScannerDemoAppStoryboard-iPad" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ID_NOTICE_VC"];
//                if (notice_vc != nil)
//                {
//                    [notice_vc setNotice:@"Select a scanner." withTitle:@"Scanners"];
//                    
//                    UINavigationController *detail_vc = (UINavigationController*)[[self.splitViewController viewControllers] objectAtIndex:1];
//                    [detail_vc setViewControllers:[NSArray arrayWithObjects:notice_vc, nil] animated:NO];
//                    
//                }
            }
            
        }
    }
    //array = 0
    else
    {
        m_CurrentScannerId = SBT_SCANNER_ID_INVALID;
        
        /* ipad -> show notice vc in details view */
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            /* ipad */
//            zt_TabletNoticeVC *notice_vc = (zt_TabletNoticeVC*)[[UIStoryboard storyboardWithName:@"ScannerDemoAppStoryboard-iPad" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ID_NOTICE_VC"];
//            if (notice_vc != nil)
//            {
//                [notice_vc setNotice:@"Scanners are not found." withTitle:@"Scanners"];
//                
//                UINavigationController *detail_vc = (UINavigationController*)[[self.splitViewController viewControllers] objectAtIndex:1];
//                [detail_vc setViewControllers:[NSArray arrayWithObjects:notice_vc, nil] animated:NO];
//                
//            }
        }
    }
        return YES;


}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"Connect"];
    self.clearsSelectionOnViewWillAppear = YES;
    [ConnectionManager sharedConnectionManager];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = [self.m_tableData count];
    if (count == 0) {
        count = 1;
        m_CurrentScannerId = SBT_SCANNER_ID_INVALID;
        m_EmptyDeviceList = YES;
    } else {
        m_EmptyDeviceList = NO;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *ActiveScannerCellIdentifier = @"ActiveScannerCell";
    static NSString *AvailableScannerCellIdentifier = @"AvailableScannerCell";
    static NSString *NoScannerCellIdentifier = @"NoScannerCell";
    
    UITableViewCell *cell = nil;
    if (m_EmptyDeviceList == NO) {
        
    
    
    SbtScannerInfo *info = [self.m_tableData objectAtIndex:(int)[indexPath row]];
    
    if ([info isActive] == YES ) {
        cell = [tableView dequeueReusableCellWithIdentifier:ActiveScannerCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ActiveScannerCellIdentifier];
        }
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@",@"\u2713",[info getScannerName]];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:AvailableScannerCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AvailableScannerCellIdentifier];
        }
        cell.textLabel.text =[NSString stringWithFormat:@"%@%@",@"\u2001",[info getScannerName]];
    }
    switch ([info getConnectionType]) {
        case SBT_CONNTYPE_MFI:
            cell.detailTextLabel.text = @"MFI";
            break;
        case SBT_CONNTYPE_BTLE:
            cell.detailTextLabel.text = @"BTLE";
            break;
        case SBT_CONNTYPE_INVALID:
            cell.detailTextLabel.text = @"Unknow Type";
            break;
        default:
  
            break;
    }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:NoScannerCellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NoScannerCellIdentifier];
        }
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone ];
        cell.textLabel.text = @"No device connected";
    
    }
    return cell;
}


- (void)showActiveScannerVC:(NSNumber *)scannerID aBarcodeView:(BOOL)barcodeView aAnimated:(BOOL)animated {
    int scanner_id = [scannerID intValue];
    m_CurrentScannerId = scanner_id;
    m_CurrentScannerActive =YES;
    
    ZebraActiveScannerController *active_vc = nil;
    
    active_vc = (ZebraActiveScannerController *)[[UIStoryboard storyboardWithName:@"ZebraScanner" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"ID_ACTIVE_SCANNER_VC"];
    if (active_vc != nil) {
        [active_vc setScannerID:scanner_id];
        [self.navigationController pushViewController:active_vc animated:YES];
        if (YES == barcodeView) {
            [active_vc showBarcodeList];
        }
        [active_vc release];
        
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell != nil) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    if (m_EmptyDeviceList == NO) {
        SbtScannerInfo *info = [self.m_tableData objectAtIndex:(int)[indexPath row]];
        if ([info isActive]) {
            [self showActiveScannerVC:[NSNumber numberWithInt:[info getScannerID]] aBarcodeView:NO aAnimated:YES];
        }
     else {
        zt_AlertView *alert = [[zt_AlertView alloc] init];
         [alert showAlertWithView:self.view withTarget:self withMethod:@selector(connectToScanner:) withObject:info withString:@"Connecting...."];
     }
    }
}


- (void) connectToScanner :(SbtScannerInfo *)scannerInfo
{
    [[ConnectionManager sharedConnectionManager] connectDeviceUsingScannerId:[scannerInfo getScannerID]];
}

- (BOOL)scannerHasAppeared:(int)scannerID {

    return NO;
}
- (BOOL)scannerHasDisappeared:(int)scannerID {

    return NO;

}
- (BOOL)scannerHasConnected:(int)scannerID {

    [self showActiveScannerVC:[NSNumber numberWithInt:scannerID] aBarcodeView:NO aAnimated:NO];
    return YES;

}
- (BOOL)scannerHasDisconnected:(int)scannerID {
    return NO;
}




/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
