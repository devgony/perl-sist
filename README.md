# foreach hash + sort

```pl
foreach my $key ( sort keys %volumes ) {}
```

# while key, value each hash

- works from `perl 5.12.1`

```pl
while ( my ( $key, $value ) = each( %volumes ) ) {}
```

# foreach array

```pl
foreach my $val ( @array ) {}
```

# while index, value each array

```pl
while ( my ( $index, $key ) = each(@targets) ) {}
```

# length of array

```pl
scalar @array_name
```

# Data::Dumper

```pl
use Data::Dumper;
print Dumper \%volumes;
```

# Deep copy with clone

```pl
use Clone 'clone';
my %volumes2 = %{ clone( \%volumes ) };
```

  <!-- # if size > 32
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
  #     return done -->

# report

1. remove empty line
2. no args
