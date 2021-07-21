# foreach hash

```pl
foreach my $key ( sort keys %volumes ) {}
```

# while key, value each hash

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
