use DBI;
use strict;
# 定义数据库名称和驱动
my $driver   = "SQLite";
my $db_name = "xmodulo.db";
my $dbd = "DBI:$driver:dbname=$db_name";
# sqlite 没有用户名密码的概念
my $username = "";
my $password = "";
# 创建并连接到数据库
# 以下创建的文件名为 xmodulo.db
my $dbh = DBI->connect($dbd, $username, $password, { RaiseError => 1 })
                      or die $DBI::errstr;
print STDERR "Database opened successfully\n";
# 创建表
my $stmt = qq(CREATE TABLE IF NOT EXISTS NETWORK
             (ID INTEGER PRIMARY KEY     AUTOINCREMENT,
              HOSTNAME       TEXT    NOT NULL,
              IPADDRESS      INT     NOT NULL,
              OS             CHAR(50),
              CPULOAD        REAL););
my $ret = $dbh->do($stmt);
if($ret < 0) {
   print STDERR $DBI::errstr;
} else {
   print STDERR "Table created successfully\n";
}
# 插入三行到表中
$stmt = qq(INSERT INTO NETWORK (HOSTNAME,IPADDRESS,OS,CPULOAD)
           VALUES ('xmodulo', 16843009, 'Ubuntu 14.10', 0.0));
$ret = $dbh->do($stmt) or die $DBI::errstr;
$stmt = qq(INSERT INTO NETWORK (HOSTNAME,IPADDRESS,OS,CPULOAD)
           VALUES ('bert', 16843010, 'CentOS 7', 0.0));
$ret = $dbh->do($stmt) or die $DBI::errstr;
$stmt = qq(INSERT INTO NETWORK (HOSTNAME,IPADDRESS,OS,CPULOAD)
           VALUES ('puppy', 16843011, 'Ubuntu 14.10', 0.0));
$ret = $dbh->do($stmt) or die $DBI::errstr;
# 在表中检索行
$stmt = qq(SELECT id, hostname, os, cpuload from NETWORK;);
my $obj = $dbh->prepare($stmt);
$ret = $obj->execute() or die $DBI::errstr;
if($ret < 0) {
   print STDERR $DBI::errstr;
}
while(my @row = $obj->fetchrow_array()) {
      print "ID: ". $row[0] . "\n";
      print "HOSTNAME: ". $row[1] ."\n";
      print "OS: ". $row[2] ."\n";
      print "CPULOAD: ". $row[3] ."\n\n";
}
# 更新表中的某行
$stmt = qq(UPDATE NETWORK set CPULOAD = 50 where OS='Ubuntu 14.10';);
$ret = $dbh->do($stmt) or die $DBI::errstr;
if( $ret < 0 ) {
   print STDERR $DBI::errstr;
} else {
   print STDERR "A total of $ret rows updated\n";
}
# 从表中删除某行
$stmt = qq(DELETE from NETWORK where ID=2;);
$ret = $dbh->do($stmt) or die $DBI::errstr;
if($ret < 0) {
   print STDERR $DBI::errstr;
} else {
   print STDERR "A total of $ret rows deleted\n";
}
# 断开数据库连接
$dbh->disconnect();
print STDERR "Exit the database\n";