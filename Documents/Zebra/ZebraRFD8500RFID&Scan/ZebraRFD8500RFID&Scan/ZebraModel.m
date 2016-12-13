//
//  ZebraModel.m
//  ZebraRFD8500
//
//  Created by fengwenwei on 16/11/18.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraModel.h"

@implementation ZebraModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    if ( self = [super init] ) {
        self.function = dict[@"function"];
    }
    return self;
}

+ (instancetype)ZebraModelWithDict:(NSDictionary *)dict {
    return [ [ZebraModel alloc] initWithDict:dict];

}

@end
