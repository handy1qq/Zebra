//
//  ZebraInventoryCell.m
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/6.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraInventoryCell.h"

@implementation ZebraInventoryCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)dealloc {
    [_m_lblTagData release];
    [_m_lblRSSIData release];
    [_m_lblTagCount release];
    [super dealloc];
}
@end
