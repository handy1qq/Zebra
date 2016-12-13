/******************************************************************************
 *
 *       Copyright Zebra Technologies, Inc. 2015
 *
 *       The copyright notice above does not evidence any
 *       actual or intended publication of such source code.
 *       The code contains Zebra Technologies
 *       Confidential Proprietary Information.
 *
 *
 *  Description:  InventoryEngine.m
 *
 *  Notes:
 *
 ******************************************************************************/

#import "RadioOperationEngine.h"
#import "RfidAppEngine.h"
#import "FileExportManager.h"
#import "AlertView.h"
#import "config.h"
#import "ui_config.h"

@implementation zt_RadioOperationEngine

-(id)init
{
    self = [super init];
    if (self != nil)
    {
        m_OperationStatusGuard = [[NSLock alloc] init];
        m_OperationParamGuard = [[NSLock alloc] init];
        
        m_TagReportConfig = nil;
        m_OperationType = ZT_RADIO_OPERATION_NONE;
        m_InventoryIsRequested = NO;
        m_LocationingIsRequested = NO;
        m_OperationInProgress = NO;
        
        m_SessionTime = 0;
        m_RadioOperationTime = 0;
        m_LastStartOperationTime = nil;
        m_FirstStartOperationTime = nil;
        
        m_InventoryMemoryBank = SRFID_MEMORYBANK_NONE;
        
        m_LocationingTagId = [[NSMutableString alloc] init];
        
        m_InventoryData = [[zt_InventoryData alloc] init];
        
        m_ProximityPercent = 0;
        
        m_TagExportCompleted = NO;
        m_TagExportDumped = YES;
        
        m_AbortRequested = NO;
        
        m_TagExportQueue = dispatch_queue_create("com.symbol.rfid_demo_app.tagexportqueue", DISPATCH_QUEUE_SERIAL);
        m_RadioEngineQueue = dispatch_queue_create("com.symbol.rfid_demo_app.radioenginequeue", DISPATCH_QUEUE_SERIAL);
        
        m_ListenersList = [[NSMutableArray alloc] init];
        
    }
    return self;
}

- (void)dealloc
{
    if (nil != m_OperationStatusGuard)
    {
        [m_OperationStatusGuard release];
    }
    
    if (nil != m_OperationParamGuard)
    {
        [m_OperationParamGuard release];
    }
    
    if (nil != m_TagReportConfig)
    {
        [m_TagReportConfig release];
    }
    
    if (nil != m_InventoryData)
    {
        [m_InventoryData release];
    }

    if (nil != m_LocationingTagId)
    {
        [m_LocationingTagId release];
    }
    
    if (nil != m_LastStartOperationTime)
    {
        [m_LastStartOperationTime release];
    }
    
    if (nil != m_FirstStartOperationTime)
    {
        [m_FirstStartOperationTime release];
    }
    
    if (nil != m_TagExportQueue)
    {
        dispatch_release(m_TagExportQueue);
    }
    
    if (nil != m_RadioEngineQueue)
    {
        dispatch_release(m_RadioEngineQueue);
    }
    
    if (nil != m_ListenersList)
    {
        [m_ListenersList removeAllObjects];
        [m_ListenersList release];
    }
    [super dealloc];
}

- (void)addOperationListener:(id<zt_IRadioOperationEngineListener>)delegate
{
    /* nrv364: no guard for listeners list as all access is supposed to be performed from UI thread */
    [m_ListenersList addObject:delegate];
}

- (void)removeOperationListener:(id<zt_IRadioOperationEngineListener>)delegate
{
    [m_ListenersList removeObject:delegate];
}

