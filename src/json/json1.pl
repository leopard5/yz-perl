#!/usr/bin/perl -w
use strict;

use Data::Dumper;
$/=undef;
my $jsontext=<DATA>;

#(?<=c)a 匹配前面为c的a,值匹配a 不匹配c，一般用于替换操作
$jsontext=~s/(?<="):/=>/g;  #"  
print $jsontext,"\n";
my $result=eval $jsontext;

print Dumper($result);
print $result->{type},"\n";
print $result->{items}->[0]->{sent};
__DATA__
{
  "type": "email",
  "items": [
    {
      "sent": "2016-0203:02.00Z",
      "subject": "Upcntation 2016",
      "timeZone": "Australia/Melbourne",
      "content": "We tonts. Way."
    },
    {
      "sent": "2016-029:00:00.00Z",
      "subject": "A pavitation",
      "timeZone": "Australia/Melbourne",
      "content": "The ll 9:00pm - 2:00am"
    }
  ]
}