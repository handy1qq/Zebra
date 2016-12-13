//
//  ZebraInventoryController.m
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/6.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraInventoryController.h"
#import "config.h"
#import "ui_config.h"
#import "AlertView.h"
#import "InventoryItem.h"
#import "ZebraInventoryCell.h"
#import "ScannerListTable.h"
#import "AppSettingsKeys.h"
#define ZT_INVENTORY_CFG_OPTION_COUNT        5

#define ZT_INVENTORY_TIMER_INTERVAL          0.2



@interface ZebraInventoryController ()

@end

@implementation ZebraInventoryController


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        //m_standartCellHeight = -1;
        
        m_OffscreenTagCell = [[zt_RFIDTagCellView alloc] init];
        m_ExpandedCellIdx = -1;
        
        m_btnOptions = [[UIBarButtonItem alloc] initWithTitle:@"Options" style:UIBarButtonItemStylePlain target:self action:@selector(btnOptionsPressed)];
        
        //选择EPC，User
        m_Mapper = [[zt_EnumMapper alloc] initWithMEMORYBANKMapperForInventory];
        
        m_InventoryOptions = [[m_Mapper getStringArray] retain];
        
        m_SelectedInventoryOption = [[[zt_RfidAppEngine sharedAppEngine] appConfiguration] getSelectedInventoryMemoryBankUI];
        [m_btnOptions setTitle:[m_Mapper getStringByEnum:m_SelectedInventoryOption]];
        
        m_Tags = [[NSMutableArray alloc] init];
        
        //m_SearchString = [[NSMutableString alloc] init];
    }
    return self;
}

- (void)setLabelTextToFit:(NSString*)text forLabel:(UILabel*)label withMaxFontSize:(float)max_font_size
{
    float lbl_height = label.frame.size.height;
    float lbl_width = label.frame.size.width;
    
    CGFloat font_size = max_font_size + 1.0;
    CGSize text_size;
    
    do
    {
        font_size--;
        text_size = [text sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:font_size]}];
        
    } while ((text_size.height > lbl_height) || (text_size.width > lbl_width));
    
    [label setFont:[UIFont systemFontOfSize:font_size]];
    [label setText:text];
}


- (void)btnOptionsPressed
{
    UIActionSheet *_options_menu = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    
    for (int i = 0; i < [m_InventoryOptions count]; i++)
    {
        [_options_menu addButtonWithTitle:[NSString stringWithFormat:@"%@ %@ \u2001", (([m_Mapper getIndxByEnum:m_SelectedInventoryOption] == i) ? @"\u2713" : @"\u2001"), (NSString*)[m_InventoryOptions objectAtIndex:i]]];
    }
    
    /* recolor & center */
    NSString *_offset_str = @"\u2713 ";
    UIButton *_btn = nil;
    UIColor *_txt_color = [UIColor blackColor];
    float _offset = [_offset_str sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:ZT_UI_INVENTORY_FONT_SZ_BIG]}].width;
    
    
    NSArray *_views = [_options_menu subviews];
    for (UIView *_vw in _views)
    {
        if (YES == [_vw isKindOfClass:[UIButton class]])
        {
            _btn = (UIButton*)_vw;
            
            [_btn.titleLabel setTextColor:_txt_color];
            [_btn.titleLabel setFont:[UIFont systemFontOfSize:ZT_UI_INVENTORY_FONT_SZ_BIG]];
            
            [((UIButton*)_vw).titleLabel setTextAlignment:NSTextAlignmentCenter];
            [((UIButton*)_vw) setContentEdgeInsets:UIEdgeInsetsMake(0.0, -_offset, 0.0, 0.0)];
        }
    }
    
    _options_menu.cancelButtonIndex = [_options_menu addButtonWithTitle:@"Hide"];
    
    [_options_menu showFromTabBar:self.tabBarController.tabBar];
    [_options_menu release];
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[[zt_RfidAppEngine sharedAppEngine] operationEngine] addOperationListener:self];
    [[zt_RfidAppEngine sharedAppEngine] addTriggerEventDelegate:self];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSearchFieldChanged:) name:UITextFieldTextDidChangeNotification object:m_txtSearch];