- (void) eventRadioOperation:(BOOL)started
{
    dispatch_async(m_RadioEngineQueue, ^{
        if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
        {
            m_OperationInProgress = started;
            [self notifyOperationInProgress];
            
            if (ZT_RADIO_OPERATION_INVENTORY ==  m_OperationType || m_batchModeEvent == SRFID_EVENT_STATUS_OPERATION_BATCHMODE)
            {
                if (YES == m_OperationInProgress)
                {
                    
                    if(m_batchModeEvent == SRFID_EVENT_STATUS_OPERATION_BATCHMODE)
                    {
                        m_OperationType = ZT_RADIO_OPERATION_INVENTORY;
                        m_InventoryIsRequested = YES;
                        m_LocationingIsRequested = NO;
                        
                        /* update operation related status/data */
                        
                        /* clear inventory data */
                        [m_InventoryData clearInventoryItemList];
                        //[[[zt_RfidAppEngine sharedAppEngine] appConfiguration] clearSelectedItem];
                        
                        /* clear time statistics */
                        if (nil != m_LastStartOperationTime)
                        {
                            [m_LastStartOperationTime release];
                            m_LastStartOperationTime = nil;
                        }
                        if (nil != m_FirstStartOperationTime)
                        {
                            [m_FirstStartOperationTime release];
                            m_FirstStartOperationTime = nil;
                        }
                        m_SessionTime = 0;
                        m_RadioOperationTime = 0;
                        
                        [self notifyOperationRequested];

                    }
                    else
                    {
                        /* save time instant of first start notification */
                        if (nil == m_FirstStartOperationTime)
                        {
                            m_FirstStartOperationTime = [[NSDate date] retain];
                        }
                        
                        if (nil != m_LastStartOperationTime)
                        {
                            [m_LastStartOperationTime release];
                            m_LastStartOperationTime = nil;
                        }
                        
                        /* save time instant of current (last) start notification */
                        m_LastStartOperationTime = [[NSDate date] retain];
                    }
                    
                }
                else /* STOP notification */
                {
                    /* check whether is is final stop -> repeat monitoring is disabled or abort has been issued */
                    
                    if (((NO == [[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] isStartTriggerPeriodic])
                         && (NO == [[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] isStartTriggerHandheld]))
                        || (YES == m_AbortRequested))
                    {
                        /* operation has finally stopped -> reader is ready for next start command */
                        m_InventoryIsRequested = NO;
                        [self notifyOperationRequested];
                    }
                    
                    /* calculate operation time */
                    if (nil != m_LastStartOperationTime)
                    {
                        NSTimeInterval cycle_time = [[NSDate date] timeIntervalSinceDate:m_LastStartOperationTime];
                        m_RadioOperationTime += cycle_time;
                        [m_LastStartOperationTime release];
                        m_LastStartOperationTime = nil;
                    }
                    
                    /* check whether we shall do data export */
                    /*
                     nrv364:
                     - tag data is exported in one of following cases:
                     - on STOP notification received after issued abort command:
                     - example #1:
                     - start = hh press; stop = hh release
                     - inv; hh press; start; hh release; stop; hh press; start; abort; stop >> export
                     - example #2:
                     - start = periodic; stop = duration
                     - inv; start; stop; start; stop; start; abort; stop >> export
                     - on issuing abort command if radio operation is not in progress:
                     - example #1:
                     - start = hh press; stop = hh release
                     - inv; hh press; start; hh release; stop; abort >> export
                     - example #2:
                     - start = immediate; stop = immediate
                     - inv; start; abort >> export
                     - on STOP notification w/o issued abort command if repeat monitoring
                     option is disabled in start trigger configuration
                     - example #1:
                     - start = immediate; stop = duration
                     - inv; start; stop >> export
                     - example #2:
                     - start = immediate; stop = hh
                     - inv; start; hh; stop >> export
                     */
                    BOOL _export = NO;
                    if (YES == m_AbortRequested)
                    {
                        NSLog(@"EXPORT data on STOP notification after ABORT");
                        _export = YES;
                    }
                    else if (NO == [[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] isStartTriggerRepeatMonitoring])
                    {
                        NSLog(@"EXPORT data on STOP notification w/o REPEAT");
                        _export = YES;
                    }
                    if (YES == _export)
                    {
                        if (nil != m_FirstStartOperationTime)
                        {
                            m_SessionTime = [[NSDate date] timeIntervalSinceDate:m_FirstStartOperationTime];
                        }
                        
                        dispatch_async(m_TagExportQueue, ^{
                            [self logInventoryToFile:nil];
                        });
                    }
                    
                }
            }
            else if (ZT_RADIO_OPERATION_LOCATIONING == m_OperationType)
            {
                /* check whether is is final stop -> repeat monitoring is disabled or abort has been issued */
                
                if (NO == m_OperationInProgress)
                {
                    if (((NO == [[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] isStartTriggerPeriodic])
                         && (NO == [[[zt_RfidAppEngine sharedAppEngine] sledConfiguration] isStartTriggerHandheld]))
                        || (YES == m_AbortRequested))
                    {
                        /* operation has finally stopped -> reader is ready for next start command */
                        m_LocationingIsRequested = NO;
                        [self notifyOperationRequested];
                    }
                }
            }
            
            [m_OperationStatusGuard unlock];
        }
    });
}

