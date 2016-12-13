//
//  ZebraReaderListController.m
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/5.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraReaderListController.h"
#import "RfidAppEngine.h"
#import "RFIDDeviceCellView.h"
#import "ui_config.h"
#define ZT_CELL_ID_READER_INFO                    @"ID_CELL_READER_INFO"
#define ZT_CELL_ID_NO_READER                      @"NO_READER"




@interface ZebraReaderListController ()<UITableViewDataSource,UITableViewDelegate,zt_IRfidAppEngineDevListDelegate> {
    int m_ActiveReaderId;
    int m_ActiveReaderIdx;
    BOOL m_EmptyDevList;
    zt_RFIDDeviceCellView *m_OffScreenTagCell;
}

/**readerlist */
@property (strong, nonatomic) NSMutableArray *readerList;
@property (retain, nonatomic) IBOutlet UITableView *m_tblReaderList;

@end

@implementation ZebraReaderListController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self != nil)
    {
        self.readerList = [[NSMutableArray alloc] init];
        
        m_OffScreenTagCell = [[zt_RFIDDeviceCellView alloc] init];
        
        
        m_ActiveReaderIdx = -1;
        m_ActiveReaderId = -1;
        m_EmptyDevList = YES;
    }
    return self;
}



- (void)viewDidLoad {
    [super viewDidLoad];
    [self setTitle:@"ReaderList"];
    [self deviceListHasBeenUpdated];
    //注册ID
    [_m_tblReaderList registerClass:[zt_RFIDDeviceCellView class] forCellReuseIdentifier:ZT_CELL_ID_READER_INFO];
    [_m_tblReaderList registerClass:[UITableViewCell class] forCellReuseIdentifier:ZT_CELL_ID_NO_READER];
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [[zt_RfidAppEngine sharedAppEngine] addDeviceListDelegate:self];
    [self deviceListHasBeenUpdated];

}

- (void)dealloc {
    [_m_tblReaderList release];
    [[zt_RfidAppEngine sharedAppEngine] removeDeviceListDelegate:self];
    [super dealloc];
}

- (BOOL)deviceListHasBeenUpdated {
    if ([[[zt_RfidAppEngine sharedAppEngine] getActualDeviceList] count] > 0) {
        NSArray *array = [[zt_RfidAppEngine sharedAppEngine] getActualDeviceList];
        [self.readerList addObjectsFromArray:array];
        BOOL found = NO;
        srfidReaderInfo *info = nil;
        
        for (int i = 0; i < [array count]; i++) {
            info = (srfidReaderInfo *)[array objectAtIndex:i];
            if (m_ActiveReaderId != -1) {
                m_ActiveReaderIdx = i;
                found = YES;
                break;
            } else {
                if (YES == [info isActive]) {
                    m_ActiveReaderId = [info getReaderID];
                    m_ActiveReaderIdx = i;
                    found = YES;
                    break;
                    
                }
                
            }
            //   [self.readerList addObject:array];
        }
        if (NO == found)
        {
            m_ActiveReaderId = -1;
            m_ActiveReaderIdx = -1;
        }
    }
    
    [self.m_tblReaderList reloadData];
    NSLog(@"readerList:%@",self.readerList);
    
    return YES;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    int count = (int)[[[zt_RfidAppEngine sharedAppEngine] getActualDeviceList] count];
    if (0 == count)
    {
        m_ActiveReaderIdx = -1;
        m_ActiveReaderId = -1;
        m_EmptyDevList = YES;
        count = 1;
    }
    else
    {
        m_EmptyDevList = NO;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!m_EmptyDevList)
        
        return [self deviceInfoCellAtIndexPath:indexPath];
    else
    {
        return [self noDeviceCellAtIndexPath:indexPath];
    }

}
- (zt_RFIDDeviceCellView *)deviceInfoCellAtIndexPath:indexPath
{
    zt_RFIDDeviceCellView *cell = [self.m_tblReaderList dequeueReusableCellWithIdentifier:ZT_CELL_ID_READER_INFO forIndexPath:indexPath];
    if (cell == nil)
    {
        cell = [[zt_RFIDDeviceCellView alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ZT_CELL_ID_READER_INFO];
    }
    
    int idx = (int)[indexPath row];
    
    srfidReaderInfo *info = (srfidReaderInfo*)[[[zt_RfidAppEngine sharedAppEngine] getActualDeviceList] objectAtIndex:idx];
    [cell setDataWithReaderInfo:info widthIndex:idx];
    
    if (idx == m_ActiveReaderIdx)
    {
        zt_SledConfiguration * sled = [[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy];
        
        if(![[[zt_RfidAppEngine sharedAppEngine] activeReader] isActive] && [[[zt_RfidAppEngine sharedAppEngine] activeReader] getBatchModeStatus])
        {
            [cell setActiveWithNoValues];
        }
        else if (sled.readerModel != nil)
        {
            [cell setActiveWithModel:[sled readerModel] withSerial:[sled readerSerialNumber] withBTAddress:[sled readerBTAddress]];
        }
        else
        {
            [cell setActiveWithModel:@"Unknown" withSerial:@"Unknown" withBTAddress:@"Unknown"];
        }
    }
    else
    {
        [cell setUnactive];
    }
    
    [cell setNeedsUpdateConstraints];
    [cell updateConstraintsIfNeeded];
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    
    return cell;
}

- (UITableViewCell *)noDeviceCellAtIndexPath:indexPath
{
    UITableViewCell *cell = [self.m_tblReaderList dequeueReusableCellWithIdentifier:ZT_CELL_ID_NO_READER forIndexPath:indexPath];
    [cell.textLabel setText:@"NO available readers"];
    [cell.textLabel setTextColor:[UIColor blackColor]];
    [cell.textLabel setFont:[UIFont systemFontOfSize:ZT_UI_CELL_CUSTOM_FONT_SZ_BIG]];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (NO == m_EmptyDevList)
    {
        int idx = (int)[indexPath row];
        
        NSMutableArray *index_paths = [[NSMutableArray alloc] init];
        
        if (-1 != m_ActiveReaderIdx)
        {
            [index_paths addObject:[NSIndexPath indexPathForRow:m_ActiveReaderIdx inSection:0]];
        }
        
        if (idx == m_ActiveReaderIdx)
        {
            m_ActiveReaderIdx = -1; /* emulate disconnection */
            int _id = m_ActiveReaderId;
            m_ActiveReaderId = -1;
            [[zt_RfidAppEngine sharedAppEngine] disconnect:_id];
        }
        else
        {
            if (-1 != m_ActiveReaderId)
            {
                int _id = m_ActiveReaderId;
                m_ActiveReaderIdx = -1;
                m_ActiveReaderId = -1;
                [[zt_RfidAppEngine sharedAppEngine] disconnect:_id];
            }
            
            //m_ActiveReaderIdx = idx; /* emulate connection */
            //m_ActiveReaderId = [(srfidReaderInfo*)[[[zt_RfidAppEngine sharedAppEngine] getActualDeviceList] objectAtIndex:idx] getReaderID];
            
            [[zt_RfidAppEngine sharedAppEngine] connect:[(srfidReaderInfo*)[[[zt_RfidAppEngine sharedAppEngine] getActualDeviceList] objectAtIndex:idx] getReaderID]];
            
            //[index_paths addObject:[NSIndexPath indexPathForRow:m_ActiveReaderIdx inSection:0]];
        }
        
        [tableView reloadRowsAtIndexPaths:index_paths withRowAnimation:UITableViewRowAnimationFade];
        
        [index_paths removeAllObjects];
        [index_paths release];
    }
}


@end
