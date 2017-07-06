#!perl
use strict;
use warnings;
use utf8;
use Encode;
use DBI;

my $dsn="DBI:mysql:database=test;host=localhost;port=3306";
my $user="root";
my $password="123456";

#连接数据库
my $dbh=DBI->connect($dsn,$user,$password,{'RaiseError'=>1});

#设置客户端编码
$dbh->do("SET character_set_client = 'utf8'");
$dbh->do("SET character_set_connection = 'utf8'");
$dbh->do("SET character_set_results= 'utf8'");

#执行查询
my $sth=$dbh->prepare("select ename from emp");
$sth->execute();

#处理结果集
while(my $ref=$sth->fetchrow_hashref()){
	#encode,decode用来转换编码
	print encode("gbk",decode("utf8",$ref->{'ename'})),"\n";
}

#断开连接
$sth->finish();
$dbh->disconnect();