- (void) eventTagData:(srfidTagData*)data
{
    dispatch_async(m_RadioEngineQueue, ^{
        if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
        {
            [m_InventoryData addInventoryItem:data];
            [m_OperationStatusGuard unlock];
        }
    });
}

- (void) eventProximityData:(int)percent
{
    dispatch_async(m_RadioEngineQueue, ^{
        if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
        {
            m_ProximityPercent = percent;
            [m_OperationStatusGuard unlock];
        }
    });
}

- (void) eventSessionTerminated
{
    NSString *deviceName = @"";
    int reader_id = [[[zt_RfidAppEngine sharedAppEngine] activeReader] getReaderID];
    NSArray *devList = [[zt_RfidAppEngine sharedAppEngine] getActualDeviceList];
    for (srfidReaderInfo *info in devList) {
        if ([info getReaderID] == reader_id) {
            deviceName = [NSString stringWithString:[info getReaderName]];
        }
    }
    
    dispatch_async(m_RadioEngineQueue, ^{
        if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
        {
            if (ZT_RADIO_OPERATION_INVENTORY == m_OperationType)
            {
                if (nil != m_FirstStartOperationTime)
                {
                    m_SessionTime = [[NSDate date] timeIntervalSinceDate:m_FirstStartOperationTime];
                }
                if (nil != m_LastStartOperationTime)
                {
                    m_RadioOperationTime += [[NSDate date] timeIntervalSinceDate:m_LastStartOperationTime];
                    [m_LastStartOperationTime release];
                    m_LastStartOperationTime = nil;
                }
                
                dispatch_async(m_TagExportQueue, ^{
                    NSLog(@"EXPORT data on TERMINATED connection");
                    if([[[zt_RfidAppEngine sharedAppEngine] temporarySledConfigurationCopy] currentBatchMode]==1)
                        m_readerTerminated = YES;
                    else
                        m_readerTerminated = NO;
                    [self logInventoryToFile:deviceName];
                });
                
                m_InventoryIsRequested = NO;
            }
            else if (ZT_RADIO_OPERATION_LOCATIONING == m_OperationType)
            {
                m_LocationingIsRequested = NO;
            }
            
            [self notifyOperationRequested];
            
            /* cleanup */
            m_AbortRequested = NO;
            m_OperationInProgress = NO;
            [self notifyOperationInProgress];
            
            [m_OperationStatusGuard unlock];
        }
    });
}

