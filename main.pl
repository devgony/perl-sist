use strict;
use warnings;

my %args = (
    parfile  => '',
    tbs_name => '',
    size     => '',
    lv_grep  => '',
);

my %volumes = (
    '/hli_data/oracle/oradata1/' => 100,
    '/hli_data/oracle/oradata2/' => 200,
    '/hli_data/oracle/oradata3/' => 300,
    '/hli_data/oracle/oradata4/' => 400,
);

my @targets = ();

sub getInput {
    print "Write TABLESPACE, SIZE(G): (eg. TSD_USER, 60G)\n";
    my $input = <>;
    chomp $input;
    return $input;
}

sub getNameSize {
    my ($input) = @_;
    my ( $name, $size ) = split( '\s*,', $input );

    # $size =~ s/\s*G\s*//ig;
    $size =~ s/\D//ig;
    return uc $name, $size, lc $name;
}

sub createDatafile {
    my ($size) = @_;
    return if ( $size <= 0 );
    my $scale = $size >= 32 ? 32 : $size;

    foreach my $key ( sort keys %volumes ) {

        if ( $volumes{$key} >= $scale ) {
            $volumes{$key} -= $scale;
            $size -= $scale;

            # print("$key $volumes{$key} $scale \n");
            push( @targets, { volume => $key, size => $scale } );
            last;
        }
    }
    createDatafile($size);
}

sub writeQuery {
    my ( $tbsName, $fileStem ) = @_;
    open( FH, '>', "$tbsName.sql" ) or die $1;
    while ( my ( $index, $key ) = each(@targets) ) {
        my $no     = $index + 1;
        my $suffix = $no < 10 ? "0$no" : "$no";
        if ( $no == 1 ) {
            print FH
"CREATE TABLESPACE $tbsName DATAFILE '$key->{volume}$fileStem\_$suffix.dbf' SIZE $key->{size}G;\n";
        }
        else {
            print FH
"ALTER TABLESPACE $tbsName ADD DATAFILE '$key->{volume}$fileStem\_$suffix.dbf' SIZE $key->{size}G;\n";
        }
    }
    close(FH);
}

######
my $input = getInput();
my ( $tbsName, $size, $fileStem ) = getNameSize($input);
createDatafile($size);
writeQuery( $tbsName, $fileStem )

