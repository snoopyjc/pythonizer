# issue_36: The '.' operator needs to convert it's operands to strings using str() function
use Carp::Assert;
$i=1;
@ar=(1,2,3);
assert("".$i eq "1");
assert("".($i+1) eq "2");
assert("".$ar[0] eq "1");
assert($ar[0]."" eq "1");
assert("".$i.$i.$i."" eq "111");
$s = "abc" . $i;
assert($s eq "abc1");
$t = $i . "abc";
assert($t eq "1abc");
$d = "1";
$u = "abc" . $d;
assert($u eq "abc1");
$hour="1";
%bytes=();
$key=7;
$bytes{$key}={};
$bytes{$key}{r}="2";
$bytes{$key}{c}="3";
$in="4";
$out="5";
my $output =join(",",$hour,$bytes{$key}{r},$bytes{$key}{c},$in,$out);
assert($output eq "1,2,3,4,5");
my $output =join(",",$hour,$bytes{$key}{r},$bytes{$key}{c},$in,$out)."\n";
assert($output eq "1,2,3,4,5\n");
print "$0 - test passed!\n";