- (SRFID_RESULT)startInventory:(BOOL)isReportOptions aMemoryBank:(SRFID_MEMORYBANK)mem_bank message:(NSString **)statusMessage
{
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        /* waiting while current inventory list is not dumped */
        int count = 15*100; /* 15 seconds */
        while (NO == m_TagExportDumped)
        {
            usleep(10*1000); // 10 ms
            count--;
            if (count <= 0)
            {
                break;
            }
        }
        
        /* mark new inventory data as not dumped */
        m_TagExportDumped = NO;
        /* mark tag export as required */
        dispatch_async(m_TagExportQueue, ^{
            m_TagExportCompleted = NO;
        });
        
        /* abort is not requested */
        m_AbortRequested = NO;
        
        zt_SledConfiguration *_sled_cfg = [[zt_RfidAppEngine sharedAppEngine] sledConfiguration];
        
        if (YES == [m_OperationParamGuard lockBeforeDate:[NSDate distantFuture]])
        {
            if (nil != m_TagReportConfig)
            {
                [m_TagReportConfig release];
                m_TagReportConfig = nil;
            }
            /* save report settings */
            if(YES == isReportOptions)
            {
                m_TagReportConfig = [[_sled_cfg getReportConfig] retain];
            }
            else
            {
                m_TagReportConfig = [[_sled_cfg getReportConfigAllOff] retain];
            }
            
            /* save memory bank settings */
            m_InventoryMemoryBank = mem_bank;
            
            [m_OperationParamGuard unlock];
        }
        
        srfidAccessConfig *_access_cfg = [[srfidAccessConfig alloc] init];
        
        if (_sled_cfg.applyFirstFilter || _sled_cfg.applySecondFilter)
        {
            [_access_cfg setDoSelect:YES];
        }
        else
        {
            [_access_cfg setDoSelect:NO];
        }
        
        
        NSString *status_msg = nil;
        m_readerTerminated = NO;
        int reader_id = [[[zt_RfidAppEngine sharedAppEngine] activeReader] getReaderID];
        SRFID_RESULT res = [[zt_RfidAppEngine sharedAppEngine] sdkStartInventory:reader_id aMemoryBank:mem_bank aReportConfig:m_TagReportConfig aAccessConfig:_access_cfg aStatusMessage:&status_msg];
        
        if (SRFID_RESULT_SUCCESS != res && ![status_msg isEqualToString:@"Inventory Started in Batch Mode"])
        {
            /* failed to start operation */
            
            /* mark current (null) inventory list as dumped */
            dispatch_async(m_TagExportQueue, ^{
                m_TagExportDumped = YES;
            });
            
            /* proceed with error message */
            NSString *error_msg = @"Operation failed";
            if (SRFID_RESULT_RESPONSE_ERROR == res)
            {
                if (nil != status_msg)
                {
                    error_msg = [NSString stringWithFormat:@"Operation failed: %@", status_msg];
                    if (nil != statusMessage)
                    {
                        *statusMessage = [NSString stringWithFormat:@"%@", status_msg];
                    }
                }
            }
            else if (SRFID_RESULT_RESPONSE_TIMEOUT == res)
            {
                error_msg = [NSString stringWithFormat:@"Operation failed: timeout"];
            }
            else if (SRFID_RESULT_READER_NOT_AVAILABLE == res)
            {
                error_msg = [NSString stringWithFormat:@"Operation failed: no active reader"];
            }
            
            if (SRFID_RESULT_READER_NOT_AVAILABLE == res)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    zt_AlertView *alert = [[zt_AlertView alloc] init];
                    [alert showWarningText:[[UIApplication sharedApplication] keyWindow].rootViewController.view withString:ZT_WARNING_NO_READER];
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [zt_AlertView showInfoMessage:[[UIApplication sharedApplication] keyWindow].rootViewController.view withHeader:ZT_RFID_APP_NAME withDetails:error_msg withDuration:3];
                });
            }
        }
        else
        {
            /* operation has started successfully */
            m_OperationType = ZT_RADIO_OPERATION_INVENTORY;
            m_InventoryIsRequested = YES;
            m_LocationingIsRequested = NO;
            
            /* update operation related status/data */
            
            /* clear inventory data */
            [m_InventoryData clearInventoryItemList];
            //[[[zt_RfidAppEngine sharedAppEngine] appConfiguration] clearSelectedItem];
            
            /* clear time statistics */
            if (nil != m_LastStartOperationTime)
            {
                [m_LastStartOperationTime release];
                m_LastStartOperationTime = nil;
            }
            if (nil != m_FirstStartOperationTime)
            {
                [m_FirstStartOperationTime release];
                m_FirstStartOperationTime = nil;
            }
            m_SessionTime = 0;
            m_RadioOperationTime = 0;
            
            [self notifyOperationRequested];
            if([status_msg isEqualToString:@"Inventory Started in Batch Mode"])
            {
                if (nil != statusMessage)
                {
                    *statusMessage = [NSString stringWithFormat:@"%@", status_msg];
                }
            }
        }
        
        if (nil != _access_cfg)
        {
            [_access_cfg release];
        }
        
        [m_OperationStatusGuard unlock];
        
        return res;
    }
    return SRFID_RESULT_FAILURE;
}

- (SRFID_RESULT)stopInventory:(NSString **)statusMessage
{
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        /*run only once on stop */
        m_AbortRequested = YES;
       
        if (NO == m_OperationInProgress)
        {
            /* abort while operation is not active */
            
            if (nil != m_FirstStartOperationTime)
            {
                m_SessionTime = [[NSDate date] timeIntervalSinceDate:m_FirstStartOperationTime];
            }
            NSLog(@"EXPORT data on ABORT");
            dispatch_async(m_TagExportQueue, ^{
                [self logInventoryToFile:nil];
            });
        }
        
        int reader_id = [[[zt_RfidAppEngine sharedAppEngine] activeReader] getReaderID];
        SRFID_RESULT res = [[zt_RfidAppEngine sharedAppEngine] sdkStopInventory:reader_id aStatusMessage:statusMessage];
        if (NO == m_OperationInProgress)
        {
            /* if abort is send when operation is not in progress -> it's a final stop, reader shall
             be ready for next start command */
            m_InventoryIsRequested = NO;
            [self notifyOperationRequested];
        }
        
        [m_OperationStatusGuard unlock];
        
        return res;
    }

    return SRFID_RESULT_FAILURE;
}

