//
//  ZebraActiveScannerBarcodeController.m
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/7.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraActiveScannerBarcodeController.h"
#import "ZebraBarcodeEventController.h"
#import "BarcodeTypes.h"
#import "config.h"
#import "ScannerAppEngine.h"
#import "ZebraActiveScannerController.h"
#import "DecodeEvent.h"
#import "BarcodeList.h"
#import "SbtSdkDefs.h"
@interface ZebraActiveScannerBarcodeController ()

@end

@implementation ZebraActiveScannerBarcodeController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        m_ScannerID = -1;
        m_HideModeSwitch = NO;
        m_BarcodeList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
//    if (m_BusyIndicator != nil)
//    {
//        [m_BusyIndicator stopAnimating];
//        [m_BusyIndicator release];
//    }
    
    if (m_BarcodeList != nil)
    {
        [m_BarcodeList removeAllObjects];
        [m_BarcodeList release];
    }
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.e];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (m_ScannerID == -1)
    {
        m_ScannerID = [(ZebraActiveScannerController*)self.tabBarController getScannerID];
        
        SbtScannerInfo *scanner_info = [[zt_ScannerAppEngine sharedAppEngine] getScannerByID:m_ScannerID];
        
        /* Hide the unsupported mode switch for CS4070 and RFD8500 scanners */
        if ([scanner_info getScannerModel] == SBT_DEVMODEL_SSI_CS4070 ||
            [scanner_info getScannerModel] == SBT_DEVMODEL_SSI_RFD8500)
        {
            m_HideModeSwitch = YES;
        }
        
    }
    
    [self showBarcode];
    
//    if (m_BusyIndicator == nil)
//    {
//        m_BusyIndicator = [[UIActivityIndicatorView alloc]
//                           initWithFrame:CGRectMake(0.0f, 0.0f, 20.0f, 20.0f)];
//        [m_BusyIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
//        
//        [m_BusyIndicator setColor:[UIColor redColor]];
//        
//        m_BusyIndicator.hidesWhenStopped = YES;
//        
//        [self.view addSubview:m_BusyIndicator];
//        
//        m_BusyIndicator.center = self.view.center;
//    }
}

- (void)showBarcode
{
    NSArray *tmp_barcode_lst = [[zt_ScannerAppEngine sharedAppEngine] getScannerBarcodesByID:m_ScannerID];
    [m_BarcodeList removeAllObjects];
    [m_BarcodeList addObjectsFromArray:tmp_barcode_lst];
    
    UITableView *tb = [self tableView];
    if (tb != nil)
    {
        /* show updated barcode list for this scanner */
        [tb reloadData];
        
        /* scroll to top to show most recent barcode */
        [tb setContentOffset:CGPointZero animated:YES];
    }
}

- (void)performActionTriggerPull:(NSString*)param
{
    SBT_RESULT res = [[zt_ScannerAppEngine sharedAppEngine] executeCommand:SBT_DEVICE_PULL_TRIGGER aInXML:param aOutXML:nil forScanner:m_ScannerID];
    
    //[m_BusyIndicator stopAnimating];
    
    if (res != SBT_RESULT_SUCCESS)
    {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           UIAlertView *alert = [[UIAlertView alloc]
                                                 initWithTitle:ZT_SCANNER_APP_NAME
                                                 message:@"Cannot perform [Trigger Pull] action"
                                                 delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
                           [alert show];
                           [alert release];
                       }
                       );
    }
}
- (void)performActionTriggerRelease:(NSString*)param
{
    SBT_RESULT res = [[zt_ScannerAppEngine sharedAppEngine] executeCommand:SBT_DEVICE_RELEASE_TRIGGER aInXML:param aOutXML:nil forScanner:m_ScannerID];
    
    // [m_BusyIndicator stopAnimating];
    
    if (res != SBT_RESULT_SUCCESS)
    {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           UIAlertView *alert = [[UIAlertView alloc]
                                                 initWithTitle:ZT_SCANNER_APP_NAME
                                                 message:@"Cannot perform [Trigger Release] action"
                                                 delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
                           [alert show];
                           [alert release];
                       }
                       );
    }
}