//    
    /* add options button */
    NSMutableArray *right_items = [[NSMutableArray alloc] init];
    
    [right_items addObject:m_btnOptions];
    [right_items addObject:barButtonDpo];
    
    self.tabBarController.navigationItem.rightBarButtonItems = right_items;
    
    [right_items removeAllObjects];
    [right_items release];
    
    /* set title */
    [self.tabBarController setTitle:@"Inventory"];
    
    /* load saved search criteria */
//    [m_SearchString setString:[[[zt_RfidAppEngine sharedAppEngine] appConfiguration] getTagSearchCriteria]];
//    [m_txtSearch setText:m_SearchString];
    
    /* load saved selected index */
    m_ExpandedCellIdx = [[[zt_RfidAppEngine sharedAppEngine] appConfiguration] getSelectedInventoryItemIndex];
    
    BOOL is_inventory = (ZT_RADIO_OPERATION_INVENTORY == [[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateOperationType]);
    
    if (NO == is_inventory && ![[[zt_RfidAppEngine sharedAppEngine] activeReader] getBatchModeStatus])
    {
        [self radioStateChangedOperationRequested:NO aType:ZT_RADIO_OPERATION_INVENTORY];
    }
    else
    {
        BOOL requested = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateInventoryRequested];
        if (YES == requested)
        {
            /* simple logic of radioStateChangedOperationRequested w/o cleaning of selected inventory item */
            [UIView performWithoutAnimation:^{
                [_m_btnStartStop setTitle:@"STOP" forState:UIControlStateNormal];
                [_m_btnStartStop layoutIfNeeded];
            }];
            
            [m_btnOptions setEnabled:NO];
            
            [m_Tags removeAllObjects];
            
            [self updateOperationDataUI];
            
            [self radioStateChangedOperationInProgress:[[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateOperationInProgress] aType:ZT_RADIO_OPERATION_INVENTORY];
            if([[[zt_RfidAppEngine sharedAppEngine] activeReader] getBatchModeStatus])
            {
                [m_Tags removeAllObjects];
                //[m_tblTags reloadData];
                batchModeLabel.hidden = NO;
            }
        }
        else
        {
            [self radioStateChangedOperationRequested:requested aType:ZT_RADIO_OPERATION_INVENTORY];
            [self radioStateChangedOperationInProgress:[[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateOperationInProgress] aType:ZT_RADIO_OPERATION_INVENTORY];
        }
    }
}

- (void)radioStateChangedOperationRequested:(BOOL)requested aType:(int)operation_type
{
    if (ZT_RADIO_OPERATION_INVENTORY != operation_type)
    {
        return;
    }
    
    if (YES == requested)
    {
        [UIView performWithoutAnimation:^{
            [_m_btnStartStop setTitle:@"STOP" forState:UIControlStateNormal];
            [_m_btnStartStop layoutIfNeeded];
        }];
        
        [m_btnOptions setEnabled:NO];
        
        /* clear selection information */
        m_ExpandedCellIdx = -1;
        [[[zt_RfidAppEngine sharedAppEngine] appConfiguration] clearTagIdAccessGracefully];
        [[[zt_RfidAppEngine sharedAppEngine] appConfiguration] clearTagIdLocationingGracefully];
        [[[zt_RfidAppEngine sharedAppEngine] appConfiguration] clearSelectedItem];
        
        /* clear tags only on start of new operation */
        [m_Tags removeAllObjects];
        if(batchModeLabel.hidden)
        {
            [m_Tags removeAllObjects];
            //[self.m_tblTags reloadData];
            batchModeLabel.hidden = NO;
        }
        
        [self updateOperationDataUI];
        
    }
    else
    {
        [UIView performWithoutAnimation:^{
            [_m_btnStartStop setTitle:@"START" forState:UIControlStateNormal];
            [_m_btnStartStop layoutIfNeeded];
        }];
        
        [m_btnOptions setEnabled:YES];
        
        /* stop timer */
        if (m_ViewUpdateTimer != nil)
        {
            [m_ViewUpdateTimer invalidate];
            m_ViewUpdateTimer = nil;
        }
        
        if(!batchModeLabel.hidden)
        {
            NSString *statusMsg;
            [[zt_RfidAppEngine sharedAppEngine] getTags:&statusMsg];
            [self updateOperationDataUI];
            batchModeLabel.hidden=YES;
            _m_tblTags.hidden = NO;
            [[zt_RfidAppEngine sharedAppEngine] purgeTags:&statusMsg];
            if (![[[zt_RfidAppEngine sharedAppEngine] activeReader] isActive])
            {
                [[zt_RfidAppEngine sharedAppEngine] reconnectAfterBatchMode];
            }
        }
        /* update statictics */
        [self updateOperationDataUI];
    }
}

- (void)radioStateChangedOperationInProgress:(BOOL)in_progress aType:(int)operation_type
{
    if (ZT_RADIO_OPERATION_INVENTORY != operation_type)
    {
        return;
    }
    
    if (YES == in_progress)
    {
        /* start timer */
        m_ViewUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:ZT_INVENTORY_TIMER_INTERVAL target:self selector:@selector(updateOperationDataUI) userInfo:nil repeats:true];
    }
    else
    {
        /* stop timer */
        if (m_ViewUpdateTimer != nil)
        {
            [m_ViewUpdateTimer invalidate];
            m_ViewUpdateTimer = nil;
        }
        
        /* update statistics */
        [self updateOperationDataUI];
    }
}