- (SRFID_RESULT)startTagLocationing:(NSString*)tagEpcID message:(NSString **)statusMessage
{
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        if (YES == [m_OperationParamGuard lockBeforeDate:[NSDate distantFuture]])
        {
            [m_LocationingTagId setString:tagEpcID];
            
            [m_OperationParamGuard unlock];
        }
        
        m_AbortRequested = NO;
        
        NSString *status_msg = nil;
        int reader_id = [[[zt_RfidAppEngine sharedAppEngine] activeReader] getReaderID];
        SRFID_RESULT res = [[zt_RfidAppEngine sharedAppEngine] sdkStartTagLocationing:reader_id aEpcId:m_LocationingTagId aStatusMessage:&status_msg];
        
        if (SRFID_RESULT_SUCCESS != res)
        {
            /* failed to start operation */
            /* proceed with error message */
            NSString *error_msg = @"Operation failed";
            if (SRFID_RESULT_RESPONSE_ERROR == res)
            {
                if (nil != status_msg)
                {
                    error_msg = [NSString stringWithFormat:@"Operation failed: %@", status_msg];
                    if (nil != statusMessage)
                    {
                        *statusMessage = [NSString stringWithFormat:@"%@", status_msg];
                    }
                }
            }
            else if (SRFID_RESULT_RESPONSE_TIMEOUT == res)
            {
                error_msg = [NSString stringWithFormat:@"Operation failed: timeout"];
            }
            else if (SRFID_RESULT_READER_NOT_AVAILABLE == res)
            {
                error_msg = [NSString stringWithFormat:@"Operation failed: no active reader"];
            }
            
            if (SRFID_RESULT_READER_NOT_AVAILABLE == res)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    zt_AlertView *alert = [[zt_AlertView alloc] init];
                    [alert showWarningText:[[UIApplication sharedApplication] keyWindow].rootViewController.view withString:ZT_WARNING_NO_READER];
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [zt_AlertView showInfoMessage:[[UIApplication sharedApplication] keyWindow].rootViewController.view withHeader:ZT_RFID_APP_NAME withDetails:error_msg withDuration:3];
                });
            }
        }
        else
        {
            /* operation has started successfully */
            m_OperationType = ZT_RADIO_OPERATION_LOCATIONING;
            m_InventoryIsRequested = NO;
            m_LocationingIsRequested = YES;
            m_ProximityPercent = 0;
            [self notifyOperationRequested];
        }
        
        [m_OperationStatusGuard unlock];
        
        return res;
    }
    return SRFID_RESULT_FAILURE;
}

- (SRFID_RESULT)stopTagLocationing:(NSString **)statusMessage
{
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        m_AbortRequested = YES;
        int reader_id = [[[zt_RfidAppEngine sharedAppEngine] activeReader] getReaderID];
        SRFID_RESULT res = [[zt_RfidAppEngine sharedAppEngine] sdkStopTagLocationing:reader_id aStatusMessage:statusMessage];
        
        if (NO == m_OperationInProgress)
        {
            /* if abort is send when operation is not in progress -> it's a final stop, reader shall
             be ready for next start command */
            m_LocationingIsRequested = NO;
            [self notifyOperationRequested];
        }
        
        [m_OperationStatusGuard unlock];
        
        return res;
    }
    return SRFID_RESULT_FAILURE;
}

- (void)clearLocationingStatistics
{
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        m_ProximityPercent = 0;
        [m_OperationStatusGuard unlock];
    }
}

