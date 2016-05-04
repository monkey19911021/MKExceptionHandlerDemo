//
//  MKUncaughtExceptionHandler.h
//  MKExceptionHandlerDemo
//
//  Created by Liujh on 16/5/4.
//  Copyright © 2016年 cn.mkapple. All rights reserved.
//

/*
 *这是一个异常处理类，异常分为程序抛出异常，可以使用NSException来处理，一种是程序向自身发送signal使程序崩溃，这种需要用到signal处理方法来应对
 *这个类能够捕获这些异常，并把异常信息保存在本地的一个txt文本里，方便以后使用邮件发送到开发者，增强软件的健壮性。
 */
#import <UIKit/UIKit.h>

@interface MKUncaughtExceptionHandler : NSObject
{
	BOOL dismissed;
}

@end

void InstallUncaughtExceptionHandler();
