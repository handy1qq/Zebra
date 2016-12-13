//
//  ZebraTableViewCell.m
//  ZebraRFD8500
//
//  Created by fengwenwei on 16/11/18.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraTableViewCell.h"
#import "ZebraModel.h"

@interface ZebraTableViewCell()

@property (retain, nonatomic) IBOutlet UILabel *name;


@end

@implementation ZebraTableViewCell


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setModel:(ZebraModel *)model {
    _model = model;
    self.name.text = model.function;
    
}

- (void)awakeFromNib {
    self.name.numberOfLines = 0;

}

- (void)dealloc {
    [_name release];
    [super dealloc];
}
@end
