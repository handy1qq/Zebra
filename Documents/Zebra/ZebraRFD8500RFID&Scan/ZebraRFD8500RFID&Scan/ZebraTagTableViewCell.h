//
//  ZebraTagTableViewCell.h
//  ZebraRFD8500
//
//  Created by fengwenwei on 16/11/20.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZebraTagTableViewCell : UITableViewCell
@property (retain, nonatomic) IBOutlet UILabel *m_txtTagIdInput;
@property (retain, nonatomic) IBOutlet UILabel *distance;


+ (instancetype)cellWithTableView:(UITableView *)tableView;

@end
