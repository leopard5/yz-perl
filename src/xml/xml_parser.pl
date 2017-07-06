use XML::Parser;

my $parser = XML::Parser->new( Handlers => {Start=>\&handle_start,End=>\&handle_end,});
$parser->parsefile( "yourXML.xml" );

my @element_stack;          # remember which elements are open

sub handle_start {
    my( $expat, $element, %attrs ) = @_;

    my $line = $expat->current_line;

    print "$element starting on # $line!\n";

    push( @element_stack, { element=>$element, line=>$line });

    if( %attrs ) {
        print "Attributes:\n";
        while( my( $key, $value ) = each( %attrs )) {
            print "\t$key => $value\n";
         }
    }
}

sub handle_end {
    my( $expat, $element ) = @_;

    my $element_record = pop( @element_stack );
    print "$element started on # ", $$element_record{ line };
}