- (void)updateOperationDataUI {
    
    NSArray *_tags = [[[[zt_RfidAppEngine sharedAppEngine] operationEngine] inventoryData] getInventoryList:NO];
    
    int tag_count = (int)[zt_InventoryData getUniqueCount:_tags];
    [self setLabelTextToFit:[NSString stringWithFormat:@"%d", tag_count] forLabel:self.uniqueTags withMaxFontSize:19.0];
    
    /* total tags */
    int totalTagCount = [zt_InventoryData getTotalCount:_tags];
    [self setLabelTextToFit:[NSString stringWithFormat:@"%d", totalTagCount] forLabel:self.totalTags withMaxFontSize:19.0];
    
    if (0 < [[[[zt_RfidAppEngine sharedAppEngine] appConfiguration] getTagSearchCriteria] length])
    {
        /* we have search criteria */
        [_tags release];
        
        //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        /*!
         *  从网络拿取数据
         */
        _tags = [[[[zt_RfidAppEngine sharedAppEngine] operationEngine] inventoryData] getInventoryList:YES];
    }
    
    [m_Tags removeAllObjects];
    [m_Tags addObjectsFromArray:_tags];
    
    
        if (nil != _tags)
    {
        [_tags release];
    }

    /* tags data */
    if(![[[zt_RfidAppEngine sharedAppEngine] activeReader] getBatchModeStatus])
    {
        batchModeLabel.hidden = YES;
        [self.m_tblTags reloadData];
    }
}
//
- (void)viewDidLoad {
    [super viewDidLoad];
        [_m_tblTags registerClass:[zt_RFIDTagCellView class] forCellReuseIdentifier:ZT_CELL_ID_TAG_DATA];    batchModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 200, 500, 50)];
    batchModeLabel.hidden = YES;
    batchModeLabel.text = @"Inventory running in Batch Mode";
    [self.view addSubview:batchModeLabel];
    [self.m_tblTags reloadData];
    [[zt_ScannerAppEngine sharedAppEngine] addDevListDelegate:self];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStartStopPressed:(id)sender {
    BOOL inventory_requested = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateInventoryRequested];
    SRFID_RESULT rfid_res = SRFID_RESULT_FAILURE;
    NSString *status = [[NSString alloc] init];
    if (NO == inventory_requested)
    {
        rfid_res = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] startInventory:YES aMemoryBank:m_SelectedInventoryOption message:&status];
        [self.m_tblTags reloadData];
        if ([status isEqualToString:@"Inventory Started in Batch Mode"]) {
            [m_Tags removeAllObjects];
           // [self.m_tblTags reloadData];
            batchModeLabel.hidden = NO;
            [UIView performWithoutAnimation:^{
                [self.m_btnStartStop setTitle:@"STOP" forState:UIControlStateNormal];
                [self.m_btnStartStop layoutIfNeeded];
            }];
        }
    }
    else
    {
        rfid_res = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] stopInventory:nil];
        if(!batchModeLabel.hidden)
        {
            NSString *statusMsg;
            [[zt_RfidAppEngine sharedAppEngine] getTags:&statusMsg];
            [self updateOperationDataUI];
            batchModeLabel.hidden=YES;
            self.m_tblTags.hidden = NO;
            [[zt_RfidAppEngine sharedAppEngine] purgeTags:&statusMsg];
            if (![[[zt_RfidAppEngine sharedAppEngine] activeReader] isActive])
            {
                [[zt_RfidAppEngine sharedAppEngine] reconnectAfterBatchMode];
            }
        }
        
    }
}

