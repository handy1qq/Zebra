//
//  ZebraInventoryController.h
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/6.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "BaseDpoVC.h"
#import "RfidAppEngine.h"
#import <UIKit/UIKit.h>
#import "RFIDTagCellView.h"
#import "ZebraInventoryCell.h"
#import "RfidSdkDefs.h"
#import "ScannerAppEngine.h"


@interface ZebraInventoryController : BaseDpoVC<UITableViewDelegate,UITableViewDataSource,zt_IRadioOperationEngineListener,zt_IRfidAppEngineTriggerEventDelegate,UIActionSheetDelegate,IScannerAppEngineDevListDelegate>{
    
    
    zt_RFIDTagCellView *m_OffscreenTagCell;
    int m_ExpandedCellIdx;
    UIBarButtonItem *m_btnOptions;
    NSMutableArray *m_Tags;
    zt_EnumMapper *m_Mapper;
    NSMutableArray *m_InventoryOptions;
    SRFID_MEMORYBANK m_SelectedInventoryOption;
    NSTimer *m_ViewUpdateTimer;
    UILabel *batchModeLabel;


    
}

@property (retain, nonatomic) IBOutlet UILabel *uniqueTags;
@property (retain, nonatomic) IBOutlet UILabel *totalTags;
@property (retain, nonatomic) IBOutlet UIButton *m_btnStartStop;
@property (retain, nonatomic) IBOutlet UITableView *m_tblTags;

- (void)updateOperationDataUI;
- (void)configureTagCell:(zt_RFIDTagCellView*)tag_cell forRow:(int)row isExpanded:(BOOL)expanded;
- (void)configureAppearance;
- (void)setRelativeDistance:(int)distance;
- (void)setLabelTextToFit:(NSString*)text forLabel:(UILabel*)label withMaxFontSize:(float)max_font_size;



@end
