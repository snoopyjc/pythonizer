use Carp::Assert;
# Non-interpolative
my $f = 'line1
line2
line3
';
assert($f eq "line1\nline2\nline3\n");

# Interpolative
my $g = "line1
$f
line3
";
assert($g eq "line1\nline1\nline2\nline3\n\nline3\n");

#Here-docs allow you to define any token as the end of a block of quoted text:

# Non-interpolative
my $h = <<'END_TXT';
line1
line2
line3
END_TXT
assert($h eq "line1\nline2\nline3\n");

#Regex style quote operators let you use pretty much any character as the delimiter--in the same way a regex allows you to change delimiters.

# Non-interpolative
my $i = q/line1
line2
line3
/;
assert($i eq "line1\nline2\nline3\n");

# Interpolative
my $i = qq{line1
$f
line3
};
assert($i eq "line1\nline1\nline2\nline3\n\nline3\n");

# Interpolative (Not yet implemented!)
my $j = <<"END_TXT";
line1
$f
line3
END_TXT
assert($j eq "line1\nline1\nline2\nline3\n\nline3\n");

# Old style interpolative (Not yet implemented!)
my $j = <<END_TXT;
line1
$f
line3
END_TXT
assert($j eq "line1\nline1\nline2\nline3\n\nline3\n");

#use constant END_T => 4;
#my $s = 1<<END_T;
#assert($s == (1<<4));

print "$0 - test passed\n";