- (void)logInventoryToFile:(NSString*)readerName
{
    if(![[[zt_RfidAppEngine sharedAppEngine] activeReader] getBatchModeStatus])
    {
    BOOL res = YES;
    NSFileHandle *file_handle = nil;
    int unique_count = 0;
    int total_count = 0;
    NSArray *dumped_tags = nil;
    BOOL is_inventory_operation = NO;
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        dumped_tags = [m_InventoryData getDumpedInventoryList];
        unique_count = (int)[zt_InventoryData getUniqueCount:dumped_tags];
        total_count = [zt_InventoryData getTotalCount:dumped_tags];
        
        /* mark current list as dumped one */
        m_TagExportDumped = YES;
        
        if (ZT_RADIO_OPERATION_INVENTORY == m_OperationType)
        {
            is_inventory_operation = YES;
        }
        
        [m_OperationStatusGuard unlock];
    }
    
    do
    {
        if (NO == is_inventory_operation)
        {
            NSLog(@"Operation is not inventory -> SKIP export ");
            break;
        }
        
        if (NO == [[[zt_RfidAppEngine sharedAppEngine] appConfiguration] getConfigDataExport])
        {
            NSLog(@"EXPORT is OFF");
            break;
        }
        if (YES == m_TagExportCompleted && !m_readerTerminated)
        {
            NSLog(@"EXPORT has been ALREADY completed");
            break;
        }
        
        // File name
        NSError *error;
        NSDate *currentTime = [NSDate date];
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'_'HH'-'mm'-'ss'.'SSS"];
        NSString *currentTimeString = [dateFormatter stringFromDate:currentTime];
        
        NSString *deviceName = @"";
        if (nil == readerName)
        {
            int reader_id = [[[zt_RfidAppEngine sharedAppEngine] activeReader] getReaderID];
            NSArray *devList = [[zt_RfidAppEngine sharedAppEngine] getActualDeviceList];
            for (srfidReaderInfo *info in devList) {
                if ([info getReaderID] == reader_id) {
                    deviceName = [NSString stringWithString:[info getReaderName]];
                }
            }
        }
        else
        {
            deviceName = [NSString stringWithString:readerName];
        }
        
        
        NSString *fileName = [NSString stringWithFormat:@"%@_%@.csv",deviceName, currentTimeString];
        
        // Directory
        NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
        
        // Get the file contents
        NSString *header = [zt_FileExportManager getHeaderWithCount:unique_count withTotalCount:total_count withReadTime:m_SessionTime];
        //NSString *data = [zt_FileExportManager getData:dumped_tags];
        //header = [header stringByAppendingFormat:@"%@", data];
        
        header = [header stringByAppendingString:@"TAG ID, COUNT"];
        
        // Write to the file
        res = [header writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (NO == res)
        {
            break;
        }
        
        file_handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
        [file_handle seekToEndOfFile];
        
        NSMutableString *str_data = [[NSMutableString alloc] init];
        [str_data setString:@""];
        NSUInteger count = [dumped_tags count];
        int simple_count = 0;
        zt_InventoryItem *tag = nil;
        for (int i = 0; i < count; i++)
        {
            tag = [dumped_tags objectAtIndex:i];
            [str_data appendFormat:@"\r%@,%d", [tag getTagId], [tag getCount]];
            simple_count++;
            if ( (simple_count > 200) || ((count - 1) == i) )
            {
                //res = [str_data write writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
                [file_handle writeData:[str_data dataUsingEncoding:NSUTF8StringEncoding]];
                /*if (NO == res)
                 {
                 [str_data release];
                 break;
                 }
                 */
                simple_count = 0;
                [str_data setString:@""];
            }
        }
        [str_data release];
        
        // Check files in folder
#if 0
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDir = [paths objectAtIndex:0];
        NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentDir error:&error];
#endif
        
        m_TagExportCompleted = YES;
        NSInteger ti = (NSInteger)m_SessionTime;
        NSInteger seconds = ti % 60;
        NSInteger minutes = (ti / 60) % 60;
        NSInteger hours = (ti / 3600);
        NSLog(@"EXPORT is COMPLETED:\n\tfile=%@\n\ttotal=%d\n\tunique=%d\n\ttime=%@", fileName, total_count, unique_count, [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds]);
    } while (0);
    
    if (nil != file_handle)
    {
        [file_handle closeFile];
    }
    
    if (NO == res)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [zt_AlertView showInfoMessage:[[UIApplication sharedApplication] keyWindow].rootViewController.view withHeader:ZT_RFID_APP_NAME withDetails:@"Failed to export inventory data" withDuration:3];
        });
    }
    if (nil != dumped_tags)
    {
        [dumped_tags release];
    }
    }
}

