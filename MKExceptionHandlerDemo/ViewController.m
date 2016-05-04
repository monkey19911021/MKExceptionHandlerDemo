//
//  ViewController.m
//  MKExceptionHandlerDemo
//
//  Created by Liujh on 16/5/4.
//  Copyright © 2016年 cn.mkapple. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//调用不存在的方法
- (IBAction)check:(UIButton *)sender {
    [self performSelector:@selector(test)];
}

//数组越界
- (IBAction)outOfLength:(id)sender {
    NSArray *array = @[@"object1"];
    //故意让数组越界：
    NSLog(@"%@", [array objectAtIndex:3]);
}

//为不存在的属性设置
- (IBAction)setValueForUndefinedKey:(id)sender {
    [self setValue:@"test" forKey:@"test"];
}

//信号机制，需要真机测试，模拟机发生的信号会被OS X拦截
- (IBAction)signalException:(id)sender {
    void (*nullFunction)()=NULL;
    nullFunction();
}

@end
