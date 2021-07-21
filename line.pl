use strict;
use warnings;

my $message =
"  Usage1: \$> perl main.pl lv_grep=oradata tbs_name=TSD_USER size=40G\n  Usage2: \$> perl main.pl lv_grep=oradata parfile=list.par\n";

my %args = (
    parfile  => '',
    tbs_name => '',
    size     => '',
    lv_grep  => '',
);

foreach my $arg (@ARGV) {
    if ( $arg eq 'help' or $arg eq '-h' ) {
        die "help:\n$message";
    }
    while ( my ( $key, $value ) = each(%args) ) {
        if ( $arg =~ /$key=/i ) {
            $args{$key} = $';
        }
    }
}

if ( $args{'parfile'} and $args{'lv_grep'} ) {
    print "$args{'parfile'}, $args{'lv_grep'}";
}
elsif ( $args{'tbs_name'} and $args{'size'} and $args{'lv_grep'} ) {
    print "$args{'tbs_name'}, $args{'size'}, $args{'lv_grep'}";
}
else {
    die "Not enough argument:\n$message";
}

# while ( my ( $key, $value ) = each(%args) ) {
#     if ($value) {
#         print "$key=$value\n";
#     }
# }

# mendatory
# parfile, lv_grep
# tbs_name, size, lv_grep
