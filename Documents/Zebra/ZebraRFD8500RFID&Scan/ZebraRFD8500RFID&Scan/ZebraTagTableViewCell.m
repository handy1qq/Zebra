//
//  ZebraTagTableViewCell.m
//  ZebraRFD8500
//
//  Created by fengwenwei on 16/11/20.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraTagTableViewCell.h"
@interface ZebraTagTableViewCell()

@end

@implementation ZebraTagTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.m_txtTagIdInput.numberOfLines = 0;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (instancetype)cellWithTableView:(UITableView *)tableView {
    static NSString *ID = @"messageCell";
    ZebraTagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [ [ [NSBundle mainBundle] loadNibNamed:@"Tagcell" owner:nil options:nil] lastObject];
    }
    return cell;
}


- (void)dealloc {
    [_m_txtTagIdInput release];
    [_distance release];
    [super dealloc];
}
@end
