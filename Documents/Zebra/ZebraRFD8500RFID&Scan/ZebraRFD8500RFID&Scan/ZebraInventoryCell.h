//
//  ZebraInventoryCell.h
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/6.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZebraInventoryCell : UITableViewCell
@property (retain, nonatomic) IBOutlet UILabel *m_lblTagData;
@property (retain, nonatomic) IBOutlet UILabel *m_lblRSSIData;
@property (retain, nonatomic) IBOutlet UILabel *m_lblTagCount;

@end
