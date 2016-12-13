//
//  ZebraModel.h
//  ZebraRFD8500
//
//  Created by fengwenwei on 16/11/18.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZebraModel : NSObject

/**name */
@property (strong, nonatomic) NSString *function;

- (instancetype)initWithDict:(NSDictionary *)dict;
+ (instancetype)ZebraModelWithDict:(NSDictionary *)dict;



@end
