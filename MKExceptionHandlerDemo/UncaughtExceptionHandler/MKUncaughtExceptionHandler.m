//
//  MKUncaughtExceptionHandler.m
//  MKExceptionHandlerDemo
//
//  Created by Liujh on 16/5/4.
//  Copyright © 2016年 cn.mkapple. All rights reserved.
//

#import "MKUncaughtExceptionHandler.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"未捕获异常类型：signal";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 0;//最后调用的地址（即函数名）
const NSInteger UncaughtExceptionHandlerReportAddressCount = 10;//显示多少调用地址

@implementation MKUncaughtExceptionHandler

NSString *applicationDocumentsDirectory() {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

//取得设备和app信息：
NSString *getAppInfo()
{
    NSString *appInfo = [NSString stringWithFormat:@"应用名 : %@ %@(%@)\n设备 : %@\n系统版本 : %@ %@\n",
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                         [UIDevice currentDevice].model,
                         [UIDevice currentDevice].systemName,
                         [UIDevice currentDevice].systemVersion];
    return appInfo;
}

//记录异常
void logException(NSException *exception) {
    NSArray *arr = [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    
    NSString *url = [NSString stringWithFormat:@"=============异常崩溃报告=============\n异常名:%@\n\n日期:%@\n\n原因:%@\n\n设备和APP信息：\n%@\n\n调用栈:\n%@",name,[NSDate date],reason,getAppInfo(),[arr componentsJoinedByString:@"\n"]];
    NSString *path = [applicationDocumentsDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Exception_%@.txt",[NSDate date]]];
    [url writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
    //除了可以选择写到应用下的某个文件，通过后续处理将信息发送到服务器等
    //还可以选择调用发送邮件的的程序，发送信息到指定的邮件地址
    //或者调用某个处理程序来处理这个信息
}

//调出最后程序崩溃前调用的函数
+ (NSArray *)backtrace
{
	 void* callstack[128];
	 int frames = backtrace(callstack, 128);
	 char **strs = backtrace_symbols(callstack, frames);
	 
	 int i;
	 NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
	 for (
	 	i = UncaughtExceptionHandlerSkipAddressCount;
	 	i < UncaughtExceptionHandlerSkipAddressCount +
			UncaughtExceptionHandlerReportAddressCount;
		i++)
	 {
	 	[backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
	 }
	 free(strs);
	 
	 return backtrace;
}

- (void)alertView:(UIAlertView *)anAlertView clickedButtonAtIndex:(NSInteger)anIndex
{
	if (anIndex == 0)
	{
		dismissed = YES;
	}
}


//处理异常，弹出提示框，释放线程
- (void)handleException:(NSException *)exception
{
	
	UIAlertView *alert =
		[[UIAlertView alloc]
			initWithTitle:NSLocalizedString(@"程序出现异常", nil)
			message:[NSString stringWithFormat:NSLocalizedString(
				@"你可以尝试继续，但程序会变得不稳定\n\n"
				@"异常详细:\n%@\n%@", nil),
				[exception reason],
				[[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]]
			delegate:self
			cancelButtonTitle:NSLocalizedString(@"退出", nil)
			otherButtonTitles:NSLocalizedString(@"继续", nil), nil];
	[alert show];
    
    logException(exception);
	
	CFRunLoopRef runLoop = CFRunLoopGetCurrent();
	CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
	
	while (!dismissed)
	{
		for (NSString *mode in (NSArray *)CFBridgingRelease(allModes))
		{
			CFRunLoopRunInMode((CFStringRef)CFBridgingRetain(mode), 0.001, false);
		}
	}
	
	CFRelease(allModes);

	NSSetUncaughtExceptionHandler(NULL);
	signal(SIGABRT, SIG_DFL);
	signal(SIGILL, SIG_DFL);
	signal(SIGSEGV, SIG_DFL);
	signal(SIGFPE, SIG_DFL);
	signal(SIGBUS, SIG_DFL);
	signal(SIGPIPE, SIG_DFL);
	
	if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
	{
		kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
	}
	else
	{
		[exception raise];
	}
}

@end

//处理可捕获异常，存储异常信息，调用异常处理方法
void HandleException(NSException *exception)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
    
//	NSArray *callStack = [UncaughtExceptionHandler backtrace];
	NSMutableDictionary *userInfo =
		[NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
	[userInfo
		setObject:[exception callStackSymbols]
		forKey:UncaughtExceptionHandlerAddressesKey];
	
	[[[MKUncaughtExceptionHandler alloc] init]
		performSelectorOnMainThread:@selector(handleException:)
		withObject:
			[NSException
				exceptionWithName:[exception name]
				reason:[exception reason]
				userInfo:userInfo]
		waitUntilDone:YES];
}

//处理程序发出信号的崩溃，存储崩溃前程序调用的函数栈，调用异常处理方法
void SignalHandler(int signal)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum)
	{
		return;
	}
	
	NSMutableDictionary *userInfo =
		[NSMutableDictionary
			dictionaryWithObject:[NSNumber numberWithInt:signal]
			forKey:UncaughtExceptionHandlerSignalKey];

	NSArray *callStack = [MKUncaughtExceptionHandler backtrace];
	[userInfo
		setObject:callStack
		forKey:UncaughtExceptionHandlerAddressesKey];
	
	[[[MKUncaughtExceptionHandler alloc] init]
		performSelectorOnMainThread:@selector(handleException:)
		withObject:
			[NSException
				exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
				reason:
					[NSString stringWithFormat:
						NSLocalizedString(@"程序发送了“%d”信号.\n", nil),
						signal]
				userInfo:userInfo]
		waitUntilDone:YES];
}

//对外接口，处理整个程序的异常
void InstallUncaughtExceptionHandler()
{
	NSSetUncaughtExceptionHandler(&HandleException);
	signal(SIGABRT, SignalHandler);
	signal(SIGILL, SignalHandler);
	signal(SIGSEGV, SignalHandler);
	signal(SIGFPE, SignalHandler);
	signal(SIGBUS, SignalHandler);
	signal(SIGPIPE, SignalHandler);
}