/* operation status */
- (int)getStateOperationType
{
    int res = ZT_RADIO_OPERATION_NONE;
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        res = m_OperationType;
        [m_OperationStatusGuard unlock];
    }
    return res;
}

- (BOOL)getStateInventoryRequested
{
    BOOL res = NO;
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        res = m_InventoryIsRequested;
        [m_OperationStatusGuard unlock];
    }
    return res;
}

- (BOOL)getStateLocationingRequested
{
    BOOL res = NO;
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        res = m_LocationingIsRequested;
        [m_OperationStatusGuard unlock];
    }
    return res;
}

- (BOOL)getStateOperationInProgress
{
    BOOL res = NO;
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        res = m_OperationInProgress;
        [m_OperationStatusGuard unlock];
    }
    return res;
}

- (zt_InventoryData*)inventoryData
{
    return m_InventoryData;
}

- (NSTimeInterval)getRadioOperationTime
{
    NSTimeInterval res = 0.0;
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        res = m_RadioOperationTime;
        [m_OperationStatusGuard unlock];
    }

    return res;
}

- (NSDate*)getLastStartOperationTime
{
    NSDate *res = nil;
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        res = [m_LastStartOperationTime retain];
        [m_OperationStatusGuard unlock];
    }

    return res;
}

- (int)getProximityPercent
{
    int res = 0;
    if (YES == [m_OperationStatusGuard lockBeforeDate:[NSDate distantFuture]])
    {
        res = m_ProximityPercent;
        [m_OperationStatusGuard unlock];
    }
    return res;
}

/* operation parameters */
- (srfidReportConfig*)getInventoryReportConfig
{
    srfidReportConfig *cfg = [[srfidReportConfig alloc] init];
    if (YES == [m_OperationParamGuard lockBeforeDate:[NSDate distantFuture]])
    {
        [cfg setIncChannelIndex:[m_TagReportConfig getIncChannelIndex]];
        [cfg setIncFirstSeenTime:[m_TagReportConfig getIncFirstSeenTime]];
        [cfg setIncLastSeenTime:[m_TagReportConfig getIncLastSeenTime]];
        [cfg setIncPC:[m_TagReportConfig getIncPC]];
        [cfg setIncPhase:[m_TagReportConfig getIncPhase]];
        [cfg setIncRSSI:[m_TagReportConfig getIncRSSI]];
        [cfg setIncTagSeenCount:[m_TagReportConfig getIncTagSeenCount]];
        
        [m_OperationParamGuard unlock];
    }
    return cfg;
}

- (SRFID_MEMORYBANK)getInventoryMemoryBank
{
    SRFID_MEMORYBANK res = SRFID_MEMORYBANK_NONE;
    if (YES == [m_OperationParamGuard lockBeforeDate:[NSDate distantFuture]])
    {
        res = m_InventoryMemoryBank;
        [m_OperationParamGuard unlock];
    }
    return res;
}

- (void)setInventoryMemoryBank:(SRFID_MEMORYBANK)val
{
    if (YES == [m_OperationParamGuard lockBeforeDate:[NSDate distantFuture]])
    {
        m_InventoryMemoryBank = val;
        [m_OperationParamGuard unlock];
    }
}

- (NSString*)getLocationingTagId
{
    NSString *res = nil;
    if (YES == [m_OperationParamGuard lockBeforeDate:[NSDate distantFuture]])
    {
        res = [NSString stringWithString:m_LocationingTagId];
        [m_OperationParamGuard unlock];
    }
    return res;
}

/* notifications */
- (void)notifyOperationRequested
{
    BOOL requested = NO;
    if (ZT_RADIO_OPERATION_INVENTORY == m_OperationType)
    {
        requested = m_InventoryIsRequested;
    }
    else if (ZT_RADIO_OPERATION_LOCATIONING == m_OperationType)
    {
        requested = m_LocationingIsRequested;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id <zt_IRadioOperationEngineListener> listener in m_ListenersList)
        {
            [listener radioStateChangedOperationRequested:requested aType:m_OperationType];
        }
    });
}

- (void)notifyOperationInProgress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (id <zt_IRadioOperationEngineListener> listener in m_ListenersList)
        {
            [listener radioStateChangedOperationInProgress:m_OperationInProgress aType:m_OperationType];
        }
    });
}

- (void) setCurrentBatchModeStatus:(int)event
{
    m_batchModeEvent = event;
}



@end
