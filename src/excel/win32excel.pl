#!/usr/bin/perl -w

use strict;
use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Excel';

$Win32::OLE::Warn = 3;                                # die on errors...

# get already active Excel application or open new
my $Excel = Win32::OLE->GetActiveObject('Excel.Application')
    || Win32::OLE->new('Excel.Application', 'Quit');  

# open Excel file
my $Book = $Excel->Workbooks->Open("c:/komodo projects/test.xls"); 

# You can dynamically obtain the number of worksheets, rows, and columns
# through the Excel OLE interface.  Excel's Visual Basic Editor has more
# information on the Excel OLE interface.  Here we just use the first
# worksheet, rows 1 through 4 and columns 1 through 3.

# select worksheet number 1 (you can also select a worksheet by name)
my $Sheet = $Book->Worksheets(1);

foreach my $row (1..4)
{
 foreach my $col (1..3)
 {
  # skip empty cells
  next unless defined $Sheet->Cells($row,$col)->{'Value'};

 # print out the contents of a cell  
  printf "At ($row, $col) the value is %s and the formula is %s\n",
   $Sheet->Cells($row,$col)->{'Value'},
   $Sheet->Cells($row,$col)->{'Formula'};        
 }
}

# clean up after ourselves
$Book->Close;