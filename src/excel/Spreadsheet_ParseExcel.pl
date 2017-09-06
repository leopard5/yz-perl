#!/usr/bin/perl -w

use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::FmtUnicode;

my $parser   = Spreadsheet::ParseExcel->new();
my $formatter = Spreadsheet::ParseExcel::FmtUnicode->new(Unicode_Map=>"CP936");
my $workbook = $parser->parse('example.xls', $formatter);

if ( !defined $workbook ) {
    die $parser->error(), ".\n";
}

for my $worksheet ( $workbook->worksheets() ) {

    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();

    for my $row ( $row_min .. $row_max ) {
        for my $col ( $col_min .. $col_max ) {
           my $cell = $worksheet->get_cell( $row, $col );
           next unless $cell;
           print "Row, Col    = ($row, $col)\n";
           print "Value       = ", $cell->value(),       "\n";
           print "\n";
        }
    }
}