- (BOOL)onNewTriggerEvent:(BOOL)pressed
{
//    NSArray *scannerList = [[zt_ScannerAppEngine sharedAppEngine] getAvailableScannersList];
//    SbtScannerInfo *info = nil;
//    for (int i = 0; i < [scannerList count]; i++)
//    {
//        info = (SbtScannerInfo*)[scannerList objectAtIndex:i];
//        int mscannerID = [info getScannerID];
//        SbtScannerInfo *scanner_info = [[zt_ScannerAppEngine sharedAppEngine] getScannerByID:mscannerID];
//        if ([scanner_info getScannerModel] == SBT_DEVMODEL_SSI_RFD8500) {
//            ScannerListTable *listTable = (ScannerListTable *)[[UIStoryboard storyboardWithName:@"ZebraScanner" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"ID_SCANNERS_TABLE_VC"];
//            if (listTable != nil) {
//                [self.navigationController pushViewController:listTable animated:YES];
//                return YES;
//            }
//        }
//    }
//
    
    NSInteger op_mode = [[NSUserDefaults standardUserDefaults] integerForKey:ZT_SETTING_OPMODE];
    
    if (op_mode ==
        SRFID_CONNTYPE_INVALID) {
        ScannerListTable *listTable = (ScannerListTable *)[[UIStoryboard storyboardWithName:@"ZebraScanner" bundle:[NSBundle mainBundle]]instantiateViewControllerWithIdentifier:@"ID_SCANNERS_TABLE_VC"];
        if (listTable != nil) {
            [self.navigationController pushViewController:listTable animated:YES];
            return YES;
        }
    }
    
    __block ZebraInventoryController *__weak_self = self;
    BOOL requested = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] getStateInventoryRequested];
    
    if (YES == pressed)
    {
        /* trigger press -> start operation if start trigger immediate */
        
        if (YES == [[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] isStartTriggerImmediate])
        {
            /* immediate start trigger */
            
            if (NO == requested)
            {
                /* operation is not in progress / requested */
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   [__weak_self btnStartStopPressed:nil];
                               });
            }
        }
    }
    else
    {
        /* trigger release -> stop operation if stop trigger immediate */
        
        if (YES == [[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] isStopTriggerImmediate])
        {
            /* immediate stop trigger */
            
            if (YES == requested)
            {
                dispatch_async(dispatch_get_main_queue(),
                               ^{
                                   [__weak_self btnStartStopPressed:nil];
                               });
            }
        }
    }
    return YES;
    
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"hhhhhhhhhhhhh");
    return  [m_Tags count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSLog(@"eeeeeeeeeeee");
    static NSString *RFIDTagCellIdentifier = ZT_CELL_ID_TAG_DATA;
    
    zt_RFIDTagCellView *tag_cell = [tableView dequeueReusableCellWithIdentifier:RFIDTagCellIdentifier forIndexPath:indexPath];
    
    if (tag_cell == nil)
    {
        tag_cell = [[zt_RFIDTagCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:RFIDTagCellIdentifier];
    }
    
    BOOL expanded = ((m_ExpandedCellIdx == [indexPath row]) ? YES : NO);
    
    [self configureTagCell:tag_cell forRow:(int)[indexPath row] isExpanded:expanded];
    
    [tag_cell setNeedsUpdateConstraints];
    [tag_cell updateConstraintsIfNeeded];

    //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"a"];
   // [self configureTagCell:cell forRow:(int)[indexPath row] isExpanded:expanded];

   // cell.textLabel.text = @"s";
    
    return tag_cell;

}
- (void)configureTagCell:(zt_RFIDTagCellView*)tag_cell forRow:(int)row isExpanded:(BOOL)expanded
{
    /* TBD */
    zt_InventoryItem *tag_data = (zt_InventoryItem *)[m_Tags objectAtIndex:row];
    
    [tag_cell setTagData:tag_data.getTagId];
    
    [tag_cell setTagCount:[NSString stringWithFormat:@"%d", tag_data.getRSSI]];
    if (YES == expanded)
    {
        [tag_cell setBankIdentifier:(NSString*)[m_Mapper getStringByEnum:[[[zt_RfidAppEngine sharedAppEngine] operationEngine] getInventoryMemoryBank]]];
        
        [tag_cell setBankData:[NSString stringWithFormat:@"%@", tag_data.getMemoryBankData]];
        
        srfidReportConfig *report_fields = [[[zt_RfidAppEngine sharedAppEngine] operationEngine] getInventoryReportConfig];
        
        if (YES == [report_fields getIncPC])
        {
            [tag_cell setPCData:tag_data.getPC];
        }
        else
        {
            [tag_cell setUnperfomPCData];
        }
        
        if (YES == [report_fields getIncRSSI])
        {

        }
        else
        {
            [tag_cell setUnperfomRSSIData];
        }
        
        if (YES == [report_fields getIncPhase])
        {
            [tag_cell setPhaseData:tag_data.getPhase];
            
        }
        else
        {
            [tag_cell setUnperfomPhaseData];
        }
        
        if (YES == [report_fields getIncChannelIndex])
        {
            [tag_cell setChannelData:tag_data.getChannelIndex];
        }
        else
        {
            [tag_cell setUnperfomChannelData];
        }
        if (YES == [report_fields getIncTagSeenCount])
        {
           // [tag_cell setTagCount:[NSString stringWithFormat:@"%d",tag_data.getCount]];
        }
        else
        {
            [tag_cell setUnperfomTagSeenCount];
        }
        [report_fields release];
    }
    
    [tag_cell configureViewMode:expanded];
}



- (void)dealloc {
    
    [[zt_ScannerAppEngine sharedAppEngine] removeDevListDelegate:self];
    [_uniqueTags release];
    [_totalTags release];
    [_m_btnStartStop release];
    [_m_tblTags release];
    if(nil != m_Mapper)
    {
        [m_Mapper release];
    }
    
    if (nil != m_Tags)
    {
        [m_Tags removeAllObjects];
        [m_Tags release];
    }
    
    if (nil != m_OffscreenTagCell)
    {
        [m_OffscreenTagCell release];
    }
    
    if (nil != m_btnOptions)
    {
        [m_btnOptions release];
    }
    
    if (nil != m_InventoryOptions)
    {
        [m_InventoryOptions removeAllObjects];
        [m_InventoryOptions release];
    }
    [super dealloc];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[[zt_RfidAppEngine sharedAppEngine] operationEngine] removeOperationListener:self];
    [[zt_RfidAppEngine sharedAppEngine] removeTriggerEventDelegate:self];
    /* stop timer */
    if (m_ViewUpdateTimer != nil)
    {
        [m_ViewUpdateTimer invalidate];
        m_ViewUpdateTimer = nil;
    }
    
}

@end