- (void)performActionBarcodeMode:(NSString*)param
{
    SBT_RESULT res = [[zt_ScannerAppEngine sharedAppEngine] executeCommand:SBT_DEVICE_CAPTURE_BARCODE aInXML:param aOutXML:nil forScanner:m_ScannerID];
    
    // [m_BusyIndicator stopAnimating];
    
    if (res != SBT_RESULT_SUCCESS)
    {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           UIAlertView *alert = [[UIAlertView alloc]
                                                 initWithTitle:ZT_SCANNER_APP_NAME
                                                 message:@"Cannot perform [Scanner Mode] action"
                                                 delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
                           [alert show];
                           [alert release];
                       }
                       );
    }
}

#pragma mark - Table view data source
/* ###################################################################### */
/* ########## Table View Data Source Delegate Protocol implementation ### */
/* ###################################################################### */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 3 - (YES == m_HideModeSwitch ? 1 : 0);
        case 1:
            if ([m_BarcodeList count] > 0)
            {
                return [m_BarcodeList count];
            }
            else
            {
                return 1;
            }
        default:
            return 0;
    }
}

//-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    if (0 == section)
//    {
//        return @"Actions";
//    }
//    else if (1 == section)
//    {
//        return [NSString stringWithFormat:@"Barcode List: Count = %d",(unsigned int)[m_BarcodeList count]];
//    }
//    return @"Unknown";
//}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    /* Add custom section header for the Barcode list section in the table */
//    if (1 == section)
//    {
//        /* Specify component sizes */
//        CGFloat headerWidth = self.tableView.frame.size.width;
//        CGFloat headerHeight = 20.0f;
//        CGFloat btnWidth = 60.0f;
//        CGFloat btnHeight = 30.0f;
//
//        /* Create custom view for section header */
//        UITableViewHeaderFooterView *customHeaderView = [[[UITableViewHeaderFooterView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, headerWidth, headerHeight)] autorelease];
//
//        /* Create clear button */
//        UIButton *clearButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//        [clearButton setFrame:CGRectMake(headerWidth-btnWidth, 7.0f, btnWidth, btnHeight)];
//        [clearButton setTitle:@"Clear" forState:UIControlStateNormal];
//        [clearButton setBackgroundColor:[UIColor clearColor]];
//        [clearButton addTarget:self action:@selector(btnClearBarcodeList:) forControlEvents:UIControlEventTouchUpInside];
//        [customHeaderView addSubview:clearButton];
//
//        [clearButton setEnabled:[m_BarcodeList count] > 0 ? true : false];
//        clearButton.translatesAutoresizingMaskIntoConstraints = NO;
//
//        NSLayoutConstraint *clearBtnConstraintRight = [NSLayoutConstraint constraintWithItem:clearButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:customHeaderView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10];
//
//        NSLayoutConstraint *clearBtnConstraintBottom = [NSLayoutConstraint constraintWithItem:clearButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:customHeaderView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
//
//        [customHeaderView addConstraint:clearBtnConstraintRight];
//        [customHeaderView addConstraint:clearBtnConstraintBottom];
//
//        return customHeaderView;
//    }
//
//    return nil;
//}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (0 == [indexPath section]) /* action section */
    {
        static NSString *CellIdentifierAction = @"BarcodeActionCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierAction forIndexPath:indexPath];
        
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierAction];
        }
        
        switch ([indexPath row])
        {
            case 0:
                cell.textLabel.text = @"Pull Trigger";
                break;
            case 1:
            {
                cell.textLabel.text = @"Release Trigger";
                if ([[[zt_ScannerAppEngine sharedAppEngine] getScannerByID:m_ScannerID] getScannerModel] == SBT_DEVMODEL_SSI_CS4070) {
                    cell.textLabel.enabled = NO;
                    cell.userInteractionEnabled = NO;
                }
            }
                
                break;
            case 2:
                cell.textLabel.text = @"Switch to barcode mode";
                break;
            default:
                cell.textLabel.text = @"Unknown";
        }
    }
    else if (1 == [indexPath section]) /* barcode list section */
    {
        if ([m_BarcodeList count] > 0)
        {
            static NSString *CellIdentifierData = @"BarcodeDataCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierData forIndexPath:indexPath];
            
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifierData];
            }
            
            cell.textLabel.text = [(zt_BarcodeData*)[m_BarcodeList objectAtIndex:([m_BarcodeList count] - 1 - [indexPath row])] getDecodeDataAsStringUsingEncoding:NSUTF8StringEncoding];
            
            cell.detailTextLabel.text = get_barcode_type_name([(zt_BarcodeData*)[m_BarcodeList objectAtIndex:([m_BarcodeList count] - 1 - [indexPath row])] getDecodeType]);
        }
        else
        {
            static NSString *CellIdentifierNoData = @"BarcodeNoDataCell";
            cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierNoData forIndexPath:indexPath];
            
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierNoData];
            }
            
            cell.textLabel.text = @"No barcode received";
            cell.detailTextLabel.text = nil;
        }
        [cell reloadInputViews];
        [cell layoutIfNeeded];
    }
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate
/* ###################################################################### */
/* ########## Table View Delegate Protocol implementation ############### */
/* ###################################################################### */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([indexPath section] == 0) /* actions section */
    {
        if ([indexPath row] == 0) /* soft trigger pull */
        {
            /* we are going to perform attempt of scanning */
            
            NSString *in_xml = [NSString stringWithFormat:@"<inArgs><scannerID>%d</scannerID></inArgs>", m_ScannerID];
           // [m_BusyIndicator startAnimating];
            [self performSelectorInBackground:@selector(performActionTriggerPull:) withObject:in_xml];
            NSLog(@"%d",m_ScannerID);
            
            
        }
        else if ([indexPath row] == 1) /* soft trigger release */
        {
            NSString *in_xml = [NSString stringWithFormat:@"<inArgs><scannerID>%d</scannerID></inArgs>", m_ScannerID];
          //  [m_BusyIndicator startAnimating];
            [self performSelectorInBackground:@selector(performActionTriggerRelease:) withObject:in_xml];
        }
    }
    else if (1 == [indexPath section]) /* barcode list section */
    {
        if ([m_BarcodeList count] > 0)
        {
            ZebraBarcodeEventController *barcode_vc = nil;
            
                /* iphone */
                barcode_vc = (ZebraBarcodeEventController*)[[UIStoryboard storyboardWithName:@"ZebraScanner" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"barcodeData"];
        
            if (barcode_vc != nil)
            {
                zt_BarcodeData *decode_event = (zt_BarcodeData*)[m_BarcodeList objectAtIndex:([m_BarcodeList count] - 1 - [indexPath row])];
                [barcode_vc configureAsChild];
                [barcode_vc setBarcodeEventData:decode_event fromScanner:m_ScannerID];
                [self.navigationController pushViewController:barcode_vc animated:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? YES : YES];
                /* barcode_vc is autoreleased object returned by instantiateViewControllerWithIdentifier */
            }
        }
    }
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell != nil)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView reloadData];
        //[cell setSelected:NO animated:YES];
    }
}

/* Clear table containing the scanned barcode list */
//- (IBAction)btnClearBarcodeList:(id)sender
//{
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clear Barcode Data?"
//                                                    message:@"Are you sure that you want to clear all barcode data? This information cannot be restored after it is cleared."
//                                                   delegate:self
//                                          cancelButtonTitle:@"Cancel"
//                                          otherButtonTitles:@"Continue", nil];
//    [alert show];
//    [alert release];
//
//}
//
#pragma mark UIAlertViewDelegate

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    switch(buttonIndex)
//    {
//        case 0: //"Cancel" pressed
//            // don't do anything if user does not want to clear the barcode list
//            break;
//
//        case 1: //"Continue" pressed
//
//            [[zt_ScannerAppEngine sharedAppEngine] clearScannerBarcodesByID:m_ScannerID];
//            [m_BarcodeList removeAllObjects];
//            //[self.tableView reloadData];
//
//            break;
//    }
//}


@end
