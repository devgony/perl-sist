use strict;
use warnings;
use Data::Dumper;
use Clone 'clone';

my $fileName = $0;

my $message = "
Usage1: \$> perl $fileName lv_grep=oradata tbs_name=TSD_USER size=40G directory=SQLS
  *directory is optional [default = ./]
Usage2: \$> perl $fileName lv_grep=oradata parfile=list.par directory=SQLS
  list.par:
    TSD_USER, 40G
    TSD_TEST, 50G\n";

my $cmd = 'cat mock_df-tg';

my %args = (
    parfile   => '',
    tbs_name  => '',
    size      => '',
    lv_grep   => '',
    directory => '.',
);

# my %volumes = (
#     '/hli_data/oracle/oradata1/' => 100,
#     '/hli_data/oracle/oradata2/' => 200,
#     '/hli_data/oracle/oradata3/' => 300,
#     '/hli_data/oracle/oradata4/' => 400,
# );

my %volumes = ();

my @targets = ();

sub parseArgs {
    foreach my $arg (@ARGV) {
        if ( $arg eq 'help' or $arg eq '-h' ) {
            die "help:$message";
        }
        while ( my ( $key, $value ) = each(%args) ) {
            if ( $arg =~ /$key=/i ) {
                $args{$key} = $';
            }
        }
    }
}

# sub getInput {
#     print "Write TABLESPACE, SIZE(G): (eg. TSD_USER, 60G)\n";
#     my $input = <>;
#     chomp $input;
#     return $input;
# }

sub getNameSize {
    my ($input) = @_;
    my ( $name, $size ) = split( '\s*,', $input );

    # $size =~ s/\s*G\s*//ig;
    $size =~ s/\D//ig;
    return uc $name, $size;
}

sub createDatafile {
    my ( $tbsName, $size ) = @_;
    $size =~ s/\D//ig;
    return 1 if ( $size <= 0 );    # return if done
    my $scale    = $size >= 32 ? 32 : $size;
    my $prevSize = $size;

    foreach my $key ( sort keys %volumes ) {
        if ( $volumes{$key} >= $scale ) {
            $volumes{$key} -= $scale;

            # print "$key, $volumes{$key}\n";
            $size -= $scale;

            # print("$key $volumes{$key} $scale \n");
            push( @targets, { volume => $key, size => $scale } );
            last;
        }

    }
    if ( $prevSize == $size ) {
        print "Error: Not enough space for $tbsName\n";

        # %volumes = %{ clone( \%prevVolumes ) };
        return 0;
    }
    else {
        createDatafile( $tbsName, $size );
    }
}

sub writeQuery {
    my ($tbsName) = @_;
    my $fileStem = lc $tbsName;
    $tbsName = uc $tbsName;
    my $outFile = "$args{'directory'}/$tbsName.sql";
    open( FH, '>', "$outFile" ) or die "$outFile: $!";
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
    print "Created: $outFile\n";
}

sub showRemaining {
    print "Estimated Remaining lv: \n";
    foreach my $key ( sort keys %volumes ) {
        print("$key: $volumes{$key}G\n");
    }
}

sub aCycle {
    my ( $tbsName, $size ) = @_;

    # juse in case for not enough space
    my %prevVolumes = %{ clone( \%volumes ) };
    my $ok          = createDatafile( $tbsName, $size );
    if ($ok) {
        writeQuery($tbsName);
    }
    else {
        %volumes = %prevVolumes;
    }
}

sub main {
    if ( $args{'parfile'} and $args{'lv_grep'} ) {

        # print "$args{'parfile'}, $args{'lv_grep'}\n";
        open( FHR, '<', $args{'parfile'} )
          or die "$args{'parfile'}: $!";
        while (<FHR>) {
            my ( $tbsName, $size ) = getNameSize($_);
            @targets = ();
            aCycle( $tbsName, $size );
        }
        close(FHR);
    }
    elsif ( $args{'tbs_name'} and $args{'size'} and $args{'lv_grep'} ) {

        # print "$args{'tbs_name'}, $args{'size'}, $args{'lv_grep'}";
        # my $ok = createDatafile( $args{'tbs_name'}, $args{'size'} );
        # writeQuery( $args{'tbs_name'} ) if $ok;
        aCycle( $args{'tbs_name'}, $args{'size'} );

    }
    else {
        die "Not enough argument:$message";
    }
}

# sub readFile {
#     open( FH, '<', $args{'parfile'} ) or die $!;
#     while (<FH>) {
#         print $_;
#     }
#     close(FH);
# }

######
# my $input = getInput();
# my ( $tbsName, $size, $fileStem ) = getNameSize($input);
# createDatafile($size);
# writeQuery( $tbsName, $fileStem )

sub getVolumes {
    my @output = qx/$cmd|grep $args{'lv_grep'}|awk '{print \$7","\$5}'/;

    # print "$output:\n";
    foreach my $line (@output) {
        chomp $line;
        my ( $volume, $size ) = split( ',', $line );
        $volumes{$volume} = $size;
    }
}

parseArgs();
getVolumes();
main();
showRemaining();

# perl main.pl lv_grep=oradata parfile=list.par

