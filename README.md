# iOS异常处理模块使用说明
## iOS异常说明：
	iOS的异常有两种：
1.	普通异常，能够被NSException捕获的异常<br>
对于普通异常我们可以使用NSException来捕获并且进行处理。

2.	信号机制异常，不能够被NSException捕获的异常，由系统向自身发出闪退信号导致程序崩溃。<br>
对于信号机制异常，需要用信号处理函数: `void	(*signal(int, void (*)(int)))(int);`<br>
	1.	为某信号注册处理函数：`signal(SIGABRT, SignalHandler);`  为信号SIGABRT注册一个SignalHandler处理方法。<br>
	2.	实现SignalHandler方法：`void SignalHandler(int signal){//实现方法}；`


## UncaughtExceptionHandler使用方法：
在项目的`AppDelegate.m`文件的import进`UncaughtExceptionHandler.h`
然后在方法：`- (BOOL)application: didFinishLaunchingWithOptions；`里设置全局异常监控方法：`InstallUncaughtExceptionHandler();`

每当异常出现就会弹出一个异常提示框告诉用户软件出现崩溃了，之后程序就会闪退了，并且会在程序的Documents文件夹里生成命名格式为：Exception+时间的异常日志。

之后需要添加异常日志发送功能，这样开发者就能立即修复软件的错误。
