//
//  ViewController.m
//  SPHttpWithCache
//
//  Created by 换一换 on 16/3/8.
//  Copyright © 2016年 张洋. All rights reserved.
//

#import "ViewController.h"
#import "SPHttpWithYYCache.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
 // [self deleteCache];
   [SPHttpWithYYCache getRequestCacheUrlStr:@"http://api.beikeshushe.com/gateway.php??uid=33&method=readgroup.recommend_read_group&p=1" success:^(NSDictionary *requestDic, NSString *msg) {
       NSLog(@"%@",requestDic);
   } failure:^(NSString *errorInfo) {
       
   }];
    
    
    
}
-(void)deleteCache
{
    [[[YYCache alloc] initWithName:@"SPHttpCache"] removeAllObjectsWithProgressBlock:nil endBlock:^(BOOL error) {
        if (!error) {
            NSLog(@"清除成功");
        }
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
