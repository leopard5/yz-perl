use threads; #声明模块
use warnings;use strict;
print localtime(time),"\n"; #输出系统时间；
my $j=0;
my $thread;
while()
{
	last if($j>=10)；#这里控制一下任务数量，共10个；
	#控制创建的线程数，这里是5，scalar函数返回列表threads->list()元素的个数；
	while(scalar(threads->list())<5)
	{ $j++; #创建一个线程，这个线程其实就是调用（引用）函数“ss”； #函数‘ss’包含两个参数（$j和$j）；
		threads->new(\&ss,$j,$j);
	}
	foreach $thread(threads->list(threads::all))
	{ if($thread->is_joinable()) #判断线程是否运行完成；
		{ $thread->join();
			#输出中间结果；
			print scalar(threads->list()),"\t$j\t",localtime(time),"\n";
		}
	}
}
#join掉剩下的线程（因为在while中当j=10时，还有4个线程正在运行，但是此时程序将退出while循，所以在这里需要额外程序join掉剩下的4个线程）
foreach $thread(threads->list(threads::all))
{ 
	$thread->join();
	print scalar(threads->list()),"\t$j\t",localtime(time),"\n";
}
#输出程序结束的时间，和程序开始运行时间比较，看程序运行性能；
print localtime(time),"\n";
#下面就是每个线程引用的函数；
sub ss()
{ 
	my ($t,$s)=@_;
	sleep($t); #sleep函数，睡觉；以秒为单位；
	print "$s\t";
}