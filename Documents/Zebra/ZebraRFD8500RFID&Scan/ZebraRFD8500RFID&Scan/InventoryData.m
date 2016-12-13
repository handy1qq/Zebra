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
 *  Description:  InventoryData.m
 *
 *  Notes:
 *
 ******************************************************************************/

#import "InventoryData.h"
#import "RfidAppEngine.h"

@interface zt_InventoryData()
{
    NSMutableArray *m_InventoryItemList;
    NSLock *m_InventoryItemListGuard;
}

@end

@implementation zt_InventoryData

-(id)init
{
    self = [super init];
    if (self != nil)
    {
        m_InventoryItemList = [[NSMutableArray alloc] init];
        m_InventoryItemListGuard = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    if (nil != m_InventoryItemListGuard)
    {
        [m_InventoryItemListGuard release];
    }
    
    if (nil != m_InventoryItemList)
    {
        [m_InventoryItemList removeAllObjects];
        [m_InventoryItemList release];
    }
    
    [super dealloc];
}

- (BOOL)myContainsString:(NSString*)string1 withOtherString:(NSString *)string2{
    NSRange range = [string1 rangeOfString:string2];
    return range.length != 0;
}

- (NSArray*) getInventoryList:(BOOL)search
{
    NSMutableArray *_tags = [[NSMutableArray alloc] init];
    
    if (YES == [m_InventoryItemListGuard lockBeforeDate:[NSDate distantFuture]])
    {
        if (NO == search)
        {
            [_tags addObjectsFromArray:m_InventoryItemList];
        }
        else
        {
            for (zt_InventoryItem *tag_data in m_InventoryItemList)
            {
                NSString *tag_id = [[tag_data getTagId] uppercaseString];
                if (YES == [self myContainsString:tag_id withOtherString:[[[zt_RfidAppEngine sharedAppEngine] appConfiguration] getTagSearchCriteria]])
                {
                    [_tags addObject:tag_data];
                }
            }
        }
        [m_InventoryItemListGuard unlock];
    }
    return _tags;
}

- (void)addInventoryItem:(srfidTagData *)tagData
{
    if (YES == [m_InventoryItemListGuard lockBeforeDate:[NSDate distantFuture]])
    {
        BOOL _found = NO;
        /* TBD: nrv364: use appropriate container to increase performane for many tags */
        for (zt_InventoryItem *_old_item in m_InventoryItemList)
        {
            if (YES == [[_old_item getTagId] isEqualToString:[tagData getTagId]])
            {
                _found = YES;
                
                [_old_item incCount];
                
                if (NO == [[_old_item getMemoryBankData] isEqualToString:[tagData getMemoryBankData]])
                {
                    [[_old_item getTagData] setMemoryBankData:[tagData getMemoryBankData]];
                    /* nrv364: why MemoryBank is not set (android impl) */
                }
                
                /* TBD: nrv364: PC, phase, channel, rssi are set only
                 if app settings enable their inclusion on protocol level
                 (android impl) */
                [[_old_item getTagData] setPC:[tagData getPC]];
                [[_old_item getTagData] setPeakRSSI:[tagData getPeakRSSI]];
                [[_old_item getTagData] setPhaseInfo:[tagData getPhaseInfo]];
                [[_old_item getTagData] setChannelIndex:[tagData getChannelIndex]];
                break;
            }
        }
        if (NO == _found)
        {
            zt_InventoryItem *_item = [[zt_InventoryItem alloc] initWithTagData:tagData];
            
            /* TBD: nrv364:
             - PC, phase, channel, rssi are set only
             if app settings enable their inclusion on protocol level
             (android impl)
             - default values are zeros (android impl)
             */
            for (int i=1; i<tagData.getTagSeenCount; i++) {
                [_item incCount];
            }
            [m_InventoryItemList addObject:_item];
            
            [_item release];
        }
        
        [m_InventoryItemListGuard unlock];
    }
}

- (void)clearInventoryItemList
{
    
    if (YES == [m_InventoryItemListGuard lockBeforeDate:[NSDate distantFuture]])
    {
        [m_InventoryItemList removeAllObjects];
        
        [m_InventoryItemListGuard unlock];
    }
}

+ (unsigned long)getUniqueCount:(NSArray*)tags
{
    return [tags count];
}

+ (int)getTotalCount:(NSArray*)tags
{
    int totalTagCount = 0;
    
    for (zt_InventoryItem *tag_data in tags)
    {
        totalTagCount += [tag_data getCount];
    }
    
    return totalTagCount;
}

- (NSArray*)getDumpedInventoryList
{
    NSMutableArray *_dumped = [[NSMutableArray alloc] init];
    
    if (YES == [m_InventoryItemListGuard lockBeforeDate:[NSDate distantFuture]])
    {
        [_dumped addObjectsFromArray:m_InventoryItemList];
        [m_InventoryItemListGuard unlock];
    }
    return _dumped;
}

@end
