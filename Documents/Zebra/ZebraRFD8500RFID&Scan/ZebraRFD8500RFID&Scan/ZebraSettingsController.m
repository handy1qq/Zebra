//
//  ZebraSettingsController.m
//  ZebraRFD8500RFID&Scan
//
//  Created by fengwenwei on 16/12/5.
//  Copyright © 2016年 fengwenwei. All rights reserved.
//

#import "ZebraSettingsController.h"
#import "RfidAppEngine.h"
#import "ZebraModel.h"
#import "ZebraTableViewCell.h"
#import "ZebraReaderListController.h"

@interface ZebraSettingsController ()<UITableViewDataSource,UITableViewDelegate,zt_IRfidAppEngineDevListDelegate>

/**<#注释#> */
@property (strong, nonatomic) NSMutableArray *readerList;


@end

@implementation ZebraSettingsController


- (NSMutableArray *)readerList {
    if (_readerList == nil) {
        _readerList = [NSMutableArray array];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"function.json" ofType:nil];
        NSData *data = [NSData dataWithContentsOfFile:path];
        NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        NSMutableArray *reader = [NSMutableArray array];
        for (NSDictionary *dic in array) {
            ZebraModel *model = [[ZebraModel alloc] initWithDict:dic];
            [reader addObject:model];
        }
        _readerList = reader;
    }
    return _readerList;
}

- (void)dealloc {
    //[_readerList release];
   // [self.tableView release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.readerList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *iD = @"read";
    // Configure the cell...
    ZebraTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:iD forIndexPath:indexPath];
    cell.model = self.readerList[indexPath.item];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {

            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            ZebraReaderListController *readerList = [[UIStoryboard storyboardWithName:@"ZebraRFID" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"vc"];
            [self.navigationController pushViewController:readerList animated:YES];
        
    }

}

- (BOOL)deviceListHasBeenUpdated {
    return YES;

}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
