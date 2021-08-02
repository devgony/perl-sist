#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use constant A_FILE_SIZE => 32000;    # MB

my $cmd = 'cat mock_df-tm';

# my $cmd = 'df -tm';
my $fileName = $0;
my $message  = "
tbsgen\@0.9.3
Usage1: \$> tbsgen lv_grep=data subdir=ESB tbs_name=TSD_USER size=40G directory=SQLS
Usage2: \$> tbsgen lv_grep=data subdir=ESB parfile=list.par directory=SQLS
* lv_grep:   keyword to grep
- subdir:    optionally sets subdir for datafile [default: '']
* tbs_name:  tablespace name
* size:      each datafile size supports G, M scale[default: M]
* parfile:   list of tablespaces and sizes, example↓
              TSD_USER, 40G
              TSD_TEST, 50G
- directory: optionally sets directory to save [default: ./]\n";

my %args = (
    parfile   => '',
    tbs_name  => '',
    size      => '',
    lv_grep   => '',
    subdir    => '',
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

sub cloneHash {
    my (%origin) = @_;
    my %clonedHash = ();
    while ( my ( $key, $value ) = each(%origin) ) {
        $clonedHash{$key} = $value;
    }
    return %clonedHash;
}

sub parseArgs {
    foreach my $arg (@ARGV) {
        if ( $arg eq 'help' or $arg eq '-h' ) {
            die "Help>$message";
        }
        while ( my ( $key, $value ) = each(%args) ) {
            if ( $arg =~ /$key=/i ) {
                if ( $key eq 'subdir' ) {
                    $args{$key} = "$'/";
                }
                elsif ( $key eq 'size' ) {
                    my $sizeInput = $';
                    $args{$key} = handleScale($sizeInput);
                }
                else {
                    $args{$key} = $';
                }
            }
        }
    }
}

sub handleScale {
    my ($sizeInput) = @_;
    if ( $sizeInput =~ /\d+/ ) {
        my $number = $&;
        my $scale  = $';
        if ( $scale =~ /g/i ) {
            return $number * 1024;
        }
        elsif ( $scale =~ /^m|^\s*\n/i or $scale eq '' ) {
            return $number;
        }
        else {
            die "Err: Wrong scale for size: $sizeInput";
        }
    }
    else {
        die "Err: Wrong number for size: $'";
    }
}

sub getVolumes {
    my @output = qx/$cmd|grep $args{'lv_grep'}|awk '{print \$6","\$4}'/;

    foreach my $line (@output) {
        chomp $line;
        my ( $volume, $size ) = split( ',', $line );
        $volumes{$volume} = $size;
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
    $name =~ s/\W//ig;
    my $sizeMB = handleScale($size);

    # $size =~ s/\D//ig;
    return uc $name, $sizeMB;
}

sub createDatafile {
    my ( $tbsName, $size ) = @_;

    # $size =~ s/\D//ig;
    return 1 if ( $size <= 0 );    # return if done
    my $scale    = $size >= A_FILE_SIZE ? A_FILE_SIZE : $size;
    my $prevSize = $size;

    foreach my $key ( sort keys %volumes ) {
        if ( $volumes{$key} >= $scale ) {
            $volumes{$key} -= $scale;
            $size -= $scale;
            push( @targets, { volume => $key, size => $scale } );
            last;
        }
    }
    if ( $prevSize == $size ) {
        print "Error: Not enough space for $tbsName\n";
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
"CREATE TABLESPACE $tbsName DATAFILE '$key->{volume}/$args{'subdir'}$fileStem\_$suffix.dbf' SIZE $key->{size}M;\n";
        }
        else {
            print FH
"ALTER TABLESPACE $tbsName ADD DATAFILE '$key->{volume}/$args{'subdir'}$fileStem\_$suffix.dbf' SIZE $key->{size}M;\n";
        }
    }
    close(FH);
    print "Created: $outFile\n";
}

sub showRemaining {
    print "Estimated Remaining lv: \n";
    foreach my $key ( sort keys %volumes ) {
        print("$key: $volumes{$key}M\n");
    }
}

sub aCycle {
    my ( $tbsName, $size ) = @_;

    # juse in case for not enough space
    # my %prevVolumes = %{ clone( \%volumes ) };
    my %prevVolumes = cloneHash(%volumes);
    my $ok          = createDatafile( $tbsName, $size );
    if ($ok) {
        writeQuery($tbsName);
    }
    else {
        %volumes = %prevVolumes;
    }
}

sub main {
    if (    $args{'parfile'}
        and $args{'tbs_name'}
        and $args{'size'}
        and $args{'lv_grep'} )
    {
        die "*Error: Conflicted argument:$message";
    }
    elsif ( $args{'tbs_name'} and $args{'size'} and $args{'lv_grep'} ) {
        getVolumes();
        aCycle( $args{'tbs_name'}, $args{'size'} );
    }
    elsif ( $args{'parfile'} and $args{'lv_grep'} ) {
        getVolumes();
        open( FHR, '<', $args{'parfile'} )
          or die "$args{'parfile'}: $!";
        while (<FHR>) {
            unless ( $_ =~ '^\n' ) {
                my ( $tbsName, $size ) = getNameSize($_);
                @targets = ();
                aCycle( $tbsName, $size );
            }
        }
        close(FHR);
    }
    else {
        die "*Error: Not enough argument:$message";
    }
}

parseArgs();
main();
showRemaining();
