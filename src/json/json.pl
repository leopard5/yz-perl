#!/usr/bin/perl
use Encode;
use JSON;
use Data::Dumper;

my $json = new JSON;
#或以转换字符集 my $json = JSON->new->utf8;
my $json_obj;

if(open(MYFILE, "FILE_PATH/json.html")) 
{
  print "读取json数据成功。\n";
  while(<MYFILE>) 
  {
    $json_obj = $json->decode("$_");
    #见下面的解析方法 
  }
}else{
  print "读取json数据失败。\n";
}