use strict;
use warnings;

my %volumes = (
    '/hli_data/oracle/oradata1/' => 100,
    '/hli_data/oracle/oradata2/' => 200,
    '/hli_data/oracle/oradata3/' => 300,
    '/hli_data/oracle/oradata4/' => 400,
);

my @targets = ();

# print( $volumes{'/hli_data/oracle/oradata1/'}, "\n" );

sub getInput {
    print "Write TABLESPACE, SIZE(G): (eg. TSD_USER, 60G)\n";
    my $input = <>;
    chomp $input;
    return $input;
}

sub getNameSize {
    my ($input) = @_;
    my ( $name, $size ) = split( ',\s*', $input );
    $size =~ s/\s*G\s*//ig;
    return $name, $size, lc $name;
}

sub createDatafile {
    my ($size) = @_;
    return if ( $size <= 0 );
    my $scale = $size >= 32 ? 32 : $size;
    foreach my $key ( sort keys %volumes ) {
        if ( $volumes{$key} >= $scale ) {
            $volumes{$key} -= $scale;
            $size -= $scale;

            # print("$key $volumes{$key}\n");
            push( @targets, { volume => $key, size => $scale } );
            last;
        }
    }
    createDatafile($size);
}

# sub createDatafiles {
#     my ($size) = @_;
#     if ($size > 0) {
#         aDatafile($size)
#     } else {

#     }
# }

# ####
my $input = getInput();
my ( $name, $size, $fileStem ) = getNameSize($input);
createDatafile($size);

# print $targets[0]{'volume'};

foreach my ( $index, $key ) (@targets){
    print "$index, $key->{volume}, $key->{size}\n";
  }

  # 1 => 32
  # 2 => 32
  # 3 => 32

  # if size > 32
  #     if free > 32
  #         find free 32
  #         size - 32,
  #         volume - 32
  #         filename, 32
  #         recur
  #     else
  #         return false
  # else
  #     if free > size
  #         size = 0
  #         volumn - size
  #         filename, size
  #     else
  #         return false
  #     return done
